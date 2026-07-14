class SensorData {
  final double? temperature;
  final double? humidity;
  final int gas;
  final int airQuality;
  final bool motion;
  final DateTime? updatedAt;

  SensorData({
    this.temperature,
    this.humidity,
    this.gas = 0,
    this.airQuality = 0,
    this.motion = false,
    this.updatedAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      gas: json['gas'] as int? ?? 0,
      airQuality: json['airQuality'] as int? ?? 0,
      motion: json['motion'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class DeviceState {
  final bool light;
  final bool fan;
  final bool buzzer;
  final bool lockOpen;
  final bool gasAlert;

  DeviceState({
    this.light = false,
    this.fan = false,
    this.buzzer = false,
    this.lockOpen = false,
    this.gasAlert = false,
  });

  factory DeviceState.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DeviceState();
    return DeviceState(
      light: json['light'] as bool? ?? false,
      fan: json['fan'] as bool? ?? false,
      buzzer: json['buzzer'] as bool? ?? false,
      lockOpen: json['lockOpen'] as bool? ?? false,
      gasAlert: json['gasAlert'] as bool? ?? false,
    );
  }

  DeviceState copyWith({
    bool? light,
    bool? fan,
    bool? buzzer,
    bool? lockOpen,
    bool? gasAlert,
  }) {
    return DeviceState(
      light: light ?? this.light,
      fan: fan ?? this.fan,
      buzzer: buzzer ?? this.buzzer,
      lockOpen: lockOpen ?? this.lockOpen,
      gasAlert: gasAlert ?? this.gasAlert,
    );
  }
}

class Device {
  final String deviceId;
  final String name;
  final bool online;
  final DeviceState state;
  final SensorData? latestSensor;

  Device({
    required this.deviceId,
    this.name = 'Smart Home',
    this.online = false,
    DeviceState? state,
    this.latestSensor,
  }) : state = state ?? DeviceState();

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['deviceId'] as String? ?? '',
      name: json['name'] as String? ?? 'Smart Home',
      online: json['online'] as bool? ?? false,
      state: DeviceState.fromJson(json['state'] as Map<String, dynamic>?),
      latestSensor: json['latestSensor'] != null
          ? SensorData.fromJson(json['latestSensor'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AlertItem {
  final String id;
  final String deviceId;
  final String type;
  final String severity;
  final String message;
  final bool resolved;
  final DateTime? createdAt;

  AlertItem({
    required this.id,
    required this.deviceId,
    required this.type,
    required this.severity,
    required this.message,
    this.resolved = false,
    this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['_id']?.toString() ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'warning',
      message: json['message'] as String? ?? '',
      resolved: json['resolved'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class ActivityItem {
  final String id;
  final String action;
  final String target;
  final String? message;
  final String source;
  final DateTime? createdAt;

  ActivityItem({
    required this.id,
    required this.action,
    required this.target,
    this.message,
    this.source = 'system',
    this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['_id']?.toString() ?? '',
      action: json['action'] as String? ?? '',
      target: json['target'] as String? ?? '',
      message: json['message'] as String?,
      source: json['source'] as String? ?? 'system',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class HistorySensorPoint {
  final double? temperature;
  final double? humidity;
  final int gas;
  final int airQuality;
  final bool motion;
  final DateTime? createdAt;

  HistorySensorPoint({
    this.temperature,
    this.humidity,
    this.gas = 0,
    this.airQuality = 0,
    this.motion = false,
    this.createdAt,
  });

  factory HistorySensorPoint.fromJson(Map<String, dynamic> json) {
    return HistorySensorPoint(
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      gas: json['gas'] as int? ?? 0,
      airQuality: json['airQuality'] as int? ?? 0,
      motion: json['motion'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
