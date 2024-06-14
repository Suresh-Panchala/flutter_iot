// mqtt_service.dart
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  final String server;
  final String clientIdentifier;

  MqttServerClient? _client;

  MQTTService(this.server, this.clientIdentifier);

  Future<void> connect() async {
    _client = MqttServerClient(server, clientIdentifier);
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = _onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
    } catch (e) {
      _client!.disconnect();
      rethrow;
    }

    if (_client!.connectionStatus!.state != MqttConnectionState.connected) {
      _client!.disconnect();
      throw Exception('Failed to connect to MQTT broker');
    }
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _client?.disconnect();
  }
}
