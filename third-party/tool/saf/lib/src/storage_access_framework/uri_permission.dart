/// Description of a single Uri permission grant.
/// This grants may have been created via `Intent#FLAG_GRANT_READ_URI_PERMISSION`,
/// etc when sending an `Intent`, or explicitly through `Context#grantUriPermission(String, android.net.Uri, int)`.
///
/// [Refer to details](https://developer.android.com/reference/android/content/UriPermission)
class UriPermission {
  /// Whether an [UriPermission] is created with [`FLAG_GRANT_READ_URI_PERMISSION`](https://developer.android.com/reference/android/content/Intent#FLAG_GRANT_READ_URI_PERMISSION)
  final bool isReadPermission;

  /// Whether an [UriPermission] is created with [`FLAG_GRANT_WRITE_URI_PERMISSION`](https://developer.android.com/reference/android/content/Intent#FLAG_GRANT_WRITE_URI_PERMISSION)
  final bool isWritePermission;

  /// Return the time when this permission was first persisted, in milliseconds
  /// since January 1, 1970 00:00:00.0 UTC. Returns `INVALID_TIME` if
  /// not persisted.
  ///
  /// [Refer to details](https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/content/UriPermission.java#77)
  final int persistedTime;

  /// Return the Uri this permission pertains to.
  ///
  /// [Refer to details](https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/content/UriPermission.java#56)
  final Uri uri;

  /// Even we allow create instances of this class avoid it and use
  /// `persistedUriPermissions` API instead
  const UriPermission(
      {required this.isReadPermission,
      required this.isWritePermission,
      required this.persistedTime,
      required this.uri});

  @override
  bool operator ==(Object other) =>
      other is UriPermission &&
      isReadPermission == other.isReadPermission &&
      isWritePermission == other.isWritePermission &&
      persistedTime == other.persistedTime &&
      uri == other.uri;

  @override
  int get hashCode =>
      Object.hash(isReadPermission, isWritePermission, persistedTime, uri);

  static UriPermission fromMap(Map<String, dynamic> map) {
    return UriPermission(
      isReadPermission: map['isReadPermission'],
      isWritePermission: map['isWritePermission'],
      persistedTime: map['persistedTime'],
      uri: Uri.parse(map['uri']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isReadPermission': isReadPermission,
      'isWritePermission': isWritePermission,
      'persistedTime': persistedTime,
      'uri': '$uri',
    };
  }

  @override
  String toString() => 'UriPermission('
      'isReadPermission: $isReadPermission, '
      'isWritePermission: $isWritePermission, '
      'persistedTime: $persistedTime, '
      'uri: $uri)';
}
