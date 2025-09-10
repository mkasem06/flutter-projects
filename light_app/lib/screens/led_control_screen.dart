import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/led_control_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../models/led_control_models.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LEDControlScreen extends StatefulWidget {
  const LEDControlScreen({super.key});

  @override
  State<LEDControlScreen> createState() => _LEDControlScreenState();
}

class _LEDControlScreenState extends State<LEDControlScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Color _pickerColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LED Controller'),
        centerTitle: true,
        actions: [
          Consumer<LEDControlProvider>(
            builder: (context, ledProvider, child) {
              return IconButton(
                icon: Icon(
                  ledProvider.isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: ledProvider.isOn ? Colors.yellow : Colors.grey,
                ),
                onPressed: () async => await ledProvider.togglePower(),
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetoothProvider, child) {
          if (!bluetoothProvider.isConnected) {
            return _buildNotConnectedView();
          }

          return Consumer<LEDControlProvider>(
            builder: (context, ledProvider, child) {
              return Column(
                children: [
                  // Connection Status & Power Control
                  _buildStatusCard(bluetoothProvider, ledProvider),

                  // Main Controls
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Brightness Control
                          _buildBrightnessControl(ledProvider),
                          const SizedBox(height: 20),

                          // Zone-specific brightness controls (conditionally shown)
                          if (ledProvider.ledState.currentZone !=
                              ColorZone.uniform)
                            ..._buildZoneBrightnessControls(ledProvider),

                          // Lighting Mode Selection
                          _buildModeControl(ledProvider),
                          const SizedBox(height: 20),

                          // Zone Selection Tabs
                          _buildZoneTabs(ledProvider),
                          const SizedBox(height: 20),

                          // Color Picker
                          _buildColorPicker(ledProvider),
                          const SizedBox(height: 20),

                          // Color Palettes
                          _buildColorPalettes(ledProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotConnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Device Connected',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect to a Bluetooth device to control LEDs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to bluetooth screen
              Navigator.pushNamed(context, '/bluetooth');
            },
            icon: const Icon(Icons.bluetooth),
            label: const Text('Connect Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      BluetoothProvider bluetoothProvider, LEDControlProvider ledProvider) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_connected,
                      color: bluetoothProvider.isConnected
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bluetoothProvider.isConnected
                          ? 'Connected'
                          : 'Disconnected',
                      style: TextStyle(
                        color: bluetoothProvider.isConnected
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (bluetoothProvider.connectedDevice != null)
                  Text(
                    bluetoothProvider.connectedDevice!.platformName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Row(
                  children: [
                    Icon(
                      ledProvider.isOn
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                      color: ledProvider.isOn ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ledProvider.isOn ? 'LEDs ON' : 'LEDs OFF',
                      style: TextStyle(
                        color: ledProvider.isOn ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Switch(
              value: ledProvider.isOn,
              onChanged: (value) async => await ledProvider.togglePower(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessControl(LEDControlProvider ledProvider) {
    final currentZone = ledProvider.ledState.currentZone;
    final brightness = ledProvider.ledState.zoneBrightnesses[currentZone] ??
        ledProvider.ledState.brightness;
    final title = currentZone == ColorZone.uniform
        ? 'Brightness'
        : '${currentZone.displayName} Brightness';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_6, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${brightness}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: brightness.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) async {
                if (currentZone == ColorZone.uniform) {
                  await ledProvider.setBrightness(value.toInt());
                } else {
                  await ledProvider.setZoneBrightness(
                      currentZone, value.toInt());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildZoneBrightnessControls(LEDControlProvider ledProvider) {
    return [
      _buildSingleZoneBrightnessControl(ledProvider, ColorZone.partition1),
      const SizedBox(height: 16),
      _buildSingleZoneBrightnessControl(ledProvider, ColorZone.partition2),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildSingleZoneBrightnessControl(
      LEDControlProvider ledProvider, ColorZone zone) {
    final brightness = ledProvider.ledState.zoneBrightnesses[zone] ?? 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.brightness_auto,
                    color: Color(
                        ledProvider.ledState.zoneColors[zone] ?? 0xFFFFFFFF)),
                const SizedBox(width: 8),
                Text(
                  '${zone.displayName} Brightness',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${brightness}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            Slider(
              value: brightness.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (value) async {
                await ledProvider.setZoneBrightness(zone, value.toInt());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeControl(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Lighting Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LightingMode.values.map((mode) {
                final isSelected = ledProvider.mode == mode;
                return ElevatedButton(
                  onPressed: () async => await ledProvider.setMode(mode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  child: Text(mode.displayName),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneTabs(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.layers, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Control Zone',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (index) async {
                  await ledProvider.setColorZone(ColorZone.values[index]);
                },
                tabs: ColorZone.values.map((zone) {
                  return Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(
                                ledProvider.ledState.zoneColors[zone] ??
                                    0xFFFFFFFF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: Text(zone.displayName)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette, color: Colors.pink),
                const SizedBox(width: 8),
                Text(
                  'Color Picker',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(ledProvider.getCurrentZoneColor()),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ColorPicker(
                pickerColor: Color(ledProvider.getCurrentZoneColor()),
                onColorChanged: (Color color) {
                  _pickerColor = color;
                },
                colorPickerWidth: 300,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                displayThumbColor: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ledProvider.setColor(_pickerColor.toARGB32());
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Apply Color'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ledProvider.addCustomColor(_pickerColor.toARGB32());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Color saved to custom colors')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPalettes(LEDControlProvider ledProvider) {
    return Column(
      children: [
        // Default Colors
        _buildColorPalette(
          'Default Colors',
          Icons.color_lens,
          Colors.teal,
          ledProvider.defaultColors,
          ledProvider,
          isCustom: false,
        ),
        const SizedBox(height: 16),
        // Custom Colors
        _buildColorPalette(
          'Custom Colors',
          Icons.star,
          Colors.amber,
          ledProvider.customColors,
          ledProvider,
          isCustom: true,
        ),
      ],
    );
  }

  Widget _buildColorPalette(
    String title,
    IconData icon,
    Color iconColor,
    List<ColorItem> colors,
    LEDControlProvider ledProvider, {
    required bool isCustom,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isCustom) ...[
                  const Spacer(),
                  if (colors.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_all, size: 20),
                      onPressed: () async {
                        // Clear all custom colors by removing them one by one
                        for (int i = colors.length - 1; i >= 0; i--) {
                          await ledProvider.removeCustomColor(i);
                        }
                      },
                      tooltip: 'Clear all',
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (colors.isEmpty && isCustom)
              SizedBox(
                height: 60,
                child: Center(
                  child: Text(
                    'No custom colors yet. Use the color picker to add some!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: colors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final colorItem = entry.value;
                  return GestureDetector(
                    onTap: () async =>
                        await ledProvider.setColor(colorItem.color),
                    onLongPress: isCustom
                        ? () => _showDeleteColorDialog(
                            index, colorItem, ledProvider)
                        : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorItem.flutterColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
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

  void _showDeleteColorDialog(
      int index, ColorItem colorItem, LEDControlProvider ledProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Color'),
        content: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colorItem.flutterColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Remove this custom color?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ledProvider.removeCustomColor(index);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
