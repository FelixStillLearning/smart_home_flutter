import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_home_provider.dart';
import '../widgets/common_app_bar.dart';

class ControllingScreen extends StatelessWidget {
  const ControllingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SmartHomeProvider>(context);

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Smart Home',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Door Control
            _buildDoorControlCard(provider),
            const SizedBox(height: 16),

            // Light Control
            _buildLightControlCard(provider),
            const SizedBox(height: 16),

            // Curtain Control
            _buildCurtainControlCard(provider, context),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorControlCard(SmartHomeProvider provider) {
    final isLocked = provider.doorStatus?.isLocked ?? true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  size: 40,
                  color: isLocked ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Door Lock',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLocked ? 'Locked' : 'Unlocked',
                        style: TextStyle(
                          fontSize: 14,
                          color: isLocked ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected ? provider.lockDoor : null,
                    icon: const Icon(Icons.lock_rounded),
                    label: const Text('Lock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        provider.isConnected ? provider.unlockDoor : null,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Unlock'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightControlCard(SmartHomeProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  provider.isLightOn
                      ? Icons.lightbulb
                      : Icons.lightbulb_outline,
                  size: 40,
                  color: provider.isLightOn ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.isLightOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              provider.isLightOn ? Colors.amber : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: provider.isLightOn,
                  onChanged: provider.isConnected
                      ? (value) => provider.setLightState(value)
                      : null,
                  activeColor: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected
                        ? () => provider.setLightState(true)
                        : null,
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('Turn ON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected
                        ? () => provider.setLightState(false)
                        : null,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text('Turn OFF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurtainControlCard(
      SmartHomeProvider provider, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.blinds,
                  size: 40,
                  color: Colors.indigo,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Curtain',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.curtainPosition}% Open',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.indigo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: provider.curtainPosition.toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              label: '${provider.curtainPosition}%',
              onChanged: provider.isConnected
                  ? (value) => provider.setCurtainPosition(value.toInt())
                  : null,
              activeColor: Colors.indigo,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected
                        ? () => provider.setCurtainPosition(0)
                        : null,
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected
                        ? () => provider.setCurtainPosition(100)
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Open'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
