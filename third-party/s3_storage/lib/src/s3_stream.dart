import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

class StorageByteStream extends StreamView<List<int>> {
  StorageByteStream.fromStream({
    required Stream<List<int>> stream,
    required this.contentLength,
  }) : super(stream);

  final int? contentLength;

  Future<Uint8List> toBytes() {
    var completer = Completer<Uint8List>();
    var sink = ByteConversionSink.withCallback(
            (bytes) => completer.complete(Uint8List.fromList(bytes)));
    listen(sink.add,
        onError: completer.completeError,
        onDone: sink.close,
        cancelOnError: true);
    return completer.future;
  }
}
