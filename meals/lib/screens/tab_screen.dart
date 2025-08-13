import 'package:flutter/material.dart';
import 'package:meals/models/meal.dart';
import 'package:meals/screens/category_screen.dart';
import 'package:meals/screens/filters_screen.dart';
import 'package:meals/screens/meals_screen.dart';
import 'package:meals/widgets/main_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meals/providers/favourites_provider.dart';
import 'package:meals/providers/filters_provider.dart';

const kInitialFilters = {
  Filter.glutenFree: false,
  Filter.lactoseFree: false,
  Filter.vegan: false,
  Filter.vegetarian: false,
};

class TabScreen extends ConsumerStatefulWidget {
  const TabScreen({super.key});

  @override
  ConsumerState<TabScreen> createState() => _TabScreenState();
}

class _TabScreenState extends ConsumerState<TabScreen> {
  final List<Meal> favouriteMeals = [];

  int currentSelectedTab = 0;

  void selectTabs(int index) {
    setState(() {
      currentSelectedTab = index;
    });
  }

  void setScreen(String id) async {
    Navigator.pop(context);
    if (id == 'filters') {
      await Navigator.of(context).push<Map<Filter, bool>>(
        MaterialPageRoute(
          builder: (context) {
            return const FiltersScreen();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableMeals = ref.watch(filteredMealsProvider);
    Widget activeScreen = CategoryScreen(
      availableMeals: availableMeals,
    );
    var activeTitle = 'Categories';

    if (currentSelectedTab == 1) {
      final favouriteMeals = ref.watch(favouriteMealProvider);
      activeScreen = MealsScreen(
        meals: favouriteMeals,
      );
      activeTitle = 'Favourites';
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(activeTitle),
      ),
      drawer: MainDrawer(
        onSelectScreen: setScreen,
      ),
      body: activeScreen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentSelectedTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.fastfood,
            ),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.star,
            ),
            label: 'Favourites',
          ),
        ],
        onTap: (index) => selectTabs(index),
      ),
    );

    // BottomNavyBar(
    //   items: [
    //     BottomNavyBarItem(
    //       icon: const Icon(Icons.fastfood),
    //       title: const Text(
    //         'Categories',
    //       ),
    //       textAlign: TextAlign.center,
    //       activeColor: Theme.of(context).colorScheme.onSecondaryFixed,
    //     ),
    //     BottomNavyBarItem(
    //       icon: const Icon(Icons.star),
    //       title: const Text(
    //         'Favourites',
    //       ),
    //       textAlign: TextAlign.center,
    //       activeColor: Theme.of(context).colorScheme.onSecondaryFixed,
    //     ),
    //   ],
    //   selectedIndex: currentSelectedTab,
    //   onItemSelected: (index) => selectTabs(index),
    //   mainAxisAlignment: MainAxisAlignment.center,
    //   backgroundColor: Theme.of(context).colorScheme.secondaryFixedDim,
    //   borderRadius: BorderRadius.circular(10),
    //   itemPadding: EdgeInsets.symmetric(horizontal: 4),
    //   showElevation: true,
    // ),
  }
}
