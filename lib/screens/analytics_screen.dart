import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/analytics_models.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _apiService = ApiService();

  String _selectedRange = '24h';
  SensorStats? _stats;
  List<HourlyData> _hourlyData = [];
  bool _isLoading = false;
  String _selectedChart = 'temperature';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _apiService.getSensorStats(range: _selectedRange);
    final hourly = await _apiService.getHourlyData(range: _selectedRange);

    setState(() {
      _stats = stats;
      _hourlyData = hourly;
      _isLoading = false;
    });
  }

  Future<void> _exportData() async {
    try {
      final csvData =
          await _apiService.exportSensorDataToCSV(range: _selectedRange);

      if (csvData == null) {
        _showMessage('No data to export', isError: true);
        return;
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sensor_data_$_selectedRange.csv');
      await file.writeAsString(csvData);

      // Share the file
      _showMessage('Data exported successfully');

      // Optional: Share file
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Successful'),
          content:
              Text('File saved to:\n${file.path}\n\nDo you want to share it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Share'),
            ),
          ],
        ),
      );

      // Note: share_plus doesn't work on desktop, you might need platform-specific code
      // For now, just show the path
      if (result == true) {
        _showMessage('File location: ${file.path}');
      }
    } catch (e) {
      _showMessage('Failed to export: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
            tooltip: 'Export to CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time Range Selector
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 24),

                  // Statistics Cards
                  const Text(
                    'Statistics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsCards(),
                  const SizedBox(height: 24),

                  // Chart Type Selector
                  const Text(
                    'Charts',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildChartTypeSelector(),
                  const SizedBox(height: 16),

                  // Chart
                  _buildChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text('Time Range: '),
            const SizedBox(width: 12),
            Expanded(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '24h', label: Text('24h')),
                  ButtonSegment(value: '7d', label: Text('7d')),
                  ButtonSegment(value: '30d', label: Text('30d')),
                ],
                selected: {_selectedRange},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedRange = newSelection.first;
                  });
                  _loadData();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) {
      return const Center(child: Text('No statistics available'));
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Temperature',
                _stats!.temperature,
                Icons.thermostat,
                Colors.orange,
                '°C',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Humidity',
                _stats!.humidity != null ? _stats!.humidity : null,
                Icons.water_drop,
                Colors.blue,
                '%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Light',
                _stats!.light,
                Icons.light_mode,
                Colors.yellow,
                'lux',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Gas',
                _stats!.gas,
                Icons.air,
                Colors.red,
                'ppm',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    dynamic stats,
    IconData icon,
    Color color,
    String unit,
  ) {
    final hasData = stats != null;
    final avg = hasData ? (stats.avg ?? 0.0) : 0.0;
    final min = hasData ? (stats.min ?? 0.0) : 0.0;
    final max = hasData ? (stats.max ?? 0.0) : 0.0;
    final count = hasData ? (stats.count ?? 0) : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${avg.toStringAsFixed(1)} $unit',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              'Min: ${min.toStringAsFixed(1)} | Max: ${max.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              'Count: $count',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChartTypeChip('temperature', 'Temperature', Colors.orange),
          _buildChartTypeChip('humidity', 'Humidity', Colors.blue),
          _buildChartTypeChip('light', 'Light', Colors.yellow),
          _buildChartTypeChip('gas', 'Gas', Colors.red),
        ],
      ),
    );
  }

  Widget _buildChartTypeChip(String value, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedChart == value,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedChart = value);
          }
        },
        selectedColor: color.withOpacity(0.3),
        checkmarkColor: color,
      ),
    );
  }

  Widget _buildChart() {
    if (_hourlyData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No chart data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < _hourlyData.length) {
                        final hour = _hourlyData[value.toInt()].hour;
                        // Show only every 4th hour to avoid clutter
                        if (value.toInt() % 4 == 0) {
                          return Text(
                            hour.split(' ').last,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(),
                  isCurved: true,
                  color: _getChartColor(),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _getChartColor().withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _hourlyData.length; i++) {
      final data = _hourlyData[i];
      double? value;

      switch (_selectedChart) {
        case 'temperature':
          value = data.temperature;
          break;
        case 'humidity':
          value = data.humidity;
          break;
        case 'light':
          value = data.light;
          break;
        case 'gas':
          value = data.gas;
          break;
      }

      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    return spots;
  }

  Color _getChartColor() {
    switch (_selectedChart) {
      case 'temperature':
        return Colors.orange;
      case 'humidity':
        return Colors.blue;
      case 'light':
        return Colors.yellow[700]!;
      case 'gas':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
