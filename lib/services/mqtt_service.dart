import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  // ========== KONFIGURASI MQTT BROKER ==========
  // GANTI DENGAN CREDENTIALS HIVEMQ KAMU!
  static const String broker = 'broker.hivemq.com'; // Ganti dengan HiveMQ cloud URL
  static const int port = 1883; // Atau 8883 untuk SSL
  static const String clientId = 'FlutterSmartHome';
  static const String username = ''; // Kosongkan jika pakai broker.hivemq.com
  static const String password = ''; // Kosongkan jika pakai broker.hivemq.com

  // MQTT Topics
  static const String topicTemperature = 'smarthome/sensor/temperature';
  static const String topicHumidity = 'smarthome/sensor/humidity';
  static const String topicGas = 'smarthome/sensor/gas';
  static const String topicLight = 'smarthome/sensor/light';
  static const String topicDoorStatus = 'smarthome/door/status';
  
  static const String topicControlDoor = 'smarthome/control/door';
  static const String topicControlLight = 'smarthome/control/light';
  static const String topicControlCurtain = 'smarthome/control/curtain';

  late MqttServerClient client;
  bool _isConnected = false;

  // Callbacks untuk menerima data
  Function(Map<String, dynamic>)? onTemperatureReceived;
  Function(Map<String, dynamic>)? onHumidityReceived;
  Function(Map<String, dynamic>)? onGasReceived;
  Function(Map<String, dynamic>)? onLightReceived;
  Function(Map<String, dynamic>)? onDoorStatusReceived;
  Function(String)? onConnectionStatusChanged;

  MqttService() {
    client = MqttServerClient.withPort(broker, clientId, port);
    client.logging(on: false);
    client.keepAlivePeriod = 60;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;
    
    // Security context untuk SSL (jika pakai port 8883)
    // client.secure = true;
    // client.securityContext = SecurityContext.defaultContext;
  }

  // ========== CONNECTION METHODS ==========
  
  Future<bool> connect() async {
    try {
      print('[MQTT] Connecting to $broker:$port...');
      
      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .withWillTopic('smarthome/app/status')
          .withWillMessage('Flutter app disconnected')
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      
      if (username.isNotEmpty && password.isNotEmpty) {
        connMessage.authenticateAs(username, password);
      }
      
      client.connectionMessage = connMessage;
      
      await client.connect();
      
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('[MQTT] ✅ Connected successfully!');
        _isConnected = true;
        _subscribeToTopics();
        _listenToMessages();
        return true;
      } else {
        print('[MQTT] ❌ Connection failed: ${client.connectionStatus}');
        _isConnected = false;
        return false;
      }
    } catch (e) {
      print('[MQTT] ❌ Connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  void disconnect() {
    if (_isConnected) {
      client.disconnect();
      _isConnected = false;
      print('[MQTT] Disconnected');
    }
  }

  bool get isConnected => _isConnected;

  // ========== SUBSCRIPTION METHODS ==========

  void _subscribeToTopics() {
    // Subscribe ke semua topic sensor
    client.subscribe(topicTemperature, MqttQos.atLeastOnce);
    client.subscribe(topicHumidity, MqttQos.atLeastOnce);
    client.subscribe(topicGas, MqttQos.atLeastOnce);
    client.subscribe(topicLight, MqttQos.atLeastOnce);
    client.subscribe(topicDoorStatus, MqttQos.atLeastOnce);
    
    print('[MQTT] 📡 Subscribed to all sensor topics');
  }

  void _listenToMessages() {
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final topic = messages[0].topic;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        
        // Route berdasarkan topic
        switch (topic) {
          case topicTemperature:
            onTemperatureReceived?.call(data);
            break;
          case topicHumidity:
            onHumidityReceived?.call(data);
            break;
          case topicGas:
            onGasReceived?.call(data);
            break;
          case topicLight:
            onLightReceived?.call(data);
            break;
          case topicDoorStatus:
            onDoorStatusReceived?.call(data);
            break;
        }
        
        print('[MQTT] 📨 $topic: $payload');
      } catch (e) {
        print('[MQTT] ❌ Error parsing message from $topic: $e');
      }
    });
  }

  // ========== PUBLISH METHODS ==========

  void publishDoorControl(String command) {
    final payload = jsonEncode({
      'command': command,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    _publish(topicControlDoor, payload);
  }

  void publishLightControl(String command) {
    final payload = jsonEncode({
      'command': command,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    _publish(topicControlLight, payload);
  }

  void publishCurtainControl(int position) {
    final payload = jsonEncode({
      'command': 'SET_POSITION',
      'position': position,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
    _publish(topicControlCurtain, payload);
  }

  void _publish(String topic, String payload) {
    if (!_isConnected) {
      print('[MQTT] ❌ Cannot publish - not connected');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print('[MQTT] 📤 Published to $topic: $payload');
  }

  // ========== CALLBACK HANDLERS ==========

  void _onConnected() {
    print('[MQTT] 🟢 Connection established');
    _isConnected = true;
    onConnectionStatusChanged?.call('Connected');
  }

  void _onDisconnected() {
    print('[MQTT] 🔴 Disconnected');
    _isConnected = false;
    onConnectionStatusChanged?.call('Disconnected');
  }

  void _onSubscribed(String topic) {
    print('[MQTT] ✅ Subscribed to $topic');
  }

  void _pong() {
    print('[MQTT] 🏓 Ping response received');
  }
}
