import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

class MQTTClientWrapper {
  MqttServerClient client;
  //final topic = 'room2_Pump';
  final topic;
  MqttCurrentConnectionState mqttConnectionState =
      MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  final VoidCallback onConnectedCallback;
  final Function(List<dynamic>) onPumperChanged;

  MQTTClientWrapper(this.onConnectedCallback, this.topic, this.onPumperChanged);

  void prepareMqttClient() async {
    this.client = await _connectClient();
    subscribeToTopic(this.topic);
    //_publishMessage('Hello');
  }

  Future<MqttServerClient> _connectClient() async {
    MqttServerClient client = MqttServerClient.withPort(
        '65e43e44ae804a39a13fdbde9785fe22.s1.eu.hivemq.cloud', '123', 8883);

    client.secure = true;
    client.logging(on: false);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onUnsubscribed = _onUnsubscribed;
    client.onSubscribed = _onSubscribed;
    client.onSubscribeFail = _onSubscribeFail;
    client.pongCallback = _pong;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .authenticateAs('gacontrolai', 'Gacontrolai@123')
        .keepAliveFor(60)
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      print('MQTTClientWrapper::Mosquitto client connecting....');
      mqttConnectionState = MqttCurrentConnectionState.CONNECTING;

      await client.connect();
    } catch (e) {
      print('MQTTClientWrapper::client exception - $e');
      mqttConnectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      mqttConnectionState = MqttCurrentConnectionState.CONNECTED;
      print('MQTTClientWrapper::Mosquitto client connected');
    } else {
      print(
          'MQTTClientWrapper::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      mqttConnectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
    return client;
  }

  void subscribeToTopic(String topicName) {
    print('MQTTClientWrapper::Subscribing to the $topicName topic');
    this.client.subscribe(topicName, MqttQos.atLeastOnce);

    this.client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received message:$payload from topic: ${c[0].topic}>');
      if (payload.contains('id') && c[0].topic == topicName) onPumperChanged(jsonDecode(payload));
    });
  }

  void _publishMessage(String message) {
    final pubTopic = this.topic;
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    this.client.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload);
    print('MQTTClientWrapper::Publishing message $message to topic $pubTopic');
  }

  void _onSubscribed(String topic) {
    print('MQTTClientWrapper::Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
  }

  void _onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  void _onUnsubscribed(String topic) {
    print('Unsubscribed topic: $topic');
  }

  void _onDisconnected() {
    print('Disconnected');
    mqttConnectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    mqttConnectionState = MqttCurrentConnectionState.CONNECTED;
    print(
        'MQTTClientWrapper::OnConnected client callback - Client connection was sucessful');
    onConnectedCallback();
  }

  void _pong() {
    print('Ping response client callback invoked');
  }
}
