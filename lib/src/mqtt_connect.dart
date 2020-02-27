import 'package:flutter/material.dart';
import 'package:flutter_abstract_package/flutter_abstract_package.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:mqtt_client/mqtt_client.dart';

enum MQTTAppConnectionState {
  connected,
  connecting,
  data,
  disconnected,
  initialize,
  publish,
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

///
/// **************************************************************************
///
class MQTTManager {
  /// Private instance of client
  MqttClient _client;

  /// Internal reference that holds state of the mqtt connection, accessible via getter
  MQTTAppConnectionState _currentState;

  /// String that is prepended to MQTT messages
  final String _identifier;

  /// The url-style host of the mqtt server
  final String _host;

  /// The topic to subscribe to
  final String _topic;

  /// Async Dart Sink that will receive mqtt state and data messages
  final Sink<MQTTResponse> _sink;

  /// Constructor
  MQTTManager({
    @required String host,
    @required String topic,
    String identifier = '7.1.1 Nougat',
    @required Sink sink,
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

  /// Getter for current state
  MQTTAppConnectionState get currentState => _currentState;

  /// this initialize the mqtt session, creating a client that can be connected to and
  /// subscribe to the mqtt server to listen for messages
  void initializeMQTTClient({
    int port = 1883,
    int keepAliveSeconds = 30,
    bool logging = false,
  }) {
    assert(port != null && port > 0);
    assert(keepAliveSeconds != null && keepAliveSeconds > 5);
    _client = MqttClient(_host, _identifier);
    _client.port = port;
    _client.keepAlivePeriod = keepAliveSeconds;
    _client.onDisconnected = onDisconnected;
    _client.logging(on: logging ?? false);

    /// Add the successful connection callback
    _client.onConnected = onConnected;
    _client.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    _sink.add(MQTTResponse(MQTTAppConnectionState.initialize, _topic, 'mqtt client initializing'));
    Log.t('mqtt client connecting....');
    _client.connectionMessage = connMess;
  }

  /// Connect to the mqtt server and start listening for messages
  Future<void> connect() async {
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

  /// Disconnect from the mqtt server
  void disconnect() {
    Log.t('mqtt Disconnected');
    _sink.add(MQTTResponse(MQTTAppConnectionState.disconnected, _topic, 'mqtt client disconnected'));
    _client.disconnect();
  }

  /// Publish a message to the mqtt server
  void publish(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload);
    _sink.add(MQTTResponse(MQTTAppConnectionState.publish, _topic, message));
  }

  /// The successful connect callback, this is called by the mqtt_client that was created in initialize phase
  /// to respond when connection is made. When there is a connection, the updates.listen of the client will
  /// be called when an mqtt message is published.
  void onConnected() {
    _currentState = MQTTAppConnectionState.connected;
    Log.t('...mqtt client connected');
    _sink.add(MQTTResponse(MQTTAppConnectionState.connected, _topic, '...mqtt client connected'));
    _client.subscribe(_topic, MqttQos.atLeastOnce);

    /// This is the listener that will receive messages from the mqtt-server
    _client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      /// Because the data is a byte stream it is converted into string and returned via the Sink.add
      /// so that interested listeners all receive the data
      final MqttPublishMessage recMess = c[0].payload;
      final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      _sink.add(MQTTResponse(MQTTAppConnectionState.data, _topic, payload));

      Log.t('mqtt Change notification:: topic is <${c[0].topic}>, payload is <-- $payload -->');
    });
    Log.t('mqtt OnConnected client callback - Client connection was sucessful');
  }

  /// The unsolicited disconnect callback
  void onDisconnected() {
    Log.t('mqtt Client disconnection');
    Log.t('code = ${_client.connectionStatus.returnCode}');
    _currentState = MQTTAppConnectionState.disconnected;
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    Log.t('mqtt Subscription confirmed for topic $topic');
  }
}
