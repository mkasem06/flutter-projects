import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothProvider extends ChangeNotifier {
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothAdapterState _bluetoothState = BluetoothAdapterState.unknown;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  // Original APK BLE Protocol Constants (reverse engineered)
  static const String SERVICE_UUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
  static const String WRITE_CHARACTERISTIC_UUID =
      "0000ffe1-0000-1000-8000-00805f9b34fb";
  static const String NOTIFY_CHARACTERISTIC_UUID =
      "0000ffe1-0000-1000-8000-00805f9b34fb";

  // Device name patterns from original APK + your specific device
  static const List<String> DEVICE_NAME_PATTERNS = [
    "LAMP",
    "LED",
    "CarLED",
    "BLE-LED",
    "RGB-LED",
    "FRGN",
    "Car Light",
    "Pocket Link", // Your specific device
    "CTQ1", // Your device model
  ];

  // Response handling
  final StreamController<Uint8List> _responseController =
      StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get responseStream => _responseController.stream;

  // Getters
  List<BluetoothDevice> get devices => _devices;
  bool get isDiscovering => _isScanning;
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothAdapterState get bluetoothState => _bluetoothState;

  BluetoothProvider() {
    _initialize();
  }

  // Auto-connect support
  String? _lastDeviceIdForAutoConnect;
  Timer? _autoConnectTimer;
  Timer? _reconnectTimer;
  bool _autoConnectEnabled = false;

  void setLastDeviceForAutoConnect(String deviceId) {
    _lastDeviceIdForAutoConnect = deviceId;
  }

  void setAutoConnectEnabled(bool enabled) {
    _autoConnectEnabled = enabled;
    if (enabled && _lastDeviceIdForAutoConnect != null && !_isConnected) {
      // Start auto-connect with delay to allow initialization
      _scheduleAutoConnect();
    } else if (!enabled) {
      _cancelAutoConnect();
    }
  }

  void _scheduleAutoConnect({Duration delay = const Duration(seconds: 2)}) {
    _autoConnectTimer?.cancel();
    _autoConnectTimer = Timer(delay, () {
      if (_autoConnectEnabled && !_isConnected) {
        attemptAutoConnect();
      }
    });
  }

  void _cancelAutoConnect() {
    _autoConnectTimer?.cancel();
    _reconnectTimer?.cancel();
  }

  void _scheduleReconnect({Duration delay = const Duration(seconds: 5)}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_autoConnectEnabled &&
          !_isConnected &&
          _lastDeviceIdForAutoConnect != null) {
        debugPrint('Attempting reconnection...');
        attemptAutoConnect();
      }
    });
  }

  Future<void> attemptAutoConnect() async {
    if (_lastDeviceIdForAutoConnect == null ||
        _isConnected ||
        !_autoConnectEnabled) {
      return;
    }

    debugPrint(
        'Attempting auto-connect to device: $_lastDeviceIdForAutoConnect');

    try {
      // Ensure Bluetooth is enabled first
      if (!await isBluetoothEnabled()) {
        debugPrint('Bluetooth not enabled, cannot auto-connect');
        return;
      }

      await requestPermissions();

      // Try to find the device in system bonded devices first
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      BluetoothDevice? targetDevice;

      try {
        targetDevice = bondedDevices.firstWhere(
          (device) => device.remoteId.str == _lastDeviceIdForAutoConnect,
        );
        debugPrint('Found bonded device: ${targetDevice.platformName}');
      } catch (e) {
        debugPrint('Device not found in bonded devices, starting scan...');
      }

      if (targetDevice != null) {
        final success = await connectToDevice(targetDevice);
        if (success) {
          debugPrint('Auto-connect successful');
          return;
        }
      }

      // If bonded device connection failed, try scanning
      debugPrint('Scanning for device...');
      await _scanForAutoConnectDevice();
    } catch (e) {
      debugPrint('Auto-connect failed: $e');
      // Retry auto-connect after delay if still enabled
      if (_autoConnectEnabled) {
        _scheduleAutoConnect(delay: const Duration(seconds: 10));
      }
    }
  }

  Future<void> _scanForAutoConnectDevice() async {
    if (_isScanning) return;

    try {
      _devices.clear();
      _isScanning = true;
      notifyListeners();

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen for scan results and try to connect when target device is found
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.remoteId.str == _lastDeviceIdForAutoConnect) {
            debugPrint(
                'Found target device during scan: ${result.device.platformName}');
            // Stop scanning and connect
            FlutterBluePlus.stopScan();
            connectToDevice(result.device);
            return;
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await subscription.cancel();

      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      debugPrint('Scan for auto-connect failed: $e');
    }
  }

  Future<void> _initialize() async {
    // Get initial state
    _bluetoothState = await FlutterBluePlus.adapterState.first;

    // Listen for Bluetooth adapter state changes
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      _bluetoothState = state;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) =>
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited);
  }

  Future<bool> isBluetoothEnabled() async {
    return _bluetoothState == BluetoothAdapterState.on;
  }

  Future<void> enableBluetooth() async {
    if (_bluetoothState != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }
  }

  // Original APK-style device filtering
  bool _isTargetDevice(BluetoothDevice device) {
    final deviceName = device.platformName.toLowerCase();

    // Check if device name matches any of the patterns from original APK
    return DEVICE_NAME_PATTERNS
        .any((pattern) => deviceName.contains(pattern.toLowerCase()));
  }

  Future<void> startDiscovery() async {
    if (_isScanning) return;

    try {
      await requestPermissions();

      if (!await isBluetoothEnabled()) {
        await enableBluetooth();
      }

      _devices.clear();
      _isScanning = true;
      notifyListeners();

      // Start scanning without strict service filter to find all devices
      // The original APK might scan all devices and filter by name
      await FlutterBluePlus.startScan(
        timeout:
            const Duration(seconds: 15), // Longer timeout for better detection
        // Remove strict service filter to find your Pocket Link device
        // withServices: [Guid(SERVICE_UUID)],
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // More flexible filtering - check both name patterns and service UUIDs
          final hasMatchingName = _isTargetDevice(result.device);
          final hasTargetService = result.advertisementData.serviceUuids.any(
              (uuid) => uuid
                  .toString()
                  .toLowerCase()
                  .contains(SERVICE_UUID.toLowerCase()));

          if ((hasMatchingName || hasTargetService) &&
              !_devices.any((d) => d.remoteId == result.device.remoteId)) {
            _devices.add(result.device);
            notifyListeners();
          }
        }
      });

      // Auto-stop scanning after timeout
      Timer(const Duration(seconds: 15), () {
        stopDiscovery();
      });
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isScanning) return;

    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  // Original APK-style connection with service discovery
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (_isConnected) {
      await disconnect();
    }

    try {
      // Connect with timeout like original APK
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;

      // Listen for connection state changes
      _connectionSubscription = device.connectionState.listen((state) {
        final wasConnected = _isConnected;
        _isConnected = state == BluetoothConnectionState.connected;

        if (wasConnected && !_isConnected) {
          // Connection was lost
          debugPrint('Connection lost, cleaning up...');
          _cleanup();

          // Schedule reconnection if auto-connect is enabled
          if (_autoConnectEnabled && _lastDeviceIdForAutoConnect != null) {
            debugPrint('Scheduling reconnection attempt...');
            _scheduleReconnect();
          }
        }
        notifyListeners();
      });

      // Discover services and characteristics
      await _discoverServices(device);

      _isConnected = true;
      notifyListeners();

      // Send initialization commands like the original APK
      await _initializeDevice();

      return true;
    } catch (e) {
      _connectedDevice = null;
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  // Initialize device and read current settings (from original APK)
  Future<void> _initializeDevice() async {
    try {
      // Give the connection a brief moment to stabilize
      await Future.delayed(const Duration(milliseconds: 300));

      print('BLE link ready. Triggering device state sync...');

      // Automatically sync device state after connection
      if (_connectedDevice != null) {
        // Notify other providers that we're connected and ready
        notifyListeners();

        // Wait a bit more for the connection to fully stabilize
        await Future.delayed(const Duration(milliseconds: 500));

        // The LEDControlProvider will automatically sync via updateBluetoothProvider
        print(
            'Device initialization completed - state sync will be handled by LEDControlProvider');
      }
    } catch (e) {
      print('Device initialization failed: $e');
      // Continue anyway - device might still work for sending commands
    }
  }

  // Service discovery exactly like original APK but more flexible
  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();

    BluetoothCharacteristic? foundWriteChar;
    BluetoothCharacteristic? foundNotifyChar;

    // First, try to find the exact service UUID from original APK
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          final charUuid = characteristic.uuid.toString().toLowerCase();

          if (charUuid == WRITE_CHARACTERISTIC_UUID.toLowerCase()) {
            foundWriteChar = characteristic;
          }

          if (charUuid == NOTIFY_CHARACTERISTIC_UUID.toLowerCase()) {
            foundNotifyChar = characteristic;
          }
        }
        break;
      }
    }

    // If exact service not found, look for any service with writable characteristics
    // This handles devices like Pocket Link that might use different UUIDs
    if (foundWriteChar == null) {
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          // Look for characteristics with write properties
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            foundWriteChar = characteristic;
          }

          // Look for characteristics with notify properties
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            foundNotifyChar = characteristic;
          }

          // If we found both, we can stop looking
          if (foundWriteChar != null && foundNotifyChar != null) {
            break;
          }
        }
        if (foundWriteChar != null && foundNotifyChar != null) {
          break;
        }
      }
    }

    // Set the characteristics we found
    _writeCharacteristic = foundWriteChar;

    // Enable notifications if we found a notify characteristic
    if (foundNotifyChar != null) {
      try {
        if (foundNotifyChar.properties.notify ||
            foundNotifyChar.properties.indicate) {
          await foundNotifyChar.setNotifyValue(true);

          _notificationSubscription =
              foundNotifyChar.lastValueStream.listen((data) {
            if (data.isNotEmpty) {
              _responseController.add(Uint8List.fromList(data));
            }
          });
        }
      } catch (e) {
        // Some devices might not support notifications, that's ok
        print('Notification setup failed: $e');
      }
    }

    // We need at least a write characteristic to control the LED
    if (_writeCharacteristic == null) {
      throw Exception(
          'No writable characteristic found. Device may not be compatible.');
    }
  }

  // Original APK data transmission method
  Future<void> sendData(Uint8List data) async {
    if (!_isConnected || _writeCharacteristic == null) {
      throw Exception(
          'Device not connected or write characteristic not available');
    }

    try {
      // Split data into chunks if necessary (MTU limit handling like original APK)
      const int maxChunkSize = 20;

      // Choose write mode based on characteristic capabilities
      final supportsWriteWithoutResponse =
          _writeCharacteristic!.properties.writeWithoutResponse;
      final supportsWriteWithResponse = _writeCharacteristic!.properties.write;

      Future<void> writeChunk(Uint8List chunk) async {
        if (supportsWriteWithoutResponse) {
          await _writeCharacteristic!.write(chunk, withoutResponse: true);
        } else if (supportsWriteWithResponse) {
          await _writeCharacteristic!.write(chunk, withoutResponse: false);
        } else {
          throw Exception('Characteristic does not support write operations');
        }
      }

      if (data.length <= maxChunkSize) {
        await writeChunk(data);
      } else {
        // Send data in chunks
        for (int i = 0; i < data.length; i += maxChunkSize) {
          final end =
              (i + maxChunkSize < data.length) ? i + maxChunkSize : data.length;
          final chunk = data.sublist(i, end);
          await writeChunk(Uint8List.fromList(chunk));

          // Small delay between chunks to be safe
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  // Wait for response with timeout (original APK pattern)
  Future<Uint8List?> sendDataAndWaitResponse(Uint8List data,
      {Duration timeout = const Duration(seconds: 5)}) async {
    await sendData(data);

    try {
      return await responseStream.first.timeout(timeout);
    } on TimeoutException {
      return null;
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _cleanup();
  }

  void _cleanup() {
    _writeCharacteristic = null;
    _connectedDevice = null;
    _isConnected = false;
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();
    _connectionSubscription = null;
    _notificationSubscription = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelAutoConnect();
    stopDiscovery();
    disconnect();
    _responseController.close();
    super.dispose();
  }
}
