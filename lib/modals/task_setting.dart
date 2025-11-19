import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../notifications/local_notifs.dart';

const kDarkGreen = Color(0xFF004643);

class TaskSetting extends StatefulWidget {
  /// null = create, non-null = edit existing doc
  final String? editDocId;
  /// Firestore document data used to prefill when editing
  final Map<String, dynamic>? existing;

  const TaskSetting({super.key, this.editDocId, this.existing});

  @override
  State<TaskSetting> createState() => _TaskSettingState();
}

class _TaskSettingState extends State<TaskSetting> {
  int _step = 0;

  // Step 1: plant selection
  final Set<String> _selectedPlantIds = {};
  final Map<String, String> _selectedPlantNames = {}; // id -> name
  final Map<String, String> _selectedPlantTypes = {}; // id -> type

  // Step 2: task type
  String _taskType = 'watering'; // watering | fertilizing | pruning

  // Step 3: time + date
  DateTime? _pickedDate = DateTime.now();
  TimeOfDay _pickedTime = const TimeOfDay(hour: 8, minute: 0);

  // Repeat (simple)
  String _repeat = 'once'; // once | daily | every | weekly
  int _everyNDays = 2;
  int _weeklyWeekday = DateTime.now().weekday % 7; // 0 Sun .. 6 Sat
  DateTime? _endDate; // optional end for repeats

  // Controllers for manual time input
  final _hourCtrl = TextEditingController(text: '8');
  final _minuteCtrl = TextEditingController(text: '00');
  String _amPm = 'AM';

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex == null) return; // create mode

    // Step 1: selected plants
    final ids = (ex['plantIds'] is List) ? List<String>.from(ex['plantIds']) : <String>[];
    final names = (ex['plantNames'] is List) ? List<String>.from(ex['plantNames']) : <String>[];
    _selectedPlantIds.addAll(ids);
    for (int i = 0; i < ids.length && i < names.length; i++) {
      _selectedPlantNames[ids[i]] = names[i];
    }

    // Step 2: type
    _taskType = (ex['taskType'] as String?) ?? 'watering';

    // Step 3: date/time
    final ts = ex['date'];
    if (ts is Timestamp) _pickedDate = ts.toDate();
    final timeStr = ex['time']?.toString();
    final parsedTime = timeStr != null ? _parseTime(timeStr) : null;
    if (parsedTime != null) {
      _pickedTime = parsedTime;
      _updateTimeControllers(_pickedTime);
    }

    _repeat = (ex['repeat'] as String?) ?? 'once';
    _everyNDays = (ex['everyNDays'] as int?) ?? _everyNDays;
    _weeklyWeekday = (ex['weeklyWeekday'] as int?) ?? _weeklyWeekday;

    final endRaw = ex['endDate'];
    if (endRaw is Timestamp) _endDate = endRaw.toDate();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  void _updateTimeControllers(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    _hourCtrl.text = hour.toString();
    _minuteCtrl.text = time.minute.toString().padLeft(2, '0');
    _amPm = time.period == DayPeriod.am ? 'AM' : 'PM';
  }

  TimeOfDay _getTimeFromControllers() {
    int hour = int.tryParse(_hourCtrl.text) ?? 8;
    int minute = int.tryParse(_minuteCtrl.text) ?? 0;

    // Clamp values
    if (hour < 1) hour = 1;
    if (hour > 12) hour = 12;
    if (minute < 0) minute = 0;
    if (minute > 59) minute = 59;

    // Convert to 24-hour
    int hour24 = hour;
    if (_amPm == 'PM' && hour != 12) hour24 += 12;
    if (_amPm == 'AM' && hour == 12) hour24 = 0;

    return TimeOfDay(hour: hour24, minute: minute);
  }

  TimeOfDay? _parseTime(String s) {
    final r = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
    final m = r.firstMatch(s.trim());
    if (m == null) return null;
    int h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final ap = m.group(3)!.toUpperCase();
    if (ap == 'PM' && h != 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: min);
  }

  /// Get watering interval based on plant type (in days)
  int _getWateringInterval(String plantType) {
    switch (plantType.toLowerCase()) {
      case 'vine':
        return 2; // High water needs
      case 'leaf':
        return 3; // Moderate water needs
      case 'root':
        return 4; // Deep watering, less frequent
      case 'fruit':
        return 2; // Consistent moisture
      default:
        return 3; // Default
    }
  }

  /// Apply smart watering preset
  void _applyWateringPreset() {
    if (_selectedPlantTypes.isEmpty) return;

    // Get the most common interval from selected plants
    final intervals = _selectedPlantTypes.values.map(_getWateringInterval).toList();
    final avgInterval = (intervals.reduce((a, b) => a + b) / intervals.length).round();

    setState(() {
      if (avgInterval == 1) {
        _repeat = 'daily';
        _everyNDays = 1; // Make sure this is set
      } else {
        _repeat = 'every';
        _everyNDays = avgInterval;
      }
      // Set time to 8:00 AM
      _pickedTime = const TimeOfDay(hour: 8, minute: 0);
      _hourCtrl.text = '8';
      _minuteCtrl.text = '00';
      _amPm = 'AM';
      // Set date to tomorrow
      _pickedDate = DateTime.now().add(const Duration(days: 1));
      // Clear end date when applying preset
      _endDate = null;
    });

    _showSnackBar('Applied recommended watering schedule: Every $avgInterval day${avgInterval > 1 ? 's' : ''} at 8:00 AM');
  }

  /// Build the **first** occurrence from selected date/time, always in the future.
  DateTime _computeFirstOccurrence({bool alignWeekly = false}) {
    final base = _pickedDate ?? DateTime.now();
    final currentTime = _getTimeFromControllers();
    var first = DateTime(base.year, base.month, base.day, currentTime.hour, currentTime.minute);

    // If weekly, align to the chosen weekday (0=Sun..6=Sat)
    if (alignWeekly) {
      while ((first.weekday % 7) != (_weeklyWeekday % 7)) {
        first = first.add(const Duration(days: 1));
      }
    }

    final minFuture = DateTime.now().add(const Duration(minutes: 1));
    if (first.isBefore(minFuture)) {
      if (alignWeekly) {
        // bump to next week if already past
        while (!first.isAfter(minFuture)) {
          first = first.add(const Duration(days: 7));
        }
      } else {
        first = minFuture;
      }
    }
    return first;
  }

  /// Generate a finite series (used when endDate is set OR for 'once'/'every')
  Iterable<DateTime> _generateDateSeries() sync* {
    if (_pickedDate == null) return;

    // First occurrence (align for weekly)
    final firstOccurrence = _computeFirstOccurrence(alignWeekly: _repeat == 'weekly');

    // Determine the end boundary
    DateTime effectiveEnd;
    if (_endDate != null) {
      effectiveEnd = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
    } else {
      // Default capped horizons for finite scheduling
      switch (_repeat) {
        case 'once':
          effectiveEnd = firstOccurrence;
          break;
        case 'daily':
          effectiveEnd = firstOccurrence.add(const Duration(days: 30));
          break;
        case 'every':
          effectiveEnd = firstOccurrence.add(const Duration(days: 60));
          break;
        case 'weekly':
          effectiveEnd = firstOccurrence.add(const Duration(days: 7 * 12)); // 12 weeks
          break;
        default:
          effectiveEnd = firstOccurrence;
      }
    }

    switch (_repeat) {
      case 'once':
        if (!firstOccurrence.isAfter(effectiveEnd)) yield firstOccurrence;
        break;

      case 'daily':
        var current = firstOccurrence;
        while (!current.isAfter(effectiveEnd)) {
          yield current;
          current = current.add(const Duration(days: 1));
        }
        break;

      case 'every':
        final step = _everyNDays <= 0 ? 2 : _everyNDays;
        var current = firstOccurrence;
        while (!current.isAfter(effectiveEnd)) {
          yield current;
          current = current.add(Duration(days: step));
        }
        break;

      case 'weekly':
        var current = firstOccurrence;
        while (!current.isAfter(effectiveEnd)) {
          yield current;
          current = current.add(const Duration(days: 7));
        }
        break;
    }
  }

  Future<void> _save() async {
    // Validation
    if (_selectedPlantIds.isEmpty) {
      _showSnackBar('Please select at least one plant.');
      return;
    }
    if (_pickedDate == null) {
      _showSnackBar('Please select a date.');
      return;
    }

    // Get current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar('You must be logged in to create tasks.');
      return;
    }

    // Get final time from controllers
    final finalTime = _getTimeFromControllers();

    // Loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Titles
      final title = '${_taskType[0].toUpperCase()}${_taskType.substring(1)} Reminder';
      final plantNames = _selectedPlantNames.values.toList();
      final body = '$title for ${plantNames.join(", ")} is due now!';

      // Cancel old notifications if editing
      if (widget.editDocId != null && widget.existing != null) {
        final oldIds = (widget.existing!['notificationIds'] as List?)?.cast<int>() ?? const <int>[];
        if (oldIds.isNotEmpty) {
          await LocalNotifs.instance.cancelIds(oldIds);
        }
      }

      // Decide infinite vs finite scheduling
      final isInfiniteDaily = _repeat == 'daily' && _endDate == null;
      final isInfiniteWeekly = _repeat == 'weekly' && _endDate == null;

      List<int> notificationIds = [];
      DateTime firstOccurrence;

      if (isInfiniteDaily) {
        // First future anchor
        firstOccurrence = _computeFirstOccurrence(alignWeekly: false);
        final id = await LocalNotifs.instance.scheduleDaily(
          title: title,
          body: body,
          time: finalTime,
          anchorDate: firstOccurrence,
        );
        notificationIds = [id];
      } else if (isInfiniteWeekly) {
        // First future aligned to chosen weekday
        firstOccurrence = _computeFirstOccurrence(alignWeekly: true);
        final id = await LocalNotifs.instance.scheduleWeekly(
          title: title,
          body: body,
          weekday0to6: _weeklyWeekday,
          time: finalTime,
          anchorDate: firstOccurrence,
        );
        notificationIds = [id];
      } else {
        // Finite series (once / every / or daily/weekly with endDate)
        final dateSeries = _generateDateSeries().toList();
        firstOccurrence = dateSeries.isNotEmpty
            ? dateSeries.first
            : DateTime.now().add(const Duration(minutes: 1));
        if (dateSeries.isNotEmpty) {
          notificationIds = await LocalNotifs.instance.scheduleMany(
            title: title,
            body: body,
            dates: dateSeries,
          );
        }
      }

      // Prepare Firestore payload with userId
      final taskData = {
        'plantIds': _selectedPlantIds.toList(),
        'plantNames': plantNames,
        'taskType': _taskType,
        'date': Timestamp.fromDate(firstOccurrence),
        'time': _formatTime(finalTime),
        'repeat': _repeat,
        'everyNDays': _repeat == 'every' ? _everyNDays : null,
        'weeklyWeekday': _repeat == 'weekly' ? _weeklyWeekday : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'notificationIds': notificationIds,
        'userId': currentUser.uid, // Add user ID
        // Hint: -1 means "endless" (daily/weekly without endDate)
        'totalScheduled': (isInfiniteDaily || isInfiniteWeekly) ? -1 : notificationIds.length,
      };

      final col = FirebaseFirestore.instance.collection('scheduledTasks');
      if (widget.editDocId == null) {
        await col.add({...taskData, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await col.doc(widget.editDocId).update({...taskData, 'updatedAt': FieldValue.serverTimestamp()});
      }

      if (!mounted) return;
      Navigator.pop(context); // loading
      Navigator.pop(context); // dialog
      _showSnackBar(widget.editDocId == null
          ? 'Task created and reminders scheduled!'
          : 'Task updated successfully!');
    } catch (e, st) {
      debugPrint('❌ Save task failed: $e\n$st');
      if (!mounted) return;
      Navigator.pop(context); // loading
      _showSnackBar('Failed to save task: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button - fixed at top
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_step == 0)
                      _StepSelectPlant(
                        selected: _selectedPlantIds,
                        selectedNames: _selectedPlantNames,
                        selectedTypes: _selectedPlantTypes,
                      ),
                    if (_step == 1)
                      _StepTaskType(
                        taskType: _taskType,
                        onChange: (v) => setState(() => _taskType = v),
                      ),
                    if (_step == 2)
                      _StepDateTime(
                        repeat: _repeat,
                        setRepeat: (v) => setState(() => _repeat = v),
                        hourCtrl: _hourCtrl,
                        minuteCtrl: _minuteCtrl,
                        amPm: _amPm,
                        setAmPm: (v) => setState(() => _amPm = v),
                        date: _pickedDate,
                        onPickDate: () async {
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2100),
                            initialDate: _pickedDate ?? DateTime.now(),
                          );
                          if (d != null) setState(() => _pickedDate = d);
                        },
                        endDate: _endDate,
                        onPickEndDate: () async {
                          final d = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2022),
                            lastDate: DateTime(2100),
                            initialDate: _endDate ?? (_pickedDate ?? DateTime.now()),
                          );
                          setState(() => _endDate = d);
                        },
                        everyNDays: _everyNDays,
                        setEveryNDays: (v) => setState(() => _everyNDays = v),
                        weeklyWeekday: _weeklyWeekday,
                        setWeeklyWeekday: (v) => setState(() => _weeklyWeekday = v),
                        showWateringPreset: _taskType == 'watering' && _selectedPlantTypes.isNotEmpty,
                        onApplyPreset: _applyWateringPreset,
                        selectedPlantTypes: _selectedPlantTypes,
                      ),
                  ],
                ),
              ),
            ),
            // Buttons - fixed at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_step == 0 && _selectedPlantIds.isEmpty) return;
                        if (_step == 2) {
                          _save();
                        } else {
                          setState(() => _step++);
                        }
                      },
                      child: Text(_step == 2 ? (widget.editDocId == null ? 'Add Task' : 'Save Changes') : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ap';
  }
}

/* ---------- Step 0: Select Plant(s) ---------- */
class _StepSelectPlant extends StatelessWidget {
  final Set<String> selected;
  final Map<String, String> selectedNames;
  final Map<String, String> selectedTypes;

  const _StepSelectPlant({
    required this.selected,
    required this.selectedNames,
    required this.selectedTypes,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Please log in to view plants', style: TextStyle(color: Colors.red)),
      );
    }

    final q = FirebaseFirestore.instance
        .collection('gardenPlants')
        .where('userId', isEqualTo: currentUser.uid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/titles/AddPlantLabel.png',
          height: 28,
          errorBuilder: (_, __, ___) => const Text(
            'Add Plant',
            style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator(color: kDarkGreen));
            }
            final docs = snap.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length + 1,
              itemBuilder: (_, i) {
                if (i == docs.length) {
                  final allChecked = selected.length == docs.length && docs.isNotEmpty;
                  return CheckboxListTile(
                    value: allChecked,
                    onChanged: (v) {
                      selected.clear();
                      selectedNames.clear();
                      selectedTypes.clear();
                      if (v == true) {
                        for (final d in docs) {
                          selected.add(d.id);
                          selectedNames[d.id] = (d['plantName'] ?? '') as String;
                          selectedTypes[d.id] = (d['plantType'] ?? '') as String;
                        }
                      }
                      (context as Element).markNeedsBuild();
                    },
                    title: const Text('All'),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }
                final d = docs[i];
                final id = d.id;
                final name = (d['plantName'] ?? '') as String;
                final type = (d['plantType'] ?? '') as String;
                final img = (d['imageUrl'] ?? '') as String;
                final checked = selected.contains(id);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (v) {
                    if (v == true) {
                      selected.add(id);
                      selectedNames[id] = name;
                      selectedTypes[id] = type;
                    } else {
                      selected.remove(id);
                      selectedNames.remove(id);
                      selectedTypes.remove(id);
                    }
                    (context as Element).markNeedsBuild();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: img.isEmpty ? Container(color: const Color(0xFFE5E7EB)) : Image.network(img, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(type, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/* ---------- Step 1: Choose Task Type ---------- */
class _StepTaskType extends StatelessWidget {
  final String taskType;
  final ValueChanged<String> onChange;

  const _StepTaskType({required this.taskType, required this.onChange});

  @override
  Widget build(BuildContext context) {
    Widget _btn(String label, String value, Color border, {Color? fill}) {
      final selected = taskType == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton(
          onPressed: () => onChange(value),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: selected ? border : border.withOpacity(.5), width: 2),
            backgroundColor: selected ? (fill ?? Colors.white.withOpacity(.08)) : Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: selected ? border : kDarkGreen),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(
          'assets/titles/TaskTypeLabel.png',
          height: 28,
          errorBuilder: (_, __, ___) => const Text(
            'Select Task Type',
            style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        _btn('Watering', 'watering', const Color(0xFF31A8FF), fill: const Color(0xFF31A8FF).withOpacity(.12)),
        _btn('Fertilizing', 'fertilizing', const Color(0xFF22C55E), fill: const Color(0xFF22C55E).withOpacity(.10)),
        _btn('Pruning', 'pruning', const Color(0xFFF59E0B), fill: const Color(0xFFF59E0B).withOpacity(.10)),
      ],
    );
  }
}

/* ---------- Step 2: Date & Time ---------- */
class _StepDateTime extends StatelessWidget {
  final TextEditingController hourCtrl;
  final TextEditingController minuteCtrl;
  final String amPm;
  final ValueChanged<String> setAmPm;
  final DateTime? date;
  final VoidCallback onPickDate;
  final String repeat;
  final ValueChanged<String> setRepeat;
  final DateTime? endDate;
  final VoidCallback onPickEndDate;
  final int everyNDays;
  final ValueChanged<int> setEveryNDays;
  final int weeklyWeekday;
  final ValueChanged<int> setWeeklyWeekday;
  final bool showWateringPreset;
  final VoidCallback onApplyPreset;
  final Map<String, String> selectedPlantTypes;

  const _StepDateTime({
    required this.hourCtrl,
    required this.minuteCtrl,
    required this.amPm,
    required this.setAmPm,
    required this.date,
    required this.onPickDate,
    required this.repeat,
    required this.setRepeat,
    required this.endDate,
    required this.onPickEndDate,
    required this.everyNDays,
    required this.setEveryNDays,
    required this.weeklyWeekday,
    required this.setWeeklyWeekday,
    required this.showWateringPreset,
    required this.onApplyPreset,
    required this.selectedPlantTypes,
  });

  @override
  Widget build(BuildContext context) {
    String _fmtDate(DateTime? d) => d == null ? 'mm/dd/yyyy' : '${d.month}/${d.day}/${d.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/titles/SetDateLabel.png',
          height: 28,
          errorBuilder: (_, __, ___) => const Text(
            'Set Date and time',
            style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 10),

        // Smart Watering Preset Button
        if (showWateringPreset) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF31A8FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF31A8FF).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Color(0xFF31A8FF), size: 18),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Smart Watering Schedule',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF31A8FF), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on: ${selectedPlantTypes.values.toSet().join(", ")}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onApplyPreset,
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('Apply Schedule', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF31A8FF),
                      side: const BorderSide(color: Color(0xFF31A8FF)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Manual Time Input
        Row(
          children: [
            // Hour
            Expanded(
              flex: 2,
              child: TextField(
                controller: hourCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  labelText: 'Hour',
                  hintText: '12',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            // Minute
            Expanded(
              flex: 2,
              child: TextField(
                controller: minuteCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  labelText: 'Minute',
                  hintText: '00',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            // AM/PM Toggle - Custom compact version
            Expanded(
              flex: 2,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setAmPm('AM'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: amPm == 'AM' ? kDarkGreen : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(7),
                              bottomLeft: Radius.circular(7),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'AM',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: amPm == 'AM' ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, color: Colors.grey.shade400),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setAmPm('PM'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: amPm == 'PM' ? kDarkGreen : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'PM',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: amPm == 'PM' ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date Picker
        OutlinedButton(
          onPressed: onPickDate,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Date'),
              Text(_fmtDate(date)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Repeat', style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.w700)),
        RadioListTile(
          value: 'once',
          groupValue: repeat,
          onChanged: (v) => setRepeat(v as String),
          title: const Text('Once'),
        ),
        RadioListTile(
          value: 'daily',
          groupValue: repeat,
          onChanged: (v) => setRepeat(v as String),
          title: const Text('Daily'),
        ),
        RadioListTile(
          value: 'every',
          groupValue: repeat,
          onChanged: (v) => setRepeat(v as String),
          title: Row(
            children: [
              const Text('Every'),
              const SizedBox(width: 8),
              SizedBox(
                width: 64,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(isDense: true, hintText: '2'),
                  controller: TextEditingController(text: everyNDays.toString()),
                  onChanged: (t) {
                    final n = int.tryParse(t);
                    if (n != null && n > 0) setEveryNDays(n);
                  },
                ),
              ),
              const SizedBox(width: 6),
              const Text('days'),
            ],
          ),
        ),
        RadioListTile(
          value: 'weekly',
          groupValue: repeat,
          onChanged: (v) => setRepeat(v as String),
          title: Row(
            children: [
              const Text('Weekly On  '),
              DropdownButton<int>(
                value: weeklyWeekday,
                items: List.generate(7, (i) {
                  const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                  return DropdownMenuItem(value: i, child: Text(names[i]));
                }),
                onChanged: (v) => v != null ? setWeeklyWeekday(v) : null,
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onPickEndDate,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('End Date (optional)'),
              Text(_fmtDate(endDate)),
            ],
          ),
        ),
      ],
    );
  }
}