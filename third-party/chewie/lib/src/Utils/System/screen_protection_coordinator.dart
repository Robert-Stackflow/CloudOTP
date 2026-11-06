/// Serialize native protection transitions and avoid reattaching the secure
/// rendering surface whenever Flutter rebuilds a page.
class ScreenProtectionCoordinator {
  bool? _applied;
  Future<void> _pending = Future.value();
  bool? get applied => _applied;

  Future<void> set(bool enabled, Future<void> Function(bool) apply) {
    final operation = _pending.then((_) async {
      if (_applied == enabled) return;
      await apply(enabled);
      _applied = enabled;
    });
    _pending = operation.catchError((Object _) {});
    return operation;
  }
}
