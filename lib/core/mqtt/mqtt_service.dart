import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:familly_baecon/core/config/app_config.dart';

class MqttService {
  final String server;
  final int port;
  final String clientId;
  final String? username;
  final String? password;
  late MqttServerClient _client;
  final _controller = StreamController<MqttReceivedMessage<MqttMessage>>.broadcast();

  MqttService({
    required this.server,
    required this.clientId,
    this.port = 1883,
    this.username,
    this.password,
  }) {
    _client = MqttServerClient(server, clientId);
    _client.port = port;
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;
    _client.onConnected = () {};
    _client.onDisconnected = () {};
    _client.logging(on: false);
  }

  Future<void> connect() async {
    try {
      final user = username?.isNotEmpty == true ? username : (AppConfig.mqttUsername.isNotEmpty ? AppConfig.mqttUsername : null);
      final pass = password?.isNotEmpty == true ? password : (AppConfig.mqttPassword.isNotEmpty ? AppConfig.mqttPassword : null);
      await _client.connect(user, pass);
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
    _client.subscribe(topic, MqttQos.atLeastOnce);
  }

  Stream<Map<String, dynamic>> jsonMessages(String topic) {
    subscribe(topic);
    return messages
        .where((msg) => msg.topic == topic)
        .map((msg) {
          final payload = msg.payload as MqttPublishMessage;
          final raw = MqttPublishPayload.bytesToStringAsString(payload.payload.message);
          final decoded = jsonDecode(raw);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('MQTT payload must be a JSON object');
          }
          return decoded;
        });
  }
}

