import 'package:flutter/material.dart';
import '../../data/models/item_model.dart';

enum ConflictChoice { keepMine, keepServer }

Future<ConflictChoice?> showConflictDialog({
  required BuildContext context,
  required Item myVersion,
  required Item serverVersion,
}) {
  return showDialog<ConflictChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Item was changed elsewhere'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This item was updated on another device since you opened it. Which version do you want to keep?',
          ),
          const SizedBox(height: 16),
          Text('Your version: "${myVersion.title}"',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Server version: "${serverVersion.title}"',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictChoice.keepServer),
          child: const Text('Keep Server Version'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, ConflictChoice.keepMine),
          child: const Text('Keep My Version'),
        ),
      ],
    ),
  );
}