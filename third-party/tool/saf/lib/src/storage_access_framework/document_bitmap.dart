import 'dart:convert';
import 'dart:typed_data';

class DocumentBitmap {
  final String? base64;
  final Uri? uri;
  final int? width;
  final int? height;
  final int? byteCount;
  final int? density;

  const DocumentBitmap(
      {required this.base64,
      required this.uri,
      required this.width,
      required this.height,
      required this.byteCount,
      required this.density});

  static DocumentBitmap fromMap(Map<String, dynamic> map) {
    return DocumentBitmap(
      uri: (() {
        final uri = map['uri'];

        if (uri == null) return null;

        return Uri.parse(uri);
      })(),
      width: map['width'],
      height: map['height'],
      base64: map['base64'],
      byteCount: map['byteCount'],
      density: map['density'],
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uri': '$uri',
      'width': width,
      'height': height,
      'base64': base64,
      'byteCount': byteCount,
      'density': density,
    };
  }

  Uint8List? get bytes {
    if (base64 == null) return null;

    const codec = Base64Codec();

    return codec.decode(base64!);
  }

  @override
  bool operator ==(Object other) {
    if (other is! DocumentBitmap) return false;

    return other.byteCount == byteCount &&
        other.width == width &&
        other.height == height &&
        other.uri == uri &&
        other.density == density &&
        other.base64 == base64;
  }

  @override
  int get hashCode =>
      Object.hash(width, height, uri, density, byteCount, base64);
}
