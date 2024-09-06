import 'package:saf/src/storage_access_framework/api.dart';
import 'package:saf/src/channels.dart';

/// Extend the native SAF api funtionality and add some of the real Use case methods for Applicatoions
class Saf {
  String? _uriString;
  String _directory;
  Saf(this._directory) {
    _uriString = makeUriString(path: _directory, isTreeUri: true);
  }

  /// Request the user for access to [Directory Permission], if access hasn't already
  /// been grant access before.
  ///
  /// Returns [bool].
  Future<bool?> getDirectoryPermission(
      {bool grantWritePermission = true, bool isDynamic = false}) async {
    try {
      /// Check if user has already Permission Granted
      var isGranted = await isPersistedPermissionDirectoryFor(_uriString);
      if (isGranted != null && isGranted) return true;

      const kOpenDocumentTree = 'openDocumentTree';
      const kGrantWritePermission = 'grantWritePermission';
      const kInitialUri = 'initialUri';

      /// Initial location of native file explorer
      /// when user is prompted to chose the directory
      String initialUri = makeUriString(path: _directory);

      final args = <String, dynamic>{
        kGrantWritePermission: grantWritePermission,
        kInitialUri: initialUri
      };

      /// Get the URI of user selected Directory path
      final selectedDirectoryUri = await kDocumentFileChannel
          .invokeMethod<String?>(kOpenDocumentTree, args);
      if (isDynamic) {
        _uriString = selectedDirectoryUri;
        _directory = makeDirectoryPath(_uriString!);
      }
      if (!isDynamic && selectedDirectoryUri != _uriString) {
        releasePersistableUriPermission(selectedDirectoryUri);
        return false;
      }

      return true;
    } catch (e) {
      return null;
    }
  }

  /// Returns an `List<String>` with all persisted [Directory]
  ///
  /// To persist an [Directory] call `getDirectoryPermission`
  /// and to remove an persisted [URI] call `releasePersistedPermissions`
  static Future<List<String>?> getPersistedPermissionDirectories() async {
    var uriPermissions = await persistedUriPermissions();

    if (uriPermissions == null) return null;

    List<String> uriStrings = [];
    for (var uriPermission in uriPermissions) {
      uriStrings.add(makeDirectoryPath(uriPermission.uri.toString()));
    }
    return uriStrings;
  }

  /// Equivalent to `DocumentsContract.buildDocumentUriUsingTree` and
  /// here it decode URI's to full Path
  ///
  /// [Refer to details](https://developer.android.com/reference/android/provider/DocumentsContract#buildDocumentUriUsingTree%28android.net.Uri,%20java.lang.String%29)
  Future<List<String>?> getFilesPath({String fileType = "any"}) async {
    try {
      const kGetFilesPath = "buildChildDocumentsPathUsingTree";
      const kFileType = "fileType";
      const kSourceTreeUriString = "sourceTreeUriString";
      var sourceTreeUriString = _uriString;

      final args = <String, dynamic>{
        kFileType: fileType,
        kSourceTreeUriString: sourceTreeUriString,
      };
      final paths = await kDocumentsContractChannel
          .invokeMethod<List<dynamic>?>(kGetFilesPath, args);
      if (paths == null) return null;
      return List<String>.from(paths);
    } catch (e) {
      return null;
    }
  }

  // Request to `cache` the Granted Directory into App's Package [files] folder
  Future<List<String>?> cache({String? fileType}) async {
    try {
      const kCacheToExternalFilesDirectory = "cacheToExternalFilesDirectory";
      const kSourceTreeUriString = "sourceTreeUriString";
      const kFileType = "fileType";
      const kCacheDirectoryName = "cacheDirectoryName";

      var cacheDirectoryName = makeDirectoryPathToName(_directory);
      fileType ??= "any";

      final args = <String, dynamic>{
        kSourceTreeUriString: _uriString,
        kFileType: fileType,
        kCacheDirectoryName: cacheDirectoryName,
      };
      final paths = await kDocumentFileChannel.invokeMethod<List<dynamic>?>(
          kCacheToExternalFilesDirectory, args);
      if (paths == null) return null;
      return List<String>.from(paths);
    } catch (e) {
      return null;
    }
  }

  /// Returns an `List<String>` with all cached files full path
  ///
  /// To cach an [Directory] call `cache`
  /// and to clear a cached [Directory] call `clearCache`
  Future<List<String>?> getCachedFilesPath() async {
    try {
      const kGetFilesPath = "getCachedFilesPath";
      const kCacheDirectoryName = "cacheDirectoryName";

      var cacheDirectoryName = makeDirectoryPathToName(_directory);

      final args = <String, dynamic>{
        kCacheDirectoryName: cacheDirectoryName,
      };
      final paths = await kDocumentFileChannel.invokeMethod<List<dynamic>?>(
          kGetFilesPath, args);
      if (paths == null) return null;
      return List<String>.from(paths);
    } catch (e) {
      return null;
    }
  }

  // Request to `cache` the single files from Granted Directory into App's Package [files] folder
  Future<String?> singleCache({
    required String? filePath,
    String? directory,
  }) async {
    try {
      const kSingleCacheToExternalFilesDirectory =
          "singleCacheToExternalFilesDirectory";
      const kSourceUriString = "sourceUriString";
      const kCacheDirectoryName = "cacheDirectoryName";

      var sourceUriString = makeUriString(path: filePath as String);
      var cacheDirectoryName = makeDirectoryPathToName(_directory);
      if (directory != null) {
        cacheDirectoryName = makeDirectoryPathToName(directory);
      }

      final args = <String, dynamic>{
        kSourceUriString: sourceUriString,
        kCacheDirectoryName: cacheDirectoryName,
      };
      final path = await kDocumentFileChannel.invokeMethod<String?>(
          kSingleCacheToExternalFilesDirectory, args);
      if (path == null) return null;
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Returns `bool` after deleting files from App's Package [files] folder
  /// for respective Granted Directory
  /// To cache an [Directory] call `cache`
  Future<bool?> clearCache() async {
    try {
      const kClearCachedFiles = "clearCachedFiles";
      const kCacheDirectoryName = "cacheDirectoryName";

      var cacheDirectoryName = makeDirectoryPathToName(_directory);

      final args = <String, dynamic>{
        kCacheDirectoryName: cacheDirectoryName,
      };
      final cleared = await kDocumentFileChannel.invokeMethod<bool?>(
          kClearCachedFiles, args);
      if (cleared == null) return null;
      return cleared;
    } catch (e) {
      return null;
    }
  }

  /// Returns 'bool' on syncing the [Directory]'s files with Cached [Directory]
  Future<bool?> sync() async {
    try {
      const kSyncWithExternalFilesDirectory = "syncWithExternalFilesDirectory";
      const kSourceTreeUriString = "sourceTreeUriString";
      const kCacheDirectoryName = "cacheDirectoryName";

      var cacheDirectoryName = makeDirectoryPathToName(_directory);

      final args = <String, dynamic>{
        kSourceTreeUriString: _uriString,
        kCacheDirectoryName: cacheDirectoryName,
      };
      final isSync = await kDocumentFileChannel.invokeMethod<bool?>(
          kSyncWithExternalFilesDirectory, args);
      if (isSync == null) return null;
      return isSync;
    } catch (e) {
      return null;
    }
  }

  /// Will revoke an persistable URI
  ///
  /// Call this when your App no longer wants the permission of an [URI] returned
  /// by `getDirectoryPermission` method
  ///
  /// To get the current persisted [URI]s call `getPersistedPermissionDirectories`
  Future<void> releasePersistedPermission() async {
    await releasePersistableUriPermission(
        makeUriString(path: _directory, isTreeUri: true));
  }

  /// Request the user for access to [Directory Permission] of User choice
  ///
  /// Returns [bool].
  static Future<bool?> getDynamicDirectoryPermission(
      {bool grantWritePermission = true}) async {
    try {
      const kOpenDocumentTree = 'openDocumentTree';
      const kGrantWritePermission = 'grantWritePermission';
      const kInitialUri = 'initialUri';

      String initialUri = makeUriString();

      final args = <String, dynamic>{
        kGrantWritePermission: grantWritePermission,
        kInitialUri: initialUri
      };
      final selectedDirectoryUri = await kDocumentFileChannel
          .invokeMethod<String?>(kOpenDocumentTree, args);
      if (selectedDirectoryUri != null) return true;
      return false;
    } catch (e) {
      return null;
    }
  }

  /// Static method for Dynamic call
  /// Equivalent to `DocumentsContract.buildDocumentUriUsingTree` and
  /// here it decode URI's to full Path
  ///
  /// [Refer to details](https://developer.android.com/reference/android/provider/DocumentsContract#buildDocumentUriUsingTree%28android.net.Uri,%20java.lang.String%29)
  static Future<List<String>?> getFilesPathFor(String? directory,
      {String fileType = "any"}) async {
    if (directory == null) return null;
    try {
      const kGetFilesPath = "buildChildDocumentsPathUsingTree";
      const kFileType = "fileType";
      const kSourceTreeUriString = "sourceTreeUriString";
      var sourceTreeUriString = makeUriString(path: directory, isTreeUri: true);

      final args = <String, dynamic>{
        kFileType: fileType,
        kSourceTreeUriString: sourceTreeUriString,
      };
      final paths = await kDocumentsContractChannel
          .invokeMethod<List<dynamic>?>(kGetFilesPath, args);
      if (paths == null) return null;
      return List<String>.from(paths);
    } catch (e) {
      return null;
    }
  }

  /// Static method for Dynamic call
  // Request to `cache` the Granted Directory into App's Package [files] folder
  static Future<List<String>?> cacheFor(String? directory,
      {String fileType = "any"}) async {
    if (directory == null) return null;
    try {
      const kCacheToExternalFilesDirectory = "cacheToExternalFilesDirectory";
      const kSourceTreeUriString = "sourceTreeUriString";
      const kFileType = "fileType";
      const kCacheDirectoryName = "cacheDirectoryName";

      var cacheDirectoryName = makeDirectoryPathToName(directory);
      var uriString = makeUriString(path: directory, isTreeUri: true);

      final args = <String, dynamic>{
        kSourceTreeUriString: uriString,
        kFileType: fileType,
        kCacheDirectoryName: cacheDirectoryName,
      };
      final paths = await kDocumentFileChannel.invokeMethod<List<dynamic>?>(
          kCacheToExternalFilesDirectory, args);
      if (paths == null) return null;
      return List<String>.from(paths);
    } catch (e) {
      return null;
    }
  }

  /// Static method for Dynamic call
  /// Returns an `List<String>` with all cached files full path
  ///
  /// To cach an [Directory] call `cache`
  /// and to clear a cached [Directory] call `clearCache`
  static Future<List<String>?> getCachedFilesPathFor(String? directory) async {
    if (directory == null) return null;
    try {
      const kGetFilesPath = "getCachedFilesPath";
      const kCacheDirectoryName = "cacheDirectoryName";

      var cacheDirectoryName = makeDirectoryPathToName(directory);

      final args = <String, dynamic>{
        kCacheDirectoryName: cacheDirectoryName,
      };
      final paths = await kDocumentFileChannel.invokeMethod<List<dynamic>?>(
          kGetFilesPath, args);
      if (paths == null) return null;
      return List<String>.from(paths);
    } catch (e) {
      return null;
    }
  }

  /// Static method for Dynamic call
  /// Returns `bool` after deleting files from App's Package [files] folder
  /// for respective Granted Directory
  /// To cache an [Directory] call `cache`
  static Future<bool?> clearCacheFor(String? directory) async {
    if (directory == null) return null;
    try {
      const kClearCachedFiles = "clearCachedFiles";
      const kCacheDirectoryName = "cacheDirectoryName";

      var cacheDirectoryName = makeDirectoryPathToName(directory);

      final args = <String, dynamic>{
        kCacheDirectoryName: cacheDirectoryName,
      };
      final cleared = await kDocumentFileChannel.invokeMethod<bool?>(
          kClearCachedFiles, args);
      if (cleared == null) return null;
      return cleared;
    } catch (e) {
      return null;
    }
  }

  /// Static method for Dynamic call
  /// Returns 'bool' on syncing the [Directory]'s files with Cached [Directory]
  static Future<bool?> syncWith(String? directory) async {
    if (directory == null) return null;
    try {
      const kDynamicSyncWithExternalFilesDirectory =
          "dynamicSyncWithExternalFilesDirectory";
      const kSourceTreeUriString = "sourceTreeUriString";
      const kCacheDirectoryName = "cacheDirectoryName";

      var sourceUriString = makeUriString(path: directory, isTreeUri: true);
      var cacheDirectoryName = makeDirectoryPathToName(directory);

      final args = <String, dynamic>{
        kSourceTreeUriString: sourceUriString,
        kCacheDirectoryName: cacheDirectoryName,
      };
      final isSync = await kDocumentFileChannel.invokeMethod<bool?>(
          kDynamicSyncWithExternalFilesDirectory, args);
      if (isSync == null) return null;
      return isSync;
    } catch (e) {
      return null;
    }
  }

  /// Will revoke an persistable URI
  ///
  /// Call this when your App no longer wants the permission of all the [URI]s
  ///
  /// To get the current persisted [URI]s call `getPersistedPermissionDirectories`
  static Future<void> releasePersistedPermissions() async {
    var persistedPermissionDirectories =
        await getPersistedPermissionDirectories();
    if (persistedPermissionDirectories != null) {
      for (var directory in persistedPermissionDirectories) {
        releasePersistableUriPermission(
            makeUriString(path: directory, isTreeUri: true));
      }
    }
  }

  /// Will revoke an persistable URI
  ///
  /// Call this when your App no longer wants the permission of an [Directory] returned
  /// by `getDirectoryPermission` method
  ///
  /// To get the current persisted [Directory]s call `getDirectoryPermission`
  static Future<void> releasePersistedPermissionFor(String? directory) async {
    if (directory != null) {
      await releasePersistableUriPermission(
          makeUriString(path: directory, isTreeUri: true));
    }
  }

  /// Convenient method to verify if a given [Directory]
  /// is allowed to be write or read from SAF API's
  ///
  /// This uses the `persistedUriPermissions` method to get the List
  /// of allowed [URI]s then will verify if the [uri] is included in
  static Future<bool?> isPersistedPermissionDirectoryFor(
      String? uriString) async {
    if (uriString == null) return null;

    var uriPermissions = await persistedUriPermissions();
    if (uriPermissions == null) return null;

    for (var uriPermission in uriPermissions) {
      if (uriString == uriPermission.uri.toString()) return true;
    }
    return false;
  }
}
