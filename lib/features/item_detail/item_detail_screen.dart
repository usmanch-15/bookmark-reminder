import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../data/services/notification_service.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ItemRepository _repository = ItemRepository();
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
  }

  Future<void> _markComplete() async {
    await _repository.updateStatus(widget.item.id!, 'completed');
    await NotificationService().cancelReminder(widget.item.notificationId);
    setState(() => _status = 'completed');
  }

  Future<void> _archive() async {
    await _repository.updateStatus(widget.item.id!, 'archived');
    await NotificationService().cancelReminder(widget.item.notificationId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await NotificationService().cancelReminder(widget.item.notificationId);
    await _repository.deleteItem(widget.item.id!);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Detail'),
        actions: [
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(item.category, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (item.note.isNotEmpty) Text(item.note),
            const SizedBox(height: 16),
            if (item.reminderDateTime != null)
              Text(
                  'Reminder: ${item.reminderDateTime!.day}/${item.reminderDateTime!.month}/${item.reminderDateTime!.year} '
                      '${item.reminderDateTime!.hour}:${item.reminderDateTime!.minute.toString().padLeft(2, '0')}'),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_status != 'completed')
                  ElevatedButton(
                    onPressed: _markComplete,
                    child: const Text('Mark Complete'),
                  ),
                const SizedBox(width: 12),
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