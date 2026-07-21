import 'package:flutter/material.dart';

import '../../domain/entities/treatment.dart';
import '../../utils/strings.dart';

/// Result of the frequency screen: the chosen mode and its parameters.
class FrequencyConfig {
  final FrequencyType type;
  final int intervalValue;
  final IntervalUnit intervalUnit;
  final List<int> weekdays;
  final int cycleDaysOn;
  final int cycleDaysOff;

  const FrequencyConfig({
    required this.type,
    this.intervalValue = 8,
    this.intervalUnit = IntervalUnit.hours,
    this.weekdays = const [],
    this.cycleDaysOn = 21,
    this.cycleDaysOff = 7,
  });
}

/// Screen to choose how often a treatment is given: daily, interval
/// (every X hours/days/months), specific days of the week, cyclic
/// (X days on / Y days off) or on demand. Pops with a [FrequencyConfig].
class FrequencyScreen extends StatefulWidget {
  final FrequencyConfig initial;
  const FrequencyScreen({super.key, required this.initial});

  @override
  State<FrequencyScreen> createState() => _FrequencyScreenState();
}

class _FrequencyScreenState extends State<FrequencyScreen> {
  late FrequencyType _type;
  late IntervalUnit _intervalUnit;
  late int _intervalValue;
  late Set<int> _weekdays;
  late int _cycleDaysOn;
  late int _cycleDaysOff;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _intervalUnit = widget.initial.intervalUnit;
    _intervalValue = widget.initial.intervalValue;
    _weekdays = widget.initial.weekdays.toSet();
    _cycleDaysOn = widget.initial.cycleDaysOn;
    _cycleDaysOff = widget.initial.cycleDaysOff;
  }

  int get _maxIntervalValue {
    switch (_intervalUnit) {
      case IntervalUnit.hours:
        return 24;
      case IntervalUnit.days:
        return 31;
      case IntervalUnit.months:
        return 12;
    }
  }

  void _selectUnit(IntervalUnit unit) {
    setState(() {
      _intervalUnit = unit;
      // Sensible default per unit; clamp if out of range.
      if (_intervalValue > _maxIntervalValue) {
        _intervalValue = _maxIntervalValue;
      }
    });
  }

  /// "Select interval in hours/days/months" dialog with a numeric
  /// dropdown and cancel/confirm buttons.
  Future<void> _pickIntervalValue() async {
    final s = S.of(context);
    var selected = _intervalValue.clamp(1, _maxIntervalValue);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.selectIntervalIn(_intervalUnit)),
          content: DropdownButtonFormField<int>(
            initialValue: selected,
            items: [
              for (var i = 1; i <= _maxIntervalValue; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => setDialogState(() => selected = v ?? selected),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(s.confirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _intervalValue = selected);
    }
  }

  Future<void> _pickCycleValue({required bool on}) async {
    final s = S.of(context);
    var selected = (on ? _cycleDaysOn : _cycleDaysOff).clamp(1, 60);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(on ? s.daysOnLabel : s.daysOffLabel),
          content: DropdownButtonFormField<int>(
            initialValue: selected,
            items: [
              for (var i = 1; i <= 60; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => setDialogState(() => selected = v ?? selected),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(s.confirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        if (on) {
          _cycleDaysOn = selected;
        } else {
          _cycleDaysOff = selected;
        }
      });
    }
  }

  void _confirm() {
    final s = S.of(context);
    if (_type == FrequencyType.weekdays && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.selectAtLeastOneDay)));
      return;
    }
    Navigator.of(context).pop(FrequencyConfig(
      type: _type,
      intervalValue: _intervalValue,
      intervalUnit: _intervalUnit,
      weekdays: _weekdays.toList()..sort(),
      cycleDaysOn: _cycleDaysOn,
      cycleDaysOff: _cycleDaysOff,
    ));
  }

  Widget _optionCard({
    required FrequencyType type,
    required String title,
    Widget? expanded,
  }) {
    final selected = _type == type;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          RadioGroup<FrequencyType>(
            groupValue: _type,
            onChanged: (v) => setState(() => _type = v ?? _type),
            child: RadioListTile<FrequencyType>(
              value: type,
              title: Text(title),
            ),
          ),
          // The card expands with its options when selected.
          if (selected && expanded != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: expanded,
            ),
        ],
      ),
    );
  }

  Widget _intervalOptions(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<IntervalUnit>(
          groupValue: _intervalUnit,
          onChanged: (v) => _selectUnit(v ?? _intervalUnit),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final unit in IntervalUnit.values)
                RadioListTile<IntervalUnit>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: unit,
                  title: Text(_unitOptionLabel(s, unit)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(s.remindEvery, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(width: 8),
            ActionChip(
              label: Text(
                  '$_intervalValue ${s.intervalUnitName(_intervalUnit, _intervalValue)}'),
              onPressed: _pickIntervalValue,
            ),
          ],
        ),
      ],
    );
  }

  String _unitOptionLabel(S s, IntervalUnit unit) {
    switch (unit) {
      case IntervalUnit.hours:
        return s.everyXHoursOption;
      case IntervalUnit.days:
        return s.everyXDaysOption;
      case IntervalUnit.months:
        return s.everyXMonthsOption;
    }
  }

  Widget _weekdayOptions(S s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var d = 1; d <= 7; d++)
          FilterChip(
            label: Text(s.weekdayShort(d)),
            selected: _weekdays.contains(d),
            onSelected: (sel) => setState(() {
              if (sel) {
                _weekdays.add(d);
              } else {
                _weekdays.remove(d);
              }
            }),
          ),
      ],
    );
  }

  Widget _cyclicOptions(S s) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(s.daysOnLabel),
          trailing: ActionChip(
            label: Text('$_cycleDaysOn'),
            onPressed: () => _pickCycleValue(on: true),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(s.daysOffLabel),
          trailing: ActionChip(
            label: Text('$_cycleDaysOff'),
            onPressed: () => _pickCycleValue(on: false),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.frequency),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: s.confirm,
            onPressed: _confirm,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _optionCard(type: FrequencyType.daily, title: s.everyDay),
          _optionCard(
            type: FrequencyType.interval,
            title: s.intervalOption,
            expanded: _intervalOptions(s),
          ),
          _optionCard(
            type: FrequencyType.weekdays,
            title: s.weekdaysOption,
            expanded: _weekdayOptions(s),
          ),
          _optionCard(
            type: FrequencyType.cyclic,
            title: s.cyclicOption,
            expanded: _cyclicOptions(s),
          ),
          _optionCard(type: FrequencyType.onDemand, title: s.onDemandOption),
        ],
      ),
    );
  }
}
