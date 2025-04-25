<p align="center">
  <h1 align="center">S3Storage Dart</h1>
</p>

This is the _unofficial_ S3 (AWS, MinIO) Dart Client SDK that provides simple APIs to access any Amazon S3 compatible object storage server.

<p align="center">
  <a href="https://github.com/MindMayhem/s3_storage/actions/workflows/dart.yml">
    <img src="https://github.com/MindMayhem/s3_storage/workflows/Dart/badge.svg">
  </a>
  <a href="https://pub.dev/packages/s3_storage">
    <img src="https://img.shields.io/pub/v/s3_storage">
  </a>
</p>


## API

| Bucket operations       | Object operations        | Presigned operations  | Bucket Policy & Notification operations |
| ----------------------- | ------------------------ | --------------------- | --------------------------------------- |
| [makeBucket]            | [getObject]              | [presignedUrl]        | [getBucketNotification]                 |
| [listBuckets]           | [getPartialObject]       | [presignedGetObject]  | [setBucketNotification]                 |
| [bucketExists]          | [fGetObject]             | [presignedPutObject]  | [removeAllBucketNotification]           |
| [removeBucket]          | [putObject]              | [presignedPostPolicy] | [listenBucketNotification]              |
| [listObjects]           | [fPutObject]             |                       | [getBucketPolicy]                       |
| [listObjectsV2]         | [copyObject]             |                       | [setBucketPolicy]                       |
| [listIncompleteUploads] | [statObject]             |                       |                                         |
| [listAllObjects]        | [removeObject]           |                       |                                         |
| [listAllObjectsV2]      | [removeObjects]          |                       |                                         |
|                         | [removeIncompleteUpload] |                       |                                         |


## Usage

### Initialize MinIO Client

**MinIO**

```dart
final s3_storage = S3Storage(
  endPoint: 'play.min.io',
  accessKey: 'Q3AM3UQ867SPQQA43P2F',
  secretKey: 'zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG',
);
```

**AWS S3**

```dart
final s3_storage = S3Storage(
  endPoint: 's3.amazonaws.com',
  accessKey: 'YOUR-ACCESSKEYID',
  secretKey: 'YOUR-SECRETACCESSKEY',
);
```

**Filebase**

```dart
final s3_storage = S3Storage(
  endPoint: 's3.filebase.com',
  accessKey: 'YOUR-ACCESSKEYID',
  secretKey: 'YOUR-SECRETACCESSKEY',
  useSSL: true,
);
```

**File upload**
```dart
import 'package:s3_storage/io.dart';
import 'package:s3_storage/s3_storage.dart';

void main() async {
  final s3_storage = S3Storage(
    endPoint: 'play.min.io',
    accessKey: 'Q3AM3UQ867SPQQA43P2F',
    secretKey: 'zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG',
  );

  await s3_storage.fPutObject('mybucket', 'myobject', 'path/to/file');
}
```

For complete example, see: [example]

> To use `fPutObject()` and `fGetObject`, you have to `import 'package:s3_storage/io.dart';`

**Upload with progress**
```dart
import 'package:s3_storage/s3_storage.dart';

void main() async {
  final s3_storage = S3Storage(
    endPoint: 'play.min.io',
    accessKey: 'Q3AM3UQ867SPQQA43P2F',
    secretKey: 'zuf+tfteSlswRu7BJ86wekitnifILbZam1KYY3TG',
  );

  await s3_storage.putObject(
    'mybucket',
    'myobject',
    Stream<Uint8List>.value(Uint8List(1024)),
    onProgress: (bytes) => print('$bytes uploaded'),
  );
}
```

**Get object**

```dart
import 'dart:io';
import 'package:s3_storage/s3_storage.dart';

void main() async {
  final s3_storage = S3Storage(
    endPoint: 's3.amazonaws.com',
    accessKey: 'YOUR-ACCESSKEYID',
    secretKey: 'YOUR-SECRETACCESSKEY',
  );

  final stream = await s3_storage.getObject('BUCKET-NAME', 'OBJECT-NAME');

  // Get object length
  print(stream.contentLength);

  // Write object data stream to file
  await stream.pipe(File('output.txt').openWrite());
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

Contributions to this repository are welcome.

## License

MIT

[tracker]: https://github.com/MindMayhem/s3_storage/issues
[example]: https://pub.dev/packages/s3_storage#-example-tab-
[link text itself]: http://www.reddit.com

[makeBucket]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/makeBucket.html
[listBuckets]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/listBuckets.html
[bucketExists]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/bucketExists.html
[removeBucket]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/removeBucket.html
[listObjects]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/listObjects.html
[listObjectsV2]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/listObjectsV2.html
[listIncompleteUploads]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/listIncompleteUploads.html
[listAllObjects]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/listAllObjects.html
[listAllObjectsV2]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/listAllObjectsV2.html

[getObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/getObject.html
[getPartialObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/getPartialObject.html
[putObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/putObject.html
[copyObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/copyObject.html
[statObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/statObject.html
[removeObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/removeObject.html
[removeObjects]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/removeObjects.html
[removeIncompleteUpload]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/removeIncompleteUpload.html

[fGetObject]: https://pub.dev/documentation/s3_storage/latest/io/StorageX/fGetObject.html
[fPutObject]: https://pub.dev/documentation/s3_storage/latest/io/StorageX/fPutObject.html

[presignedUrl]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/presignedUrl.html
[presignedGetObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/presignedGetObject.html
[presignedPutObject]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/presignedPutObject.html
[presignedPostPolicy]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/presignedPostPolicy.html

[getBucketNotification]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/getBucketNotification.html
[setBucketNotification]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/setBucketNotification.html
[removeAllBucketNotification]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/removeAllBucketNotification.html
[listenBucketNotification]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/listenBucketNotification.html

[getBucketPolicy]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/getBucketPolicy.html
[setBucketPolicy]: https://pub.dev/documentation/s3_storage/latest/s3_storage/S3Storage/setBucketPolicy.html
