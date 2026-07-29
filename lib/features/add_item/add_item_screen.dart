import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/supabase_service.dart';
import '../../core/constants/categories.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final ItemRepository _repository = ItemRepository();

  String _category = AppCategories.all.first;
  DateTime? _reminderDateTime;
  int _priority = 1;
  bool _saving = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _reminderDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveItem() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Title zaroori hai')));
      return;
    }

    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final item = Item(
      userId: userId,
      title: _titleController.text.trim(),
      note: _noteController.text.trim(),
      category: _category,
      reminderDateTime: _reminderDateTime,
      priority: _priority,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    try {
      final savedItem = await _repository.addItem(item);

      if (_reminderDateTime != null) {
        await NotificationService().scheduleReminder(
          id: savedItem.notificationId,
          title: savedItem.title,
          body: savedItem.note.isEmpty ? 'Reminder' : savedItem.note,
          dateTime: _reminderDateTime!,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: AppCategories.all
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Low')),
              DropdownMenuItem(value: 1, child: Text('Medium')),
              DropdownMenuItem(value: 2, child: Text('High')),
            ],
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_reminderDateTime == null
                ? 'Set Reminder Date/Time'
                : 'Reminder: ${_reminderDateTime!.day}/${_reminderDateTime!.month}/${_reminderDateTime!.year} '
                '${_reminderDateTime!.hour}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.alarm),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _saveItem,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _saving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
