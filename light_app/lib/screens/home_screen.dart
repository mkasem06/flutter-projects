import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/led_control_provider.dart';
import 'color_control_screen.dart';
import 'bluetooth_screen.dart';
import 'effects_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  final List<Widget> _screens = [
    const ColorControlScreen(),
    const EffectsScreen(),
    const BluetoothScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BluetoothProvider, LEDControlProvider>(
      builder: (context, bluetoothProvider, ledProvider, child) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _screens,
          ),
          floatingActionButton: _selectedIndex == 0
              ? ScaleTransition(
                  scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _fabAnimationController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      await ledProvider.togglePower();
                    },
                    icon: Icon(
                      ledProvider.isOn
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                    ),
                    label: Text(
                      ledProvider.isOn ? 'Turn Off' : 'Turn On',
                    ),
                    backgroundColor: ledProvider.isOn
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    foregroundColor: ledProvider.isOn
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.palette_outlined, Icons.palette, 0),
                  label: 'Colors',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                      Icons.auto_awesome_outlined, Icons.auto_awesome, 1),
                  label: 'Effects',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(
                      Icons.bluetooth_outlined, Icons.bluetooth, 2),
                  label: 'Bluetooth',
                ),
                BottomNavigationBarItem(
                  icon:
                      _buildNavIcon(Icons.settings_outlined, Icons.settings, 3),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = _selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 4 : 0),
      decoration: isSelected
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        size: 24,
      ),
    );
  }
}
