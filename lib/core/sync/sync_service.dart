import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../data/services/supabase_service.dart';
import 'pending_write_queue.dart';

/// Listens for connectivity changes and replays any queued offline writes.
/// Call SyncService().init() once from main.dart after Supabase init.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ItemRepository _repository = ItemRepository();

  void init() {
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        _flushQueue();
      }
    });
  }

  Future<void> _flushQueue() async {
    final pending = await PendingWriteQueue.getAll();
    if (pending.isEmpty) return;

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    for (final json in pending) {
      try {
        final now = DateTime.now();
        final item = Item(
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
        // Leave remaining queue intact if one item fails; retry next time.
        return;
      }
    }

    await PendingWriteQueue.clear();
  }

  /// Call this instead of repository.addItem() directly when you want
  /// offline-safe writes. Falls back to queueing on failure.
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