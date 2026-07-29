import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/attachment_model.dart';
import '../data/attachment_repository.dart';

class AttachmentPickerWidget extends StatefulWidget {
  final String itemId;
  const AttachmentPickerWidget({super.key, required this.itemId});

  @override
  State<AttachmentPickerWidget> createState() => _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState extends State<AttachmentPickerWidget> {
  final AttachmentRepository _repository = AttachmentRepository();
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      await _repository.uploadFile(
        itemId: widget.itemId,
        file: file,
        fileName: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            _uploading
                ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _pickAndUpload,
            ),
          ],
        ),
        StreamBuilder<List<Attachment>>(
          stream: _repository.watchAttachments(widget.itemId),
          builder: (context, snapshot) {
            final attachments = snapshot.data ?? [];
            if (attachments.isEmpty) {
              return const Text('No attachments yet', style: TextStyle(color: Colors.grey));
            }
            return Column(
              children: attachments.map((a) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(a.fileName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _repository.deleteAttachment(a),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}