import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/automation_provider.dart';
import '../models/automation_model.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AutomationProvider>(context, listen: false).loadRules();
    });
  }

  void _showAddRuleDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddAutomationRuleDialog(),
    );
  }

  void _showEditRuleDialog(AutomationRule rule) {
    showDialog(
      context: context,
      builder: (context) => AddAutomationRuleDialog(existingRule: rule),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Automation'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRuleDialog,
        child: const Icon(Icons.add),
      ),
      body: Consumer<AutomationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_mode, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No automation rules yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddRuleDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rule'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.rules.length,
            itemBuilder: (context, index) {
              final rule = provider.rules[index];
              return _buildRuleCard(rule, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildRuleCard(AutomationRule rule, AutomationProvider provider) {
    IconData deviceIcon;
    Color deviceColor;
    String deviceName;

    if (rule.deviceType == 'lamp') {
      deviceIcon = Icons.lightbulb;
      deviceColor = Colors.yellow[700]!;
      deviceName = 'Lamp';
    } else {
      deviceIcon = Icons.blinds;
      deviceColor = Colors.blue;
      deviceName = 'Curtain';
    }

    String conditionText;
    if (rule.condition == 'light_threshold') {
      final settings = LightBasedSettings.fromMap(rule.settings);
      conditionText =
          'When light < ${settings.threshold} lux: ${settings.action}';
    } else if (rule.condition == 'time_based') {
      final settings = TimeBasedSettings.fromMap(rule.settings);
      conditionText =
          'Time: ${settings.startTime} - ${settings.endTime}: ${settings.action}';
    } else {
      conditionText = rule.condition;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: deviceColor.withOpacity(0.2),
          child: Icon(deviceIcon, color: deviceColor),
        ),
        title: Text(
          deviceName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(conditionText),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  rule.enabled ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: rule.enabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  rule.enabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 12,
                    color: rule.enabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: rule.enabled,
              onChanged: (value) {
                provider.toggleRule(rule.id!);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditRuleDialog(rule);
                } else if (value == 'delete') {
                  _confirmDelete(rule, provider);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AutomationRule rule, AutomationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content:
            const Text('Are you sure you want to delete this automation rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteRule(rule.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rule deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddAutomationRuleDialog extends StatefulWidget {
  final AutomationRule? existingRule;

  const AddAutomationRuleDialog({super.key, this.existingRule});

  @override
  State<AddAutomationRuleDialog> createState() =>
      _AddAutomationRuleDialogState();
}

class _AddAutomationRuleDialogState extends State<AddAutomationRuleDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _deviceType;
  late String _condition;
  late bool _enabled;

  // Light-based settings
  final _thresholdController = TextEditingController();
  String _lightAction = 'turn_on';

  // Time-based settings
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 0);
  String _timeAction = 'turn_on';

  @override
  void initState() {
    super.initState();

    if (widget.existingRule != null) {
      _deviceType = widget.existingRule!.deviceType;
      _condition = widget.existingRule!.condition;
      _enabled = widget.existingRule!.enabled;

      if (_condition == 'light_threshold') {
        final settings =
            LightBasedSettings.fromMap(widget.existingRule!.settings);
        _thresholdController.text = settings.threshold.toString();
        _lightAction = settings.action;
      } else if (_condition == 'time_based') {
        final settings =
            TimeBasedSettings.fromMap(widget.existingRule!.settings);
        _timeAction = settings.action;
        // Parse time strings
        final startParts = settings.startTime.split(':');
        final endParts = settings.endTime.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );
        _endTime = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );
      }
    } else {
      _deviceType = 'lamp';
      _condition = 'light_threshold';
      _enabled = true;
      _thresholdController.text = '300';
    }
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  void _saveRule() {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic> settings;

    if (_condition == 'light_threshold') {
      settings = LightBasedSettings(
        threshold: double.parse(_thresholdController.text),
        action: _lightAction,
      ).toMap();
    } else {
      settings = TimeBasedSettings(
        startTime:
            '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime:
            '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        action: _timeAction,
      ).toMap();
    }

    final rule = AutomationRule(
      id: widget.existingRule?.id,
      deviceType: _deviceType,
      enabled: _enabled,
      condition: _condition,
      settings: settings,
    );

    final provider = Provider.of<AutomationProvider>(context, listen: false);

    if (widget.existingRule != null) {
      provider.updateRule(widget.existingRule!.id!, rule);
    } else {
      provider.addRule(rule);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(widget.existingRule != null ? 'Rule updated' : 'Rule added'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.existingRule != null ? 'Edit Rule' : 'Add Automation Rule'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Type
              DropdownButtonFormField<String>(
                value: _deviceType,
                decoration: const InputDecoration(
                  labelText: 'Device Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'lamp', child: Text('Lamp')),
                  DropdownMenuItem(value: 'curtain', child: Text('Curtain')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _deviceType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Condition Type
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'light_threshold',
                    child: Text('Light Threshold'),
                  ),
                  DropdownMenuItem(
                    value: 'time_based',
                    child: Text('Time Based'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _condition = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Condition-specific settings
              if (_condition == 'light_threshold') ...[
                TextFormField(
                  controller: _thresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Light Threshold (lux)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter threshold';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _lightAction,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'turn_on', child: Text('Turn On')),
                    DropdownMenuItem(
                        value: 'turn_off', child: Text('Turn Off')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _lightAction = value);
                    }
                  },
                ),
              ] else if (_condition == 'time_based') ...[
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(_startTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _startTime,
                    );
                    if (time != null) {
                      setState(() => _startTime = time);
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(_endTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _endTime,
                    );
                    if (time != null) {
                      setState(() => _endTime = time);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _timeAction,
                  decoration: const InputDecoration(
                    labelText: 'Action',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'turn_on', child: Text('Turn On')),
                    DropdownMenuItem(
                        value: 'turn_off', child: Text('Turn Off')),
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(value: 'close', child: Text('Close')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _timeAction = value);
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),

              // Enabled Switch
              SwitchListTile(
                title: const Text('Enabled'),
                value: _enabled,
                onChanged: (value) {
                  setState(() => _enabled = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveRule,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
