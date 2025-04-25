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

class NullAccessTokenException implements Exception {
  NullAccessTokenException();
}
