extension IterableExtensions<T> on Iterable<T> {
  int nullCount() => where((item) => item == null).length;

  int count(bool Function(T) test) => where(test).length;

  Iterable<T> evenIndices() => [
        for (var i = 0; i < length; i++) ...[
          if (i % 2 == 0) ...[
            elementAt(i),
          ],
        ],
      ];

  Iterable<int> indicesWhere(bool Function(T) test) => [
        for (var i = 0; i < length; i++) ...[
          if (test(elementAt(i))) ...[
            i,
          ],
        ],
      ];
}
