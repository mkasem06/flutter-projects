import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../providers/led_control_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../models/led_control_models.dart';

class ColorControlScreen extends StatefulWidget {
  const ColorControlScreen({super.key});

  @override
  State<ColorControlScreen> createState() => _ColorControlScreenState();
}

class _ColorControlScreenState extends State<ColorControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Control'),
        centerTitle: true,
        actions: [
          // Power toggle button from original APK
          Consumer<LEDControlProvider>(
            builder: (context, ledProvider, child) {
              return IconButton(
                icon: Icon(
                  ledProvider.isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: ledProvider.isOn ? Colors.amber : null,
                ),
                onPressed: () async {
                  await ledProvider.togglePower();
                },
                tooltip: ledProvider.isOn ? 'Turn Off' : 'Turn On',
              );
            },
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

                // Power Control (from original APK)
                _buildPowerControlCard(ledProvider),
                const SizedBox(height: 24),

                // Color Zone Selection (from original APK)
                _buildColorZoneCard(ledProvider),
                const SizedBox(height: 24),

                // Color Picker Card
                _buildColorPickerCard(ledProvider),
                const SizedBox(height: 24),

                // Brightness Control
                _buildBrightnessCard(ledProvider),
                const SizedBox(height: 24),

                // Default Colors (from original APK)
                _buildDefaultColorsCard(ledProvider),
                const SizedBox(height: 24),

                // Custom Colors
                _buildCustomColorsCard(ledProvider),
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

  Widget _buildPowerControlCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.power_settings_new,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Power Control',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Switch(
                  value: ledProvider.isOn,
                  onChanged: (value) async {
                    await ledProvider.togglePower();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ledProvider.isOn ? 'LEDs are ON' : 'LEDs are OFF',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ledProvider.isOn ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorZoneCard(LEDControlProvider ledProvider) {
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
                  'Color Zones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<ColorZone>(
              segments: ColorZone.values.map((zone) {
                return ButtonSegment<ColorZone>(
                  value: zone,
                  label: Text(zone.displayName),
                  icon: Icon(_getZoneIcon(zone)),
                );
              }).toList(),
              selected: {ledProvider.currentZone},
              onSelectionChanged: (Set<ColorZone> selection) {
                if (selection.isNotEmpty) {
                  ledProvider.setColorZone(selection.first);
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Current zone: ${ledProvider.currentZone.displayName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getZoneIcon(ColorZone zone) {
    switch (zone) {
      case ColorZone.uniform:
        return Icons.lightbulb;
      case ColorZone.partition1:
        return Icons.looks_one;
      case ColorZone.partition2:
        return Icons.looks_two;
    }
  }

  Widget _buildColorPickerCard(LEDControlProvider ledProvider) {
    final currentColor = Color(ledProvider.getCurrentZoneColor());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Selection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () => _showColorPicker(context, ledProvider),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.palette,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Tap to change color',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.brightness_6,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Brightness',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${ledProvider.brightness}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8.0,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 20.0),
              ),
              child: Slider(
                value: ledProvider.brightness.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (value) async {
                  await ledProvider.setBrightness(value.round());
                },
                activeColor: Theme.of(context).colorScheme.primary,
                inactiveColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultColorsCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.color_lens,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Default Colors',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ledProvider.defaultColors.map((colorItem) {
                final color = Color(colorItem.color);
                final isSelected =
                    ledProvider.getCurrentZoneColor() == colorItem.color;

                return GestureDetector(
                  onTap: () async {
                    await ledProvider.setColor(colorItem.color);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                          : Border.all(
                              color: Theme.of(context).colorScheme.outline,
                              width: 1,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
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

  Widget _buildCustomColorsCard(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Custom Colors',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    final currentColor = ledProvider.getCurrentZoneColor();
                    await ledProvider.addCustomColor(currentColor);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Color added to custom colors')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  tooltip: 'Add current color',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ledProvider.customColors.isEmpty
                ? Center(
                    child: Text(
                      'No custom colors yet.\nTap + to add current color.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        ledProvider.customColors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final colorItem = entry.value;
                      final color = Color(colorItem.color);
                      final isSelected =
                          ledProvider.getCurrentZoneColor() == colorItem.color;

                      return GestureDetector(
                        onTap: () async {
                          await ledProvider.setColor(colorItem.color);
                        },
                        onLongPress: () {
                          _showRemoveColorDialog(context, ledProvider, index);
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 3,
                                  )
                                : Border.all(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    width: 1,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
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

  void _showColorPicker(BuildContext context, LEDControlProvider ledProvider) {
    Color pickerColor = Color(ledProvider.getCurrentZoneColor());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ledProvider.setColor(pickerColor.toARGB32());
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveColorDialog(
      BuildContext context, LEDControlProvider ledProvider, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Color'),
          content: const Text('Remove this color from custom colors?'),
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
