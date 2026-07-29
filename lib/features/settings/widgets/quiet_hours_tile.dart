import 'package:flutter/material.dart';
import '../../../data/services/prefs_service.dart';

class QuietHoursTile extends StatefulWidget {
  const QuietHoursTile({super.key});

  @override
  State<QuietHoursTile> createState() => _QuietHoursTileState();
}

class _QuietHoursTileState extends State<QuietHoursTile> {
  bool _enabled = false;
  int _startHour = 22;
  int _endHour = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PrefsService.isQuietHoursEnabled();
    final start = await PrefsService.getQuietStartHour();
    final end = await PrefsService.getQuietEndHour();
    setState(() {
      _enabled = enabled;
      _startHour = start;
      _endHour = end;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Quiet Hours'),
          subtitle: Text(_enabled
              ? 'Silent from ${_startHour}:00 to ${_endHour}:00'
              : 'Notifications fire anytime'),
          value: _enabled,
          onChanged: (v) async {
            await PrefsService.setQuietHoursEnabled(v);
            setState(() => _enabled = v);
          },
        ),
        if (_enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _startHour,
                    decoration: const InputDecoration(labelText: 'Start'),
                    items: List.generate(24, (i) => i)
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h:00')))
                        .toList(),
                    onChanged: (v) async {
                      setState(() => _startHour = v!);
                      await PrefsService.setQuietHours(_startHour, _endHour);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _endHour,
                    decoration: const InputDecoration(labelText: 'End'),
                    items: List.generate(24, (i) => i)
                        .map((h) => DropdownMenuItem(value: h, child: Text('$h:00')))
                        .toList(),
                    onChanged: (v) async {
                      setState(() => _endHour = v!);
                      await PrefsService.setQuietHours(_startHour, _endHour);
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}