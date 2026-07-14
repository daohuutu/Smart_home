import 'package:flutter/material.dart';
import '../models/models.dart';

class SensorCard extends StatelessWidget {
  const SensorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceToggleCard extends StatelessWidget {
  const DeviceToggleCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, size: 32),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.connected, this.online});

  final bool connected;
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final ok = connected && (online ?? true);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ok ? Colors.green.shade100 : Colors.red.shade100,
      child: Row(
        children: [
          Icon(ok ? Icons.cloud_done : Icons.cloud_off,
              color: ok ? Colors.green.shade800 : Colors.red.shade800),
          const SizedBox(width: 8),
          Text(
            ok ? 'Đã kết nối server & thiết bị' : 'Mất kết nối',
            style: TextStyle(
              color: ok ? Colors.green.shade900 : Colors.red.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Color severityColor(String severity) {
  switch (severity) {
    case 'critical':
      return Colors.red;
    case 'warning':
      return Colors.orange;
    default:
      return Colors.blue;
  }
}

String formatDateTime(DateTime? dt) {
  if (dt == null) return '—';
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
