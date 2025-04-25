import 'package:saf/src/storage_access_framework/document_file_column.dart';

/// Represent the same entity as `DocumentFile` but will be lazily loaded
/// by `listFilesAsStream` method with dynamic
/// properties and query metadata context
///
/// _Note: Can't be instantiated_
class PartialDocumentFile {
  final Map<DocumentFileColumn, dynamic>? data;
  final QueryMetadata? metadata;

  const PartialDocumentFile._({required this.data, required this.metadata});

  static PartialDocumentFile fromMap(Map<String, dynamic> map) {
    return PartialDocumentFile._(
      data: (() {
        final data = map['data'];

        if (data == null) return null;

        return <DocumentFileColumn, dynamic>{
          for (final value in DocumentFileColumn.values)
            if (data['$value'] != null) value: data['$value'],
        };
      })(),
      metadata: QueryMetadata.fromMap(Map.from(map['metadata'])),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'data': data,
      if (metadata != null) 'metadata': metadata?.toMap(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! PartialDocumentFile) return false;

    return other.data == data && other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(data, metadata);
}

/// Represents the metadata that the given `PartialDocumentFile` was got by
/// the `contentResolver.query(uri, ...metadata)` method
///
/// _Note: Can't be instantiated_
class QueryMetadata {
  final Uri? parentUri;
  final Uri? rootUri;
  final bool? isDirectory;
  final Uri? uri;

  const QueryMetadata._(
      {required this.parentUri,
      required this.rootUri,
      required this.isDirectory,
      required this.uri});

  static Uri? _parseUri(String? uri) {
    if (uri == null) return null;

    return Uri.parse(uri);
  }

  static QueryMetadata fromMap(Map<String, dynamic> map) {
    return QueryMetadata._(
      parentUri: _parseUri(map['parentUri']),
      rootUri: _parseUri(map['rootUri']),
      isDirectory: map['isDirectory'],
      uri: _parseUri(map['uri']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'parentUri': '$parentUri',
      'rootUri': '$rootUri',
      'isDirectory': isDirectory,
      'uri': uri,
    };
  }

  @override
  bool operator ==(Object other) {
    if (other is! QueryMetadata) return false;

    return other.parentUri == parentUri &&
        other.rootUri == rootUri &&
        other.isDirectory == isDirectory &&
        other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(parentUri, rootUri, isDirectory, uri);
}
