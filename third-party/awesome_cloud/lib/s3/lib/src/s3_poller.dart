import 'dart:async';
import 'dart:convert';

import 's3_client.dart';

class NotificationPoller {
  NotificationPoller(
    this._client,
    this.bucket,
    this.prefix,
    this.suffix,
    this.events,
  );

  final StorageClient _client;
  final String bucket;
  final String? prefix;
  final String? suffix;
  final List<String>? events;

  final _eventStream = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _eventStream.stream;

  bool _stop = true;

  bool get isStarted {
    return !_stop;
  }

  /// Starts the polling.
  void start() async {
    _stop = false;
    while (!_stop) {
      await _checkForChanges();
    }
  }

  /// Stops the polling.
  void stop() {
    _stop = true;
  }

  Future<void> _checkForChanges() async {
    // Don't continue if we're looping again but are cancelled.
    if (_stop) return;

    final queries = {
      if (prefix != null) 'prefix': prefix,
      if (suffix != null) 'suffix': suffix,
      if (events != null) 'events': events,
    };

    final respStream = await _client.requestStream(
      method: 'GET',
      bucket: bucket,
      queries: queries,
    );

    await for (var resp in respStream.stream) {
      if (_stop) break;

      final chunk = utf8.decode(resp);
      if (chunk.trim().isEmpty) continue;
      final data = json.decode(chunk);
      final records = List<Map<String, dynamic>>.from(data['Records']);
      await _eventStream.addStream(Stream.fromIterable(records));
    }
  }
}
