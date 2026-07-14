import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/models.dart';

typedef DashboardCallback = void Function(Map<String, dynamic> payload);
typedef AlertCallback = void Function(AlertItem alert);

class SocketService extends ChangeNotifier {
  SocketService({
    required this.serverUrl,
    required this.deviceId,
  });

  final String serverUrl;
  final String deviceId;

  io.Socket? _socket;
  bool connected = false;

  SensorData? liveSensor;
  DeviceState deviceState = DeviceState();
  bool deviceOnline = false;
  final List<AlertItem> liveAlerts = [];

  DashboardCallback? onDashboardUpdate;
  AlertCallback? onNewAlert;

  void connect() {
    _socket?.dispose();

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      connected = true;
      _socket!.emit('register', {'role': 'client'});
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      connected = false;
      notifyListeners();
    });

    _socket!.on('dashboard_update', (data) {
      if (data is! Map) return;
      final payload = Map<String, dynamic>.from(data);

      if (payload['deviceId'] != deviceId) return;

      final type = payload['type'] as String?;
      if (type == 'sensor_data') {
        final sensorJson = Map<String, dynamic>.from(payload['data'] as Map);
        liveSensor = SensorData.fromJson(sensorJson);
        deviceOnline = true;
      } else if (type == 'device_status') {
        final statusJson = Map<String, dynamic>.from(payload['data'] as Map);
        deviceState = DeviceState.fromJson(statusJson);
        deviceOnline = true;
      } else if (type == 'device_online') {
        deviceOnline = true;
      } else if (type == 'device_offline') {
        deviceOnline = false;
      }

      onDashboardUpdate?.call(payload);
      notifyListeners();
    });

    _socket!.on('alert_new', (data) {
      if (data is! Map) return;
      final alert = AlertItem.fromJson(Map<String, dynamic>.from(data));
      if (alert.deviceId != deviceId) return;

      liveAlerts.insert(0, alert);
      if (liveAlerts.length > 20) liveAlerts.removeLast();
      onNewAlert?.call(alert);
      notifyListeners();
    });
  }

  void sendCommand(String device, bool state) {
    _socket?.emit('device_command', {
      'deviceId': deviceId,
      'device': device,
      'state': state,
    });
  }

  void toggleLight(bool value) {
    deviceState = deviceState.copyWith(light: value);
    sendCommand('light', value);
    notifyListeners();
  }

  void toggleFan(bool value) {
    deviceState = deviceState.copyWith(fan: value);
    sendCommand('fan', value);
    notifyListeners();
  }

  void toggleBuzzer(bool value) {
    deviceState = deviceState.copyWith(buzzer: value);
    sendCommand('buzzer', value);
    notifyListeners();
  }

  void toggleLock(bool open) {
    deviceState = deviceState.copyWith(lockOpen: open);
    sendCommand('lock', open);
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
