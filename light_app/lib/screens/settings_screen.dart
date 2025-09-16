import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/led_control_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoConnect = false;
  bool _savePreferences = true;
  bool _notificationsEnabled = true;
  String _selectedTheme = 'System';
  String _selectedProtocol = '0x2E Packet';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _autoConnect = SettingsService.getAutoConnect();
      _savePreferences = SettingsService.getSavePreferences();
      _notificationsEnabled = SettingsService.getNotificationsEnabled();
      _selectedTheme = SettingsService.getSelectedTheme();
      final proto = SettingsService.getBleProtocol();
      _selectedProtocol = proto == '7E' ? 'Classic 0x7E' : '0x2E Packet';
    });
  }

  Future<void> _saveSettings() async {
    await Future.wait([
      SettingsService.setAutoConnect(_autoConnect),
      SettingsService.setSavePreferences(_savePreferences),
      SettingsService.setNotificationsEnabled(_notificationsEnabled),
      SettingsService.setSelectedTheme(_selectedTheme),
      SettingsService.setBleProtocol(
          _selectedProtocol == 'Classic 0x7E' ? '7E' : '2E'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Consumer2<LEDControlProvider, BluetoothProvider>(
        builder: (context, ledProvider, bluetoothProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Settings
                _buildConnectionSettings(bluetoothProvider),
                const SizedBox(height: 24),

                // App Settings
                _buildAppSettings(),
                const SizedBox(height: 24),

                // About Section
                _buildAboutSection(ledProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionSettings(BluetoothProvider bluetoothProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bluetooth,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Connection Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto Connect'),
              subtitle: const Text('Automatically connect to last device'),
              value: _autoConnect,
              onChanged: (value) {
                setState(() {
                  _autoConnect = value;
                });
                _saveSettings();

                // Enable/disable auto-connect in the Bluetooth provider
                bluetoothProvider.setAutoConnectEnabled(value);

                // If auto-connect is enabled and we have a last device, try to connect
                if (value) {
                  final lastDeviceId =
                      SettingsService.getLastConnectedDeviceId();
                  if (lastDeviceId != null) {
                    bluetoothProvider.setLastDeviceForAutoConnect(lastDeviceId);
                    bluetoothProvider.attemptAutoConnect();
                  }
                }
              },
            ),
            ListTile(
              title: const Text('BLE Protocol'),
              subtitle: Text(_selectedProtocol),
              trailing: DropdownButton<String>(
                value: _selectedProtocol,
                items: ['0x2E Packet', 'Classic 0x7E']
                    .map((protocol) => DropdownMenuItem(
                          value: protocol,
                          child: Text(protocol),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedProtocol = value;
                    });
                    _saveSettings();
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Connected Device'),
              subtitle: Text(
                bluetoothProvider.isConnected
                    ? bluetoothProvider.connectedDevice?.platformName ??
                        'Unknown'
                    : 'No device connected',
              ),
              trailing: bluetoothProvider.isConnected
                  ? ElevatedButton(
                      onPressed: () => bluetoothProvider.disconnect(),
                      child: const Text('Disconnect'),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'App Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Save Preferences'),
              subtitle: const Text('Remember settings between app launches'),
              value: _savePreferences,
              onChanged: (value) {
                setState(() {
                  _savePreferences = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Notifications'),
              subtitle: const Text('Show connection status notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSettings();
              },
            ),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_selectedTheme),
              trailing: DropdownButton<String>(
                value: _selectedTheme,
                items: ['System', 'Light', 'Dark']
                    .map((theme) => DropdownMenuItem(
                          value: theme,
                          child: Text(theme),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTheme = value;
                    });
                    _saveSettings();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(LEDControlProvider ledProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              title: Text('App Version'),
              subtitle: Text('1.0.0'),
            ),
            const ListTile(
              title: Text('Compatible Devices'),
              subtitle: Text('Pocket Link CTQ1-13, LAMP, LED, CarLED devices'),
            ),
            ListTile(
              title: const Text('Reset to Factory'),
              subtitle: const Text('Reset all LED settings to default'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Factory Reset'),
                      content: const Text(
                          'This will reset all LED settings. Continue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    // Clear LED settings from storage
                    await SettingsService.clearLedSettings();

                    // Reset the LED provider to factory defaults
                    await ledProvider.factoryReset();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('LED settings reset to factory defaults'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
