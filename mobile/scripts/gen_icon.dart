// Generates assets/logo_app_icon.png — black background + centered logo with padding
// Run: dart run scripts/gen_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  const paddingFactor = 0.08; // 8% padding on each side

  final sourceBytes = File('assets/logo_app.png').readAsBytesSync();
  final source = img.decodePng(sourceBytes);
  if (source == null) {
    print('ERROR: could not decode assets/logo_app.png');
    exit(1);
  }

  // Output canvas: black
  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

  // Scale logo to fit with padding
  final innerSize = (size * (1 - paddingFactor * 2)).round();
  final scaled = img.copyResize(source, width: innerSize, height: innerSize, interpolation: img.Interpolation.cubic);

  // Center on canvas
  final offset = ((size - innerSize) / 2).round();
  img.compositeImage(canvas, scaled, dstX: offset, dstY: offset);

  final outBytes = img.encodePng(canvas);
  File('assets/logo_app_icon.png').writeAsBytesSync(outBytes);
  print('Done → assets/logo_app_icon.png (${size}x$size, black bg, ${(paddingFactor * 100).round()}% padding)');
}
