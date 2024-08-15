import 'dart:typed_data';

class OneDriveResponse {
  final int? statusCode;
  final String? body;
  final String? message;
  final bool isSuccess;
  final Uint8List? bodyBytes;

  OneDriveResponse({
    this.statusCode,
    this.body,
    this.message,
    this.bodyBytes,
    this.isSuccess = false
  });

  @override
  String toString() {
    return "OneDriveResponse("
        "statusCode: $statusCode, "
        "body: $body, "
        "bodyBytes: $bodyBytes, "
        "message: $message, "
        "isSuccess: $isSuccess"
      ")";
  }
}
