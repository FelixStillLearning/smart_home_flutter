// lib/screens/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Timer? _pollingTimer;
  
  double _temperature = 0.0;
  double _humidity = 0.0;
  int _gas = 0;
  int _light = 0;
  
  String _doorStatus = 'closed';
  String _lampStatus = 'off';
  String _curtainStatus = 'closed';
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchAllData();
    });
  }

  Future<void> _fetchAllData() async {
    try {
      final results = await Future.wait([
        _apiService.getSensorData('temperature'),
        _apiService.getSensorData('humidity'),
        _apiService.getSensorData('gas'),
        _apiService.getSensorData('light'),
        _apiService.getDoorStatus(),
        _apiService.getLampStatus(),
        _apiService.getCurtainStatus(),
      ]);

      if (mounted) {
        setState(() {
          if (results[0]['success'] && results[0]['data'] != null) {
            _temperature = (results[0]['data']['value'] ?? 0).toDouble();
          }
          if (results[1]['success'] && results[1]['data'] != null) {
            _humidity = (results[1]['data']['value'] ?? 0).toDouble();
          }
          if (results[2]['success'] && results[2]['data'] != null) {
            _gas = results[2]['data']['value'] ?? 0;
          }
          if (results[3]['success'] && results[3]['data'] != null) {
            _light = results[3]['data']['value'] ?? 0;
          }
          if (results[4]['success'] && results[4]['data'] != null) {
            _doorStatus = results[4]['data']['status'] ?? 'closed';
          }
          if (results[5]['success'] && results[5]['data'] != null) {
            _lampStatus = results[5]['data']['status'] ?? 'off';
          }
          if (results[6]['success'] && results[6]['data'] != null) {
            _curtainStatus = results[6]['data']['status'] ?? 'closed';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Text(
                    'Sensor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildSensorCard(
                        icon: Icons.thermostat,
                        label: 'Suhu',
                        value: '${_temperature.toStringAsFixed(1)}°C',
                        color: Colors.orange,
                      ),
                      _buildSensorCard(
                        icon: Icons.water_drop,
                        label: 'Kelembaban',
                        value: '${_humidity.toStringAsFixed(1)}%',
                        color: Colors.blue,
                      ),
                      _buildSensorCard(
                        icon: Icons.air,
                        label: 'Gas',
                        value: _gas.toString(),
                        color: Colors.red,
                      ),
                      _buildSensorCard(
                        icon: Icons.wb_sunny,
                        label: 'Cahaya',
                        value: _light.toString(),
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Perangkat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildDeviceCard(
                    icon: Icons.door_front_door,
                    label: 'Pintu',
                    status: _doorStatus == 'closed' ? 'Tertutup' : 'Terbuka',
                    isActive: _doorStatus == 'open',
                  ),
                  SizedBox(height: 12),
                  _buildDeviceCard(
                    icon: Icons.lightbulb,
                    label: 'Lampu',
                    status: _lampStatus == 'on' ? 'Menyala' : 'Mati',
                    isActive: _lampStatus == 'on',
                  ),
                  SizedBox(height: 12),
                  _buildDeviceCard(
                    icon: Icons.curtains,
                    label: 'Gorden',
                    status: _curtainStatus == 'open' ? 'Terbuka' : 'Tertutup',
                    isActive: _curtainStatus == 'open',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard({
    required IconData icon,
    required String label,
    required String status,
    required bool isActive,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 32, color: isActive ? Colors.green : Colors.grey),
        title: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.green[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isActive ? Colors.green[800] : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
