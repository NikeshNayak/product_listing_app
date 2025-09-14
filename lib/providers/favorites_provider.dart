import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<Set<int>> {
  static const _key = 'favorites_ids';

  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_key) ?? [];
    state = list.map(int.parse).toSet();
  }

  Future<void> toggle(int id) async {
    final newSet = Set<int>.from(state);
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    state = newSet;
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_key, state.map((e) => e.toString()).toList());
  }
}
