import 'package:home_widget/home_widget.dart';
import '../../data/models/item_model.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'ReminderWidgetProvider';

  /// Call this whenever items change (add/complete/delete) to refresh
  /// the home screen widget with the next 3 upcoming reminders.
  static Future<void> updateWidget(List<Item> upcomingItems) async {
    final top3 = upcomingItems.take(3).toList();

    for (int i = 0; i < 3; i++) {
      final title = i < top3.length ? top3[i].title : '';
      await HomeWidget.saveWidgetData<String>('reminder_title_$i', title);
    }

    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}