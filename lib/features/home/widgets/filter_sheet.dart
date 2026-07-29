import 'package:flutter/material.dart';
import '../home_controller.dart';

Future<void> showFilterSheet(BuildContext context, HomeController controller) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter Reminders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Priority'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: controller.selectedPriority == null,
                      onSelected: (_) => setModalState(
                              () => controller.updatePriority(null)),
                    ),
                    ChoiceChip(
                      label: const Text('Low'),
                      selected: controller.selectedPriority == 0,
                      onSelected: (_) =>
                          setModalState(() => controller.updatePriority(0)),
                    ),
                    ChoiceChip(
                      label: const Text('Medium'),
                      selected: controller.selectedPriority == 1,
                      onSelected: (_) =>
                          setModalState(() => controller.updatePriority(1)),
                    ),
                    ChoiceChip(
                      label: const Text('High'),
                      selected: controller.selectedPriority == 2,
                      onSelected: (_) =>
                          setModalState(() => controller.updatePriority(2)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Date Range'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(controller.dateRange == null
                      ? 'Pick a date range'
                      : '${controller.dateRange!.start.day}/${controller.dateRange!.start.month} - '
                      '${controller.dateRange!.end.day}/${controller.dateRange!.end.month}'),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (range != null) {
                      setModalState(() => controller.updateDateRange(range));
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          controller.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}