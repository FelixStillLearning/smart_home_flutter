import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/smart_home_provider.dart';

class ControllingScreen extends StatelessWidget {
  const ControllingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SmartHomeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Control Panel'),
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
            _buildCurtainControlCard(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDoorControlCard(SmartHomeProvider provider) {
    final isLocked = provider.doorStatus?.isLocked ?? true;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isLocked ? Icons.lock : Icons.lock_open,
                  size: 48,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isLocked ? 'Locked' : 'Unlocked',
                        style: TextStyle(
                          fontSize: 16,
                          color: isLocked ? Colors.green : Colors.orange,
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
                    icon: const Icon(Icons.lock),
                    label: const Text('Lock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.isConnected ? provider.unlockDoor : null,
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Unlock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  provider.isLightOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 48,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        provider.isLightOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 16,
                          color: provider.isLightOn ? Colors.amber : Colors.grey,
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
                  activeThumbColor: Colors.amber,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildCurtainControlCard(SmartHomeProvider provider) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.blinds,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Curtain',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${provider.curtainPosition}% Open',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blue,
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
              activeColor: Colors.blue,
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
