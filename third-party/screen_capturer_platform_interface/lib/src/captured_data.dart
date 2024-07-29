import 'dart:typed_data';

class CapturedData {
  CapturedData({
    this.imageWidth,
    this.imageHeight,
    this.imageBytes,
    this.imagePath,
  });

  final int? imageWidth;
  final int? imageHeight;
  final Uint8List? imageBytes;
  final String? imagePath;
}
