import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/services/item_repository.dart';
import '../data/export_import_service.dart';

class ExportImportScreen extends StatefulWidget {
  const ExportImportScreen({super.key});

  @override
  State<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends State<ExportImportScreen> {
  final ExportImportService _service = ExportImportService();
  final ItemRepository _repository = ItemRepository();
  bool _busy = false;
  String? _status;
  bool _isError = false;

  Future<void> _exportJson() async {
    setState(() { _busy = true; _status = null; });
    try {
      final items = await _repository.watchItems().first;
      await _service.exportAsJson(items);
      setState(() { _status = 'JSON export ready — share sheet opened.'; _isError = false; });
    } catch (e) {
      setState(() { _status = 'Export failed. Please check your connection and try again.'; _isError = true; });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() { _busy = true; _status = null; });
    try {
      final items = await _repository.watchItems().first;
      await _service.exportAsCsv(items);
      setState(() { _status = 'CSV export ready — share sheet opened.'; _isError = false; });
    } catch (e) {
      setState(() { _status = 'Export failed. Please check your connection and try again.'; _isError = true; });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickImportFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() { _busy = true; _status = null; });
    try {
      final count = await _service.importFromFile(result.files.single.path!, _repository);
      setState(() { _status = '$count items imported successfully.'; _isError = false; });
    } catch (e) {
      setState(() { _status = 'Import failed. Make sure the file format is correct.'; _isError = true; });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export / Import')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Export your reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy ? null : _exportJson,
              icon: const Icon(Icons.code),
              label: const Text('Export as JSON'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _busy ? null : _exportCsv,
              icon: const Icon(Icons.table_chart),
              label: const Text('Export as CSV'),
            ),
            const SizedBox(height: 24),
            const Text('Import reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pickImportFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Pick JSON or CSV file'),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(_isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: _isError ? Colors.red : Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_status!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}