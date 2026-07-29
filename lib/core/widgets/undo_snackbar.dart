import 'package:flutter/material.dart';

void showUndoSnackbar({
  required BuildContext context,
  required String message,
  required VoidCallback onUndo,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(label: 'UNDO', onPressed: onUndo),
    ),
  );
}