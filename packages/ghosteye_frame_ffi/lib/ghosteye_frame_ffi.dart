import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

class GhosteyeFrameRgbImage {
  const GhosteyeFrameRgbImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

const String _libName = 'ghosteye_frame_ffi';

class GhosteyeFrameFfi {
  GhosteyeFrameFfi({String? libraryPath})
      : _bindings = _GhosteyeFrameBindings(_openLibrary(libraryPath));

  static bool get isSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  final _GhosteyeFrameBindings _bindings;

  int get activeAllocationCount => _bindings.activeAllocations();

  GhosteyeFrameRgbImage convertBgra8888ToRgb({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required int maxDimension,
  }) {
    final bgraPointer = _copyBytesToNative(bytes);
    try {
      return _runConversion(
        (outImage) => _bindings.convertBgra8888ToRgb(
          bgraPointer,
          width,
          height,
          bytesPerRow,
          maxDimension,
          outImage,
        ),
      );
    } finally {
      malloc.free(bgraPointer);
    }
  }

  GhosteyeFrameRgbImage convertYuv420ToRgb({
    required Uint8List yPlane,
    required int yBytesPerRow,
    required Uint8List uPlane,
    required int uBytesPerRow,
    required int uBytesPerPixel,
    required Uint8List vPlane,
    required int vBytesPerRow,
    required int vBytesPerPixel,
    required int width,
    required int height,
    required int maxDimension,
  }) {
    final yPointer = _copyBytesToNative(yPlane);
    final uPointer = _copyBytesToNative(uPlane);
    final vPointer = _copyBytesToNative(vPlane);

    try {
      return _runConversion(
        (outImage) => _bindings.convertYuv420ToRgb(
          yPointer,
          yBytesPerRow,
          uPointer,
          uBytesPerRow,
          uBytesPerPixel,
          vPointer,
          vBytesPerRow,
          vBytesPerPixel,
          width,
          height,
          maxDimension,
          outImage,
        ),
      );
    } finally {
      malloc.free(yPointer);
      malloc.free(uPointer);
      malloc.free(vPointer);
    }
  }

  Uint8List convertBgra8888ToJpeg({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required int maxDimension,
    required int quality,
  }) {
    final bgraPointer = _copyBytesToNative(bytes);
    try {
      return _runJpegConversion(
        (outImage) => _bindings.convertBgra8888ToJpeg(
          bgraPointer,
          width,
          height,
          bytesPerRow,
          maxDimension,
          quality,
          outImage,
        ),
      );
    } finally {
      malloc.free(bgraPointer);
    }
  }

  Uint8List convertYuv420ToJpeg({
    required Uint8List yPlane,
    required int yBytesPerRow,
    required Uint8List uPlane,
    required int uBytesPerRow,
    required int uBytesPerPixel,
    required Uint8List vPlane,
    required int vBytesPerRow,
    required int vBytesPerPixel,
    required int width,
    required int height,
    required int maxDimension,
    required int quality,
  }) {
    final yPointer = _copyBytesToNative(yPlane);
    final uPointer = _copyBytesToNative(uPlane);
    final vPointer = _copyBytesToNative(vPlane);

    try {
      return _runJpegConversion(
        (outImage) => _bindings.convertYuv420ToJpeg(
          yPointer,
          yBytesPerRow,
          uPointer,
          uBytesPerRow,
          uBytesPerPixel,
          vPointer,
          vBytesPerRow,
          vBytesPerPixel,
          width,
          height,
          maxDimension,
          quality,
          outImage,
        ),
      );
    } finally {
      malloc.free(yPointer);
      malloc.free(uPointer);
      malloc.free(vPointer);
    }
  }

  Uint8List _runJpegConversion(
    int Function(Pointer<_NativeJpegImage> outImage) invoke,
  ) {
    final outImage = calloc<_NativeJpegImage>();
    try {
      final code = invoke(outImage);
      if (code != 0) {
        if (outImage.ref.data != nullptr) {
          _bindings.freeJpegBuffer(outImage.ref.data);
          outImage.ref.data = nullptr;
        }
        throw StateError(_errorMessageFor(code));
      }

      final dataPointer = outImage.ref.data;
      final byteCount = outImage.ref.length;
      if (dataPointer == nullptr || byteCount <= 0) {
        throw StateError('Native JPEG encoding returned an empty buffer.');
      }

      final jpegBytes = Uint8List.fromList(dataPointer.asTypedList(byteCount));
      _bindings.freeJpegBuffer(dataPointer);
      outImage.ref.data = nullptr;
      return jpegBytes;
    } finally {
      if (outImage.ref.data != nullptr) {
        _bindings.freeJpegBuffer(outImage.ref.data);
      }
      calloc.free(outImage);
    }
  }

  GhosteyeFrameRgbImage _runConversion(
    int Function(Pointer<_NativeRgbImage> outImage) invoke,
  ) {
    final outImage = calloc<_NativeRgbImage>();
    try {
      final code = invoke(outImage);
      if (code != 0) {
        if (outImage.ref.data != nullptr) {
          _bindings.freeBuffer(outImage.ref.data);
          outImage.ref.data = nullptr;
        }
        throw StateError(_errorMessageFor(code));
      }

      final dataPointer = outImage.ref.data;
      final byteCount = outImage.ref.length;
      if (dataPointer == nullptr || byteCount <= 0) {
        throw StateError('Native preprocessing returned an empty buffer.');
      }

      final rgbBytes = Uint8List.fromList(dataPointer.asTypedList(byteCount));
      _bindings.freeBuffer(dataPointer);
      outImage.ref.data = nullptr;

      return GhosteyeFrameRgbImage(
        bytes: rgbBytes,
        width: outImage.ref.width,
        height: outImage.ref.height,
      );
    } finally {
      if (outImage.ref.data != nullptr) {
        _bindings.freeBuffer(outImage.ref.data);
      }
      calloc.free(outImage);
    }
  }

  static DynamicLibrary _openLibrary(String? libraryPath) {
    if (libraryPath != null && libraryPath.isNotEmpty) {
      return DynamicLibrary.open(libraryPath);
    }
    if (!isSupported) {
      throw UnsupportedError(
        'ghosteye_frame_ffi does not support ${Platform.operatingSystem}.',
      );
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('$_libName.framework/$_libName');
    }
    return DynamicLibrary.open('lib$_libName.so');
  }

  String _errorMessageFor(int code) {
    return switch (code) {
      -1 => 'Invalid preprocessing arguments were provided to native code.',
      -2 => 'Ghosteye failed to allocate native preprocessing memory.',
      _ => 'Ghosteye native frame preprocessing failed with code $code.',
    };
  }

  Pointer<Uint8> _copyBytesToNative(Uint8List bytes) {
    final pointer = malloc.allocate<Uint8>(bytes.length);
    pointer.asTypedList(bytes.length).setAll(0, bytes);
    return pointer;
  }
}

final class _NativeRgbImage extends Struct {
  external Pointer<Uint8> data;

  @Int32()
  external int length;

  @Int32()
  external int width;

  @Int32()
  external int height;
}

final class _NativeJpegImage extends Struct {
  external Pointer<Uint8> data;

  @Int32()
  external int length;
}

typedef _ConvertBgraNative = Int32 Function(
  Pointer<Uint8> bgra,
  Int32 width,
  Int32 height,
  Int32 bytesPerRow,
  Int32 maxDimension,
  Pointer<_NativeRgbImage> outImage,
);
typedef _ConvertBgraDart = int Function(
  Pointer<Uint8> bgra,
  int width,
  int height,
  int bytesPerRow,
  int maxDimension,
  Pointer<_NativeRgbImage> outImage,
);

typedef _ConvertYuvNative = Int32 Function(
  Pointer<Uint8> yPlane,
  Int32 yBytesPerRow,
  Pointer<Uint8> uPlane,
  Int32 uBytesPerRow,
  Int32 uBytesPerPixel,
  Pointer<Uint8> vPlane,
  Int32 vBytesPerRow,
  Int32 vBytesPerPixel,
  Int32 width,
  Int32 height,
  Int32 maxDimension,
  Pointer<_NativeRgbImage> outImage,
);
typedef _ConvertYuvDart = int Function(
  Pointer<Uint8> yPlane,
  int yBytesPerRow,
  Pointer<Uint8> uPlane,
  int uBytesPerRow,
  int uBytesPerPixel,
  Pointer<Uint8> vPlane,
  int vBytesPerRow,
  int vBytesPerPixel,
  int width,
  int height,
  int maxDimension,
  Pointer<_NativeRgbImage> outImage,
);

typedef _FreeBufferNative = Void Function(Pointer<Uint8> buffer);
typedef _FreeBufferDart = void Function(Pointer<Uint8> buffer);

typedef _ActiveAllocationsNative = Int32 Function();
typedef _ActiveAllocationsDart = int Function();

// JPEG conversion typedefs

typedef _ConvertBgraToJpegNative = Int32 Function(
  Pointer<Uint8> bgra,
  Int32 width,
  Int32 height,
  Int32 bytesPerRow,
  Int32 maxDimension,
  Int32 quality,
  Pointer<_NativeJpegImage> outImage,
);
typedef _ConvertBgraToJpegDart = int Function(
  Pointer<Uint8> bgra,
  int width,
  int height,
  int bytesPerRow,
  int maxDimension,
  int quality,
  Pointer<_NativeJpegImage> outImage,
);

typedef _ConvertYuvToJpegNative = Int32 Function(
  Pointer<Uint8> yPlane,
  Int32 yBytesPerRow,
  Pointer<Uint8> uPlane,
  Int32 uBytesPerRow,
  Int32 uBytesPerPixel,
  Pointer<Uint8> vPlane,
  Int32 vBytesPerRow,
  Int32 vBytesPerPixel,
  Int32 width,
  Int32 height,
  Int32 maxDimension,
  Int32 quality,
  Pointer<_NativeJpegImage> outImage,
);
typedef _ConvertYuvToJpegDart = int Function(
  Pointer<Uint8> yPlane,
  int yBytesPerRow,
  Pointer<Uint8> uPlane,
  int uBytesPerRow,
  int uBytesPerPixel,
  Pointer<Uint8> vPlane,
  int vBytesPerRow,
  int vBytesPerPixel,
  int width,
  int height,
  int maxDimension,
  int quality,
  Pointer<_NativeJpegImage> outImage,
);

typedef _FreeJpegBufferNative = Void Function(Pointer<Uint8> buffer);
typedef _FreeJpegBufferDart = void Function(Pointer<Uint8> buffer);

class _GhosteyeFrameBindings {
  _GhosteyeFrameBindings(DynamicLibrary dylib)
      : _convertBgra8888ToRgb =
            dylib.lookupFunction<_ConvertBgraNative, _ConvertBgraDart>(
          'ghosteye_bgra8888_to_rgb',
        ),
        _convertYuv420ToRgb =
            dylib.lookupFunction<_ConvertYuvNative, _ConvertYuvDart>(
          'ghosteye_yuv420_to_rgb',
        ),
        _freeBuffer = dylib.lookupFunction<_FreeBufferNative, _FreeBufferDart>(
          'ghosteye_frame_free_buffer',
        ),
        _activeAllocations = dylib
            .lookupFunction<_ActiveAllocationsNative, _ActiveAllocationsDart>(
          'ghosteye_frame_active_allocations',
        ),
        _convertBgra8888ToJpeg = dylib.lookupFunction<
            _ConvertBgraToJpegNative, _ConvertBgraToJpegDart>(
          'ghosteye_bgra8888_to_jpeg',
        ),
        _convertYuv420ToJpeg =
            dylib.lookupFunction<_ConvertYuvToJpegNative, _ConvertYuvToJpegDart>(
          'ghosteye_yuv420_to_jpeg',
        ),
        _freeJpegBuffer =
            dylib.lookupFunction<_FreeJpegBufferNative, _FreeJpegBufferDart>(
          'ghosteye_jpeg_free_buffer',
        );

  final _ConvertBgraDart _convertBgra8888ToRgb;
  final _ConvertYuvDart _convertYuv420ToRgb;
  final _FreeBufferDart _freeBuffer;
  final _ActiveAllocationsDart _activeAllocations;
  final _ConvertBgraToJpegDart _convertBgra8888ToJpeg;
  final _ConvertYuvToJpegDart _convertYuv420ToJpeg;
  final _FreeJpegBufferDart _freeJpegBuffer;

  int convertBgra8888ToRgb(
    Pointer<Uint8> bgra,
    int width,
    int height,
    int bytesPerRow,
    int maxDimension,
    Pointer<_NativeRgbImage> outImage,
  ) {
    return _convertBgra8888ToRgb(
      bgra,
      width,
      height,
      bytesPerRow,
      maxDimension,
      outImage,
    );
  }

  int convertYuv420ToRgb(
    Pointer<Uint8> yPlane,
    int yBytesPerRow,
    Pointer<Uint8> uPlane,
    int uBytesPerRow,
    int uBytesPerPixel,
    Pointer<Uint8> vPlane,
    int vBytesPerRow,
    int vBytesPerPixel,
    int width,
    int height,
    int maxDimension,
    Pointer<_NativeRgbImage> outImage,
  ) {
    return _convertYuv420ToRgb(
      yPlane,
      yBytesPerRow,
      uPlane,
      uBytesPerRow,
      uBytesPerPixel,
      vPlane,
      vBytesPerRow,
      vBytesPerPixel,
      width,
      height,
      maxDimension,
      outImage,
    );
  }

  void freeBuffer(Pointer<Uint8> buffer) => _freeBuffer(buffer);

  int activeAllocations() => _activeAllocations();

  int convertBgra8888ToJpeg(
    Pointer<Uint8> bgra,
    int width,
    int height,
    int bytesPerRow,
    int maxDimension,
    int quality,
    Pointer<_NativeJpegImage> outImage,
  ) {
    return _convertBgra8888ToJpeg(
      bgra,
      width,
      height,
      bytesPerRow,
      maxDimension,
      quality,
      outImage,
    );
  }

  int convertYuv420ToJpeg(
    Pointer<Uint8> yPlane,
    int yBytesPerRow,
    Pointer<Uint8> uPlane,
    int uBytesPerRow,
    int uBytesPerPixel,
    Pointer<Uint8> vPlane,
    int vBytesPerRow,
    int vBytesPerPixel,
    int width,
    int height,
    int maxDimension,
    int quality,
    Pointer<_NativeJpegImage> outImage,
  ) {
    return _convertYuv420ToJpeg(
      yPlane,
      yBytesPerRow,
      uPlane,
      uBytesPerRow,
      uBytesPerPixel,
      vPlane,
      vBytesPerRow,
      vBytesPerPixel,
      width,
      height,
      maxDimension,
      quality,
      outImage,
    );
  }

  void freeJpegBuffer(Pointer<Uint8> buffer) => _freeJpegBuffer(buffer);
}
