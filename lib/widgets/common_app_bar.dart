import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_home_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/profile_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CommonAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SmartHomeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return AppBar(
      title: Text(title),
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
            if (value == 'profile') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            } else if (value == 'analytics') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            } else if (value == 'admin_panel') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              );
            } else if (value == 'settings') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            } else if (value == 'logout') {
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
                authProvider.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Analytics'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ];

            // Add admin panel menu if user is admin
            if (authProvider.currentUser?.role == 'admin') {
              items.insert(
                2,
                const PopupMenuItem(
                  value: 'admin_panel',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings),
                      SizedBox(width: 8),
                      Text('Admin Panel'),
                    ],
                  ),
                ),
              );
            }

            items.add(const PopupMenuDivider());
            items.add(
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            );

            return items;
          },
        ),
      ],
    );
  }
}
