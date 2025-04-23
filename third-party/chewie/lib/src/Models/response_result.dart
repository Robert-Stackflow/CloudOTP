class ResponseResult {
  bool success;
  int code;
  String message;
  int statusCode;
  dynamic data;
  dynamic data2;
  dynamic flag;

  ResponseResult({
    required this.success,
    required this.message,
    required this.data,
    required this.data2,
    required this.flag,
    required this.code,
    required this.statusCode,
  });

  ResponseResult.success({
    this.message = "Success",
    required this.data,
    this.flag,
    this.data2,
    this.code = 200,
    this.statusCode = 200,
  }) : success = true;

  ResponseResult.error({
    required this.message,
    this.data,
    this.flag,
    this.data2,
    this.code = 500,
    this.statusCode = 500,
  }) : success = false;

  @override
  String toString() {
    return 'ResponseResult{success: $success, code: $code, message: $message, statusCode: $statusCode, data: $data}';
  }
}
