import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/packing_list.dart';
import '../models/trip.dart';
import '../models/trip_meta.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import '../util/motion.dart';
import '../widgets/ui_kit.dart';
import 'trip_detail_screen.dart';

/// Full trip form (design plan Add Trip). Deliberately not a boxed form: a big
/// headline name input, then chip/grid selectors for the metadata. Doubles as
/// the edit form when [existing] is supplied — same fields, prefilled, saving
/// back over the same trip (checklist preserved).
class AddTripScreen extends ConsumerStatefulWidget {
  const AddTripScreen({super.key, this.existing});

  /// When non-null, the form edits this trip instead of creating a new one.
  final Trip? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _name = TextEditingController();
  final _budget = TextEditingController();
  final _location = TextEditingController();
  final _locationLink = TextEditingController();
  final _weather = TextEditingController();
  final _partySize = TextEditingController();
  final _notes = TextEditingController();
  Country? _country;
  Season? _season;
  CampStyle? _style;
  String _type = 'solo';
  DateTime? _start, _end;
  bool _addCalendar = false;
  bool _reminderOn = false;
  int _reminderDays = 3;
  PackingList? _startList; // null = blank checklist

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _name.text = t.name;
      if (t.budget != null) _budget.text = t.budget!.toStringAsFixed(0);
      _country = t.country;
      _season = t.season;
      _style = t.campStyle;
      _type = t.typeKey;
      _start = t.startDate;
      _end = t.endDate;
      _addCalendar = t.calendarSynced;
      _reminderOn = t.reminderDaysBefore != null;
      _reminderDays = t.reminderDaysBefore ?? 3;
      _location.text = t.location;
      _locationLink.text = t.locationLink ?? '';
      _weather.text = t.weather;
      if (t.partySize != null) _partySize.text = '${t.partySize}';
      _notes.text = t.notes;
    }
  }

  @override
  void dispose() {
    for (final ctl in [
      _name,
      _budget,
      _location,
      _locationLink,
      _weather,
      _partySize,
      _notes,
    ]) {
      ctl.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      _country != null &&
      _season != null &&
      _style != null;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? _start ?? now,
      firstDate: isStart ? now.subtract(const Duration(days: 365)) : (_start ?? now),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _save() {
    if (!_valid) return;
    final parsedBudget = double.tryParse(_budget.text.trim());
    final budget =
        (parsedBudget != null && parsedBudget > 0) ? parsedBudget : null;
    final subtitle = '${TripType.byKey(_type)!.label} · ${_season!.label}';
    final notifier = ref.read(appDataProvider.notifier);

    // Optional planning details (blank -> unset).
    final location = _location.text.trim();
    final linkText = _locationLink.text.trim();
    final locationLink = linkText.isEmpty ? null : linkText;
    final weather = _weather.text.trim();
    final party = int.tryParse(_partySize.text.trim());
    final partySize = (party != null && party > 0) ? party : null;
    final notes = _notes.text.trim();

    // Edit mode: update the existing trip in place and return to it.
    final editing = widget.existing;
    if (editing != null) {
      notifier.updateTripMeta(
        editing.id,
        name: _name.text.trim(),
        subtitle: subtitle,
        countryCode: _country!.code,
        seasonKey: _season!.key,
        campStyleKey: _style!.key,
        typeKey: _type,
        budget: budget,
        startDate: _start,
        endDate: _end ?? _start,
        calendarSynced: _start != null && _addCalendar,
        reminderDaysBefore:
            (_start != null && _reminderOn) ? _reminderDays : null,
        location: location,
        locationLink: locationLink,
        weather: weather,
        partySize: partySize,
        notes: notes,
      );
      Navigator.of(context).pop();
      return;
    }

    // Create mode.
    final trip = Trip(
      id: 't${const Uuid().v4()}',
      name: _name.text.trim(),
      subtitle: subtitle,
      countryCode: _country!.code,
      seasonKey: _season!.key,
      campStyleKey: _style!.key,
      typeKey: _type,
      budget: budget,
      startDate: _start,
      endDate: _end ?? _start,
      calendarSynced: _start != null && _addCalendar,
      reminderDaysBefore: (_start != null && _reminderOn) ? _reminderDays : null,
      location: location,
      locationLink: locationLink,
      weather: weather,
      partySize: partySize,
      notes: notes,
    );
    notifier.addTrip(trip);
    if (_startList != null) {
      notifier.applyListToTrip(trip.id, _startList!);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                      icon: Icon(Icons.close, color: p.ink),
                      onPressed: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Text(widget.isEditing ? 'EDIT TRIP' : 'NEW TRIP',
                      style: AppText.mono(12, color: p.inkMuted, letterSpacing: 1.5)),
                  const Spacer(),
                  TextButton(
                    onPressed: _valid ? _save : null,
                    child: Text('Save',
                        style: AppText.mono(14,
                            color: _valid ? p.rust : p.slate,
                            weight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ContentColumn(
                maxWidth: 640,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    TextField(
                      controller: _name,
                      onChanged: (_) => setState(() {}),
                      style: AppText.display(30, color: p.ink, height: 1.1),
                      cursorColor: p.rust,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Name your trip',
                        hintStyle: AppText.display(30, color: p.slate),
                        enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: p.border, width: 2)),
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: p.rust, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const SectionLabel('Destination'),
                    const SizedBox(height: 12),
                    _CountryGrid(
                        selected: _country,
                        onSelect: (c) => setState(() => _country = c)),
                    const SizedBox(height: 28),
                    const SectionLabel('Campsite (optional)'),
                    const SizedBox(height: 12),
                    _TextBox(
                        controller: _location,
                        hint: 'Place or campsite name',
                        icon: Icons.place_outlined),
                    const SizedBox(height: 8),
                    _TextBox(
                        controller: _locationLink,
                        hint: 'Link (maps, booking, website)',
                        icon: Icons.link,
                        keyboardType: TextInputType.url),
                    const SizedBox(height: 28),
                    const SectionLabel('Season'),
                    const SizedBox(height: 12),
                    _SeasonChips(
                        selected: _season,
                        onSelect: (s) => setState(() => _season = s)),
                    const SizedBox(height: 28),
                    const SectionLabel('Expected weather (optional)'),
                    const SizedBox(height: 12),
                    _TextBox(
                        controller: _weather,
                        hint: 'e.g. cold nights ~0°C, rain likely',
                        icon: Icons.cloud_outlined),
                    const SizedBox(height: 28),
                    const SectionLabel('Camping style'),
                    const SizedBox(height: 12),
                    _StyleGrid(
                        selected: _style,
                        onSelect: (s) => setState(() => _style = s)),
                    const SizedBox(height: 28),
                    const SectionLabel("Who's going"),
                    const SizedBox(height: 12),
                    _TypeRow(
                        selected: _type,
                        onSelect: (t) => setState(() => _type = t)),
                    const SizedBox(height: 28),
                    const SectionLabel('Party size (optional)'),
                    const SizedBox(height: 12),
                    _TextBox(
                        controller: _partySize,
                        hint: 'How many people, e.g. 4',
                        icon: Icons.groups_outlined,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 28),
                    const SectionLabel('Dates (optional)'),
                    const SizedBox(height: 12),
                    _DateRow(
                      start: _start,
                      end: _end,
                      onPick: _pickDate,
                    ),
                    if (_start != null) ...[
                      const SizedBox(height: 10),
                      _ToggleTile(
                        label: '📅 Add to calendar',
                        on: _addCalendar,
                        onTap: () =>
                            setState(() => _addCalendar = !_addCalendar),
                      ),
                      const SizedBox(height: 8),
                      _ToggleTile(
                        label: '🔔 Remind me before departure',
                        on: _reminderOn,
                        onTap: () => setState(() => _reminderOn = !_reminderOn),
                      ),
                      if (_reminderOn) ...[
                        const SizedBox(height: 8),
                        _ReminderDayRow(
                          days: _reminderDays,
                          onSelect: (d) => setState(() => _reminderDays = d),
                        ),
                      ],
                    ],
                    const SizedBox(height: 28),
                    const SectionLabel('Budget (optional)'),
                    const SizedBox(height: 12),
                    _BudgetField(controller: _budget),
                    const SizedBox(height: 28),
                    const SectionLabel('Notes (optional)'),
                    const SizedBox(height: 12),
                    _TextBox(
                        controller: _notes,
                        hint: 'Meeting point, who\'s driving, reservations…',
                        maxLines: 4),
                    // "Start from" seeds a checklist — creation only; editing a
                    // trip must not clobber the existing checklist.
                    if (!widget.isEditing) ...[
                      const SizedBox(height: 28),
                      const SectionLabel('Start from'),
                      const SizedBox(height: 12),
                      _StartFromChips(
                        lists: ref.watch(availableListsProvider),
                        selected: _startList,
                        onSelect: (l) => setState(() => _startList = l),
                      ),
                      const SizedBox(height: 24),
                      Text(
                          'A list seeds your checklist; you can still add from suggestions or your gear afterward.',
                          style: AppText.body(12, color: p.slate, height: 1.5)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Selector widgets -----------------------------------------------------

class _CountryGrid extends StatelessWidget {
  const _CountryGrid({required this.selected, required this.onSelect});
  final Country? selected;
  final ValueChanged<Country> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in Country.all)
              _cell(context, c, selected?.code == c.code),
          ],
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(selected!.name,
                style: AppText.body(13, color: p.inkMuted)),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, Country c, bool active) {
    final p = context.palette;
    return SizedBox(
      width: 58,
      child: GestureDetector(
        onTap: () => onSelect(c),
        child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? p.rustSoft : p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: active ? p.rust : p.border, width: 1.5),
          ),
          child: Column(
            children: [
              Text(c.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 2),
              Text(c.code,
                  style: AppText.mono(9,
                      color: active ? p.rust : p.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeasonChips extends StatelessWidget {
  const _SeasonChips({required this.selected, required this.onSelect});
  final Season? selected;
  final ValueChanged<Season> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in Season.all)
          GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected?.key == s.key ? p.moss : p.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: selected?.key == s.key ? p.moss : p.border,
                    width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.icon),
                  const SizedBox(width: 6),
                  Text(s.label,
                      style: AppText.body(13,
                          color: selected?.key == s.key ? p.bg : p.ink)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StyleGrid extends StatelessWidget {
  const _StyleGrid({required this.selected, required this.onSelect});
  final CampStyle? selected;
  final ValueChanged<CampStyle> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in CampStyle.all)
          SizedBox(
            width: 96,
            child: GestureDetector(
              onTap: () => onSelect(c),
              child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected?.key == c.key ? p.mossSoft : p.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected?.key == c.key ? p.moss : p.border,
                      width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(c.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(c.label,
                        textAlign: TextAlign.center,
                        style: AppText.body(12,
                            color: selected?.key == c.key ? p.moss : p.ink)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final t in TripType.all)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(t.key),
                child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == t.key ? p.selectedBg : p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected == t.key ? p.selectedBg : p.border,
                        width: 1.5),
                  ),
                  child: Text(t.label,
                      style: AppText.body(12,
                          color: selected == t.key ? p.bg : p.ink)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.start, required this.end, required this.onPick});
  final DateTime? start, end;
  final void Function(bool isStart) onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget field(String label, DateTime? value, bool isStart) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppText.mono(10, color: p.slate)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => onPick(isStart),
                child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border, width: 1.5),
                  ),
                  child: Text(
                    value == null ? 'Pick' : fmtDateRange(value, value)!,
                    style: AppText.mono(13,
                        color: value == null ? p.slate : p.ink),
                  ),
                ),
              ),
            ],
          ),
        );
    return Row(
      children: [
        field('Start', start, true),
        const SizedBox(width: 12),
        field('End', end, false),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: on ? p.mossSoft : p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: on ? p.moss : p.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
                child: Text(label,
                    style: AppText.body(12.5, color: on ? p.moss : p.ink))),
            Text(on ? 'On' : 'Off',
                style: AppText.body(12, color: on ? p.moss : p.slate)),
          ],
        ),
      ),
    );
  }
}

class _ReminderDayRow extends StatelessWidget {
  const _ReminderDayRow({required this.days, required this.onSelect});
  final int days;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final d in const [1, 3, 7])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: days == d ? p.ink : p.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: days == d ? p.ink : p.border),
                ),
                child: Text('${d}d before',
                    style: AppText.mono(11, color: days == d ? p.bg : p.ink)),
              ),
            ),
          ),
      ],
    );
  }
}

class _StartFromChips extends StatelessWidget {
  const _StartFromChips({
    required this.lists,
    required this.selected,
    required this.onSelect,
  });
  final List<PackingList> lists;
  final PackingList? selected;
  final ValueChanged<PackingList?> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget chip(String label, String? sub, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.curve,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active ? p.mossSoft : p.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: active ? p.moss : p.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppText.body(13,
                      color: active ? p.moss : p.ink,
                      weight: FontWeight.w500)),
              if (sub != null)
                Text(sub, style: AppText.mono(9, color: p.slate)),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Blank', 'leerer Start', selected == null, () => onSelect(null)),
        for (final l in lists)
          chip(l.name, '${l.itemCount} items · ${l.builtin ? 'Vorlage' : 'Eigene'}',
              selected?.id == l.id, () => onSelect(l)),
      ],
    );
  }
}

/// A bordered surface text field used for the optional free-text trip details.
class _TextBox extends StatelessWidget {
  const _TextBox({
    required this.controller,
    required this.hint,
    this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(icon, size: 16, color: p.slate),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: AppText.body(14, color: p.ink),
              cursorColor: p.rust,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.body(14, color: p.slate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetField extends StatelessWidget {
  const _BudgetField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border, width: 1.5),
      ),
      child: Row(
        children: [
          Text('€', style: AppText.mono(14, color: p.inkMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppText.mono(14, color: p.ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'e.g. 180',
                hintStyle: AppText.mono(14, color: p.slate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
