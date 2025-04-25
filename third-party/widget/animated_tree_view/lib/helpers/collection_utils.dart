extension CollectionExtension<T> on Iterable<T?> {
  List<T> filterNotNull() => List<T>.from(where((e) => e != null));

  List<S> castToListOf<S>() => map((e) => e as S?).filterNotNull();
}
