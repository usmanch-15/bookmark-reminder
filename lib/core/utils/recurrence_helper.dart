class RecurrenceHelper {
  /// Calculates the next reminder date based on recurrence type.
  static DateTime? nextOccurrence({
    required DateTime currentDate,
    required String recurrence,
    required int interval,
  }) {
    switch (recurrence) {
      case 'daily':
        return currentDate.add(Duration(days: interval));
      case 'weekly':
        return currentDate.add(Duration(days: 7 * interval));
      case 'monthly':
        return DateTime(
          currentDate.year,
          currentDate.month + interval,
          currentDate.day,
          currentDate.hour,
          currentDate.minute,
        );
      case 'none':
      default:
        return null;
    }
  }

  static const List<String> options = ['none', 'daily', 'weekly', 'monthly'];

  static String label(String value) {
    switch (value) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Does not repeat';
    }
  }
}