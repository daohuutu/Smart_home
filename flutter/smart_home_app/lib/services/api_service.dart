import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  Future<Device?> fetchDevice(String deviceId) async {
    final res = await http.get(_uri('/api/dashboard/$deviceId'));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return Device.fromJson(json['device'] as Map<String, dynamic>);
  }

  Future<List<HistorySensorPoint>> fetchSensorHistory(
    String deviceId, {
    int limit = 50,
  }) async {
    final res = await http.get(
      _uri('/api/sensors/$deviceId', {'limit': limit.toString()}),
    );
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => HistorySensorPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlertItem>> fetchAlerts(String deviceId, {int limit = 50}) async {
    final res = await http.get(
      _uri('/api/alerts/$deviceId', {'limit': limit.toString()}),
    );
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityItem>> fetchActivity(
    String deviceId, {
    int limit = 50,
  }) async {
    final res = await http.get(
      _uri('/api/activity/$deviceId', {'limit': limit.toString()}),
    );
    if (res.statusCode != 200) return [];
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> resolveAlert(String alertId) async {
    await http.patch(_uri('/api/alerts/$alertId/resolve'));
  }
}
