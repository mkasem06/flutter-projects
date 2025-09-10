import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/led_control_provider.dart';
import 'screens/home_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/color_control_screen.dart';
import 'screens/effects_screen.dart';
import 'screens/led_control_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const CarLightApp());
}

class CarLightApp extends StatelessWidget {
  const CarLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
        ChangeNotifierProxyProvider<BluetoothProvider, LEDControlProvider>(
          create: (context) => LEDControlProvider(
            Provider.of<BluetoothProvider>(context, listen: false),
          ),
          update: (context, bluetoothProvider, previous) {
            if (previous != null) {
              previous.updateBluetoothProvider(bluetoothProvider);
              return previous;
            }
            return LEDControlProvider(bluetoothProvider);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Car Light Controller',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
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
}
