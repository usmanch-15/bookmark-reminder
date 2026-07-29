import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_model.dart';
import 'supabase_service.dart';

class ItemRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const String _table = 'items';

  /// Realtime stream of the logged-in user's items, newest first.
  Stream<List<Item>> watchItems() {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at')
        .map((rows) => rows.map((row) => Item.fromJson(row)).toList());
  }

  Future<Item> addItem(Item item) async {
    final row = await _client
        .from(_table)
        .insert(item.toInsertJson())
        .select()
        .single();
    return Item.fromJson(row);
  }

  Future<void> updateItem(String id, Item item) async {
    await _client.from(_table).update(item.toUpdateJson()).eq('id', id);
  }

  Future<void> updateStatus(String id, String status) async {
    await _client.from(_table).update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteItem(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}