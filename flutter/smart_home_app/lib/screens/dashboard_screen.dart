import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.socket});

  final SocketService socket;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: socket,
      builder: (context, _) {
        final sensor = socket.liveSensor;
        final state = socket.deviceState;

        return RefreshIndicator(
          onRefresh: () async => socket.connect(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ConnectionBanner(
                connected: socket.connected,
                online: socket.deviceOnline,
              ),
              const SizedBox(height: 16),
              if (state.gasAlert)
                Card(
                  color: Colors.red.shade50,
                  child: const ListTile(
                    leading: Icon(Icons.warning, color: Colors.red),
                    title: Text('Cảnh báo rò rỉ gas!',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Còi báo động đang hoạt động'),
                  ),
                ),
              Text('Cảm biến realtime',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  SensorCard(
                    icon: Icons.thermostat,
                    label: 'Nhiệt độ',
                    value: sensor?.temperature != null
                        ? '${sensor!.temperature!.toStringAsFixed(1)}°C'
                        : '—',
                    color: Colors.orange,
                  ),
                  SensorCard(
                    icon: Icons.water_drop,
                    label: 'Độ ẩm',
                    value: sensor?.humidity != null
                        ? '${sensor!.humidity!.toStringAsFixed(1)}%'
                        : '—',
                    color: Colors.blue,
                  ),
                  SensorCard(
                    icon: Icons.air,
                    label: 'Chất lượng KK',
                    value: sensor != null ? '${sensor.airQuality}' : '—',
                    color: Colors.green,
                  ),
                  SensorCard(
                    icon: Icons.local_fire_department,
                    label: 'Khí gas',
                    value: sensor != null ? '${sensor.gas}' : '—',
                    color: Colors.red,
                  ),
                  SensorCard(
                    icon: Icons.directions_run,
                    label: 'Chuyển động',
                    value: sensor?.motion == true ? 'Có' : 'Không',
                    color: Colors.purple,
                  ),
                  SensorCard(
                    icon: Icons.power_settings_new,
                    label: 'Trạng thái',
                    value: socket.deviceOnline ? 'Online' : 'Offline',
                    color: socket.deviceOnline ? Colors.teal : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Thiết bị hiện tại',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _StatusChip('Đèn', state.light, Icons.lightbulb),
                  _StatusChip('Quạt', state.fan, Icons.air),
                  _StatusChip('Còi', state.buzzer || state.gasAlert, Icons.notifications_active),
                  _StatusChip('Khóa', state.lockOpen, Icons.lock_open),
                ],
              ),
              if (socket.liveAlerts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Cảnh báo mới',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...socket.liveAlerts.take(3).map(
                      (a) => ListTile(
                        leading: Icon(Icons.warning,
                            color: severityColor(a.severity)),
                        title: Text(a.message),
                        subtitle: Text(formatDateTime(a.createdAt)),
                      ),
                    ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.on, this.icon);

  final String label;
  final bool on;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: on ? Colors.white : Colors.grey),
      label: Text(label),
      backgroundColor: on ? Colors.teal : Colors.grey.shade200,
      labelStyle: TextStyle(color: on ? Colors.white : Colors.black87),
    );
  }
}
