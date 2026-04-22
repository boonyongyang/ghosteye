import 'dart:io';

import 'package:image/image.dart' as img;

const _defaultCropScale = 0.8;

void main(List<String> args) {
  final options = _AssetOptions.parse(args);
  final sourceFile = File(options.sourcePath);

  if (!sourceFile.existsSync()) {
    stderr.writeln('Source image not found: ${sourceFile.path}');
    stderr.writeln(
      'Usage: dart run tool/generate_brand_assets.dart --source=/absolute/path/to/icon.png',
    );
    exitCode = 64;
    return;
  }

  final sourceBytes = sourceFile.readAsBytesSync();
  final decoded = img.decodeImage(sourceBytes);

  if (decoded == null) {
    stderr.writeln('Unable to decode image: ${sourceFile.path}');
    exitCode = 65;
    return;
  }

  final flattened = _flatten(decoded);
  final master = _prepareMaster(flattened, cropScale: options.cropScale);
  final generatedFiles = <String>[];

  _copySourceAsset(sourceBytes, generatedFiles);
  _writePng('assets/branding/ghosteye-icon-master.png', master, generatedFiles);

  final launchMaster = img.copyResize(
    master,
    width: 600,
    height: 600,
    interpolation: img.Interpolation.cubic,
  );

  _writePng(
    'assets/branding/ghosteye-launch-card.png',
    launchMaster,
    generatedFiles,
  );

  const androidIcons = <String, int>{
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
    'android/app/src/main/res/drawable-nodpi/launch_logo.png': 320,
  };

  for (final entry in androidIcons.entries) {
    _writeResizedPng(entry.key, master, entry.value, generatedFiles);
  }

  const iosIcons = <String, int>{
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png':
        167,
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png':
        1024,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png': 200,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png': 400,
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png': 600,
  };

  for (final entry in iosIcons.entries) {
    _writeResizedPng(entry.key, master, entry.value, generatedFiles);
  }

  const webIcons = <String, int>{
    'web/favicon.png': 64,
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  for (final entry in webIcons.entries) {
    _writeResizedPng(entry.key, master, entry.value, generatedFiles);
  }

  stdout.writeln('Generated ${generatedFiles.length} branding assets:');
  for (final path in generatedFiles) {
    stdout.writeln(' - $path');
  }
}

img.Image _flatten(img.Image input) {
  final flattened = img.Image(width: input.width, height: input.height);
  img.fill(flattened, color: img.ColorRgb8(9, 11, 16));
  img.compositeImage(flattened, input);
  return flattened;
}

img.Image _prepareMaster(img.Image source, {required double cropScale}) {
  final minSide = source.width < source.height ? source.width : source.height;
  final normalizedScale = cropScale.clamp(0.5, 1.0);
  final cropSize = (minSide * normalizedScale).round();
  final cropX = ((source.width - cropSize) / 2).round();
  final cropY = ((source.height - cropSize) / 2).round();

  final cropped = img.copyCrop(
    source,
    x: cropX,
    y: cropY,
    width: cropSize,
    height: cropSize,
  );

  return img.copyResize(
    cropped,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.cubic,
  );
}

void _copySourceAsset(List<int> sourceBytes, List<String> generatedFiles) {
  const path = 'assets/branding/ghosteye-icon-source-ai.png';
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(sourceBytes);
  generatedFiles.add(path);
}

void _writeResizedPng(
  String path,
  img.Image image,
  int size,
  List<String> generatedFiles,
) {
  final resized = img.copyResize(
    image,
    width: size,
    height: size,
    interpolation: img.Interpolation.cubic,
  );
  _writePng(path, resized, generatedFiles);
}

void _writePng(String path, img.Image image, List<String> generatedFiles) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image, level: 6));
  generatedFiles.add(path);
}

class _AssetOptions {
  const _AssetOptions({
    required this.sourcePath,
    required this.cropScale,
  });

  factory _AssetOptions.parse(List<String> args) {
    String? sourcePath;
    var cropScale = _defaultCropScale;

    for (final arg in args) {
      if (arg.startsWith('--source=')) {
        sourcePath = arg.substring('--source='.length);
        continue;
      }

      if (arg.startsWith('--crop-scale=')) {
        final value = double.tryParse(arg.substring('--crop-scale='.length));
        if (value != null) {
          cropScale = value;
        }
      }
    }

    if (sourcePath == null || sourcePath.isEmpty) {
      stderr.writeln('Missing required --source argument.');
      exitCode = 64;
      throw const FormatException('Missing required --source argument.');
    }

    return _AssetOptions(sourcePath: sourcePath, cropScale: cropScale);
  }

  final String sourcePath;
  final double cropScale;
}
