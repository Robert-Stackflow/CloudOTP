class S3CloudFileInfo {
  String? id;
  String name;
  String path;
  int createTimestamp;
  int modifyTimestamp;
  int size;

  S3CloudFileInfo({
    required this.id,
    required this.name,
    required this.path,
    required this.createTimestamp,
    required this.modifyTimestamp,
    required this.size,
  });
}
