class WebDavFileInfo {
  String? path;
  bool? isDir;
  String? name;
  String? mimeType;
  int? size;
  String? eTag;
  DateTime? cTime;
  DateTime? mTime;

  WebDavFileInfo({
    this.path,
    this.isDir,
    this.name,
    this.mimeType,
    this.size,
    this.eTag,
    this.cTime,
    this.mTime,
  });
}
