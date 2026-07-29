class Item {
  String? id;
  String userId;
  String title;
  String note;
  String category;
  DateTime? reminderDateTime;
  int priority; // 0 = Low, 1 = Medium, 2 = High
  String status; // pending, completed, archived, deleted
  List<String> tags;
  String recurrence;
  int recurrenceInterval;
  bool pinned;
  DateTime? deletedAt;
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
    this.tags = const [],
    this.recurrence = 'none',
    this.recurrenceInterval = 1,
    this.pinned = false,
    this.deletedAt,
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
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      recurrence: json['recurrence'] as String? ?? 'none',
      recurrenceInterval: json['recurrence_interval'] as int? ?? 1,
      pinned: json['pinned'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
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
      'tags': tags,
      'recurrence': recurrence,
      'recurrence_interval': recurrenceInterval,
      'pinned': pinned,
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
      'tags': tags,
      'recurrence': recurrence,
      'recurrence_interval': recurrenceInterval,
      'pinned': pinned,
      'deleted_at': deletedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  bool get isRecurring => recurrence != 'none';
  bool get isOverdue =>
      status == 'pending' &&
          reminderDateTime != null &&
          reminderDateTime!.isBefore(DateTime.now());

  int get notificationId => (id ?? '').hashCode;
}