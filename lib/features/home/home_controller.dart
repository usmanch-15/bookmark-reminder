import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';

enum SavedView { all, today, upcoming, overdue, important }

class HomeController extends ChangeNotifier {
  final ItemRepository _repository = ItemRepository();

  String searchQuery = '';
  String? selectedCategory;
  int? selectedPriority;
  DateTimeRange? dateRange;
  SavedView savedView = SavedView.all;

  bool selectionMode = false;
  final Set<String> selectedIds = <String>{};

  Stream<List<Item>> get itemsStream => _repository.watchItems();

  void updateSearch(String query) {
    searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void updateCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void updatePriority(int? priority) {
    selectedPriority = priority;
    notifyListeners();
  }

  void updateDateRange(DateTimeRange? range) {
    dateRange = range;
    notifyListeners();
  }

  void updateSavedView(SavedView view) {
    savedView = view;
    notifyListeners();
  }

  void clearFilters() {
    selectedCategory = null;
    selectedPriority = null;
    dateRange = null;
    savedView = SavedView.all;
    notifyListeners();
  }

  void toggleSelectionMode() {
    selectionMode = !selectionMode;
    if (!selectionMode) selectedIds.clear();
    notifyListeners();
  }

  void toggleItemSelected(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    selectionMode = false;
    notifyListeners();
  }

  Future<void> bulkComplete() async {
    for (final String id in selectedIds) {
      await _repository.updateStatus(id, 'completed');
    }
    clearSelection();
  }

  Future<void> bulkArchive() async {
    for (final String id in selectedIds) {
      await _repository.updateStatus(id, 'archived');
    }
    clearSelection();
  }

  Future<void> bulkDelete() async {
    for (final String id in selectedIds) {
      await _repository.updateStatus(id, 'deleted');
    }
    clearSelection();
  }

  Future<void> togglePinned(Item item) async {
    item.pinned = !item.pinned;
    await _repository.updateItem(item.id!, item);
  }

  List<Item> filteredItems(List<Item> items) {
    List<Item> result = items.where((Item item) {
      if (item.status != 'pending') return false;

      final bool matchesSearch = item.title.toLowerCase().contains(searchQuery) ||
          item.note.toLowerCase().contains(searchQuery);
      final bool matchesCategory =
          selectedCategory == null || item.category == selectedCategory;
      final bool matchesPriority =
          selectedPriority == null || item.priority == selectedPriority;

      bool matchesDateRange = true;
      if (dateRange != null && item.reminderDateTime != null) {
        matchesDateRange = item.reminderDateTime!
            .isAfter(dateRange!.start.subtract(const Duration(seconds: 1))) &&
            item.reminderDateTime!.isBefore(dateRange!.end.add(const Duration(days: 1)));
      }

      bool matchesSavedView = true;
      final DateTime now = DateTime.now();
      switch (savedView) {
        case SavedView.today:
          matchesSavedView = item.reminderDateTime != null &&
              item.reminderDateTime!.year == now.year &&
              item.reminderDateTime!.month == now.month &&
              item.reminderDateTime!.day == now.day;
          break;
        case SavedView.upcoming:
          matchesSavedView =
              item.reminderDateTime != null && item.reminderDateTime!.isAfter(now);
          break;
        case SavedView.overdue:
          matchesSavedView = item.isOverdue;
          break;
        case SavedView.important:
          matchesSavedView = item.priority == 2;
          break;
        case SavedView.all:
          matchesSavedView = true;
          break;
      }

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesDateRange &&
          matchesSavedView;
    }).toList();

    result.sort((Item a, Item b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      if (a.reminderDateTime == null) return 1;
      if (b.reminderDateTime == null) return -1;
      return a.reminderDateTime!.compareTo(b.reminderDateTime!);
    });

    return result;
  }
}