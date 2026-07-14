import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.api,
    required this.deviceId,
  });

  final ApiService api;
  final String deviceId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool loading = true;
  List<HistorySensorPoint> sensors = [];
  List<AlertItem> alerts = [];
  List<ActivityItem> activities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final results = await Future.wait([
      widget.api.fetchSensorHistory(widget.deviceId, limit: 30),
      widget.api.fetchAlerts(widget.deviceId, limit: 30),
      widget.api.fetchActivity(widget.deviceId, limit: 30),
    ]);
    if (!mounted) return;
    setState(() {
      sensors = results[0] as List<HistorySensorPoint>;
      alerts = results[1] as List<AlertItem>;
      activities = results[2] as List<ActivityItem>;
      loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cảm biến'),
            Tab(text: 'Cảnh báo'),
            Tab(text: 'Hoạt động'),
          ],
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _SensorList(sensors: sensors),
                      _AlertList(alerts: alerts, api: widget.api, onResolved: _load),
                      _ActivityList(activities: activities),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _SensorList extends StatelessWidget {
  const _SensorList({required this.sensors});
  final List<HistorySensorPoint> sensors;

  @override
  Widget build(BuildContext context) {
    if (sensors.isEmpty) {
      return const ListTile(title: Text('Chưa có dữ liệu'));
    }
    return ListView.builder(
      itemCount: sensors.length,
      itemBuilder: (context, i) {
        final s = sensors[i];
        return ListTile(
          leading: const Icon(Icons.sensors),
          title: Text(
            'T: ${s.temperature?.toStringAsFixed(1) ?? "—"}°C | '
            'H: ${s.humidity?.toStringAsFixed(1) ?? "—"}% | '
            'Gas: ${s.gas}',
          ),
          subtitle: Text(
            'AQI: ${s.airQuality} | Motion: ${s.motion ? "Có" : "Không"} | '
            '${formatDateTime(s.createdAt)}',
          ),
        );
      },
    );
  }
}

class _AlertList extends StatelessWidget {
  const _AlertList({
    required this.alerts,
    required this.api,
    required this.onResolved,
  });

  final List<AlertItem> alerts;
  final ApiService api;
  final VoidCallback onResolved;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const ListTile(title: Text('Không có cảnh báo'));
    }
    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (context, i) {
        final a = alerts[i];
        return ListTile(
          leading: Icon(Icons.warning, color: severityColor(a.severity)),
          title: Text(a.message),
          subtitle: Text('${a.type} • ${formatDateTime(a.createdAt)}'),
          trailing: a.resolved
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.done),
                  onPressed: () async {
                    await api.resolveAlert(a.id);
                    onResolved();
                  },
                ),
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.activities});
  final List<ActivityItem> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const ListTile(title: Text('Chưa có hoạt động'));
    }
    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, i) {
        final a = activities[i];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text('${a.target} — ${a.action}'),
          subtitle: Text(
            '${a.source} • ${a.message ?? ""} • ${formatDateTime(a.createdAt)}',
          ),
        );
      },
    );
  }
}
