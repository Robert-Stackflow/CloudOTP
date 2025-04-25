import 'dart:typed_data';

import 'package:saf/src/storage_access_framework/document_file_column.dart';
import 'package:saf/src/storage_access_framework/partial_document_file.dart';
import 'package:saf/src/storage_access_framework/api.dart' as saf;

extension UriDocumentFileUtils on Uri {
  /// Same as `DocumentFile.fromTreeUri(this)`
  Future<DocumentFile?> toDocumentFile() => DocumentFile.fromTreeUri(this);
}

/// Equivalent to Android `DocumentFile` class
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile)
class DocumentFile {
  final String name;
  final String? type;
  final Uri uri;
  final bool isDirectory;
  final bool isFile;
  final bool isVirtual;

  const DocumentFile(
      {required this.name,
      required this.type,
      required this.uri,
      required this.isDirectory,
      required this.isFile,
      required this.isVirtual});

  /// Same as `uri.toDocumentFile` where `uri` is of type `Uri`
  static Future<DocumentFile?> fromTreeUri(Uri uri) => saf.fromTreeUri(uri);

  Future<bool?> canRead() async => saf.canWrite(uri);

  Future<bool?> canWrite() async => saf.canWrite(uri);

  Stream<PartialDocumentFile> listFiles(List<DocumentFileColumn> columns) =>
      saf.listFiles(uri, columns: columns);

  Future<bool?> exists() => saf.exists(uri);

  Future<bool?> delete() => saf.delete(uri);

  Future<DocumentFile?> copy(Uri destination) => saf.copy(uri, destination);

  Stream<String> getContent(Uri destination) => saf.getDocumentContent(uri);

  Future<DocumentFile?> createDirectory(String displayName) =>
      saf.createDirectory(uri, displayName);

  Future<DocumentFile?> createFileAsBytes(
          {required String mimeType,
          required String displayName,
          required Uint8List content}) =>
      saf.createFileAsBytes(uri,
          mimeType: mimeType, displayName: displayName, content: content);

  Future<DocumentFile?> createFileAsString(
          {required String mimeType,
          required String displayName,
          required String content}) =>
      saf.createFileAsString(uri,
          mimeType: mimeType, displayName: displayName, content: content);

  Future<int?> get length => saf.getDocumentLength(uri);

  Future<DateTime?> get lastModified => saf.lastModified(uri);

  Future<DocumentFile?> findFile(String displayName) =>
      saf.findFile(uri, displayName);

  Future<DocumentFile?> renameTo(String displayName) =>
      saf.renameTo(uri, displayName);

  Future<DocumentFile?> parentFile() => saf.parentFile(uri);

  static DocumentFile fromMap(Map<String, dynamic> map) {
    return DocumentFile(
      isDirectory: map['isDirectory'],
      isFile: map['isFile'],
      isVirtual: map['isVirtual'],
      name: map['name'],
      type: map['type'],
      uri: Uri.parse(map['uri']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isDirectory': isDirectory,
      'isFile': isFile,
      'isVirtual': isVirtual,
      'name': name,
      'type': type,
      'uri': '$uri',
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! DocumentFile) return false;

    return isDirectory == other.isDirectory &&
        isFile == other.isFile &&
        isVirtual == other.isVirtual &&
        name == other.name &&
        type == other.type &&
        uri == other.uri;
  }

  @override
  int get hashCode =>
      Object.hash(isDirectory, isFile, isVirtual, name, type, uri);
}
