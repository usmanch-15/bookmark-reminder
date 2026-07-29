import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../data/services/notification_service.dart';
import '../../core/utils/recurrence_helper.dart';
import '../../core/widgets/undo_snackbar.dart';
import '../../core/widgets/conflict_resolution_dialog.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ItemRepository _repository = ItemRepository();
  late String _status;
  late bool _pinned;
  late DateTime _loadedAt;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
    _pinned = widget.item.pinned;
    _loadedAt = widget.item.updatedAt;
  }

  Future<bool> _checkConflictBeforeWrite() async {
    final serverVersion = await _repository.checkForConflict(widget.item.id!, _loadedAt);
    if (serverVersion == null) return true;

    if (!mounted) return false;
    final choice = await showConflictDialog(
      context: context,
      myVersion: widget.item,
      serverVersion: serverVersion,
    );
    if (choice == ConflictChoice.keepServer) {
      setState(() {
        _status = serverVersion.status;
        _pinned = serverVersion.pinned;
        _loadedAt = serverVersion.updatedAt;
      });
      return false;
    }
    _loadedAt = DateTime.now();
    return true;
  }

  Future<void> _togglePin() async {
    final proceed = await _checkConflictBeforeWrite();
    if (!proceed) return;
    widget.item.pinned = !_pinned;
    await _repository.updateItem(widget.item.id!, widget.item);
    setState(() => _pinned = widget.item.pinned);
  }

  Future<void> _markComplete() async {
    final proceed = await _checkConflictBeforeWrite();
    if (!proceed) return;

    final item = widget.item;

    if (item.isRecurring && item.reminderDateTime != null) {
      final nextDate = RecurrenceHelper.nextOccurrence(
        currentDate: item.reminderDateTime!,
        recurrence: item.recurrence,
        interval: item.recurrenceInterval,
      );

      if (nextDate != null) {
        item.reminderDateTime = nextDate;
        await _repository.updateItem(item.id!, item);
        await NotificationService().scheduleReminder(
          id: item.notificationId,
          title: item.title,
          body: item.note.isEmpty ? 'Reminder' : item.note,
          dateTime: nextDate,
          priority: item.priority,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Next reminder set: ${_formatDate(nextDate)}')),
          );
          Navigator.pop(context);
        }
        return;
      }
    }

    await _repository.updateStatus(item.id!, 'completed');
    await NotificationService().cancelReminder(item.notificationId);
    setState(() => _status = 'completed');

    if (mounted) {
      showUndoSnackbar(
        context: context,
        message: 'Marked as complete',
        onUndo: () async {
          await _repository.updateStatus(item.id!, 'pending');
          if (mounted) setState(() => _status = 'pending');
        },
      );
    }
  }

  Future<void> _snooze() async {
    final item = widget.item;
    await NotificationService().snoozeReminder(
      id: item.notificationId,
      title: item.title,
      body: item.note.isEmpty ? 'Reminder' : item.note,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snoozed for 10 minutes')),
      );
    }
  }

  Future<void> _archive() async {
    await _repository.updateStatus(widget.item.id!, 'archived');
    await NotificationService().cancelReminder(widget.item.notificationId);
    if (!mounted) return;

    showUndoSnackbar(
      context: context,
      message: 'Item archived',
      onUndo: () => _repository.updateStatus(widget.item.id!, 'pending'),
    );
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await NotificationService().cancelReminder(widget.item.notificationId);
    await _repository.updateStatus(widget.item.id!, 'deleted');
    if (!mounted) return;

    showUndoSnackbar(
      context: context,
      message: 'Item moved to Trash',
      onUndo: () => _repository.updateStatus(widget.item.id!, 'pending'),
    );
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Detail'),
        actions: [
          IconButton(
            icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: _togglePin,
          ),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(item.category, style: const TextStyle(color: Colors.grey)),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: item.tags
                    .map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            if (item.note.isNotEmpty) Text(item.note),
            const SizedBox(height: 16),
            if (item.reminderDateTime != null)
              Text('Reminder: ${_formatDate(item.reminderDateTime!)}',
                  style: TextStyle(color: item.isOverdue ? Colors.red : null)),
            if (item.isRecurring)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Repeats: ${RecurrenceHelper.label(item.recurrence)}',
                    style: const TextStyle(color: Colors.blueGrey)),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_status != 'completed')
                  ElevatedButton(
                    onPressed: _markComplete,
                    child: Text(item.isRecurring ? 'Complete & Reschedule' : 'Mark Complete'),
                  ),
                OutlinedButton.icon(
                  onPressed: _snooze,
                  icon: const Icon(Icons.snooze),
                  label: const Text('Snooze 10 min'),
                ),
                OutlinedButton(
                  onPressed: _archive,
                  child: const Text('Archive'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}