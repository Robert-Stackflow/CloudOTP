import 'package:s3_storage/models.dart';
import 'package:s3_storage/src/s3_client.dart';
import 'package:s3_storage/src/s3_helpers.dart';

class StorageError {
  StorageError(this.message);

  final String? message;

  @override
  String toString() {
    return 'StorageError: $message';
  }
}

class StorageAnonymousRequestError extends StorageError {
  StorageAnonymousRequestError(String message) : super(message);
}

class StorageInvalidArgumentError extends StorageError {
  StorageInvalidArgumentError(String message) : super(message);
}

class StorageInvalidPortError extends StorageError {
  StorageInvalidPortError(String message) : super(message);
}

class StorageInvalidEndpointError extends StorageError {
  StorageInvalidEndpointError(String message) : super(message);
}

class StorageInvalidBucketNameError extends StorageError {
  StorageInvalidBucketNameError(String message) : super(message);

  static void check(String bucket) {
    if (isValidBucketName(bucket)) return;
    throw StorageInvalidBucketNameError('Invalid bucket name: $bucket');
  }
}

class StorageInvalidObjectNameError extends StorageError {
  StorageInvalidObjectNameError(String message) : super(message);

  static void check(String object) {
    if (isValidObjectName(object)) return;
    throw StorageInvalidObjectNameError('Invalid object name: $object');
  }
}

class StorageAccessKeyRequiredError extends StorageError {
  StorageAccessKeyRequiredError(String message) : super(message);
}

class StorageSecretKeyRequiredError extends StorageError {
  StorageSecretKeyRequiredError(String message) : super(message);
}

class StorageExpiresParamError extends StorageError {
  StorageExpiresParamError(String message) : super(message);
}

class StorageInvalidDateError extends StorageError {
  StorageInvalidDateError(String message) : super(message);
}

class StorageInvalidPrefixError extends StorageError {
  StorageInvalidPrefixError(String message) : super(message);

  static void check(String prefix) {
    if (isValidPrefix(prefix)) return;
    throw StorageInvalidPrefixError('Invalid prefix: $prefix');
  }
}

class StorageInvalidBucketPolicyError extends StorageError {
  StorageInvalidBucketPolicyError(String message) : super(message);
}

class StorageIncorrectSizeError extends StorageError {
  StorageIncorrectSizeError(String message) : super(message);
}

class StorageInvalidXMLError extends StorageError {
  StorageInvalidXMLError(String message) : super(message);
}

class StorageS3Error extends StorageError {
  StorageS3Error(String? message, [this.error, this.response]) : super(message);

  Error? error;

  StorageResponse? response;
}
