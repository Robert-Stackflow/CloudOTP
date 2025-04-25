import 'dart:async';

class EventStreamController<T> {
  EventStreamController();

  StreamController<T>? _nullableStreamController;

  StreamController<T> get _streamController =>
      _nullableStreamController ??= StreamController<T>.broadcast();

  Stream<T> get stream => _streamController.stream;

  void emit(T event) {
    _streamController.sink.add(event);
  }

  void close() {
    _nullableStreamController?.close();
  }
}
