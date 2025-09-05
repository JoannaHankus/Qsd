import 'package:flutter/material.dart';
import 'map_screen.dart';

class TaskDialog extends StatefulWidget {
  final TaskData? initial;
  const TaskDialog({super.key, this.initial});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _title;
  late TextEditingController _notes;
  DateTime? _start;
  DateTime? _end;
  bool _alarmOn = false;
  int _hour = 12;
  int _minute = 0;
  double _volume = .5;
  Difficulty _diff = Difficulty.easy;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial?.title ?? '');
    _notes = TextEditingController(text: widget.initial?.notes ?? '');
    _start = widget.initial?.startDate;
    _end = widget.initial?.endDate;
    _alarmOn = widget.initial?.reminderEnabled ?? false;
    if (widget.initial?.reminder != null) {
      _hour = widget.initial!.reminder!.hour;
      _minute = widget.initial!.reminder!.minute;
    }
    _volume = widget.initial?.volume ?? .5;
    _diff = widget.initial?.difficulty ?? Difficulty.easy;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _accept() {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wpisz nazwę zadania')));
      return;
    }
    DateTime? reminder;
    if (_alarmOn) {
      final base = DateTime.now();
      reminder = DateTime(base.year, base.month, base.day, _hour, _minute);
    }
    Navigator.pop(
      context,
      TaskData(
        title: _title.text.trim(),
        startDate: _start,
        endDate: _end,
        reminder: reminder,
        reminderEnabled: _alarmOn,
        volume: _volume,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        difficulty: _diff,
      ),
    );
  }

  Future<void> _openCalendar() async {
    final res = await showDialog<_DateRange>(
      context: context,
      builder: (_) => const _CalendarDialog(),
    );
    if (res != null) setState(() { _start = res.start; _end = res.end; });
  }

  Future<void> _openReminder() async {
    final res = await showDialog<_ReminderData>(
      context: context,
      builder: (_) => _ReminderDialog(initialOn: _alarmOn, hour: _hour, minute: _minute, volume: _volume),
    );
    if (res != null) setState(() { _alarmOn = res.on; _hour = res.hour; _minute = res.minute; _volume = res.volume; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(
        children: [
          // Ramka PNG
          Positioned.fill(
            child: Image.asset('assets/images/add_task_bg.png', fit: BoxFit.fill),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  GestureDetector(onTap: () => Navigator.pop(context), child: Image.asset('assets/icons/arrow.png', width: 24)),
                  const Spacer(),
                  TextButton(onPressed: _accept, child: const Text('Accept')),
                ]),
                const SizedBox(height: 6),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(hintText: 'Task name', border: UnderlineInputBorder()),
                ),
                const SizedBox(height: 12),
                _RowIconText(
                  icon: 'assets/icons/sun.png',
                  label: 'Date',
                  value: _start == null ? '—' : _fmtRange(_start, _end),
                  onTap: _openCalendar,
                ),
                _RowIconText(
                  icon: 'assets/icons/bell.png',
                  label: 'Reminder',
                  value: _alarmOn ? '${_two(_hour)}:${_two(_minute)}' : 'Off',
                  onTap: _openReminder,
                ),
                _RowIconText(
                  icon: 'assets/icons/quill.png',
                  label: 'Notes',
                  value: '',
                  onTap: () {},
                ),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(border: UnderlineInputBorder(), hintText: 'Write a note...'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ShieldPicker(asset: 'assets/icons/easy.png', selected: _diff == Difficulty.easy, onTap: () => setState(() => _diff = Difficulty.easy)),
                    _ShieldPicker(asset: 'assets/icons/medium.png', selected: _diff == Difficulty.medium, onTap: () => setState(() => _diff = Difficulty.medium)),
                    _ShieldPicker(asset: 'assets/icons/hard.png', selected: _diff == Difficulty.hard, onTap: () => setState(() => _diff = Difficulty.hard)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowIconText extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  const _RowIconText({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Image.asset(icon, width: 20),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          if (value.isNotEmpty) Text(value),
        ]),
      ),
    );
  }
}

class _ShieldPicker extends StatelessWidget {
  final String asset;
  final bool selected;
  final VoidCallback onTap;
  const _ShieldPicker({required this.asset, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (selected) Image.asset('assets/icons/selected.png', width: 64),
          Image.asset(asset, width: 48),
        ],
      ),
    );
  }
}

String _fmtRange(DateTime? s, DateTime? e) {
  if (s == null) return '—';
  if (e == null || e.isAtSameMomentAs(s)) return '${_two(s.day)}.${_two(s.month)}.${s.year}';
  return '${_two(s.day)}.${_two(s.month)}.${s.year} – ${_two(e.day)}.${_two(e.month)}.${e.year}';
}
String _two(int n) => n.toString().padLeft(2, '0');

String _fmtDate(DateTime d) =>
    '${_two(d.day)}.${_two(d.month)}.${d.year}';

// ==== Calendar dialog (start/end) – styl jak na screenie ====
class _DateRange { final DateTime start; final DateTime? end; const _DateRange(this.start, this.end); }

class _CalendarDialog extends StatefulWidget { const _CalendarDialog(); @override State<_CalendarDialog> createState() => _CalendarDialogState(); }

class _CalendarDialogState extends State<_CalendarDialog> {
  DateTime _view = DateTime.now();
  DateTime? _start; DateTime? _end;

  void _shiftMonth(int delta) { setState(() => _view = DateTime(_view.year, _view.month + delta, 1)); }
  void _pick(DateTime d) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) { _start = d; _end = null; }
      else if (d.isBefore(_start!)) { _start = d; }
      else { _end = d; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _monthGrid(_view);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/add_task_bg.png', fit: BoxFit.fill)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Image.asset('assets/icons/arrow.png', width: 24)),
              const Spacer(),
              Text('${_view.year}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(onPressed: () => _shiftMonth(-1), icon: const Icon(Icons.chevron_left)),
              Text(_monthName(_view.month)),
              IconButton(onPressed: () => _shiftMonth(1), icon: const Icon(Icons.chevron_right)),
            ]),
            const SizedBox(height: 8),
            _WeekHeader(),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 36),
              itemCount: days.length,
              itemBuilder: (_, i) {
                final d = days[i];
                final inMonth = d.month == _view.month;
                final selected = _start != null && (d.isAtSameMomentAs(DateTime(_start!.year, _start!.month, _start!.day)) || (_end != null && !d.isBefore(_start!) && !d.isAfter(_end!)));
                return GestureDetector(
                  onTap: () => _pick(d),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFEED9B6) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${d.day}', style: TextStyle(color: inMonth ? Colors.black : Colors.black38)),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Start Date'), Text('End Date')]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(_start == null ? '—' : _fmtDate(_start!))),
              Expanded(child: Text(_end == null ? '—' : _fmtDate(_end!))),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _start == null ? null : () => Navigator.pop(context, _DateRange(_start!, _end)),
                child: const Text('Accept'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _WeekHeader extends StatelessWidget { @override Widget build(BuildContext context) { return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [Text('Mon'), Text('Tue'), Text('Wed'), Text('Thu'), Text('Fri'), Text('Sat'), Text('Sun')]); } }

List<DateTime> _monthGrid(DateTime view) {
  final first = DateTime(view.year, view.month, 1);
  final startOffset = (first.weekday + 6) % 7; // pon=1 -> 0
  final start = first.subtract(Duration(days: startOffset));
  return List.generate(42, (i) => DateTime(start.year, start.month, start.day + i));
}

String _monthName(int m) {
  const names = ['January','February','March','April','May','June','July','August','September','October','November','December'];
  return names[m-1];
}

// ==== Reminder dialog – rolki godziny/minuty + toggle + slider ====
class _ReminderData { final bool on; final int hour; final int minute; final double volume; const _ReminderData({required this.on, required this.hour, required this.minute, required this.volume}); }

class _ReminderDialog extends StatefulWidget {
  final bool initialOn; final int hour; final int minute; final double volume;
  const _ReminderDialog({required this.initialOn, required this.hour, required this.minute, required this.volume});
  @override State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  late bool _on; late int _h; late int _m; late double _v;
  @override void initState() { super.initState(); _on = widget.initialOn; _h = widget.hour; _m = widget.minute; _v = widget.volume; }
  @override Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/add_task_bg.png', fit: BoxFit.fill)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: Image.asset('assets/icons/arrow.png', width: 24)),
              const Spacer(),
              const Text('Reminder'),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context, _ReminderData(on: _on, hour: _h, minute: _m, volume: _v)), child: const Text('Accept')),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                height: 120, width: 60,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 36,
                  physics: const FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(initialItem: _h),
                  onSelectedItemChanged: (i) => _h = i,
                  childDelegate: ListWheelChildBuilderDelegate(builder: (_, i) => Center(child: Text(_two(i))), childCount: 24),
                ),
              ),
              const SizedBox(width: 8),
              const Text(':'),
              const SizedBox(width: 8),
              SizedBox(
                height: 120, width: 60,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 36,
                  physics: const FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(initialItem: _m),
                  onSelectedItemChanged: (i) => _m = i,
                  childDelegate: ListWheelChildBuilderDelegate(builder: (_, i) => Center(child: Text(_two(i))), childCount: 60),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [const Text('Set Alarm'), const Spacer(), Switch(value: _on, onChanged: (v) => setState(() => _on = v))]),
            Row(children: [const Text('Alarm volume'), Expanded(child: Slider(value: _v, onChanged: (v) => setState(() => _v = v)))]),
          ]),
        ),
      ]),
    );
  }
}