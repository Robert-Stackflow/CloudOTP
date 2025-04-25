/// Representation of the available columns of `DocumentsContract.Document.<Column>`
///
/// [Refer to details](https://developer.android.com/reference/android/provider/DocumentsContract.Document)
class DocumentFileColumn {
  final String _id;

  const DocumentFileColumn._(this._id);

  static const _kPrefix = 'DocumentFileColumn';

  /// Equivalent to [COLUMN_DOCUMENT_ID](https://developer.android.com/reference/android/provider/DocumentsContract.Document#COLUMN_DOCUMENT_ID)
  static const id = DocumentFileColumn._('$_kPrefix.COLUMN_DOCUMENT_ID');

  /// Equivalent to [COLUMN_DISPLAY_NAME](https://developer.android.com/reference/android/provider/DocumentsContract.Document#COLUMN_DISPLAY_NAME)
  static const displayName =
      DocumentFileColumn._('$_kPrefix.COLUMN_DISPLAY_NAME');

  /// Equivalent to [COLUMN_MIME_TYPE](https://developer.android.com/reference/android/provider/DocumentsContract.Document#COLUMN_MIME_TYPE)
  static const mimeType = DocumentFileColumn._('$_kPrefix.COLUMN_MIME_TYPE');

  /// Equivalent to [COLUMN_LAST_MODIFIED](https://developer.android.com/reference/android/provider/DocumentsContract.Document#COLUMN_LAST_MODIFIED)
  static const lastModified =
      DocumentFileColumn._('$_kPrefix.COLUMN_LAST_MODIFIED');

  /// Equivalent to [COLUMN_SIZE](https://developer.android.com/reference/android/provider/DocumentsContract.Document#COLUMN_SIZE)
  static const size = DocumentFileColumn._('$_kPrefix.COLUMN_SIZE');

  /// Equivalent to [COLUMN_SUMMARY](https://developer.android.com/reference/android/provider/DocumentsContract.Document#COLUMN_SUMMARY)
  static const summary = DocumentFileColumn._('$_kPrefix.COLUMN_SUMMARY');

  @override
  bool operator ==(Object other) {
    return other is DocumentFileColumn && other._id == _id;
  }

  static const values = <DocumentFileColumn>[
    id,
    displayName,
    mimeType,
    lastModified,
    size,
    summary,
  ];

  @override
  int get hashCode => _id.hashCode;

  @override
  String toString() => _id;
}
