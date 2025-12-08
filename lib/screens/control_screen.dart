// lib/screens/control_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({Key? key}) : super(key: key);

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final ApiService _apiService = ApiService();
  
  String _doorStatus = 'closed';
  String _lampStatus = 'off';
  String _curtainStatus = 'closed';
  
  bool _isLoadingDoor = false;
  bool _isLoadingLamp = false;
  bool _isLoadingCurtain = false;

  @override
  void initState() {
    super.initState();
    _fetchDeviceStatus();
  }

  Future<void> _fetchDeviceStatus() async {
    try {
      final results = await Future.wait([
        _apiService.getDoorStatus(),
        _apiService.getLampStatus(),
        _apiService.getCurtainStatus(),
      ]);

      if (mounted) {
        setState(() {
          if (results[0]['success'] && results[0]['data'] != null) {
            _doorStatus = results[0]['data']['status'] ?? 'closed';
          }
          if (results[1]['success'] && results[1]['data'] != null) {
            _lampStatus = results[1]['data']['status'] ?? 'off';
          }
          if (results[2]['success'] && results[2]['data'] != null) {
            _curtainStatus = results[2]['data']['status'] ?? 'closed';
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _controlDoor(String action) async {
    setState(() => _isLoadingDoor = true);
    try {
      await _apiService.controlDoor(action);
      await _fetchDeviceStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pintu berhasil ${action == "open" ? "dibuka" : "ditutup"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDoor = false);
      }
    }
  }

  Future<void> _controlLamp(String action) async {
    setState(() => _isLoadingLamp = true);
    try {
      await _apiService.controlLamp(action);
      await _fetchDeviceStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lampu berhasil ${action == "on" ? "dinyalakan" : "dimatikan"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLamp = false);
      }
    }
  }

  Future<void> _controlCurtain(String action) async {
    setState(() => _isLoadingCurtain = true);
    try {
      await _apiService.controlCurtain(action);
      await _fetchDeviceStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gorden berhasil ${action == "open" ? "dibuka" : "ditutup"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurtain = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kontrol Perangkat'),
        backgroundColor: Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDeviceStatus,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildDeviceControl(
              icon: Icons.door_front_door,
              title: 'Pintu',
              status: _doorStatus,
              isLoading: _isLoadingDoor,
              onAction1: () => _controlDoor('open'),
              onAction2: () => _controlDoor('close'),
              action1Label: 'Buka',
              action2Label: 'Tutup',
              statusText: _doorStatus == 'open' ? 'Terbuka' : 'Tertutup',
            ),
            SizedBox(height: 16),
            _buildDeviceControl(
              icon: Icons.lightbulb,
              title: 'Lampu',
              status: _lampStatus,
              isLoading: _isLoadingLamp,
              onAction1: () => _controlLamp('on'),
              onAction2: () => _controlLamp('off'),
              action1Label: 'Nyalakan',
              action2Label: 'Matikan',
              statusText: _lampStatus == 'on' ? 'Menyala' : 'Mati',
            ),
            SizedBox(height: 16),
            _buildDeviceControl(
              icon: Icons.curtains,
              title: 'Gorden',
              status: _curtainStatus,
              isLoading: _isLoadingCurtain,
              onAction1: () => _controlCurtain('open'),
              onAction2: () => _controlCurtain('close'),
              action1Label: 'Buka',
              action2Label: 'Tutup',
              statusText: _curtainStatus == 'open' ? 'Terbuka' : 'Tertutup',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceControl({
    required IconData icon,
    required String title,
    required String status,
    required bool isLoading,
    required VoidCallback onAction1,
    required VoidCallback onAction2,
    required String action1Label,
    required String action2Label,
    required String statusText,
  }) {
    final bool isActive = (status == 'open' || status == 'on');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: isActive ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: isActive ? Colors.green[800] : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAction1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(action1Label),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onAction2,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(action2Label),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
