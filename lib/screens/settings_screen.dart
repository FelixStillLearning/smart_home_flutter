import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<SettingsProvider>(context, listen: false).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildSectionTitle('Appearance'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Theme'),
                      subtitle: Text(_getThemeLabel(settings.theme)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showThemeDialog(settingsProvider),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionTitle('Notifications'),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive alerts and updates'),
                  value: settings.notifications,
                  onChanged: (value) {
                    settingsProvider.updateNotifications(value);
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Data & Refresh Section
              _buildSectionTitle('Data & Refresh'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.refresh),
                      title: const Text('Auto Refresh'),
                      subtitle: const Text('Automatically refresh sensor data'),
                      value: settings.autoRefresh,
                      onChanged: (value) {
                        settingsProvider.updateAutoRefresh(value);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Refresh Interval'),
                      subtitle: Text('${settings.refreshInterval} seconds'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showRefreshIntervalDialog(settingsProvider),
                      enabled: settings.autoRefresh,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Language Section
              _buildSectionTitle('Language'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  subtitle: Text(_getLanguageLabel(settings.language)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(settingsProvider),
                ),
              ),
              const SizedBox(height: 24),

              // About Section
              _buildSectionTitle('About'),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info),
                      title: Text('Version'),
                      subtitle: Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Developer'),
                      subtitle: const Text('Smart Home IoT Team'),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Smart Home IoT',
                          applicationVersion: '1.0.0',
                          applicationIcon: const Icon(Icons.home, size: 48),
                          children: const [
                            Text(
                              'A comprehensive smart home management system with IoT integration.',
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Danger Zone
              _buildSectionTitle('Danger Zone'),
              Card(
                color: Colors.red.withOpacity(0.1),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.orange),
                      title: const Text(
                        'Reset Settings',
                        style: TextStyle(color: Colors.orange),
                      ),
                      subtitle: const Text('Restore default settings'),
                      onTap: () => _confirmResetSettings(settingsProvider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Sign out from your account'),
                      onTap: () => _confirmLogout(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
        return 'System Default';
      default:
        return theme;
    }
  }

  String _getLanguageLabel(String language) {
    switch (language) {
      case 'en':
        return 'English';
      case 'id':
        return 'Bahasa Indonesia';
      default:
        return language;
    }
  }

  void _showThemeDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: provider.settings.theme,
              onChanged: (value) {
                if (value != null) {
                  provider.updateTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: provider.settings.theme,
              onChanged: (value) {
                if (value != null) {
                  provider.updateTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: provider.settings.theme,
              onChanged: (value) {
                if (value != null) {
                  provider.updateTheme(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: provider.settings.language,
              onChanged: (value) {
                if (value != null) {
                  provider.updateLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Bahasa Indonesia'),
              value: 'id',
              groupValue: provider.settings.language,
              onChanged: (value) {
                if (value != null) {
                  provider.updateLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRefreshIntervalDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refresh Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('3 seconds'),
              value: 3,
              groupValue: provider.settings.refreshInterval,
              onChanged: (value) {
                if (value != null) {
                  provider.updateRefreshInterval(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('5 seconds'),
              value: 5,
              groupValue: provider.settings.refreshInterval,
              onChanged: (value) {
                if (value != null) {
                  provider.updateRefreshInterval(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('10 seconds'),
              value: 10,
              groupValue: provider.settings.refreshInterval,
              onChanged: (value) {
                if (value != null) {
                  provider.updateRefreshInterval(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<int>(
              title: const Text('30 seconds'),
              value: 30,
              groupValue: provider.settings.refreshInterval,
              onChanged: (value) {
                if (value != null) {
                  provider.updateRefreshInterval(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmResetSettings(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to default'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();

              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
