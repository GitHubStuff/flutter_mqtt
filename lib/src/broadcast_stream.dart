import 'dart:async';

import 'mqtt_connect.dart';

/// Defines a class for a StreamController, that will have take care of
/// implementation details like access to the stream, and sink.
/// The 'void dispose()' abstract will "remind" implementations to
/// to call 'close()' to close the stream in the Widget class's 'void dispose()'
///
abstract class BroadcastStream<T> {
  final StreamController<T> _streamController = StreamController<T>.broadcast();
  Stream<T> get stream => _streamController.stream;
  Sink<T> get sink => _streamController.sink;

  void dispose();

  void close() => _streamController.close();
}

class MQTTResponse {
  final String data;
  final MQTTAppConnectionState mqttAppConnectionState;
  final String topic;
  MQTTResponse(this.mqttAppConnectionState, this.topic, this.data);
}

class MQTTStream extends BroadcastStream<MQTTResponse> {
  @override
  void dispose() {
    super.close();
  }
}
