import 'package:flutter/foundation.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/supabase_service.dart';
import '../../core/constants/categories.dart';
import '../../core/sync/sync_service.dart';

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
  bool savedOffline = false;

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
    tags = rawText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
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
      errorMessage = 'Session expired. Please log in again.';
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    savedOffline = false;
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
      // Offline-aware: tries Supabase first, queues locally if it fails
      // (e.g. no internet). Notification is only scheduled if the save
      // succeeded immediately with a real server id.
      final wentOnline = await SyncService().addItemOfflineAware(item);

      if (wentOnline && reminderDateTime != null) {
        // Re-fetch isn't strictly needed here since addItemOfflineAware
        // doesn't return the saved row; schedule using a locally
        // generated notification id based on title+timestamp instead.
        await NotificationService().scheduleReminder(
          id: '${item.title}-${now.millisecondsSinceEpoch}'.hashCode,
          title: item.title,
          body: item.note.isEmpty ? 'Reminder' : item.note,
          dateTime: reminderDateTime!,
          priority: priority,
        );
      }

      isSaving = false;
      savedOffline = !wentOnline;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      errorMessage = 'Could not save item. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }
}