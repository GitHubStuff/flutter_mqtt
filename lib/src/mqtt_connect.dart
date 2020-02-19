import 'package:flutter/material.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

import 'broadcast_stream.dart';

enum MQTTAppConnectionState {
  connected,
  connecting,
  data,
  disconnected,
  initialize,
  publish,
}

//class MQTTAppState with ChangeNotifier {
//  MQTTAppConnectionState _appConnectionState = MQTTAppConnectionState.disconnected;
//
//  void setReceivedText(String text) {
//    _receivedText = text;
//    _historyText = _historyText + '\n' + _receivedText;
//    notifyListeners();
//  }
//
//  void setAppConnectionState(MQTTAppConnectionState state) {
//    _appConnectionState = state;
//    notifyListeners();
//  }
//
//  String get getReceivedText => _receivedText;
//  String get getHistoryText => _historyText;
//  MQTTAppConnectionState get getAppConnectionState => _appConnectionState;
//}

///
/// **************************************************************************
///
class MQTTManager {
  // Private instance of client
  MQTTAppConnectionState _currentState;
  mqtt.MqttClient _client;
  final String _identifier;
  final String _host;
  final String _topic;
  final Sink _sink;
  // Constructor
  MQTTManager({
    @required String host,
    @required String topic,
    @required String identifier,
    @required Sink<MQTTStream> sink,
    MQTTAppConnectionState state = MQTTAppConnectionState.disconnected,
  })  : assert(host != null),
        assert(topic != null),
        assert(identifier != null),
        assert(state != null),
        assert(sink != null),
        _identifier = identifier,
        _host = host,
        _topic = topic,
        _currentState = state,
        _sink = sink;

  void initializeMQTTClient({
    int port = 1883,
    int keepAliveSeconds = 30,
    bool logging = false,
  }) {
    assert(port != null && port > 0);
    assert(keepAliveSeconds != null && keepAliveSeconds > 5);
    _client = mqtt.MqttClient(_host, _identifier);
    _client.port = port;
    _client.keepAlivePeriod = keepAliveSeconds;
    _client.onDisconnected = onDisconnected;
    _client.logging(on: logging ?? false);

    /// Add the successful connection callback
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;

    final mqtt.MqttConnectMessage connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(mqtt.MqttQos.atLeastOnce);
    _sink.add(MQTTResponse(MQTTAppConnectionState.initialize, _topic, 'mqtt client initializing'));
    Log.t('mqtt client connecting....');
    _client.connectionMessage = connMess;
  }

  // Connect to the host
  void connect() async {
    assert(_client != null);
    try {
      Log.t('mqtt client connecting....');
      _sink.add(MQTTResponse(MQTTAppConnectionState.connecting, _topic, 'mqtt client connecting...'));
      _currentState = MQTTAppConnectionState.connecting;
      await _client.connect();
    } on Exception catch (e) {
      Log.e('mqtt client exception - $e');
      disconnect();
    }
  }

  void disconnect() {
    Log.t('mqtt Disconnected');
    _sink.add(MQTTResponse(MQTTAppConnectionState.disconnected, _topic, 'mqtt client disconnected'));

    _client.disconnect();
  }

  void publish(String message) {
    final mqtt.MqttClientPayloadBuilder builder = mqtt.MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(_topic, mqtt.MqttQos.exactlyOnce, builder.payload);
    _sink.add(MQTTResponse(MQTTAppConnectionState.publish, _topic, message));
  }

  /// The successful connect callback
  void onConnected() {
    _currentState = MQTTAppConnectionState.connected;
    Log.t('...mqtt client connected');
    _sink.add(MQTTResponse(MQTTAppConnectionState.connected, _topic, '...mqtt client connected'));
    _client.subscribe(_topic, mqtt.MqttQos.atLeastOnce);
    _client.updates.listen((List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> c) {
      final mqtt.MqttPublishMessage recMess = c[0].payload;
      final String payload = mqtt.MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _sink.add(MQTTResponse(MQTTAppConnectionState.data, _topic, payload));

      Log.t('mqtt Change notification:: topic is <${c[0].topic}>, payload is <-- $payload -->');
    });
    print('mqtt OnConnected client callback - Client connection was sucessful');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    Log.t('mqtt Client disconnection');
    if (_client.connectionStatus.returnCode == mqtt.MqttConnectReturnCode.solicited) {
      Log.t('mqtt OnDisconnected callback');
    }
    _currentState = MQTTAppConnectionState.disconnected;
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('mqtt Subscription confirmed for topic $topic');
  }
}
