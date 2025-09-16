import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/led_control_provider.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/color_control_screen.dart';
import 'screens/effects_screen.dart';
import 'screens/led_control_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings service
  await SettingsService.initialize();

  runApp(const CarLightApp());
}

class CarLightApp extends StatefulWidget {
  const CarLightApp({super.key});

  @override
  State<CarLightApp> createState() => _CarLightAppState();
}

class _CarLightAppState extends State<CarLightApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Save settings when app goes to background or is paused
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _saveCurrentSettings();
    }
  }

  void _saveCurrentSettings() {
    try {
      // Get the current context from the navigator
      final context = navigatorKey.currentContext;
      if (context != null) {
        final bluetoothProvider =
            Provider.of<BluetoothProvider>(context, listen: false);
        final ledControlProvider =
            Provider.of<LEDControlProvider>(context, listen: false);

        // Save current state
        SettingsService.saveLedState(ledControlProvider.ledState);

        // Save last connected device if connected
        if (bluetoothProvider.isConnected &&
            bluetoothProvider.connectedDevice != null) {
          SettingsService.setLastConnectedDevice(
              bluetoothProvider.connectedDevice!.platformName);
          SettingsService.setLastConnectedDeviceId(
              bluetoothProvider.connectedDevice!.remoteId.str);
        }
      }
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  // Global navigator key to access context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProxyProvider<BluetoothProvider, LEDControlProvider>(
          create: (context) {
            final bluetoothProvider =
                Provider.of<BluetoothProvider>(context, listen: false);
            final ledProvider = LEDControlProvider(bluetoothProvider);

            // Load saved settings after provider is created
            _loadSavedSettings(bluetoothProvider, ledProvider);

            return ledProvider;
          },
          update: (context, bluetoothProvider, previous) {
            if (previous != null) {
              previous.updateBluetoothProvider(bluetoothProvider);
              return previous;
            }
            final ledProvider = LEDControlProvider(bluetoothProvider);
            _loadSavedSettings(bluetoothProvider, ledProvider);
            return ledProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Car Light Controller',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _getThemeMode(),
        navigatorKey: navigatorKey,
        home: const HomeScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/bluetooth': (context) => const BluetoothScreen(),
          '/color-control': (context) => const ColorControlScreen(),
          '/effects': (context) => const EffectsScreen(),
          '/led-control': (context) => const LEDControlScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }

  void _loadSavedSettings(BluetoothProvider bluetoothProvider,
      LEDControlProvider ledControlProvider) {
    // Load saved LED state if preferences are enabled
    if (SettingsService.getSavePreferences()) {
      final savedLedState = SettingsService.loadLedState();
      ledControlProvider.loadFromSavedState(savedLedState);

      // Load saved Bluetooth device for auto-connect
      if (SettingsService.getAutoConnect()) {
        final lastDeviceId = SettingsService.getLastConnectedDeviceId();
        if (lastDeviceId != null) {
          bluetoothProvider.setLastDeviceForAutoConnect(lastDeviceId);
          bluetoothProvider.setAutoConnectEnabled(true);

          // Schedule auto-connect with a delay to allow the app to fully initialize
          Future.delayed(const Duration(seconds: 3), () {
            bluetoothProvider.attemptAutoConnect();
          });
        }
      }
    }
  }

  ThemeMode _getThemeMode() {
    final themeString = SettingsService.getSelectedTheme();
    switch (themeString) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
