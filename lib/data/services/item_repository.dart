import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_model.dart';
import 'supabase_service.dart';
import 'prefs_service.dart';

class ItemRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const String _table = 'items';

  Stream<List<Item>> watchItems() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((rows) {
      PrefsService.setLastSyncNow();
      return rows.map((row) => Item.fromJson(row)).toList();
    });
  }

  Future<Item> addItem(Item item) async {
    final row = await _client
        .from(_table)
        .insert(item.toInsertJson())
        .select()
        .single();
    return Item.fromJson(row);
  }

  Future<Item> fetchById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).single();
    return Item.fromJson(row);
  }

  Future<void> updateItem(String id, Item item) async {
    await _client.from(_table).update(item.toUpdateJson()).eq('id', id);
  }

  /// Checks if the row changed on the server since [localUpdatedAt] was
  /// loaded. Returns the current server version if there's a conflict,
  /// or null if it's safe to update.
  Future<Item?> checkForConflict(String id, DateTime localUpdatedAt) async {
    final serverItem = await fetchById(id);
    if (serverItem.updatedAt.isAfter(localUpdatedAt)) {
      return serverItem;
    }
    return null;
  }

  Future<void> updateStatus(String id, String status) async {
    final data = {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status == 'deleted') {
      data['deleted_at'] = DateTime.now().toIso8601String();
    }
    await _client.from(_table).update(data).eq('id', id);
  }

  Future<void> hardDelete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}