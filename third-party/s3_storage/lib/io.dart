import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' show dirname;
import 'package:s3_storage/src/s3.dart';
import 'package:s3_storage/src/s3_errors.dart';
import 'package:s3_storage/src/s3_helpers.dart';

extension StorageX on S3Storage {
  // Uploads the object using contents from a file
  Future<String> fPutObject(
    String bucket,
    String object,
    String filePath, [
    Map<String, String>? metadata,
  ]) async {
    StorageInvalidBucketNameError.check(bucket);
    StorageInvalidObjectNameError.check(object);

    metadata ??= {};
    metadata = insertContentType(metadata, filePath);
    metadata = prependXAMZMeta(metadata);

    final file = File(filePath);
    final stat = await file.stat();
    if (stat.size > maxObjectSize) {
      throw StorageError(
        '$filePath size : ${stat.size}, max allowed size : 5TB',
      );
    }

    return putObject(
      bucket,
      object,
      file.openRead().cast<Uint8List>(),
      size: stat.size,
      metadata: metadata,
    );
  }

  /// Downloads and saves the object as a file in the local filesystem.
  Future<void> fGetObject(
    String bucket,
    String object,
    String filePath,
  ) async {
    StorageInvalidBucketNameError.check(bucket);
    StorageInvalidObjectNameError.check(object);

    final stat = await statObject(bucket, object);
    final dir = dirname(filePath);
    await Directory(dir).create(recursive: true);

    final partFileName = '$filePath.${stat.etag}.part.s3storage';
    final partFile = File(partFileName);
    IOSink partFileStream;
    var offset = 0;

    final rename = () {
      partFile.rename(filePath);
    };

    if (await partFile.exists()) {
      final localStat = await partFile.stat();
      if (stat.size == localStat.size) return rename();
      offset = localStat.size;
      partFileStream = partFile.openWrite(mode: FileMode.append);
    } else {
      partFileStream = partFile.openWrite(mode: FileMode.write);
    }

    final dataStream = await getPartialObject(bucket, object, offset);
    await dataStream.pipe(partFileStream);

    final localStat = await partFile.stat();
    if (localStat.size != stat.size) {
      throw StorageError(
          'Size mismatch between downloaded file and the object');
    }

    return rename();
  }
}
