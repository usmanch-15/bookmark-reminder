import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Completed'),
              Tab(text: 'Archived'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ItemStatusList(status: 'completed'),
            _ItemStatusList(status: 'archived'),
          ],
        ),
      ),
    );
  }
}

class _ItemStatusList extends StatelessWidget {
  final String status;
  const _ItemStatusList({required this.status});

  @override
  Widget build(BuildContext context) {
    final repository = ItemRepository();

    return StreamBuilder<List<Item>>(
      stream: repository.watchItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = (snapshot.data ?? [])
            .where((i) => i.status == status)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (items.isEmpty) {
          return Center(child: Text('No $status items'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.category),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'restore') {
                      await repository.updateStatus(item.id!, 'pending');
                    } else if (value == 'delete') {
                      await repository.deleteItem(item.id!);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'restore', child: Text('Restore')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}