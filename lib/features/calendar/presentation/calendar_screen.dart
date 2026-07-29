import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/models/item_model.dart';
import '../../../data/services/item_repository.dart';
import '../../item_detail/item_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final ItemRepository _repository = ItemRepository();

  List<Item> _itemsForDay(List<Item> items, DateTime day) {
    return items.where((item) {
      final d = item.reminderDateTime;
      return d != null &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: StreamBuilder<List<Item>>(
        stream: _repository.watchItems(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final selected = _selectedDay ?? _focusedDay;
          final dayItems = _itemsForDay(items, selected);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay ?? _focusedDay, day),
                eventLoader: (day) => _itemsForDay(items, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
              ),
              const Divider(),
              Expanded(
                child: dayItems.isEmpty
                    ? const Center(child: Text('No reminders this day'))
                    : ListView.builder(
                  itemCount: dayItems.length,
                  itemBuilder: (context, index) {
                    final item = dayItems[index];
                    return ListTile(
                      title: Text(item.title),
                      subtitle: Text(item.category),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}