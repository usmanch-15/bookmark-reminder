import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Completed'),
              Tab(text: 'Archived'),
              Tab(text: 'Trash'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ItemStatusList(status: 'completed'),
            _ItemStatusList(status: 'archived'),
            _ItemStatusList(status: 'deleted', isTrash: true),
          ],
        ),
      ),
    );
  }
}

class _ItemStatusList extends StatelessWidget {
  final String status;
  final bool isTrash;
  const _ItemStatusList({required this.status, this.isTrash = false});

  static const int restoreWindowDays = 30;

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final repository = ItemRepository();

    return StreamBuilder<List<Item>>(
      stream: repository.watchItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonListLoader();
        }

        final items = (snapshot.data ?? [])
            .where((i) => i.status == status)
            .toList()
          ..sort((a, b) => (b.deletedAt ?? b.updatedAt).compareTo(a.deletedAt ?? a.updatedAt));

        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: EmptyStateWidget(
                    icon: isTrash ? Icons.delete_outline : Icons.inbox_outlined,
                    title: 'No $status items',
                    subtitle: isTrash
                        ? 'Deleted items stay here for $restoreWindowDays days.'
                        : 'Items you $status will show up here.',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              String? subtitle = item.category;

              if (isTrash) {
                final deletedAt = item.deletedAt ?? item.updatedAt;
                final daysLeft = restoreWindowDays - DateTime.now().difference(deletedAt).inDays;
                subtitle = daysLeft > 0
                    ? '$daysLeft days left to restore'
                    : 'Eligible for permanent deletion';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(subtitle ?? ''),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'restore') {
                        await repository.updateStatus(item.id!, 'pending');
                      } else if (value == 'delete') {
                        await repository.updateStatus(item.id!, 'deleted');
                      } else if (value == 'delete_forever') {
                        await repository.hardDelete(item.id!);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'restore', child: Text('Restore')),
                      if (isTrash)
                        const PopupMenuItem(value: 'delete_forever', child: Text('Delete Forever'))
                      else
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}