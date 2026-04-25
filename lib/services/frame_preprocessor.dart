import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ghosteye_frame_ffi/ghosteye_frame_ffi.dart';

import '../models/frame_data.dart';
import '../models/frame_preprocessor_settings.dart';
import 'image_converter.dart';

class FramePreprocessorResult {
  const FramePreprocessorResult({
    required this.imageBytes,
    required this.backend,
  });

  final Uint8List imageBytes;
  final FramePreprocessorBackend backend;
}

abstract class FramePreprocessor {
  factory FramePreprocessor.worker({
    required FramePreprocessorSettings settings,
    Duration workerDelay = Duration.zero,
    String? ffiLibraryPath,
  }) {
    final resolvedSettings = settings.backend == FramePreprocessorBackend.ffi &&
            !supportsBackend(FramePreprocessorBackend.ffi)
        ? settings.copyWith(backend: FramePreprocessorBackend.dart)
        : settings;

    return switch (resolvedSettings.backend) {
      FramePreprocessorBackend.dart => DartFramePreprocessor(
          settings: resolvedSettings,
          workerDelay: workerDelay,
          ffiLibraryPath: ffiLibraryPath,
        ),
      FramePreprocessorBackend.ffi => FfiFramePreprocessor(
          settings: resolvedSettings,
          workerDelay: workerDelay,
          ffiLibraryPath: ffiLibraryPath,
        ),
    };
  }

  FramePreprocessorSettings get settings;

  Future<FramePreprocessorResult> preprocess(FrameData frame);

  Future<void> dispose();

  static bool supportsBackend(FramePreprocessorBackend backend) {
    return switch (backend) {
      FramePreprocessorBackend.dart => true,
      FramePreprocessorBackend.ffi => GhosteyeFrameFfi.isSupported,
    };
  }
}

class DartFramePreprocessor extends _WorkerFramePreprocessor {
  DartFramePreprocessor({
    required super.settings,
    super.workerDelay,
    super.ffiLibraryPath,
  });
}

class FfiFramePreprocessor extends _WorkerFramePreprocessor {
  FfiFramePreprocessor({
    required super.settings,
    super.workerDelay,
    super.ffiLibraryPath,
  });
}

class _WorkerFramePreprocessor implements FramePreprocessor {
  _WorkerFramePreprocessor({
    required this.settings,
    this.workerDelay = Duration.zero,
    this.ffiLibraryPath,
  });

  @override
  final FramePreprocessorSettings settings;
  final Duration workerDelay;
  final String? ffiLibraryPath;

  final Map<int, Completer<FramePreprocessorResult>> _pendingRequests =
      <int, Completer<FramePreprocessorResult>>{};
  ReceivePort? _receivePort;
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;
  Isolate? _workerIsolate;
  Completer<SendPort>? _readyPortCompleter;
  var _nextRequestId = 0;
  var _isDisposed = false;

  @override
  Future<FramePreprocessorResult> preprocess(FrameData frame) async {
    if (_isDisposed) {
      throw StateError('FramePreprocessor has already been disposed.');
    }

    final sendPort = await _ensureWorkerPort();
    final requestId = _nextRequestId++;
    final completer = Completer<FramePreprocessorResult>();
    _pendingRequests[requestId] = completer;
    sendPort.send(_buildProcessMessage(requestId, frame));
    return completer.future;
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    if (_readyPortCompleter case final readyPort?) {
      if (!readyPort.isCompleted) {
        readyPort.completeError(
          StateError('Frame preprocessing was canceled during shutdown.'),
        );
      }
    }

    if (_readyPortCompleter case final readyPort?) {
      try {
        final sendPort = await readyPort.future;
        sendPort.send(const <Object?>['shutdown']);
      } catch (_) {
        // The worker never finished booting; failing pending requests above is
        // sufficient for shutdown in that case.
      }
    }

    _workerIsolate?.kill(priority: Isolate.immediate);
    _workerIsolate = null;
    _receivePort?.close();
    _errorPort?.close();
    _exitPort?.close();

    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Frame preprocessing was canceled during shutdown.'),
        );
      }
    }
    _pendingRequests.clear();
  }

  Future<SendPort> _ensureWorkerPort() async {
    if (_readyPortCompleter case final existing?) {
      return existing.future;
    }

    final completer = _readyPortCompleter = Completer<SendPort>();
    _receivePort = ReceivePort()..listen(_handleWorkerMessage);
    _errorPort = ReceivePort()..listen(_handleWorkerError);
    _exitPort = ReceivePort()..listen(_handleWorkerExit);

    _workerIsolate = await Isolate.spawn<_WorkerBootstrapMessage>(
      _workerMain,
      _WorkerBootstrapMessage(
        sendPort: _receivePort!.sendPort,
        backend: settings.backend,
        workerDelay: workerDelay,
        ffiLibraryPath: ffiLibraryPath,
      ),
      onError: _errorPort!.sendPort,
      onExit: _exitPort!.sendPort,
    );

    return completer.future;
  }

  List<Object?> _buildProcessMessage(int requestId, FrameData frame) {
    return <Object?>[
      'process',
      requestId,
      settings.maxDimension,
      settings.jpegQuality,
      frame.format,
      frame.width,
      frame.height,
      <List<Object?>>[
        for (final plane in frame.planes)
          <Object?>[
            TransferableTypedData.fromList(<Uint8List>[plane.bytes]),
            plane.bytesPerRow,
            plane.bytesPerPixel,
          ],
      ],
    ];
  }

  void _handleWorkerMessage(dynamic message) {
    if (message is! List<Object?> || message.isEmpty) {
      return;
    }

    final kind = message.first;
    if (kind == 'ready') {
      final sendPort = message[1] as SendPort;
      if (!(_readyPortCompleter?.isCompleted ?? true)) {
        _readyPortCompleter!.complete(sendPort);
      }
      return;
    }

    if (kind == 'result') {
      final requestId = message[1] as int;
      final data = message[2] as TransferableTypedData;
      final completer = _pendingRequests.remove(requestId);
      if (completer == null || completer.isCompleted) {
        return;
      }
      completer.complete(
        FramePreprocessorResult(
          imageBytes: data.materialize().asUint8List(),
          backend: settings.backend,
        ),
      );
      return;
    }

    if (kind == 'error') {
      final requestId = message[1] as int;
      final errorMessage = message[2] as String;
      final completer = _pendingRequests.remove(requestId);
      if (completer == null || completer.isCompleted) {
        return;
      }
      completer.completeError(StateError(errorMessage));
    }
  }

  void _handleWorkerError(dynamic message) {
    final errorMessage = switch (message) {
      [final Object error, final Object stackTrace] => '$error\n$stackTrace',
      _ => 'Unknown frame worker failure.',
    };
    _failPendingRequests(StateError(errorMessage));
  }

  void _handleWorkerExit(dynamic _) {
    if (_isDisposed) {
      return;
    }
    _failPendingRequests(
      StateError('Frame preprocessing worker exited unexpectedly.'),
    );
  }

  void _failPendingRequests(Object error) {
    if (_readyPortCompleter case final readyPort?) {
      if (!readyPort.isCompleted) {
        readyPort.completeError(error);
      }
    }
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pendingRequests.clear();
  }
}

class _WorkerBootstrapMessage {
  const _WorkerBootstrapMessage({
    required this.sendPort,
    required this.backend,
    required this.workerDelay,
    this.ffiLibraryPath,
  });

  final SendPort sendPort;
  final FramePreprocessorBackend backend;
  final Duration workerDelay;
  final String? ffiLibraryPath;
}

void _workerMain(_WorkerBootstrapMessage bootstrap) {
  final receivePort = ReceivePort();
  final codec = ImageConverterService();
  GhosteyeFrameFfi? ffi;

  bootstrap.sendPort.send(<Object?>['ready', receivePort.sendPort]);

  receivePort.listen((dynamic message) async {
    if (message is! List<Object?> || message.isEmpty) {
      return;
    }

    final kind = message.first;
    if (kind == 'shutdown') {
      receivePort.close();
      Isolate.exit();
    }

    if (kind != 'process') {
      return;
    }

    final requestId = message[1] as int;
    final maxDimension = message[2] as int;
    final jpegQuality = message[3] as int;
    final format = message[4] as String;
    final width = message[5] as int;
    final height = message[6] as int;
    final rawPlanes = (message[7] as List<Object?>).cast<List<Object?>>();

    try {
      if (bootstrap.workerDelay > Duration.zero) {
        await Future<void>.delayed(bootstrap.workerDelay);
      }

      final frame = FrameData(
        width: width,
        height: height,
        format: format,
        planes: rawPlanes
            .map((rawPlane) => FramePlaneData(
                  bytes: (rawPlane[0] as TransferableTypedData)
                      .materialize()
                      .asUint8List(),
                  bytesPerRow: rawPlane[1] as int,
                  bytesPerPixel: rawPlane[2] as int,
                ))
            .toList(growable: false),
      );

      final imageBytes = switch (bootstrap.backend) {
        FramePreprocessorBackend.dart => codec.convertFrameToImageBytes(
            frame,
            maxDimension: maxDimension,
            jpegQuality: jpegQuality,
          ),
        FramePreprocessorBackend.ffi => _convertWithFfi(
            ffi: ffi ??= GhosteyeFrameFfi(
              libraryPath: bootstrap.ffiLibraryPath,
            ),
            frame: frame,
            maxDimension: maxDimension,
            jpegQuality: jpegQuality,
          ),
      };

      bootstrap.sendPort.send(
        <Object?>[
          'result',
          requestId,
          TransferableTypedData.fromList(<Uint8List>[imageBytes]),
        ],
      );
    } catch (error, stackTrace) {
      bootstrap.sendPort.send(
        <Object?>[
          'error',
          requestId,
          '$error\n$stackTrace',
        ],
      );
    }
  });
}

Uint8List _convertWithFfi({
  required GhosteyeFrameFfi ffi,
  required FrameData frame,
  required int maxDimension,
  required int jpegQuality,
}) {
  return switch (frame.format) {
    'bgra8888' => ffi.convertBgra8888ToJpeg(
        bytes: frame.planes.first.bytes,
        width: frame.width,
        height: frame.height,
        bytesPerRow: frame.planes.first.bytesPerRow,
        maxDimension: maxDimension,
        quality: jpegQuality,
      ),
    'yuv420' => ffi.convertYuv420ToJpeg(
        yPlane: frame.planes[0].bytes,
        yBytesPerRow: frame.planes[0].bytesPerRow,
        uPlane: frame.planes[1].bytes,
        uBytesPerRow: frame.planes[1].bytesPerRow,
        uBytesPerPixel: frame.planes[1].bytesPerPixel,
        vPlane: frame.planes[2].bytes,
        vBytesPerRow: frame.planes[2].bytesPerRow,
        vBytesPerPixel: frame.planes[2].bytesPerPixel,
        width: frame.width,
        height: frame.height,
        maxDimension: maxDimension,
        quality: jpegQuality,
      ),
    _ => throw UnsupportedError('Unsupported camera format: ${frame.format}'),
  };
}
