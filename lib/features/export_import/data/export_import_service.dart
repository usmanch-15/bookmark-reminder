import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/item_model.dart';
import '../../../data/services/item_repository.dart';
import '../../../data/services/supabase_service.dart';

class ExportImportService {
  Future<String> exportAsJson(List<Item> items) async {
    final List<Map<String, dynamic>> data = items
        .map((Item i) => <String, dynamic>{...i.toInsertJson(), 'id': i.id})
        .toList();
    final String jsonString = jsonEncode(data);

    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/bookmark_reminder_export.json');
    await file.writeAsString(jsonString);
    await Share.shareXFiles(<XFile>[XFile(file.path)]);
    return file.path;
  }

  Future<String> exportAsCsv(List<Item> items) async {
    final List<List<dynamic>> rows = <List<dynamic>>[
      <String>['title', 'note', 'category', 'reminder_date_time', 'priority', 'status', 'tags'],
      ...items.map((Item i) => <dynamic>[
        i.title,
        i.note,
        i.category,
        i.reminderDateTime?.toIso8601String() ?? '',
        i.priority,
        i.status,
        i.tags.join('|'),
      ]),
    ];

    final String csvString = const ListToCsvConverter().convert(rows);
    final Directory dir = await getTemporaryDirectory();
    final File file = File('${dir.path}/bookmark_reminder_export.csv');
    await file.writeAsString(csvString);
    await Share.shareXFiles(<XFile>[XFile(file.path)]);
    return file.path;
  }

  Future<int> importFromFile(String path, ItemRepository repository) async {
    final String? userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final File file = File(path);
    final String content = await file.readAsString();
    int importedCount = 0;

    if (path.endsWith('.json')) {
      final List<dynamic> data = jsonDecode(content) as List<dynamic>;
      for (final dynamic row in data) {
        final Map<String, dynamic> map = row as Map<String, dynamic>;
        final DateTime now = DateTime.now();
        final Item item = Item(
          userId: userId,
          title: (map['title'] ?? 'Untitled') as String,
          note: (map['note'] ?? '') as String,
          category: (map['category'] ?? 'Personal') as String,
          reminderDateTime: map['reminder_date_time'] != null &&
              map['reminder_date_time'].toString().isNotEmpty
              ? DateTime.tryParse(map['reminder_date_time'].toString())
              : null,
          priority: (map['priority'] ?? 1) as int,
          status: 'pending',
          tags: map['tags'] != null ? List<String>.from(map['tags'] as List) : <String>[],
          createdAt: now,
          updatedAt: now,
        );
        await repository.addItem(item);
        importedCount++;
      }
    } else if (path.endsWith('.csv')) {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(content, eol: '\n');
      for (int i = 1; i < rows.length; i++) {
        final List<dynamic> row = rows[i];
        if (row.length < 6) continue;
        final DateTime now = DateTime.now();
        final Item item = Item(
          userId: userId,
          title: row[0].toString(),
          note: row[1].toString(),
          category: row[2].toString(),
          reminderDateTime:
          row[3].toString().isNotEmpty ? DateTime.tryParse(row[3].toString()) : null,
          priority: int.tryParse(row[4].toString()) ?? 1,
          status: 'pending',
          tags: row[5].toString().isNotEmpty ? row[5].toString().split('|') : <String>[],
          createdAt: now,
          updatedAt: now,
        );
        await repository.addItem(item);
        importedCount++;
      }
    } else {
      throw Exception('Unsupported file type');
    }

    return importedCount;
  }
}