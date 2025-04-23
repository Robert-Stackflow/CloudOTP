import 'dart:io';

void main() {
  final srcDir = Directory('lib/src');
  final exportFile = File('lib/exports.dart');
  final buffer = StringBuffer();

  for (final entity in srcDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final relativePath =
          entity.path.replaceFirst('lib/', '').replaceAll("\\", "/");
      buffer.writeln("export '$relativePath';");
    }
  }

  exportFile.writeAsStringSync(buffer.toString());
  print('✅ Generated lib/exports.dart');
}
