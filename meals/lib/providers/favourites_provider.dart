import 'package:meals/models/meal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavouritesProvider extends StateNotifier<List<Meal>> {
  FavouritesProvider() : super([]);

  bool toggleFavouriteMeal(Meal meal) {
    final isMealFavourite = state.contains(meal);
    if (isMealFavourite) {
      state = state
          .where(
            (element) => element.id != meal.id,
          )
          .toList();
      return true;
    } else {
      state = [...state, meal];
      return false;
    }
  }
}

final favouriteMealProvider =
    StateNotifierProvider<FavouritesProvider, List<Meal>>((ref) {
      return FavouritesProvider();
    });
