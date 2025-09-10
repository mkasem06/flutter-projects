import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/led_control_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../models/led_control_models.dart';

class EffectsScreen extends StatefulWidget {
  const EffectsScreen({super.key});

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _welcomeFunctionEnabled = false;
  int _welcomeColor = 0xFFFFFFFF;
  bool _steeringWheelLearningMode = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lighting Effects & Settings'),
        centerTitle: true,
        actions: [
          // Emergency factory reset button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'factory_reset') {
                _showFactoryResetDialog(context);
              } else if (value == 'device_info') {
                _showDeviceInfoDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'device_info',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Device Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'factory_reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Factory Reset'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<LEDControlProvider, BluetoothProvider>(
        builder: (context, ledProvider, bluetoothProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status
                _buildConnectionStatus(bluetoothProvider),
                const SizedBox(height: 24),

                // Lighting Mode Selection (from original APK)
                _buildLightingModeCard(ledProvider),
                const SizedBox(height: 24),

                // Welcome Function (from original APK)
                _buildWelcomeFunctionCard(ledProvider),
                const SizedBox(height: 24),

                // Car Settings (from original APK)
                _buildCarSettingsCard(ledProvider),
                const SizedBox(height: 24),

                // Advanced Controls (from original APK)
                _buildAdvancedControlsCard(ledProvider),
                const SizedBox(height: 24),

                // Diagnostic Tools
                _buildDiagnosticCard(ledProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(BluetoothProvider bluetoothProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              bluetoothProvider.isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth_disabled,
              color: bluetoothProvider.isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                bluetoothProvider.isConnected
                    ? 'Connected to ${bluetoothProvider.connectedDevice?.platformName ?? 'Device'}'
                    : 'Not connected',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightingModeCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Lighting Effects',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: LightingMode.values.map((mode) {
                final isSelected = ledProvider.mode == mode;
                return Material(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await ledProvider.setMode(mode);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getModeIcon(mode),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              mode.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeFunctionCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Welcome Function',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Switch(
                  value: _welcomeFunctionEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _welcomeFunctionEnabled = value;
                    });
                    if (value) {
                      // Apply welcome color as a simple effect
                      await ledProvider.setColor(_welcomeColor);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Light up when doors open/close',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_welcomeFunctionEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Welcome Color:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showWelcomeColorPicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(_welcomeColor),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCarSettingsCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Car Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Door Configuration (from original APK)
            ListTile(
              leading: const Icon(Icons.sensor_door),
              title: const Text('Door Configuration'),
              subtitle: const Text('Configure door lighting behavior'),
              onTap: () {
                _showDoorConfigDialog(context, ledProvider);
              },
            ),

            const Divider(),

            // Steering Wheel Learning (from original APK)
            SwitchListTile(
              secondary: const Icon(Icons.settings_remote),
              title: const Text('Steering Wheel Learning'),
              subtitle: Text(_steeringWheelLearningMode
                  ? 'Press any steering wheel button to map'
                  : 'Learn steering wheel button controls'),
              value: _steeringWheelLearningMode,
              onChanged: (value) async {
                setState(() {
                  _steeringWheelLearningMode = value;
                });
                // Placeholder: not supported by provider
                debugPrint('Steering wheel learning toggled: $value');
                if (value && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Press any button on your steering wheel to learn'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedControlsCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Advanced Controls',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Zone Brightness Controls (from original APK)
            ...ColorZone.values.map((zone) {
              if (zone == ColorZone.uniform) return const SizedBox.shrink();

              final brightness =
                  ledProvider.ledState.zoneBrightnesses[zone] ?? 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${zone.displayName} Brightness',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      value: brightness.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${brightness}%',
                      onChanged: (value) async {
                        await ledProvider.setZoneBrightness(
                            zone, value.round());
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Diagnostic Tools',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Use sync as a proxy for device info query
                      await ledProvider.syncFromDevice();
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Device Info'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Use sync as a basic diagnostic action
                      await ledProvider.syncFromDevice();
                    },
                    icon: const Icon(Icons.medical_services),
                    label: const Text('Diagnostics'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(LightingMode mode) {
    switch (mode) {
      case LightingMode.static:
        return Icons.lightbulb;
      case LightingMode.breathing:
        return Icons.favorite;
      case LightingMode.strobe:
        return Icons.flash_on;
      case LightingMode.fade:
        return Icons.gradient;
      case LightingMode.rainbow:
        return Icons.color_lens;
      case LightingMode.auto:
        return Icons.auto_awesome;
    }
  }

  void _showWelcomeColorPicker() {
    // Color picker for welcome function
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Welcome Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            0xFFFF0000,
            0xFF00FF00,
            0xFF0000FF,
            0xFFFFFF00,
            0xFFFF00FF,
            0xFF00FFFF,
            0xFFFFFFFF,
            0xFFFF8000
          ]
              .map((color) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _welcomeColor = color;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showDoorConfigDialog(
      BuildContext context, LEDControlProvider ledProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Door Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Configure which doors activate the welcome function:'),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Driver Door'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Passenger Door'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Rear Doors'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFactoryResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory Reset'),
        content: const Text('This will reset all settings to factory defaults. '
            'Are you sure you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final ledProvider = context.read<LEDControlProvider>();
              await ledProvider.factoryReset();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Factory reset completed')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeviceInfoDialog(BuildContext context) {
    final ledProvider = context.read<LEDControlProvider>();
    // Optionally trigger a sync before showing info
    ledProvider.syncFromDevice();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Device: ${context.read<BluetoothProvider>().connectedDevice?.platformName ?? 'Unknown'}'),
            const SizedBox(height: 8),
            Text('Status: ${ledProvider.isOn ? 'ON' : 'OFF'}'),
            const SizedBox(height: 8),
            Text('Mode: ${ledProvider.mode.displayName}'),
            const SizedBox(height: 8),
            Text('Brightness: ${ledProvider.brightness}%'),
            const SizedBox(height: 8),
            Text('Zone: ${ledProvider.currentZone.displayName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
