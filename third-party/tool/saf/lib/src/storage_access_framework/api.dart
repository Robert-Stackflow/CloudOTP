import 'dart:typed_data';

import 'package:saf/src/channels.dart';
import 'package:saf/src/storage_access_framework/document_bitmap.dart';
import 'package:saf/src/storage_access_framework/document_file.dart';
import 'package:saf/src/storage_access_framework/document_file_column.dart';
import 'package:saf/src/storage_access_framework/partial_document_file.dart';
import 'package:saf/src/storage_access_framework/uri_permission.dart';

/// Convert Directory path to URI String
String makeUriString({String path = "", bool isTreeUri = false}) {
  String uri = "";
  String base =
      "content://com.android.externalstorage.documents/tree/primary%3A";
  String documentUri = "/document/primary%3A" +
      path.replaceAll("/", "%2F").replaceAll(" ", "%20");
  if (isTreeUri) {
    uri = base + path.replaceAll("/", "%2F").replaceAll(" ", "%20");
  } else {
    var pathSegments = path.split("/");
    var fileName = pathSegments[pathSegments.length - 1];
    var directory = path.split("/$fileName")[0];
    uri = base +
        directory.replaceAll("/", "%2F").replaceAll(" ", "%20") +
        documentUri;
  }
  return uri;
}

/// Convert URI String into Directory path
String makeDirectoryPath(String uriString) {
  String directoryPathUriString = uriString.split("primary%3A")[1];
  String directoryPath =
      directoryPathUriString.replaceAll("%2F", "/").replaceAll("%20", " ");
  return directoryPath;
}

/// Create a name Alias for Directory path e.g. Android/media/matrix -> Android_media_matrix
String makeDirectoryPathToName(String path) {
  return path.replaceAll("/", "_");
}

/// Start Activity Action: Allow the user to pick a directory subtree.
/// When invoked, the system will display the various `DocumentsProvider`
/// instances installed on the device, letting the user navigate through them.
/// Apps can fully manage documents within the returned directory.
///
/// [Refer to details](https://developer.android.com/reference/android/content/Intent#ACTION_OPEN_DOCUMENT_TREE)
///
/// support the initial directory of the directory picker
Future<String?> openDocumentTree(
    {bool grantWritePermission = true, String? initialDirPath = ""}) async {
  String initialUri = makeUriString(path: initialDirPath as String);
  const kOpenDocumentTree = 'openDocumentTree';

  const kGrantWritePermission = 'grantWritePermission';
  const kInitialUri = 'initialUri';

  final args = <String, dynamic>{
    kGrantWritePermission: grantWritePermission,
    kInitialUri: initialUri
  };
  final selectedDirectoryUri =
      await kDocumentFileChannel.invokeMethod<String?>(kOpenDocumentTree, args);

  if (selectedDirectoryUri == null) return null;

  return selectedDirectoryUri.toString();
}

/// Build Document URI's from tree URI
Future<List<String>?> getFilesUri(String treeUriString,
    {String fileType = "media"}) async {
  try {
    const kGetFilesUri = "buildChildDocumentsUriUsingTree";

    const kFileType = "fileType";
    const kTreeUriString = "treeUriString";

    final args = <String, dynamic>{
      kFileType: fileType,
      kTreeUriString: treeUriString,
    };
    final paths = await kDocumentsContractChannel.invokeMethod<List<dynamic>>(
        kGetFilesUri, args);
    if (paths == null) return null;
    return List<String>.from(paths);
  } catch (e) {
    return null;
  }
}

/// Get the path for App Package's [files] Directory i.e. ~/Android/data/<package-id>/files/
Future<String?> getExternalFilesDirPath() async {
  try {
    const kGetFilesUri = "getExternalFilesDirPath";
    final path = await kDocumentFileChannel.invokeMethod<String?>(kGetFilesUri);
    if (path == null) return null;
    return path;
  } catch (e) {
    return null;
  }
}

/// Returns an `List<URI>` with all persisted [URI]
///
/// To persist an [URI] call `openDocumentTree`
/// and to remove an persisted [URI] call `releasePersistableUriPermission`
Future<List<UriPermission>?> persistedUriPermissions() async {
  const kPersistedUriPermissions = 'persistedUriPermissions';

  final persistedUriPermissions =
      await kDocumentFileChannel.invokeListMethod(kPersistedUriPermissions);

  if (persistedUriPermissions == null) return null;

  return persistedUriPermissions
      .map((e) => UriPermission.fromMap(Map.from(e)))
      .toList();
}

/// Will revoke an persistable URI
///
/// Call this when your App no longer wants the permission of an [URI] returned
/// by `openDocumentTree` method
///
/// To get the current persisted [URI]s call `persistedUriPermissions`
Future<void> releasePersistableUriPermission(directory) async {
  const kReleasePersistableUriPermission = 'releasePersistableUriPermission';

  const kUri = 'uri';

  final args = <String, String>{kUri: '$directory'};

  await kDocumentFileChannel.invokeMethod(
      kReleasePersistableUriPermission, args);
}

/// Convenient method to verify if a given [uri]
/// is allowed to be write or read from SAF API's
///
/// This uses the `releasePersistableUriPermission` method to get the List
/// of allowed [URI]s then will verify if the [uri] is included in
Future<bool> isPersistedUri(Uri uri) async {
  final persistedUris = await persistedUriPermissions();

  return persistedUris?.any((persistedUri) => persistedUri.uri == uri) ?? false;
}

/// Equivalent to `DocumentFile.canRead`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#canRead())
Future<bool?> canRead(Uri uri) async {
  const kCanRead = 'canRead';

  const kUri = 'uri';

  final args = {kUri: '$uri'};

  return await kDocumentFileChannel.invokeMethod<bool>(kCanRead, args);
}

/// Equivalent to `DocumentFile.canWrite`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#canWrite())
Future<bool?> canWrite(Uri uri) async {
  const kCanWrite = 'canWrite';

  const kUri = 'uri';

  final args = {kUri: '$uri'};

  return await kDocumentFileChannel.invokeMethod<bool>(kCanWrite, args);
}

/// Equivalent to `DocumentsContract.getDocumentThumbnail`
///
/// [Refer to details](https://developer.android.com/reference/android/provider/DocumentsContract#getDocumentThumbnail(android.content.ContentResolver,%20android.net.Uri,%20android.graphics.Point,%20android.os.CancellationSignal))
Future<DocumentBitmap?> getDocumentThumbnail({
  required Uri rootUri,
  required String documentId,
  required double width,
  required double height,
}) async {
  const kGetDocumentThumbnail = 'getDocumentThumbnail';

  const kRootUri = 'rootUri';
  const kDocumentId = 'documentId';
  const kWidth = 'width';
  const kHeight = 'height';

  final args = <String, dynamic>{
    kRootUri: '$rootUri',
    kDocumentId: documentId,
    kWidth: width,
    kHeight: height,
  };

  final bitmap = await kDocumentsContractChannel
      .invokeMapMethod<String, dynamic>(kGetDocumentThumbnail, args);

  if (bitmap == null) return null;

  return DocumentBitmap.fromMap(bitmap);
}

/// Emits a new event for each child document file
///
/// Works with small and large data file sets
///
/// ```dart
/// /// Usage:
///
/// final myState = <PartialDocumentFile>[];
///
/// final onDocumentFile = listFiles(myUri, [DocumentFileColumn.id]);
///
/// onDocumentFile.listen((document) {
///   myState.add(document);
///
///   final documentId = document.data?[DocumentFileColumn.id]
///
///   print('$documentId was added to state');
/// });
/// ```
///
/// [Refer to details](https://stackoverflow.com/questions/41096332/issues-traversing-through-directory-hierarchy-with-android-storage-access-framew)
Stream<PartialDocumentFile> listFiles(Uri uri,
    {required List<DocumentFileColumn> columns}) {
  const kListFiles = 'listFiles';

  const kUri = 'uri';
  const kEvent = 'event';
  const kColumns = 'columns';

  final args = <String, dynamic>{
    kUri: '$uri',
    kEvent: kListFiles,
    kColumns: columns.map((e) => '$e').toList(),
  };

  final onCursorRowResult =
      kDocumentFileEventChannel.receiveBroadcastStream(args);

  return onCursorRowResult
      .map((e) => PartialDocumentFile.fromMap(Map.from(e)))
      .cast<PartialDocumentFile>();
}

/// Verify if a given [uri] exists
Future<bool?> exists(Uri uri) async {
  const kExists = 'exists';

  const kUri = 'uri';

  final args = <String, String>{kUri: '$uri'};

  return await kDocumentFileChannel.invokeMethod<bool>(kExists, args);
}

/// Equivalent to `DocumentsContract.buildDocumentUriUsingTree`
///
/// [Refer to details](https://developer.android.com/reference/android/provider/DocumentsContract#buildDocumentUriUsingTree%28android.net.Uri,%20java.lang.String%29)
Future<Uri?> buildDocumentUriUsingTree(Uri treeUri, String documentId) async {
  const kBuildDocumentUriUsingTree = 'buildDocumentUriUsingTree';

  const kTreeUriString = "treeUriString";
  const kDocumentId = 'documentId';

  final args = <String, String>{
    kTreeUriString: '$treeUri',
    kDocumentId: documentId,
  };

  final uri = await kDocumentsContractChannel.invokeMethod<String>(
      kBuildDocumentUriUsingTree, args);

  if (uri == null) return null;

  return Uri.parse(uri);
}

/// Equivalent to `DocumentsContract.buildDocumentUri`
///
/// [Refer to details](https://developer.android.com/reference/android/provider/DocumentsContract#buildDocumentUri%28java.lang.String,%20java.lang.String%29)
Future<Uri?> buildDocumentUri(String authority, String documentId) async {
  const kBuildDocumentUri = 'buildDocumentUri';

  const kAuthority = 'authority';
  const kDocumentId = 'documentId';

  final args = <String, String>{
    kAuthority: authority,
    kDocumentId: documentId,
  };

  final uri = await kDocumentsContractChannel.invokeMethod<String>(
      kBuildDocumentUri, args);

  if (uri == null) return null;

  return Uri.parse(uri);
}

/// Equivalent to `DocumentsContract.buildDocumentUri`
///
/// [Refer to details](https://developer.android.com/reference/android/provider/DocumentsContract#buildDocumentUri%28java.lang.String,%20java.lang.String%29)
Future<Uri?> buildTreeDocumentUri(String authority, String documentId) async {
  const kBuildTreeDocumentUri = 'buildTreeDocumentUri';

  const kAuthority = 'authority';
  const kDocumentId = 'documentId';

  final args = <String, String>{
    kAuthority: authority,
    kDocumentId: documentId,
  };

  final uri = await kDocumentsContractChannel.invokeMethod<String>(
      kBuildTreeDocumentUri, args);

  if (uri == null) return null;

  return Uri.parse(uri);
}

/// Equivalent to `DocumentFile.delete`
///
/// Returns `true` if deleted successfully
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#delete%28%29)
Future<bool?> delete(Uri uri) async {
  const kDelete = 'delete';

  const kUri = 'uri';

  final args = <String, String>{kUri: '$uri'};

  return await kDocumentFileChannel.invokeMethod<bool>(kDelete, args);
}

/// Create a direct child document tree named `displayName` given a parent `parentUri`
///
/// Equivalent to `DocumentFile.createDirectory`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#createDirectory%28java.lang.String%29)
Future<DocumentFile?> createDirectory(Uri parentUri, String displayName) async {
  const kCreateDirectory = 'createDirectory';

  const kDisplayNameArg = 'displayName';
  const kUri = 'uri';

  final args = <String, String>{
    kUri: '$parentUri',
    kDisplayNameArg: displayName,
  };

  final createdDocumentFile = await kDocumentFileChannel
      .invokeMapMethod<String, dynamic>(kCreateDirectory, args);

  if (createdDocumentFile == null) return null;

  return DocumentFile.fromMap(createdDocumentFile);
}

/// Create a direct child document of `parentUri`
/// - `mimeType` is the type of document following [this specs](https://www.iana.org/assignments/media-types/media-types.xhtml)
/// - `displayName` is the name of the documnt, must be a valid file name
/// - `content` is the content of the document as a list of bytes `Uint8List`
///
/// Returns the created file as a `DocumentFile`
Future<DocumentFile?> createFileAsBytes(Uri parentUri,
    {required String mimeType,
    required String displayName,
    required Uint8List content}) async {
  const kCreateFile = 'createFile';

  const kMimeTypeArg = 'mimeType';
  const kContentArg = 'content';
  const kDisplayNameArg = 'displayName';
  const kDirectoryUriArg = 'directoryUri';

  final directoryUri = '$parentUri';

  final args = <String, dynamic>{
    kMimeTypeArg: mimeType,
    kContentArg: content,
    kDisplayNameArg: displayName,
    kDirectoryUriArg: directoryUri,
  };

  final createdDocumentFile = await kDocumentFileChannel
      .invokeMapMethod<String, dynamic>(kCreateFile, args);

  if (createdDocumentFile == null) return null;

  return DocumentFile.fromMap(createdDocumentFile);
}

/// Convenient method to create a file
/// using `content` as String instead Uint8List
Future<DocumentFile?> createFileAsString(Uri parentUri,
    {required String mimeType,
    required String displayName,
    required String content}) {
  return createFileAsBytes(
    parentUri,
    displayName: displayName,
    mimeType: mimeType,
    content: Uint8List.fromList(content.codeUnits),
  );
}

/// Equivalent to `DocumentFile.length`
///
/// Returns the size of a given document `uri` in bytes
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#length%28%29)
Future<int?> getDocumentLength(Uri uri) async {
  const kLength = 'length';

  const kUri = 'uri';

  final args = <String, String>{kUri: '$uri'};

  final length = await kDocumentFileChannel.invokeMethod<int>(kLength, args);

  return length;
}

/// Equivalent to `DocumentFile.lastModified`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#lastModified%28%29)
Future<DateTime?> lastModified(Uri uri) async {
  const kLastModified = 'lastModified';

  const kUri = 'uri';

  final args = <String, String>{kUri: '$uri'};

  final inMillisecondsSinceEpoch =
      await kDocumentFileChannel.invokeMethod<int>(kLastModified, args);

  if (inMillisecondsSinceEpoch == null) return null;

  return DateTime.fromMillisecondsSinceEpoch(inMillisecondsSinceEpoch);
}

/// Equivalent to `DocumentFile.findFile`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#findFile%28java.lang.String%29)
Future<DocumentFile?> findFile(Uri directoryUri, String displayName) async {
  const kFindFile = 'findFile';

  const kDisplayNameArg = 'displayName';
  const kUri = 'uri';

  final args = <String, String>{
    kUri: '$directoryUri',
    kDisplayNameArg: displayName,
  };

  final matchedDocumentFile = await kDocumentFileChannel
      .invokeMapMethod<String, dynamic>(kFindFile, args);

  if (matchedDocumentFile == null) return null;

  return DocumentFile.fromMap(matchedDocumentFile);
}

/// Rename the current document `uri` to a new `displayName`
///
/// **Note: after using this method `uri` is not longer valid,
/// use the returned document instead**
///
/// Returns the updated document
///
/// Equivalent to `DocumentFile.renameTo`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#renameTo%28java.lang.String%29)
Future<DocumentFile?> renameTo(Uri uri, String displayName) async {
  const kRenameTo = 'renameTo';

  const kDisplayNameArg = 'displayName';
  const kUri = 'uri';

  final args = <String, String>{
    kUri: '$uri',
    kDisplayNameArg: displayName,
  };

  final updatedDocumentFile = await kDocumentFileChannel
      .invokeMapMethod<String, dynamic>(kRenameTo, args);

  if (updatedDocumentFile == null) return null;

  return DocumentFile.fromMap(updatedDocumentFile);
}

/// Create a new `DocumentFile` instance given `uri`
///
/// Equivalent to `DocumentFile.fromTreeUri`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#fromTreeUri%28android.content.Context,%20android.net.Uri%29)
Future<DocumentFile?> fromTreeUri(Uri uri) async {
  const kFromTreeUri = 'fromTreeUri';

  const kUri = 'uri';

  final documentFile = await kDocumentFileChannel
      .invokeMapMethod<String, dynamic>(kFromTreeUri, {kUri: '$uri'});

  if (documentFile == null) return null;

  return DocumentFile.fromMap(documentFile);
}

/// Get the parent file of the given `uri`
///
/// Equivalent to `DocumentFile.getParentFile`
///
/// [Refer to details](https://developer.android.com/reference/androidx/documentfile/provider/DocumentFile#getParentFile%28%29)
Future<DocumentFile?> parentFile(Uri uri) async {
  const kParentFile = 'parentFile';

  const kUri = 'uri';

  final args = <String, String>{kUri: '$uri'};

  final parent = await kDocumentFileChannel.invokeMapMethod<String, dynamic>(
      kParentFile, args);

  if (parent == null) return null;

  return DocumentFile.fromMap(parent);
}

/// Copy a document `uri` to the `destination`
///
/// This API uses the `createFile` and `readDocumentContent` API's behind the scenes
Future<DocumentFile?> copy(Uri uri, Uri destination) async {
  const kCopy = 'copy';

  const kUri = 'uri';
  const kDestination = 'destination';

  final args = <String, String>{kUri: '$uri', kDestination: '$destination'};

  final duplicatedFile =
      await kDocumentFileChannel.invokeMapMethod<String, dynamic>(kCopy, args);

  if (duplicatedFile == null) return null;

  return DocumentFile.fromMap(duplicatedFile);
}

/// Get content of a given document `uri`
///
/// Equivalent to `contentDescriptor` usage
///
/// [Refer to details](https://developer.android.com/training/data-storage/shared/documents-files#input_stream)
Stream<String> getDocumentContent(Uri uri) {
  const kGetDocumentContent = 'getDocumentContent';

  const kUri = 'uri';
  const kEvent = 'event';

  final args = <String, String>{kUri: '$uri', kEvent: kGetDocumentContent};

  final onNewLine = kDocumentFileEventChannel.receiveBroadcastStream(args);

  return onNewLine.map<String>((line) => line as String);
}
