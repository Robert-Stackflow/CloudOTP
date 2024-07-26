enum GestureStatus {
  create,
  createFailed,
  verify,
  verifyFailed,
  verifyFailedCountOverflow
}

class GestureNotifier {
  GestureNotifier({
    required this.status,
    required this.gestureText,
  });

  GestureStatus status;
  String gestureText;

  void setStatus({required GestureStatus status, required String gestureText}) {
    this.status = status;
    this.gestureText = gestureText;
  }
}
