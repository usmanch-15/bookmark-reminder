import 'package:flutter/material.dart';
import '../../../data/services/prefs_service.dart';
import '../../../core/sync/pending_write_queue.dart';
import '../../../core/sync/sync_service.dart';

class SyncStatusTile extends StatefulWidget {
  const SyncStatusTile({super.key});

  @override
  State<SyncStatusTile> createState() => _SyncStatusTileState();
}

class _SyncStatusTileState extends State<SyncStatusTile> {
  DateTime? _lastSync;
  bool _hasPending = false;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lastSync = await PrefsService.getLastSync();
    final hasPending = await PendingWriteQueue.hasPending;
    if (!mounted) return;
    setState(() {
      _lastSync = lastSync;
      _hasPending = hasPending;
    });
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await SyncService().flushQueuePublic();
    await _load();
    if (!mounted) return;
    setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final syncText = _lastSync != null
        ? 'Last synced: ${_lastSync!.hour.toString().padLeft(2, '0')}:${_lastSync!.minute.toString().padLeft(2, '0')}'
        : 'Not synced yet';

    return ListTile(
      leading: Icon(
        _hasPending ? Icons.sync_problem : Icons.cloud_done_outlined,
        color: _hasPending ? Colors.orange : Colors.green,
      ),
      title: Text(_hasPending ? 'Pending changes waiting to sync' : 'All changes synced'),
      subtitle: Text(syncText),
      trailing: _hasPending
          ? (_retrying
          ? const SizedBox(
          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(onPressed: _retry, child: const Text('Retry')))
          : null,
    );
  }
}