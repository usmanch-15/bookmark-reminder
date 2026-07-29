import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import 'home_controller.dart';
import 'widgets/filter_sheet.dart';
import '../add_item/add_item_screen.dart';
import '../item_detail/item_detail_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../calendar/presentation/calendar_screen.dart';
import '../stats/presentation/stats_screen.dart';
import '../export_import/presentation/export_import_screen.dart';
import '../../core/constants/categories.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/skeleton_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    // Realtime stream already keeps data fresh; this gives visible
    // pull-to-refresh feedback and a brief pause for UX confirmation.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _confirmBulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected items?'),
        content: Text('${_controller.selectedIds.length} item(s) will be moved to Trash.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) await _controller.bulkDelete();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final inSelectionMode = _controller.selectionMode;

        return Scaffold(
          appBar: inSelectionMode
              ? AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: _controller.clearSelection,
            ),
            title: Text('${_controller.selectedIds.length} selected'),
            actions: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark Complete',
                onPressed: _controller.selectedIds.isEmpty
                    ? null
                    : _controller.bulkComplete,
              ),
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Archive',
                onPressed: _controller.selectedIds.isEmpty
                    ? null
                    : _controller.bulkArchive,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: _controller.selectedIds.isEmpty
                    ? null
                    : _confirmBulkDelete,
              ),
            ],
          )
              : AppBar(
            title: const Text('Bookmark Reminder',
                style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => showFilterSheet(context, _controller),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CalendarScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StatsScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.import_export),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExportImportScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          floatingActionButton: inSelectionMode
              ? null
              : FloatingActionButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddItemScreen())),
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _controller.updateSearch,
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _ViewChip(
                      label: 'All',
                      selected: _controller.savedView == SavedView.all,
                      onTap: () => _controller.updateSavedView(SavedView.all),
                    ),
                    _ViewChip(
                      label: 'Today',
                      selected: _controller.savedView == SavedView.today,
                      onTap: () => _controller.updateSavedView(SavedView.today),
                    ),
                    _ViewChip(
                      label: 'Upcoming',
                      selected: _controller.savedView == SavedView.upcoming,
                      onTap: () => _controller.updateSavedView(SavedView.upcoming),
                    ),
                    _ViewChip(
                      label: 'Overdue',
                      selected: _controller.savedView == SavedView.overdue,
                      onTap: () => _controller.updateSavedView(SavedView.overdue),
                    ),
                    _ViewChip(
                      label: 'Important',
                      selected: _controller.savedView == SavedView.important,
                      onTap: () => _controller.updateSavedView(SavedView.important),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _ViewChip(
                      label: 'All Categories',
                      selected: _controller.selectedCategory == null,
                      onTap: () => _controller.updateCategory(null),
                    ),
                    ...AppCategories.all.map((c) => _ViewChip(
                      label: c,
                      selected: _controller.selectedCategory == c,
                      onTap: () => _controller.updateCategory(c),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<List<Item>>(
                  stream: _controller.itemsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonListLoader();
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final items = _controller.filteredItems(snapshot.data ?? []);

                    if (items.isEmpty) {
                      return EmptyStateWidget(
                        icon: Icons.bookmark_add_outlined,
                        title: 'No reminders found',
                        subtitle: 'Try adjusting filters or add a new item.',
                        actionLabel: 'Add Item',
                        onAction: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const AddItemScreen())),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = _controller.selectedIds.contains(item.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: isSelected
                                ? Theme.of(context).primaryColor.withOpacity(0.1)
                                : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              leading: inSelectionMode
                                  ? Checkbox(
                                value: isSelected,
                                onChanged: (_) =>
                                    _controller.toggleItemSelected(item.id!),
                              )
                                  : (item.pinned
                                  ? const Icon(Icons.push_pin, size: 18)
                                  : null),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(item.title,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${item.category}'
                                    '${item.reminderDateTime != null ? ' • ${_formatDate(item.reminderDateTime!)}' : ''}',
                                style: TextStyle(
                                  color: item.isOverdue ? Colors.red : null,
                                ),
                              ),
                              trailing: inSelectionMode
                                  ? null
                                  : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      item.pinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => _controller.togglePinned(item),
                                  ),
                                  _PriorityDot(priority: item.priority),
                                ],
                              ),
                              onTap: () {
                                if (inSelectionMode) {
                                  _controller.toggleItemSelected(item.id!);
                                } else {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)));
                                }
                              },
                              onLongPress: () {
                                if (!inSelectionMode) _controller.toggleSelectionMode();
                                _controller.toggleItemSelected(item.id!);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ViewChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final int priority;
  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final colors = [Colors.green, Colors.orange, Colors.red];
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(shape: BoxShape.circle, color: colors[priority]),
    );
  }
}