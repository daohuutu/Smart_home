import 'package:flutter/material.dart';
import 'config.dart';
import 'screens/control_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'services/api_service.dart';
import 'services/socket_service.dart';

void main() {
  runApp(const SmartHomeApp());
}

class SmartHomeApp extends StatefulWidget {
  const SmartHomeApp({super.key});

  @override
  State<SmartHomeApp> createState() => _SmartHomeAppState();
}

class _SmartHomeAppState extends State<SmartHomeApp> {
  late final SocketService _socket;
  late final ApiService _api;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _api = ApiService(baseUrl: kServerUrl);
    _socket = SocketService(serverUrl: kServerUrl, deviceId: kDeviceId);
    _socket.connect();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final device = await _api.fetchDevice(kDeviceId);
    if (device == null || !mounted) return;
    setState(() {
      _socket.deviceOnline = device.online;
      _socket.deviceState = device.state;
      if (device.latestSensor != null) {
        _socket.liveSensor = device.latestSensor;
      }
    });
  }

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(socket: _socket),
      ControlScreen(socket: _socket),
      HistoryScreen(api: _api, deviceId: kDeviceId),
    ];

    return MaterialApp(
      title: 'Smart Home',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Home'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  kDeviceId,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
        body: pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Giám sát',
            ),
            NavigationDestination(
              icon: Icon(Icons.toggle_on_outlined),
              selectedIcon: Icon(Icons.toggle_on),
              label: 'Điều khiển',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history),
              label: 'Lịch sử',
            ),
          ],
        ),
      ),
    );
  }
}
