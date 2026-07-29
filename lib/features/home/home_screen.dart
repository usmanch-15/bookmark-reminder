import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';
import '../../data/services/item_repository.dart';
import '../add_item/add_item_screen.dart';
import '../item_detail/item_detail_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/constants/categories.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ItemRepository _repository = ItemRepository();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmark Reminder',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddItemScreen()),
        ),
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
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...AppCategories.all.map((c) => _CategoryChip(
                  label: c,
                  selected: _selectedCategory == c,
                  onTap: () => setState(() => _selectedCategory = c),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _repository.watchItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var items = (snapshot.data ?? []).where((item) {
                  final matchesSearch =
                      item.title.toLowerCase().contains(_searchQuery) ||
                          item.note.toLowerCase().contains(_searchQuery);
                  final matchesCategory = _selectedCategory == null ||
                      item.category == _selectedCategory;
                  return matchesSearch &&
                      matchesCategory &&
                      item.status == 'pending';
                }).toList();

                items.sort((a, b) {
                  if (a.reminderDateTime == null) return 1;
                  if (b.reminderDateTime == null) return -1;
                  return a.reminderDateTime!.compareTo(b.reminderDateTime!);
                });

                if (items.isEmpty) {
                  return const Center(child: Text('Koi item nahi mila'));
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        title: Text(item.title,
                            style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${item.category}'
                              '${item.reminderDateTime != null ? ' • ${_formatDate(item.reminderDateTime!)}' : ''}',
                        ),
                        trailing: _PriorityDot(priority: item.priority),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(item: item)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors[priority],
      ),
    );
  }
}