import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  State<BluetoothScreen> createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        centerTitle: true,
        actions: [
          Consumer<BluetoothProvider>(
            builder: (context, bluetoothProvider, child) {
              return IconButton(
                onPressed: bluetoothProvider.isDiscovering
                    ? null
                    : () => _startDiscovery(bluetoothProvider),
                icon: bluetoothProvider.isDiscovering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: Consumer<BluetoothProvider>(
        builder: (context, bluetoothProvider, child) {
          return Column(
            children: [
              // Bluetooth Status Card
              _buildBluetoothStatusCard(bluetoothProvider),

              // Connected Device (if any)
              if (bluetoothProvider.isConnected)
                _buildConnectedDeviceCard(bluetoothProvider),

              // Device List
              Expanded(
                child: _buildDeviceList(bluetoothProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<BluetoothProvider>(
        builder: (context, bluetoothProvider, child) {
          return FloatingActionButton.extended(
            onPressed: bluetoothProvider.isDiscovering
                ? () => bluetoothProvider.stopDiscovery()
                : () => _startDiscovery(bluetoothProvider),
            icon: Icon(
              bluetoothProvider.isDiscovering ? Icons.stop : Icons.search,
            ),
            label: Text(
              bluetoothProvider.isDiscovering ? 'Stop Scan' : 'Scan Devices',
            ),
          );
        },
      ),
    );
  }

  Widget _buildBluetoothStatusCard(BluetoothProvider bluetoothProvider) {
    final isOn = bluetoothProvider.bluetoothState == BluetoothAdapterState.on;

    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                isOn ? Icons.bluetooth : Icons.bluetooth_disabled,
                size: 32,
                color: isOn ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bluetooth Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _getBluetoothStatusText(bluetoothProvider.bluetoothState),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isOn ? Colors.green : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
              if (!isOn)
                ElevatedButton(
                  onPressed: () => _enableBluetooth(bluetoothProvider),
                  child: const Text('Enable'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceCard(BluetoothProvider bluetoothProvider) {
    final device = bluetoothProvider.connectedDevice;
    if (device == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bluetooth_connected,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Device',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      device.platformName.isNotEmpty
                          ? device.platformName
                          : 'Unknown Device',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      device.remoteId.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _showDisconnectDialog(bluetoothProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(BluetoothProvider bluetoothProvider) {
    if (bluetoothProvider.bluetoothState != BluetoothAdapterState.on) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Bluetooth is disabled',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enable Bluetooth to discover LED controllers',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    if (bluetoothProvider.devices.isEmpty && !bluetoothProvider.isDiscovering) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No LED controllers found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Only compatible LED lighting devices are shown',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Make sure your LED controller is in pairing mode',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[400],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter info banner
        if (bluetoothProvider.devices.isNotEmpty ||
            bluetoothProvider.isDiscovering)
          Container(
            margin: const EdgeInsets.all(16.0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Showing only compatible LED lighting devices',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                if (bluetoothProvider.devices.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${bluetoothProvider.devices.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Device list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: bluetoothProvider.devices.length +
                (bluetoothProvider.isDiscovering ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (bluetoothProvider.isDiscovering &&
                  index == bluetoothProvider.devices.length) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Scanning for LED controllers...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final device = bluetoothProvider.devices[index];
              final isConnected = bluetoothProvider.connectedDevice?.remoteId ==
                  device.remoteId;

              return Card(
                elevation: isConnected ? 4 : 1,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDeviceIcon(device),
                      color: isConnected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    device.platformName.isNotEmpty
                        ? device.platformName
                        : 'LED Controller',
                    style: TextStyle(
                      fontWeight:
                          isConnected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.remoteId.toString()),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'LED Compatible',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: isConnected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : ElevatedButton(
                          onPressed: () =>
                              _connectToDevice(bluetoothProvider, device),
                          child: const Text('Connect'),
                        ),
                  onTap: isConnected
                      ? null
                      : () => _connectToDevice(bluetoothProvider, device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getDeviceIcon(BluetoothDevice device) {
    final deviceName = device.platformName.toLowerCase();

    // More specific LED device icons
    if (deviceName.contains('car') ||
        deviceName.contains('auto') ||
        deviceName.contains('vehicle')) {
      return Icons.car_crash;
    } else if (deviceName.contains('strip') || deviceName.contains('ribbon')) {
      return Icons.highlight;
    } else if (deviceName.contains('bulb') || deviceName.contains('lamp')) {
      return Icons.lightbulb;
    } else if (deviceName.contains('rgb') || deviceName.contains('color')) {
      return Icons.palette;
    } else if (deviceName.contains('smart') || deviceName.contains('wifi')) {
      return Icons.wifi;
    } else if (deviceName.contains('controller') ||
        deviceName.contains('control')) {
      return Icons.settings_remote;
    }

    // Default LED icon for any LED device
    return Icons.light;
  }

  String _getBluetoothStatusText(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.on:
        return 'Enabled and ready';
      case BluetoothAdapterState.off:
        return 'Disabled';
      case BluetoothAdapterState.turningOn:
        return 'Turning on...';
      case BluetoothAdapterState.turningOff:
        return 'Turning off...';
      default:
        return 'Unknown status';
    }
  }

  Future<void> _startDiscovery(BluetoothProvider bluetoothProvider) async {
    try {
      await bluetoothProvider.startDiscovery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting discovery: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _connectToDevice(
      BluetoothProvider bluetoothProvider, BluetoothDevice device) async {
    try {
      await bluetoothProvider.connectToDevice(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Connected to ${device.platformName.isNotEmpty ? device.platformName : 'Device'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDisconnectDialog(BluetoothProvider bluetoothProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Disconnect Device'),
          content: Text(
            'Disconnect from ${bluetoothProvider.connectedDevice?.platformName ?? 'this device'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                bluetoothProvider.disconnect();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _enableBluetooth(BluetoothProvider bluetoothProvider) async {
    try {
      await bluetoothProvider.enableBluetooth();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth enabled'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enabling Bluetooth: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
