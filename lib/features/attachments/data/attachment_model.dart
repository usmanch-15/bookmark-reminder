class Attachment {
  final String id;
  final String itemId;
  final String fileName;
  final String fileUrl;
  final DateTime createdAt;

  Attachment({
    required this.id,
    required this.itemId,
    required this.fileName,
    required this.fileUrl,
    required this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      fileName: json['file_name'] as String,
      fileUrl: json['file_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}