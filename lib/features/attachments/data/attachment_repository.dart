import 'dart:io';
import '../../../data/services/supabase_service.dart';
import 'attachment_model.dart';

class AttachmentRepository {
  final _client = SupabaseService.client;
  static const _bucket = 'attachments';
  static const _table = 'item_attachments';

  Future<Attachment> uploadFile({
    required String itemId,
    required File file,
    required String fileName,
  }) async {
    final userId = SupabaseService.currentUser!.id;
    final storagePath = '$userId/$itemId/$fileName';

    await _client.storage.from(_bucket).upload(storagePath, file);
    final publicUrl = _client.storage.from(_bucket).getPublicUrl(storagePath);

    final row = await _client
        .from(_table)
        .insert({
      'item_id': itemId,
      'user_id': userId,
      'file_name': fileName,
      'file_url': publicUrl,
    })
        .select()
        .single();

    return Attachment.fromJson(row);
  }

  Stream<List<Attachment>> watchAttachments(String itemId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('item_id', itemId)
        .map((rows) => rows.map((r) => Attachment.fromJson(r)).toList());
  }

  Future<void> deleteAttachment(Attachment attachment) async {
    final userId = SupabaseService.currentUser!.id;
    final storagePath = '$userId/${attachment.itemId}/${attachment.fileName}';
    await _client.storage.from(_bucket).remove([storagePath]);
    await _client.from(_table).delete().eq('id', attachment.id);
  }
}