import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_home_provider.dart';
import '../providers/auth_provider.dart';
import 'monitoring_screen.dart';
import 'controlling_screen.dart';
import 'login_screen.dart';

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
      appBar: AppBar(
        title: const Text('🏠 Smart Home Dashboard'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  provider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isConnected ? 'Connected' : 'Offline',
                  style: TextStyle(
                    color: provider.isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          // User menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Apakah Anda yakin ingin logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true && context.mounted) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authProvider.currentUser?.name ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      authProvider.currentUser?.email ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      elevation: 4,
      color: isLocked ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              size: 64,
              color: isLocked ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              isLocked ? 'PINTU TERKUNCI' : 'PINTU TERBUKA',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.isConnected ? provider.toggleDoor : null,
                icon: Icon(isLocked ? Icons.lock_open : Icons.lock),
                label: Text(isLocked ? 'Buka Pintu' : 'Kunci Pintu'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isLocked ? Colors.orange : Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickControlsSection(SmartHomeProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickControlButton(
                    icon: provider.isLightOn
                        ? Icons.lightbulb
                        : Icons.lightbulb_outline,
                    label: 'Lampu',
                    isOn: provider.isLightOn,
                    onPressed:
                        provider.isConnected ? provider.toggleLight : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickControlButton(
                    icon: Icons.blinds,
                    label: 'Gorden',
                    subtitle: '${provider.curtainPosition}%',
                    onPressed: provider.isConnected
                        ? () {
                            // Toggle gorden (0 atau 100)
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
        ),
      ),
    );
  }

  Widget _buildQuickControlButton({
    required IconData icon,
    required String label,
    String? subtitle,
    bool isOn = false,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        backgroundColor: isOn ? Colors.amber.shade100 : null,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(fontSize: 12)),
        ],
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
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
