enum ResponseStatus {
  success(200, 'Success'),
  connectionError(500, 'Connection Error'),
  unauthorized(401, 'Unauthorized'),
  nullAccessToken(9001, 'Null Access Token'),
  notFound(404, 'Not Found');

  final int code;
  final String message;

  const ResponseStatus(this.code, this.message);
}

class UploadStatus {
  final int index;
  final int total;
  final int start;
  final int end;
  final String contentLength;
  final String range;

  UploadStatus(
    this.index,
    this.total,
    this.start,
    this.end,
    this.contentLength,
    this.range,
  );
}

class CloudBaseException implements Exception {
  final String message;

  CloudBaseException(this.message);

  @override
  String toString() {
    return 'CloudBaseException: $message';
  }
}

class CloudNetworkException extends CloudBaseException {
  final int? statusCode;

  CloudNetworkException(
      [super.message = 'Network error ocurred', this.statusCode]);

  @override
  String toString() {
    return 'NetworkException: $message${statusCode != null ? ' (StatusCode: $statusCode)' : ''}';
  }
}

class NullAccessTokenException extends CloudBaseException {
  NullAccessTokenException(
      [super.message = "Null access token exception occurred"]);
}

class StateMisMatchException extends CloudBaseException {
  StateMisMatchException([super.message = "State mismatch exception occurred"]);

  @override
  String toString() {
    return 'StateMisMatchException: $message';
  }
}
