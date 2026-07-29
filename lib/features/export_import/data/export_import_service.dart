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
    final data = items.map((i) => {...i.toInsertJson(), 'id': i.id}).toList();
    final jsonString = jsonEncode(data);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bookmark_reminder_export.json');
    await file.writeAsString(jsonString);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    return file.path;
  }

  Future<String> exportAsCsv(List<Item> items) async {
    final rows = <List<dynamic>>[
      ['title', 'note', 'category', 'reminder_date_time', 'priority', 'status', 'tags'],
      ...items.map((i) => [
        i.title,
        i.note,
        i.category,
        i.reminderDateTime?.toIso8601String() ?? '',
        i.priority,
        i.status,
        i.tags.join('|'),
      ]),
    ];

    final csvString = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bookmark_reminder_export.csv');
    await file.writeAsString(csvString);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    return file.path;
  }

  /// Reads a JSON or CSV file and inserts items into Supabase.
  /// Returns the number of items successfully imported.
  Future<int> importFromFile(String path, ItemRepository repository) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    final file = File(path);
    final content = await file.readAsString();
    int importedCount = 0;

    if (path.endsWith('.json')) {
      final List<dynamic> data = jsonDecode(content);
      for (final row in data) {
        final now = DateTime.now();
        final item = Item(
          userId: userId,
          title: row['title'] ?? 'Untitled',
          note: row['note'] ?? '',
          category: row['category'] ?? 'Personal',
          reminderDateTime: row['reminder_date_time'] != null &&
              row['reminder_date_time'].toString().isNotEmpty
              ? DateTime.tryParse(row['reminder_date_time'])
              : null,
          priority: row['priority'] ?? 1,
          status: 'pending',
          tags: row['tags'] != null ? List<String>.from(row['tags']) : [],
          createdAt: now,
          updatedAt: now,
        );
        await repository.addItem(item);
        importedCount++;
      }
    } else if (path.endsWith('.csv')) {
      final rows = const CsvToListConverter().convert(content, eol: '\n');
      // Skip header row (index 0)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 6) continue;
        final now = DateTime.now();
        final item = Item(
          userId: userId,
          title: row[0].toString(),
          note: row[1].toString(),
          category: row[2].toString(),
          reminderDateTime: row[3].toString().isNotEmpty
              ? DateTime.tryParse(row[3].toString())
              : null,
          priority: int.tryParse(row[4].toString()) ?? 1,
          status: 'pending',
          tags: row[5].toString().isNotEmpty
              ? row[5].toString().split('|')
              : [],
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