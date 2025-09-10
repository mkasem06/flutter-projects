import 'package:flutter/material.dart';

// LED Control Models - Based on original APK structure

class ColorItem {
  final int color;
  final String? name;

  ColorItem({required this.color, this.name});

  Color get flutterColor => Color(color);

  @override
  String toString() => 'ColorItem(color: $color, name: $name)';
}

enum LightingMode {
  static(0, 'Static'),
  breathing(1, 'Breathing'),
  strobe(2, 'Strobe'),
  fade(3, 'Fade'),
  rainbow(4, 'Rainbow'),
  auto(5, 'Auto');

  const LightingMode(this.value, this.displayName);
  final int value;
  final String displayName;
}

enum ColorZone {
  uniform(0, 'Uniform'),
  partition1(1, 'Zone 1'),
  partition2(2, 'Zone 2');

  const ColorZone(this.value, this.displayName);
  final int value;
  final String displayName;
}

class LEDState {
  final bool isOn;
  final int brightness;
  final LightingMode mode;
  final ColorZone currentZone;
  final Map<ColorZone, int> zoneColors;
  final List<ColorItem> customColors;

  const LEDState({
    required this.isOn,
    required this.brightness,
    required this.mode,
    required this.currentZone,
    required this.zoneColors,
    required this.customColors,
  });

  LEDState copyWith({
    bool? isOn,
    int? brightness,
    LightingMode? mode,
    ColorZone? currentZone,
    Map<ColorZone, int>? zoneColors,
    List<ColorItem>? customColors,
  }) {
    return LEDState(
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      mode: mode ?? this.mode,
      currentZone: currentZone ?? this.currentZone,
      zoneColors: zoneColors ?? this.zoneColors,
      customColors: customColors ?? this.customColors,
    );
  }
}

// BLE Command structure - reverse engineered from APK
class BLECommand {
  final List<int> data;

  BLECommand(this.data);

  @override
  String toString() =>
      'BLECommand(${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')})';
}

// Original APK color control commands
class ColorControlCmd {
  static BLECommand createColorCommand({
    required bool isOn,
    required int zone, // 0=uniform, 1=partition1, 2=partition2
    required int color,
  }) {
    // Extract RGB from color
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;

    // Based on original APK BLE protocol
    return BLECommand([
      0x7E, // Header
      0x00, // Device address
      isOn ? 0x03 : 0x04, // Command: 03=color on, 04=off
      zone, // Zone selection
      r, g, b, // RGB values
      0x00, 0xEF // Footer
    ]);
  }

  static BLECommand createPowerCommand(bool isOn) {
    return BLECommand([
      0x7E, // Header
      0x00, // Device address
      isOn ? 0x01 : 0x02, // Command: 01=on, 02=off
      0x00, 0x00, 0x00, 0x00,
      0x00, 0xEF // Footer
    ]);
  }
}

class BrightnessCmd {
  static BLECommand createBrightnessCommand(int brightness) {
    // Brightness range 0-100 -> 0-255
    final brightnessValue = (brightness * 255 / 100).clamp(0, 255).toInt();

    return BLECommand([
      0x7E, // Header
      0x00, // Device address
      0x05, // Brightness command
      brightnessValue,
      0x00, 0x00, 0x00,
      0x00, 0xEF // Footer
    ]);
  }
}

class ModeCmd {
  static BLECommand createModeCommand(LightingMode mode) {
    return BLECommand([
      0x7E, // Header
      0x00, // Device address
      0x06, // Mode command
      mode.value, // 0=static, 1=auto, 2=strobe
      0x00, 0x00, 0x00,
      0x00, 0xEF // Footer
    ]);
  }
}

// Default colors from original APK
class DefaultColors {
  static const List<int> predefinedColors = [
    0xFFFF0000, // Red
    0xFF00FF00, // Green
    0xFF0000FF, // Blue
    0xFFFFFF00, // Yellow
    0xFFFF00FF, // Magenta
    0xFF00FFFF, // Cyan
    0xFFFFFFFF, // White
    0xFFFF8000, // Orange
    0xFF8000FF, // Purple
    0xFF00FF80, // Lime
    0xFF80FF00, // Yellow-Green
    0xFF0080FF, // Sky Blue
    0xFFFF0080, // Pink
    0xFF80FFFF, // Light Cyan
    0xFFFF8080, // Light Red
    0xFF8080FF, // Light Blue
  ];

  static List<ColorItem> getDefaultColorItems() {
    return predefinedColors.map((color) => ColorItem(color: color)).toList();
  }
}
