import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../widgets/widgets.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key, required this.socket});

  final SocketService socket;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: socket,
      builder: (context, _) {
        final state = socket.deviceState;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConnectionBanner(
              connected: socket.connected,
              online: socket.deviceOnline,
            ),
            const SizedBox(height: 16),
            Text('Điều khiển thiết bị',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Lệnh gửi qua Socket.IO tới ESP32',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DeviceToggleCard(
              icon: Icons.lightbulb_outline,
              label: 'Đèn',
              value: state.light,
              onChanged: socket.toggleLight,
            ),
            DeviceToggleCard(
              icon: Icons.air,
              label: 'Quạt',
              value: state.fan,
              onChanged: socket.toggleFan,
            ),
            DeviceToggleCard(
              icon: Icons.notifications_active_outlined,
              label: 'Còi báo động',
              value: state.buzzer,
              subtitle: state.gasAlert ? 'Gas alert đang bật còi' : null,
              onChanged: socket.toggleBuzzer,
            ),
            DeviceToggleCard(
              icon: Icons.lock_outline,
              label: 'Khóa cửa',
              value: state.lockOpen,
              subtitle: state.lockOpen ? 'Đang mở' : 'Đang đóng',
              onChanged: socket.toggleLock,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: socket.deviceOnline
                  ? () {
                      socket.toggleLight(false);
                      socket.toggleFan(false);
                      socket.toggleBuzzer(false);
                      socket.toggleLock(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã tắt tất cả')),
                      );
                    }
                  : null,
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Tắt tất cả'),
            ),
          ],
        );
      },
    );
  }
}
