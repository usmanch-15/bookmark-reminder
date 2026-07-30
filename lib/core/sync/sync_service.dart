import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../data/services/supabase_service.dart';
import 'pending_write_queue.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ItemRepository _repository = ItemRepository();

  void init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final bool isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        _flushQueue();
      }
    });
  }

  Future<void> _flushQueue() async {
    final pending = await PendingWriteQueue.getAll();
    if (pending.isEmpty) return;

    final String? userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    for (final Map<String, dynamic> json in pending) {
      try {
        final DateTime now = DateTime.now();
        final Item item = Item(
          userId: userId,
          title: json['title'] ?? 'Untitled',
          note: json['note'] ?? '',
          category: json['category'] ?? 'Personal',
          reminderDateTime: json['reminder_date_time'] != null
              ? DateTime.tryParse(json['reminder_date_time'])
              : null,
          priority: json['priority'] ?? 1,
          status: 'pending',
          createdAt: now,
          updatedAt: now,
        );
        await _repository.addItem(item);
      } catch (_) {
        return;
      }
    }

    await PendingWriteQueue.clear();
  }

  Future<void> flushQueuePublic() async {
    await _flushQueue();
  }

  Future<bool> addItemOfflineAware(Item item) async {
    try {
      await _repository.addItem(item);
      return true;
    } catch (_) {
      await PendingWriteQueue.enqueue(item.toInsertJson());
      return false;
    }
  }
}