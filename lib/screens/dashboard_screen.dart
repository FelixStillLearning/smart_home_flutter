import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_home_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_app_bar.dart';
import 'monitoring_screen.dart';
import 'controlling_screen.dart';
import 'login_screen.dart';
import 'admin_screen.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const MonitoringScreen(),
    const ControllingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart),
            label: 'Monitoring',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.control_camera),
            label: 'Control',
          ),
        ],
      ),
    );
  }
}

// ========== DASHBOARD HOME SCREEN ==========

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SmartHomeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Smart Home',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Reconnect jika disconnected
          if (!provider.isConnected) {
            await provider.connectToBackend();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Pintu Card
              _buildDoorStatusCard(context, provider),
              const SizedBox(height: 16),

              // Quick Controls
              _buildQuickControlsSection(provider),
              const SizedBox(height: 16),

              // Sensor Overview
              Text(
                'Sensor Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // Sensor Cards Grid
              _buildSensorGrid(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoorStatusCard(
      BuildContext context, SmartHomeProvider provider) {
    final isLocked = provider.doorStatus?.isLocked ?? true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLocked ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              size: 48,
              color: isLocked ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              isLocked ? 'PINTU TERKUNCI' : 'PINTU TERBUKA',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLocked ? 'Rumah Anda Aman' : 'Perhatian Diperlukan',
              style: TextStyle(
                fontSize: 14,
                color: isLocked ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isConnected ? provider.toggleDoor : null,
                icon: Icon(isLocked ? Icons.lock_open : Icons.lock),
                label: Text(
                  isLocked ? 'Buka Pintu' : 'Kunci Pintu',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: isLocked ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickControlsSection(SmartHomeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Controls',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickControlButton(
                icon: provider.isLightOn
                    ? Icons.lightbulb_rounded
                    : Icons.lightbulb_outline_rounded,
                label: 'Lampu',
                isOn: provider.isLightOn,
                color: Colors.amber,
                onPressed: provider.isConnected ? provider.toggleLight : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickControlButton(
                icon: Icons.blinds_closed_rounded,
                label: 'Gorden',
                subtitle: '${provider.curtainPosition}%',
                color: Colors.indigo,
                onPressed: provider.isConnected
                    ? () {
                        provider.setCurtainPosition(
                          provider.curtainPosition > 50 ? 0 : 100,
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickControlButton({
    required IconData icon,
    required String label,
    String? subtitle,
    bool isOn = false,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Card(
      elevation: isOn ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isOn ? color : Colors.white,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isOn ? Colors.white : color,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOn ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorGrid(SmartHomeProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildSensorCard(
          icon: Icons.thermostat,
          title: 'Suhu',
          value: provider.temperatureString,
          color: Colors.red,
        ),
        _buildSensorCard(
          icon: Icons.water_drop,
          title: 'Kelembaban',
          value: provider.humidityString,
          color: Colors.blue,
        ),
        _buildSensorCard(
          icon: Icons.warning_amber,
          title: 'Gas',
          value: provider.gasString,
          color: Color(provider.gasData?.getStatusColor() ?? 0xFF388E3C),
        ),
        _buildSensorCard(
          icon: Icons.wb_sunny,
          title: 'Cahaya',
          value: provider.lightString,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
