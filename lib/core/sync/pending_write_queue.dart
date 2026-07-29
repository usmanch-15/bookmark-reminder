import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A minimal offline queue: stores pending "add item" operations as JSON
/// strings when the device is offline, and replays them once back online.
class PendingWriteQueue {
  static const _key = 'pending_item_writes';

  static Future<void> enqueue(Map<String, dynamic> itemJson) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.add(jsonEncode(itemJson));
    await prefs.setStringList(_key, list);
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<bool> get hasPending async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.isNotEmpty;
  }
}