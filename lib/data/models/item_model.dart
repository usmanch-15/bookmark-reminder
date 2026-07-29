class Item {
  String? id;
  String userId;
  String title;
  String note;
  String category;
  DateTime? reminderDateTime;
  int priority; // 0 = Low, 1 = Medium, 2 = High
  String status; // pending, completed, archived
  DateTime createdAt;
  DateTime updatedAt;

  Item({
    this.id,
    required this.userId,
    required this.title,
    this.note = '',
    required this.category,
    this.reminderDateTime,
    this.priority = 1,
    this.status = 'pending',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      note: json['note'] as String? ?? '',
      category: json['category'] as String,
      reminderDateTime: json['reminder_date_time'] != null
          ? DateTime.parse(json['reminder_date_time'] as String)
          : null,
      priority: json['priority'] as int? ?? 1,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'note': note,
      'category': category,
      'reminder_date_time': reminderDateTime?.toIso8601String(),
      'priority': priority,
      'status': status,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'note': note,
      'category': category,
      'reminder_date_time': reminderDateTime?.toIso8601String(),
      'priority': priority,
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// A stable local integer id derived from the Supabase UUID.
  /// Used for scheduling/cancelling local notifications.
  int get notificationId => (id ?? '').hashCode;
}