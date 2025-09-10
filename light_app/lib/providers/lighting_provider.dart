import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LightingMode { static, breathe, strobe, rainbow, music, custom }

enum LightZone { interior, exterior, ambient, footwell, dashboard }

class LightingProvider extends ChangeNotifier {
  Color _selectedColor = Colors.blue;
  LightingMode _currentMode = LightingMode.static;
  double _brightness = 1.0;
  double _speed = 0.5;
  bool _isLightOn = false;
  Map<LightZone, bool> _zoneStatus = {
    for (var zone in LightZone.values) zone: false
  };
  List<Color> _favoriteColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.cyan,
  ];

  // Getters
  Color get selectedColor => _selectedColor;
  LightingMode get currentMode => _currentMode;
  double get brightness => _brightness;
  double get speed => _speed;
  bool get isLightOn => _isLightOn;
  Map<LightZone, bool> get zoneStatus => _zoneStatus;
  List<Color> get favoriteColors => _favoriteColors;

  LightingProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _selectedColor =
        Color(prefs.getInt('selected_color') ?? Colors.blue.toARGB32());
    _currentMode = LightingMode.values[prefs.getInt('current_mode') ?? 0];
    _brightness = prefs.getDouble('brightness') ?? 1.0;
    _speed = prefs.getDouble('speed') ?? 0.5;
    _isLightOn = prefs.getBool('is_light_on') ?? false;

    // Load zone status
    for (var zone in LightZone.values) {
      _zoneStatus[zone] = prefs.getBool('zone_${zone.name}') ?? false;
    }

    // Load favorite colors
    final colorValues = prefs.getStringList('favorite_colors');
    if (colorValues != null) {
      _favoriteColors = colorValues.map((e) => Color(int.parse(e))).toList();
    }

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('selected_color', _selectedColor.toARGB32());
    await prefs.setInt('current_mode', _currentMode.index);
    await prefs.setDouble('brightness', _brightness);
    await prefs.setDouble('speed', _speed);
    await prefs.setBool('is_light_on', _isLightOn);

    // Save zone status
    for (var zone in LightZone.values) {
      await prefs.setBool('zone_${zone.name}', _zoneStatus[zone] ?? false);
    }

    // Save favorite colors
    final colorValues =
        _favoriteColors.map((e) => e.toARGB32().toString()).toList();
    await prefs.setStringList('favorite_colors', colorValues);
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
    _saveSettings();
  }

  void setMode(LightingMode mode) {
    _currentMode = mode;
    notifyListeners();
    _saveSettings();
  }

  void setBrightness(double brightness) {
    _brightness = brightness.clamp(0.0, 1.0);
    notifyListeners();
    _saveSettings();
  }

  void setSpeed(double speed) {
    _speed = speed.clamp(0.0, 1.0);
    notifyListeners();
    _saveSettings();
  }

  void toggleLight() {
    _isLightOn = !_isLightOn;
    notifyListeners();
    _saveSettings();
  }

  void setLightOn(bool isOn) {
    _isLightOn = isOn;
    notifyListeners();
    _saveSettings();
  }

  void toggleZone(LightZone zone) {
    _zoneStatus[zone] = !(_zoneStatus[zone] ?? false);
    notifyListeners();
    _saveSettings();
  }

  void setZoneStatus(LightZone zone, bool status) {
    _zoneStatus[zone] = status;
    notifyListeners();
    _saveSettings();
  }

  void addFavoriteColor(Color color) {
    if (!_favoriteColors.contains(color) && _favoriteColors.length < 12) {
      _favoriteColors.add(color);
      notifyListeners();
      _saveSettings();
    }
  }

  void removeFavoriteColor(Color color) {
    _favoriteColors.remove(color);
    notifyListeners();
    _saveSettings();
  }

  String getLightingCommand() {
    // Generate command string based on current settings
    // This would be specific to your LED controller protocol
    final r = ((_selectedColor.r * 255.0).round() * _brightness).round();
    final g = ((_selectedColor.g * 255.0).round() * _brightness).round();
    final b = ((_selectedColor.b * 255.0).round() * _brightness).round();

    return 'RGB:$r,$g,$b|MODE:${_currentMode.name}|SPEED:${(_speed * 100).round()}|POWER:${_isLightOn ? 1 : 0}';
  }

  String getZoneCommand(LightZone zone) {
    final isOn = _zoneStatus[zone] ?? false;
    return 'ZONE:${zone.name}|STATUS:${isOn ? 1 : 0}';
  }

  // Preset lighting effects
  void applyPreset(String presetName) {
    switch (presetName) {
      case 'Cool Blue':
        setColor(const Color(0xFF0066FF));
        setMode(LightingMode.breathe);
        setBrightness(0.8);
        break;
      case 'Warm White':
        setColor(const Color(0xFFFFE4B5));
        setMode(LightingMode.static);
        setBrightness(1.0);
        break;
      case 'Party Mode':
        setColor(const Color(0xFFFF0080));
        setMode(LightingMode.rainbow);
        setSpeed(0.8);
        setBrightness(1.0);
        break;
      case 'Focus':
        setColor(const Color(0xFFFFFFFF));
        setMode(LightingMode.static);
        setBrightness(0.9);
        break;
      case 'Relax':
        setColor(const Color(0xFF8A2BE2));
        setMode(LightingMode.breathe);
        setBrightness(0.6);
        setSpeed(0.3);
        break;
    }
  }
}
