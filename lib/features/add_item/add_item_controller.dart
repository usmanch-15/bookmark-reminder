import 'package:flutter/foundation.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/supabase_service.dart';
import '../../core/constants/categories.dart';

class AddItemController extends ChangeNotifier {
  final ItemRepository _repository = ItemRepository();

  String title = '';
  String note = '';
  String category = AppCategories.all.first;
  DateTime? reminderDateTime;
  int priority = 1;
  List<String> tags = [];
  String recurrence = 'none';
  int recurrenceInterval = 1;
  bool isSaving = false;
  String? errorMessage;

  void setTitle(String value) => title = value;
  void setNote(String value) => note = value;

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void setPriority(int value) {
    priority = value;
    notifyListeners();
  }

  void setReminderDateTime(DateTime value) {
    reminderDateTime = value;
    notifyListeners();
  }

  void setTagsFromText(String rawText) {
    tags = rawText
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  void setRecurrence(String value) {
    recurrence = value;
    notifyListeners();
  }

  void setRecurrenceInterval(int value) {
    recurrenceInterval = value;
    notifyListeners();
  }

  Future<bool> saveItem() async {
    if (title.trim().isEmpty) {
      errorMessage = 'Title zaroori hai';
      notifyListeners();
      return false;
    }

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) {
      errorMessage = 'User login nahi hai';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final now = DateTime.now();
    final item = Item(
      userId: userId,
      title: title.trim(),
      note: note.trim(),
      category: category,
      reminderDateTime: reminderDateTime,
      priority: priority,
      status: 'pending',
      tags: tags,
      recurrence: recurrence,
      recurrenceInterval: recurrenceInterval,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final savedItem = await _repository.addItem(item);

      if (reminderDateTime != null) {
        await NotificationService().scheduleReminder(
          id: savedItem.notificationId,
          title: savedItem.title,
          body: savedItem.note.isEmpty ? 'Reminder' : savedItem.note,
          dateTime: reminderDateTime!,
        );
      }

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      errorMessage = 'Save failed: $e';
      notifyListeners();
      return false;
    }
  }
}