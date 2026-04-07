import 'dart:async';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String server;
  final String clientId;
  late MqttServerClient _client;
  final _controller = StreamController<MqttReceivedMessage<MqttMessage>>.broadcast();

  MqttService({required this.server, required this.clientId}) {
    _client = MqttServerClient(server, clientId);
    _client.logging(on: false);
  }

  Future<void> connect() async {
    try {
      await _client.connect();
      _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>>? c) {
        if (c != null) {
          for (final msg in c) {
            _controller.add(msg);
          }
        }
      });
    } catch (e) {
      disconnect();
      rethrow;
    }
  }

  void disconnect() {
    _client.disconnect();
  }

  Stream<MqttReceivedMessage<MqttMessage>> get messages => _controller.stream;

  void subscribe(String topic) {
    _client.subscribe(topic, MqttQos.atMostOnce);
  }
}

