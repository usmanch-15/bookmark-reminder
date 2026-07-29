import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../core/widgets/empty_state_widget.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  static const int restoreWindowDays = 30;

  @override
  Widget build(BuildContext context) {
    final repository = ItemRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: StreamBuilder<List<Item>>(
        stream: repository.watchItems(),
        builder: (context, snapshot) {
          final items = (snapshot.data ?? [])
              .where((i) => i.status == 'deleted')
              .toList()
            ..sort((a, b) => (b.deletedAt ?? b.updatedAt)
                .compareTo(a.deletedAt ?? a.updatedAt));

          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.delete_outline,
              title: 'Trash is empty',
              subtitle: 'Deleted items stay here for 30 days before permanent removal.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final deletedAt = item.deletedAt ?? item.updatedAt;
              final daysLeft = restoreWindowDays -
                  DateTime.now().difference(deletedAt).inDays;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(daysLeft > 0
                      ? '$daysLeft days left to restore'
                      : 'Eligible for permanent deletion'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'restore') {
                        await repository.updateStatus(item.id!, 'pending');
                      } else if (value == 'delete_forever') {
                        await repository.hardDelete(item.id!);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'restore', child: Text('Restore')),
                      PopupMenuItem(
                          value: 'delete_forever',
                          child: Text('Delete Forever')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}