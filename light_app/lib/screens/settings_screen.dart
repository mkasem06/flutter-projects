import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/led_control_provider.dart';
import '../providers/bluetooth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _selectedProtocol = '0x2E Packet'; // '0x2E Packet' or 'Classic 0x7E'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoConnect = prefs.getBool('auto_connect') ?? false;
      _savePreferences = prefs.getBool('save_preferences') ?? true;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedTheme = prefs.getString('selected_theme') ?? 'System';
      final proto = prefs.getString('ble_protocol') ?? '2E';
      _selectedProtocol = proto == '7E' ? 'Classic 0x7E' : '0x2E Packet';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_connect', _autoConnect);
    await prefs.setBool('save_preferences', _savePreferences);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('selected_theme', _selectedTheme);
    await prefs.setString(
        'ble_protocol', _selectedProtocol == 'Classic 0x7E' ? '7E' : '2E');
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
                _buildAboutSection(),
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
              },
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

  Widget _buildAboutSection() {
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
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    final ledProvider = context.read<LEDControlProvider>();
                    await ledProvider.factoryReset();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Factory reset completed')),
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
