import 'package:flutter/foundation.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';

class HomeController extends ChangeNotifier {
  final ItemRepository _repository = ItemRepository();

  String searchQuery = '';
  String? selectedCategory;
  List<Item> _allItems = [];

  Stream<List<Item>> get itemsStream => _repository.watchItems();

  void setItems(List<Item> items) {
    _allItems = items;
  }

  void updateSearch(String query) {
    searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void updateCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  List<Item> filteredItems(List<Item> items) {
    var result = items.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(searchQuery) ||
          item.note.toLowerCase().contains(searchQuery);
      final matchesCategory =
          selectedCategory == null || item.category == selectedCategory;
      return matchesSearch && matchesCategory && item.status == 'pending';
    }).toList();

    result.sort((a, b) {
      if (a.reminderDateTime == null) return 1;
      if (b.reminderDateTime == null) return -1;
      return a.reminderDateTime!.compareTo(b.reminderDateTime!);
    });

    return result;
  }
}