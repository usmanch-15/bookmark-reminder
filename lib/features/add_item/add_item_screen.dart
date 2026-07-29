import 'package:flutter/material.dart';
import 'add_item_controller.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/recurrence_helper.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();
  final AddItemController _controller = AddItemController();
  String? _reminderError;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;

    setState(() => _reminderError = null);
    _controller.setReminderDateTime(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  Future<void> _save() async {
    final formValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      _reminderError = (_controller.recurrence != 'none' && _controller.reminderDateTime == null)
          ? 'Recurring reminders need a start date/time'
          : null;
    });

    if (!formValid || _reminderError != null) return;

    _controller.setTitle(_titleController.text);
    _controller.setNote(_noteController.text);
    _controller.setTagsFromText(_tagsController.text);
    final success = await _controller.saveItem();
    if (success && mounted) {
      Navigator.pop(context);
    } else if (_controller.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_controller.errorMessage!)));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Title must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(labelText: 'Note'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'e.g. urgent, exam, project',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _controller.category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppCategories.all
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => _controller.setCategory(v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _controller.priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Low')),
                    DropdownMenuItem(value: 1, child: Text('Medium')),
                    DropdownMenuItem(value: 2, child: Text('High')),
                  ],
                  onChanged: (v) => _controller.setPriority(v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _controller.recurrence,
                  decoration: const InputDecoration(labelText: 'Repeat'),
                  items: RecurrenceHelper.options
                      .map((r) => DropdownMenuItem(value: r, child: Text(RecurrenceHelper.label(r))))
                      .toList(),
                  onChanged: (v) => _controller.setRecurrence(v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_controller.reminderDateTime == null
                      ? 'Set Reminder Date/Time'
                      : 'Reminder: ${_controller.reminderDateTime!.day}/${_controller.reminderDateTime!.month}/${_controller.reminderDateTime!.year} '
                      '${_controller.reminderDateTime!.hour}:${_controller.reminderDateTime!.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.alarm),
                  onTap: _pickDateTime,
                ),
                if (_reminderError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(_reminderError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                if (_controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _controller.isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _controller.isSaving
                      ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}