import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/led_control_models.dart';
import 'bluetooth_provider.dart';

enum BleProtocol { packet2E, packet7E }

class LEDControlProvider extends ChangeNotifier {
  BluetoothProvider _bluetoothProvider;
  StreamSubscription<Uint8List>? _bleNotifySub;

  LEDControlProvider(this._bluetoothProvider) {
    _initializeState();
    _attachBleListener();
  }

  void updateBluetoothProvider(BluetoothProvider provider) {
    if (!identical(_bluetoothProvider, provider)) {
      _bleNotifySub?.cancel();
      _bluetoothProvider = provider;
      _attachBleListener();
      // If already connected, try to sync state shortly after switching provider
      if (_bluetoothProvider.isConnected) {
        Future.delayed(const Duration(milliseconds: 800), () {
          print('Auto-syncing device state after connection...');
          syncFromDevice();
        });
      }
      notifyListeners();
    }
  }

  void _attachBleListener() {
    _bleNotifySub = _bluetoothProvider.responseStream.listen(_onBleNotification,
        onError: (e) => debugPrint('BLE notify error: $e'));
  }

  @override
  void dispose() {
    _bleNotifySub?.cancel();
    super.dispose();
  }

  // Protocol selection (default to 0x2E packets, can be switched from settings later)
  BleProtocol _protocol = BleProtocol.packet2E;
  BleProtocol get protocol => _protocol;
  void setProtocol(BleProtocol p) {
    _protocol = p;
    notifyListeners();
  }

  // LED State Management
  LEDState _ledState = LEDState(
    isOn: false,
    brightness: 100,
    mode: LightingMode.static,
    currentZone: ColorZone.uniform,
    zoneColors: {
      ColorZone.uniform: 0xFFFFFFFF,
      ColorZone.partition1: 0xFFFF0000,
      ColorZone.partition2: 0xFF0000FF,
    },
    zoneBrightnesses: {
      ColorZone.uniform: 100,
      ColorZone.partition1: 100,
      ColorZone.partition2: 100,
    },
    customColors: [],
  );

  // Original APK Protocol Constants (reverse engineered)
  static const int CMD_COLOR_CONTROL = 0x8D; // -115 in signed byte
  static const int CMD_BRIGHTNESS = 0x90; // -112 in signed byte
  static const int CMD_MODE_CONTROL = 0x8E; // -114 in signed byte
  static const int CMD_POWER_CONTROL =
      0x7C; // 124 (unused here, keep for reference)

  // Color modes from original APK
  static const int COLOR_MODE_UNIFORM = 0;
  static const int COLOR_MODE_PARTITION = 1;
  static const int COLOR_MODE_GRADIENT = 2;

  // Brightness modes
  static const int BRIGHTNESS_MODE_UNIFORM = 1;
  static const int BRIGHTNESS_MODE_PARTITION = 2;

  // Getters
  LEDState get ledState => _ledState;
  bool get isOn => _ledState.isOn;
  int get brightness => _ledState.brightness;
  LightingMode get mode => _ledState.mode;
  ColorZone get currentZone => _ledState.currentZone;
  List<ColorItem> get customColors => _ledState.customColors;
  List<ColorItem> get defaultColors => DefaultColors.getDefaultColorItems();

  int getCurrentZoneColor() =>
      _ledState.zoneColors[_ledState.currentZone] ?? 0xFFFFFFFF;

  void _initializeState() {
    // Initialize with default custom colors (reverse engineered from APK)
    _ledState = _ledState.copyWith(
      customColors: [
        ColorItem(color: 0xFFFF6B6B), // Light Red
        ColorItem(color: 0xFF4ECDC4), // Teal
        ColorItem(color: 0xFF45B7D1), // Blue
        ColorItem(color: 0xFFAB47BC), // Purple
        ColorItem(color: 0xFF26A69A), // Cyan
        ColorItem(color: 0xFFEF5350), // Red
      ],
    );
    notifyListeners();
  }

  // 0x2E Packet builder
  Uint8List _createDataPack(int dataType, List<int> data) {
    const int HEAD = 0x2E; // 46

    final packetLength = 4 + data.length; // HEAD + TYPE + LEN + DATA + CHK
    final buffer = ByteData(packetLength);

    buffer.setUint8(0, HEAD);
    buffer.setUint8(1, dataType & 0xFF);
    buffer.setUint8(2, data.length & 0xFF);

    for (int i = 0; i < data.length; i++) {
      buffer.setUint8(3 + i, data[i] & 0xFF);
    }

    int sum = 0;
    for (int i = 1; i < packetLength - 1; i++) {
      sum += buffer.getUint8(i);
    }
    final checksum = (sum ^ 0xFF) & 0xFF;
    buffer.setUint8(packetLength - 1, checksum);

    final packet = buffer.buffer.asUint8List();
    print(
        'BLE Packet (0x2E): ${packet.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');

    return packet;
  }

  // Color Control Command for 0x2E protocol
  Future<void> _sendColorControlCommand({
    required bool setup,
    required int type,
    required int color1,
    required int color2,
  }) async {
    if (!_bluetoothProvider.isConnected) return;

    final data = <int>[];

    if (setup) {
      data.add(0x01); // Setup flag
      data.add(type); // Color mode type

      final r1 = (color1 >> 16) & 0xFF;
      final g1 = (color1 >> 8) & 0xFF;
      final b1 = color1 & 0xFF;

      final r2 = (color2 >> 16) & 0xFF;
      final g2 = (color2 >> 8) & 0xFF;
      final b2 = color2 & 0xFF;

      data.addAll([r1, g1, b1, r2, g2, b2]);
    } else {
      data.add(0x00); // Query flag
    }

    final packet = _createDataPack(CMD_COLOR_CONTROL, data);
    await _bluetoothProvider.sendData(packet);
  }

  // Brightness Control Command for 0x2E protocol
  Future<void> _sendBrightnessCommand({
    required bool setup,
    required bool switchOn,
    required int type,
    required int brightness1, // 0-100
    required int brightness2, // 0-100
    bool scaleTo255 = false,
  }) async {
    if (!_bluetoothProvider.isConnected) return;

    final data = <int>[];

    if (setup) {
      data.add(0x01); // Setup flag

      int controlByte = 0;
      if (switchOn) controlByte |= 0x40; // Set switch bit (64)
      if (type == BRIGHTNESS_MODE_UNIFORM) {
        controlByte |= 0x08; // Uniform mode
      } else if (type == BRIGHTNESS_MODE_PARTITION) {
        controlByte |= 0x11; // Partition mode
      }
      data.add(controlByte);

      // Map 0-100 -> 0-255 as many controllers expect full 8-bit
      int mapToByte(int v) => (v.clamp(0, 100) * 255 / 100).round();
      data.add(mapToByte(brightness1) & 0xFF);
      data.add(mapToByte(brightness2) & 0xFF);
    } else {
      data.add(0x00); // Query flag
    }

    final packet = _createDataPack(CMD_BRIGHTNESS, data);
    await _bluetoothProvider.sendData(packet);
  }

  // Effect/Mode Control Command for 0x2E protocol
  Future<void> _sendModeCommand(int mode, List<int> parameters) async {
    if (!_bluetoothProvider.isConnected) return;

    final data = <int>[0x01]; // Setup flag
    data.add(mode & 0xFF);
    data.addAll(parameters.map((p) => p & 0xFF));

    final packet = _createDataPack(CMD_MODE_CONTROL, data);
    await _bluetoothProvider.sendData(packet);
  }

  // Classic 0x7E protocol send helpers
  Future<void> _send7E(Uint8List frame) async {
    if (!_bluetoothProvider.isConnected) return;
    print(
        'BLE Packet (0x7E): ${frame.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    await _bluetoothProvider.sendData(frame);
  }

  // Parse incoming BLE notifications and update state
  void _onBleNotification(Uint8List data) {
    try {
      if (data.isEmpty) return;

      if (data[0] == 0x2E) {
        _parse2EPacket(data);
      } else if (data[0] == 0x7E) {
        _parse7EFrame(data);
      } else {
        debugPrint('Unknown BLE frame start: 0x${data[0].toRadixString(16)}');
      }
    } catch (e) {
      debugPrint('Failed to parse BLE notification: $e');
    }
  }

  void _parse2EPacket(Uint8List packet) {
    if (packet.length < 4) return;
    final type = packet[1];
    final len = packet[2];
    if (packet.length < 4 + len) return;

    // Verify checksum (sum of [1..n-2] xor 0xFF == last)
    int sum = 0;
    for (int i = 1; i < (3 + len); i++) sum += packet[i];
    final chk = (sum ^ 0xFF) & 0xFF;
    if (chk != packet[3 + len]) {
      debugPrint('Checksum mismatch for 0x2E packet');
      return;
    }

    final data = packet.sublist(3, 3 + len);

    switch (type) {
      case CMD_COLOR_CONTROL: // 0x8D
        if (data.isNotEmpty) {
          final flag = data[0];
          if (flag == 0x00 && data.length >= 8) {
            // Query response: [00, type, r1,g1,b1,r2,g2,b2]
            final modeType = data[1];
            final r1 = data[2], g1 = data[3], b1 = data[4];
            final r2 = data[5], g2 = data[6], b2 = data[7];
            int c1 = (0xFF << 24) | (r1 << 16) | (g1 << 8) | b1;
            int c2 = (0xFF << 24) | (r2 << 16) | (g2 << 8) | b2;
            final updated = Map<ColorZone, int>.from(_ledState.zoneColors);
            if (modeType == COLOR_MODE_UNIFORM) {
              updated[ColorZone.uniform] = c1;
            } else if (modeType == COLOR_MODE_PARTITION) {
              updated[ColorZone.partition1] = c1;
              updated[ColorZone.partition2] = c2;
            }
            _ledState = _ledState.copyWith(zoneColors: updated);
            notifyListeners();
          }
        }
        break;
      case CMD_BRIGHTNESS: // 0x90
        if (data.isNotEmpty) {
          final flagOrCtl = data[0];
          // Expect setup flag 0/1 as first byte in protocol; for query resp it's likely 0x00
          if (flagOrCtl == 0x00 && data.length >= 3) {
            final b1 = data[1];
            final b2 = data[2];
            // Map 0-255 back to 0-100
            int toPct(int v) => (v * 100 / 255).round().clamp(0, 100);
            final avg = ((toPct(b1) + toPct(b2)) / 2).round();
            _ledState = _ledState.copyWith(brightness: avg);
            notifyListeners();
          }
          // Also infer power from control bit if present
          final isOn = (flagOrCtl & 0x40) != 0;
          if (_ledState.isOn != isOn) {
            _ledState = _ledState.copyWith(isOn: isOn);
            notifyListeners();
          }
        }
        break;
      case CMD_MODE_CONTROL: // 0x8E
        if (data.length >= 2) {
          final modeValue = data[1];
          final mapped = LightingMode.values.firstWhere(
            (m) => m.value == modeValue,
            orElse: () => LightingMode.static,
          );
          _ledState = _ledState.copyWith(mode: mapped);
          notifyListeners();
        }
        break;
      default:
        debugPrint('Unhandled 0x2E type: 0x${type.toRadixString(16)}');
    }
  }

  void _parse7EFrame(Uint8List frame) {
    // Basic 0x7E framing: [0x7E, addr, cmd, ... , 0xEF]
    if (frame.length < 4 || frame.last != 0xEF) return;
    final cmd = frame[2];
    switch (cmd) {
      case 0x01: // Power on
      case 0x02: // Power off
        final isOn = cmd == 0x01;
        if (_ledState.isOn != isOn) {
          _ledState = _ledState.copyWith(isOn: isOn);
          notifyListeners();
        }
        break;
      case 0x03: // Color set
        if (frame.length >= 9) {
          final zone = frame[3];
          final r = frame[4], g = frame[5], b = frame[6];
          final color = (0xFF << 24) | (r << 16) | (g << 8) | b;
          final updated = Map<ColorZone, int>.from(_ledState.zoneColors);
          final z = ColorZone.values[zone.clamp(0, 2)];
          updated[z] = color;
          _ledState = _ledState.copyWith(zoneColors: updated);
          notifyListeners();
        }
        break;
      case 0x05: // Brightness
        if (frame.length >= 5) {
          final b = frame[3];
          final pct = (b * 100 / 255).round().clamp(0, 100);
          _ledState = _ledState.copyWith(brightness: pct);
          notifyListeners();
        }
        break;
      case 0x06: // Mode
        if (frame.length >= 5) {
          final mv = frame[3];
          final mapped = LightingMode.values.firstWhere(
            (m) => m.value == mv,
            orElse: () => LightingMode.static,
          );
          _ledState = _ledState.copyWith(mode: mapped);
          notifyListeners();
        }
        break;
      default:
        debugPrint('Unhandled 0x7E cmd: 0x${cmd.toRadixString(16)}');
    }
  }

  // Public method to query device for current settings
  Future<void> syncFromDevice() async {
    if (!_bluetoothProvider.isConnected) {
      print('Cannot sync: device not connected');
      return;
    }

    print('Starting device state synchronization...');

    try {
      if (_protocol == BleProtocol.packet2E) {
        // Query current colors first
        print('Querying device colors...');
        await _sendColorControlCommand(
            setup: false, type: COLOR_MODE_UNIFORM, color1: 0, color2: 0);
        await Future.delayed(const Duration(milliseconds: 200));

        // Query partition colors as well
        await _sendColorControlCommand(
            setup: false, type: COLOR_MODE_PARTITION, color1: 0, color2: 0);
        await Future.delayed(const Duration(milliseconds: 200));

        // Query current brightness and power state
        print('Querying device brightness and power state...');
        await _sendBrightnessCommand(
            setup: false,
            switchOn: false, // This will be ignored in query mode
            type: BRIGHTNESS_MODE_UNIFORM,
            brightness1: 0,
            brightness2: 0);
        await Future.delayed(const Duration(milliseconds: 200));

        // Query partition brightness as well
        await _sendBrightnessCommand(
            setup: false,
            switchOn: false,
            type: BRIGHTNESS_MODE_PARTITION,
            brightness1: 0,
            brightness2: 0);
        await Future.delayed(const Duration(milliseconds: 200));

        // Query current mode/effect
        print('Querying device mode...');
        final modeQuery =
            _createDataPack(CMD_MODE_CONTROL, [0x00]); // Query flag
        await _bluetoothProvider.sendData(modeQuery);

        print('Device state sync queries sent. Waiting for responses...');

        // Give device time to respond to all queries
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // 0x7E protocol typically does not have explicit query; rely on notifications
        print('Using 0x7E protocol - relying on notifications for state sync');
      }
    } catch (e) {
      print('Sync from device failed: $e');
    }
  }

  // Public Control Methods

  Future<void> togglePower() async {
    final newState = !_ledState.isOn;

    _ledState = _ledState.copyWith(isOn: newState);
    notifyListeners();

    try {
      // 0x2E brightness command to toggle power via control bit (raw 0-100)
      await _sendBrightnessCommand(
        setup: true,
        switchOn: newState,
        type: BRIGHTNESS_MODE_UNIFORM,
        brightness1: _ledState.brightness,
        brightness2: _ledState.brightness,
        scaleTo255: false,
      );
      // Also send scaled variant for compatibility
      await Future.delayed(const Duration(milliseconds: 50));
      await _sendBrightnessCommand(
        setup: true,
        switchOn: newState,
        type: BRIGHTNESS_MODE_UNIFORM,
        brightness1: _ledState.brightness,
        brightness2: _ledState.brightness,
        scaleTo255: true,
      );
      // Always send classic 0x7E power frame as fallback
      await _send7E(Uint8List.fromList(
          ColorControlCmd.createPowerCommand(newState).data));

      // Fallback via color: off -> black, on -> resend current colors
      try {
        if (!newState) {
          // Turn off by setting black
          await _sendColorControlCommand(
            setup: true,
            type: _ledState.currentZone == ColorZone.uniform
                ? COLOR_MODE_UNIFORM
                : COLOR_MODE_PARTITION,
            color1: 0xFF000000,
            color2: 0xFF000000,
          );
        } else {
          // Resend current colors without changing state
          final c1 = _ledState.zoneColors[ColorZone.partition1] ??
              _ledState.zoneColors[ColorZone.uniform] ??
              0xFFFFFFFF;
          final c2 = _ledState.zoneColors[ColorZone.partition2] ??
              _ledState.zoneColors[ColorZone.uniform] ??
              0xFFFFFFFF;
          await _sendColorControlCommand(
            setup: true,
            type: (_ledState.currentZone == ColorZone.uniform)
                ? COLOR_MODE_UNIFORM
                : COLOR_MODE_PARTITION,
            color1: c1,
            color2: c2,
          );
        }
      } catch (_) {}

      print('Power toggle sent: ${newState ? "ON" : "OFF"}');
    } catch (e) {
      _ledState = _ledState.copyWith(isOn: !newState);
      notifyListeners();
      print('Power toggle failed: $e');
      rethrow;
    }
  }

  int _scaleColor(int argb, int brightnessPct) {
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    double f = (brightnessPct.clamp(0, 100)) / 100.0;
    int sr = (r * f).round().clamp(0, 255);
    int sg = (g * f).round().clamp(0, 255);
    int sb = (b * f).round().clamp(0, 255);
    return (a << 24) | (sr << 16) | (sg << 8) | sb;
  }

  Future<void> setBrightness(int brightness) async {
    final clampedBrightness = brightness.clamp(0, 100);

    _ledState = _ledState.copyWith(brightness: clampedBrightness);
    notifyListeners();

    try {
      // 0x2E raw 0-100
      await _sendBrightnessCommand(
        setup: true,
        switchOn: _ledState.isOn,
        type: _ledState.currentZone == ColorZone.uniform
            ? BRIGHTNESS_MODE_UNIFORM
            : BRIGHTNESS_MODE_PARTITION,
        brightness1: clampedBrightness,
        brightness2: clampedBrightness,
        scaleTo255: false,
      );
      // 0x2E scaled 0-255
      await Future.delayed(const Duration(milliseconds: 50));
      await _sendBrightnessCommand(
        setup: true,
        switchOn: _ledState.isOn,
        type: _ledState.currentZone == ColorZone.uniform
            ? BRIGHTNESS_MODE_UNIFORM
            : BRIGHTNESS_MODE_PARTITION,
        brightness1: clampedBrightness,
        brightness2: clampedBrightness,
        scaleTo255: true,
      );
      // 0x7E brightness fallback
      await _send7E(Uint8List.fromList(
          BrightnessCmd.createBrightnessCommand(clampedBrightness).data));

      // Fallback via color scaling (do not mutate stored colors)
      try {
        if (_ledState.currentZone == ColorZone.uniform) {
          final base = _ledState.zoneColors[ColorZone.uniform] ?? 0xFFFFFFFF;
          final scaled = _scaleColor(base, clampedBrightness);
          await _sendColorControlCommand(
            setup: true,
            type: COLOR_MODE_UNIFORM,
            color1: scaled,
            color2: scaled,
          );
        } else {
          final c1 = _ledState.zoneColors[ColorZone.partition1] ?? 0xFFFFFFFF;
          final c2 = _ledState.zoneColors[ColorZone.partition2] ?? 0xFFFFFFFF;
          final s1 = _scaleColor(c1, clampedBrightness);
          final s2 = _scaleColor(c2, clampedBrightness);
          await _sendColorControlCommand(
            setup: true,
            type: COLOR_MODE_PARTITION,
            color1: s1,
            color2: s2,
          );
        }
      } catch (_) {}

      print('Brightness set to: $clampedBrightness%');
    } catch (e) {
      print('Brightness command failed: $e');
    }
  }

  Future<void> setZoneBrightness(ColorZone zone, int brightness) async {
    final clampedBrightness = brightness.clamp(0, 100);

    final updatedBrightnesses =
        Map<ColorZone, int>.from(_ledState.zoneBrightnesses);
    updatedBrightnesses[zone] = clampedBrightness;
    _ledState = _ledState.copyWith(zoneBrightnesses: updatedBrightnesses);
    notifyListeners();

    try {
      if (zone == ColorZone.partition1 || zone == ColorZone.partition2) {
        // Get the other zone's brightness to send a complete command
        final b1 = updatedBrightnesses[ColorZone.partition1] ?? 100;
        final b2 = updatedBrightnesses[ColorZone.partition2] ?? 100;

        // 0x2E raw 0-100 (partition)
        await _sendBrightnessCommand(
          setup: true,
          switchOn: _ledState.isOn,
          type: BRIGHTNESS_MODE_PARTITION,
          brightness1: b1,
          brightness2: b2,
          scaleTo255: false,
        );
        // 0x2E scaled 0-255
        await Future.delayed(const Duration(milliseconds: 50));
        await _sendBrightnessCommand(
          setup: true,
          switchOn: _ledState.isOn,
          type: BRIGHTNESS_MODE_PARTITION,
          brightness1: b1,
          brightness2: b2,
          scaleTo255: true,
        );
        // 0x7E fallback (no per-zone on classic, sets global)
        await _send7E(Uint8List.fromList(
            BrightnessCmd.createBrightnessCommand(clampedBrightness).data));

        // Fallback via color scaling per-zone
        try {
          final c1 = _ledState.zoneColors[ColorZone.partition1] ?? 0xFFFFFFFF;
          final c2 = _ledState.zoneColors[ColorZone.partition2] ?? 0xFFFFFFFF;
          final s1 = _scaleColor(c1, b1);
          final s2 = _scaleColor(c2, b2);
          await _sendColorControlCommand(
            setup: true,
            type: COLOR_MODE_PARTITION,
            color1: s1,
            color2: s2,
          );
        } catch (_) {}
      } else {
        // If it's the uniform zone, fall back to the global brightness setter
        await setBrightness(clampedBrightness);
      }
      print('Zone ${zone.displayName} brightness set to: $clampedBrightness%');
    } catch (e) {
      print('Zone brightness command failed: $e');
    }
  }

  Future<void> setColor(int color) async {
    final updatedColors = Map<ColorZone, int>.from(_ledState.zoneColors);
    updatedColors[_ledState.currentZone] = color;

    // If uniform zone is selected, sync the color to partition zones as well
    if (_ledState.currentZone == ColorZone.uniform) {
      updatedColors[ColorZone.partition1] = color;
      updatedColors[ColorZone.partition2] = color;
    }

    _ledState = _ledState.copyWith(zoneColors: updatedColors);
    notifyListeners();

    try {
      if (_protocol == BleProtocol.packet2E) {
        if (_ledState.currentZone == ColorZone.uniform) {
          await _sendColorControlCommand(
            setup: true,
            type: COLOR_MODE_UNIFORM,
            color1: color,
            color2: color,
          );
        } else {
          await _sendColorControlCommand(
            setup: true,
            type: COLOR_MODE_PARTITION,
            color1: updatedColors[ColorZone.partition1] ?? 0xFFFFFFFF,
            color2: updatedColors[ColorZone.partition2] ?? 0xFFFFFFFF,
          );
        }
      } else {
        // Map ColorZone to zone index expected by 0x7E format
        final zoneIndex = _ledState.currentZone.index; // 0,1,2
        await _send7E(Uint8List.fromList(ColorControlCmd.createColorCommand(
          isOn: _ledState.isOn,
          zone: zoneIndex,
          color: color,
        ).data));
      }

      print(
          'Color set for ${_ledState.currentZone.displayName}: ${color.toRadixString(16)}');
    } catch (e) {
      print('Color command failed: $e');
    }
  }

  Future<void> setZoneColor(ColorZone zone, int color) async {
    final updatedColors = Map<ColorZone, int>.from(_ledState.zoneColors);
    updatedColors[zone] = color;

    _ledState = _ledState.copyWith(zoneColors: updatedColors);
    notifyListeners();

    try {
      if (_protocol == BleProtocol.packet2E) {
        if (zone == ColorZone.uniform) {
          await _sendColorControlCommand(
            setup: true,
            type: COLOR_MODE_UNIFORM,
            color1: color,
            color2: color,
          );
        } else {
          await _sendColorControlCommand(
            setup: true,
            type: COLOR_MODE_PARTITION,
            color1: updatedColors[ColorZone.partition1] ?? 0xFFFFFFFF,
            color2: updatedColors[ColorZone.partition2] ?? 0xFFFFFFFF,
          );
        }
      } else {
        final zoneIndex = zone.index;
        await _send7E(Uint8List.fromList(ColorControlCmd.createColorCommand(
          isOn: _ledState.isOn,
          zone: zoneIndex,
          color: color,
        ).data));
      }
      print('Zone ${zone.displayName} color set: ${color.toRadixString(16)}');
    } catch (e) {
      print('Zone color command failed: $e');
    }
  }

  Future<void> setColorZone(ColorZone zone) async {
    _ledState = _ledState.copyWith(currentZone: zone);
    notifyListeners();
    print('Color zone changed to: ${zone.displayName}');
  }

  Future<void> setMode(LightingMode mode) async {
    _ledState = _ledState.copyWith(mode: mode);
    notifyListeners();

    int modeCmd = 0;
    List<int> parameters = [];

    switch (mode) {
      case LightingMode.static:
        modeCmd = 0x01;
        parameters = [0x00];
        break;
      case LightingMode.breathing:
        modeCmd = 0x02;
        parameters = [0x01, 0x64];
        break;
      case LightingMode.strobe:
        modeCmd = 0x03;
        parameters = [0x02, 0x32];
        break;
      case LightingMode.fade:
        modeCmd = 0x04;
        parameters = [0x03, 0x50];
        break;
      case LightingMode.rainbow:
        modeCmd = 0x05;
        parameters = [0x04, 0x80];
        break;
      case LightingMode.auto:
        modeCmd = 0x06;
        parameters = [0x05, 0x60];
        break;
    }

    try {
      if (_protocol == BleProtocol.packet2E) {
        await _sendModeCommand(modeCmd, parameters);
      } else {
        await _send7E(Uint8List.fromList(ModeCmd.createModeCommand(mode).data));
      }
      print('Lighting mode set to: ${mode.displayName}');
    } catch (e) {
      print('Mode command failed: $e');
    }
  }

  Future<void> addCustomColor(int color) async {
    final updatedColors = List<ColorItem>.from(_ledState.customColors);
    updatedColors.add(ColorItem(color: color));
    _ledState = _ledState.copyWith(customColors: updatedColors);
    notifyListeners();
  }

  Future<void> removeCustomColor(int index) async {
    if (index >= 0 && index < _ledState.customColors.length) {
      final updatedColors = List<ColorItem>.from(_ledState.customColors);
      updatedColors.removeAt(index);
      _ledState = _ledState.copyWith(customColors: updatedColors);
      notifyListeners();
    }
  }

  // ---- Compatibility stubs for EffectsScreen ----
  Future<void> setWelcomeEffect(bool enabled, int color) async {
    // Placeholder: not supported by current protocol
    debugPrint(
        'setWelcomeEffect(enabled=$enabled, color=0x${color.toRadixString(16)})');
    // Optionally, we might set a static color briefly as a visual confirmation
    if (_bluetoothProvider.isConnected && enabled) {
      try {
        await setColor(color);
      } catch (_) {}
    }
  }

  Future<void> setSteeringWheelLearning(bool enabled) async {
    // Placeholder: not supported by current protocol
    debugPrint('setSteeringWheelLearning(enabled=$enabled)');
  }

  Future<void> requestDeviceInfo() async {
    // Placeholder: could send a query packet if protocol docs are available
    debugPrint('requestDeviceInfo() called');
  }

  Future<void> requestDiagnosticInfo() async {
    // Placeholder for diagnostics
    debugPrint('requestDiagnosticInfo() called');
  }

  // Exposed utility used by Settings screen
  Future<void> factoryReset() async {
    // Reset local state
    _ledState = _ledState.copyWith(
      isOn: true,
      brightness: 100,
      mode: LightingMode.static,
      currentZone: ColorZone.uniform,
      zoneColors: {
        ColorZone.uniform: 0xFFFFFFFF,
        ColorZone.partition1: 0xFFFFFFFF,
        ColorZone.partition2: 0xFFFFFFFF,
      },
    );
    notifyListeners();

    if (!_bluetoothProvider.isConnected) return;

    try {
      // Send white color, full brightness, static mode
      await setColor(0xFFFFFFFF);
      await setBrightness(100);
      await setMode(LightingMode.static);
    } catch (e) {
      debugPrint('Factory reset BLE send failed: $e');
    }
  }
}
