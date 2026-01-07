import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/access_log_model.dart';
import 'package:intl/intl.dart';

class AccessLogsScreen extends StatefulWidget {
  const AccessLogsScreen({super.key});

  @override
  State<AccessLogsScreen> createState() => _AccessLogsScreenState();
}

class _AccessLogsScreenState extends State<AccessLogsScreen> {
  final _apiService = ApiService();
  List<AccessLog> _filteredLogs = [];
  bool _isLoading = false;

  String? _filterStatus;
  int? _filterUserId;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    List<AccessLog> logs;

    if (_filterStatus != null) {
      logs = await _apiService.getAccessLogsByStatus(_filterStatus!);
    } else if (_filterUserId != null) {
      logs = await _apiService.getAccessLogsByUser(_filterUserId!);
    } else {
      logs = await _apiService.getAccessLogs(limit: 200);
    }

    setState(() {
      _filteredLogs = logs;
      _isLoading = false;
    });
  }

  void _applyFilter(String? status, int? userId) {
    setState(() {
      _filterStatus = status;
      _filterUserId = userId;
    });
    _loadLogs();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        currentStatus: _filterStatus,
        currentUserId: _filterUserId,
        onApply: _applyFilter,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _filterUserId = null;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _filterStatus != null || _filterUserId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Logs'),
        actions: [
          if (hasFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter info
          if (hasFilters)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters: ${_filterStatus ?? ''} ${_filterUserId != null ? 'User ID: $_filterUserId' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? const Center(child: Text('No access logs found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = _filteredLogs[index];
                          return _buildLogCard(log);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AccessLog log) {
    final isSuccess = log.status.toLowerCase() == 'success';
    final timestamp = DateTime.tryParse(log.timestamp);
    final formattedTime = timestamp != null
        ? DateFormat('dd MMM yyyy, HH:mm:ss').format(timestamp)
        : log.timestamp;

    IconData methodIcon;
    Color methodColor;

    switch (log.method.toLowerCase()) {
      case 'face':
        methodIcon = Icons.face;
        methodColor = Colors.blue;
        break;
      case 'fingerprint':
        methodIcon = Icons.fingerprint;
        methodColor = Colors.purple;
        break;
      case 'pin':
        methodIcon = Icons.pin;
        methodColor = Colors.orange;
        break;
      case 'remote':
        methodIcon = Icons.phone_android;
        methodColor = Colors.green;
        break;
      default:
        methodIcon = Icons.lock;
        methodColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          child: Icon(
            isSuccess ? Icons.check : Icons.close,
            color: isSuccess ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          log.userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(methodIcon, size: 14, color: methodColor),
                const SizedBox(width: 4),
                Text(
                  log.method.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: methodColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formattedTime,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: Text(
          'ID: ${log.userId}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final String? currentStatus;
  final int? currentUserId;
  final Function(String?, int?) onApply;

  const FilterDialog({
    super.key,
    this.currentStatus,
    this.currentUserId,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  String? _selectedStatus;
  final _userIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    if (widget.currentUserId != null) {
      _userIdController.text = widget.currentUserId.toString();
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Logs'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 'success', child: Text('Success')),
              DropdownMenuItem(value: 'failed', child: Text('Failed')),
            ],
            onChanged: (value) {
              setState(() => _selectedStatus = value);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _userIdController,
            decoration: const InputDecoration(
              labelText: 'User ID (optional)',
              border: OutlineInputBorder(),
              hintText: 'Leave empty for all users',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final userId = _userIdController.text.isEmpty
                ? null
                : int.tryParse(_userIdController.text);
            widget.onApply(_selectedStatus, userId);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
