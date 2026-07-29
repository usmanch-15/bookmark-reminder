import 'package:flutter/material.dart';
import '../../../data/models/item_model.dart';
import '../../../data/services/item_repository.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  int _completionStreak(List<Item> items) {
    final completedDates = items
        .where((i) => i.status == 'completed')
        .map((i) => DateTime(i.updatedAt.year, i.updatedAt.month, i.updatedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completedDates.isEmpty) return 0;

    int streak = 0;
    var expectedDay = DateTime.now();
    expectedDay = DateTime(expectedDay.year, expectedDay.month, expectedDay.day);

    for (final day in completedDates) {
      if (day == expectedDay || day == expectedDay.subtract(const Duration(days: 1))) {
        streak++;
        expectedDay = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, int> _weeklyOverdueTrend(List<Item> items) {
    final now = DateTime.now();
    final trend = <String, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = '${day.day}/${day.month}';
      final count = items.where((item) {
        return item.status == 'pending' &&
            item.reminderDateTime != null &&
            item.reminderDateTime!.year == day.year &&
            item.reminderDateTime!.month == day.month &&
            item.reminderDateTime!.day == day.day &&
            item.isOverdue;
      }).length;
      trend[label] = count;
    }
    return trend;
  }

  @override
  Widget build(BuildContext context) {
    final repository = ItemRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: StreamBuilder<List<Item>>(
        stream: repository.watchItems(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final pending = items.where((i) => i.status == 'pending').length;
          final completed = items.where((i) => i.status == 'completed').length;
          final archived = items.where((i) => i.status == 'archived').length;
          final overdue = items.where((i) => i.isOverdue).length;
          final streak = _completionStreak(items);

          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          final monthAgo = now.subtract(const Duration(days: 30));
          final completedThisWeek = items
              .where((i) => i.status == 'completed' && i.updatedAt.isAfter(weekAgo))
              .length;
          final completedThisMonth = items
              .where((i) => i.status == 'completed' && i.updatedAt.isAfter(monthAgo))
              .length;

          final categoryTotals = <String, int>{};
          final categoryCompleted = <String, int>{};
          for (final item in items) {
            categoryTotals[item.category] = (categoryTotals[item.category] ?? 0) + 1;
            if (item.status == 'completed') {
              categoryCompleted[item.category] =
                  (categoryCompleted[item.category] ?? 0) + 1;
            }
          }

          final overdueTrend = _weeklyOverdueTrend(items);
          final maxTrendValue = overdueTrend.values.isEmpty
              ? 1
              : overdueTrend.values.reduce((a, b) => a > b ? a : b).clamp(1, 999);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _SummaryCard(label: 'This Week', value: completedThisWeek, icon: Icons.check_circle_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(label: 'This Month', value: completedThisMonth, icon: Icons.calendar_month_outlined)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _SummaryCard(label: 'Streak', value: streak, icon: Icons.local_fire_department, suffix: streak == 1 ? ' day' : ' days')),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(label: 'Overdue', value: overdue, icon: Icons.warning_amber_outlined, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _StatCard(label: 'Pending', value: pending, color: Colors.orange),
              _StatCard(label: 'Completed', value: completed, color: Colors.green),
              _StatCard(label: 'Archived', value: archived, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('Overdue Trend (last 7 days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: overdueTrend.entries.map((e) {
                    final barHeight = (e.value / maxTrendValue) * 70;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: barHeight < 4 ? 4 : barHeight,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(e.key, style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Category Productivity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...categoryTotals.entries.map((e) {
                final done = categoryCompleted[e.key] ?? 0;
                final total = e.value;
                final pct = total == 0 ? 0.0 : done / total;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key),
                          Text('$done/$total'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color? color;
  final String suffix;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color ?? Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text('$value$suffix', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Text('$value', style: const TextStyle(color: Colors.white))),
        title: Text(label),
      ),
    );
  }
}