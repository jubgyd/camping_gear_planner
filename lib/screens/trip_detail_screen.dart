import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../models/item.dart';
import '../models/item_status.dart';
import '../models/trip.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/backup.dart';
import '../util/format.dart';
import '../util/motion.dart';
import 'add_trip_screen.dart';
import '../widgets/budget_gauge.dart';
import '../widgets/contour_header.dart';
import '../widgets/product_thumb.dart';
import '../widgets/progress_ridge.dart';
import '../widgets/status_dot.dart';
import '../widgets/ui_kit.dart';
import 'item_edit_screen.dart';
import 'my_gear_screen.dart';
import 'share_screen.dart';
import 'template_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({super.key, required this.tripId});
  final String tripId;

  void _flash(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1400)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final data = ref.watch(appDataProvider).valueOrNull;
    final trip = data?.trips.firstWhereOrNull((t) => t.id == tripId);
    if (trip == null) {
      return Scaffold(
          backgroundColor: p.bg,
          body: Center(child: Text(context.t('td_not_found'))));
    }
    final c = ref.read(appDataProvider.notifier);

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          _Header(trip: trip, onFlash: (m) => _flash(context, m)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ContentColumn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TripInfoCard(trip: trip),
                      for (final cat in trip.categories)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CategoryCard(trip: trip, category: cat),
                        ),
                      _AddCategoryButton(
                        onAdd: (name) => c.addCategory(trip.id, name),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t('td_checklist_hint'),
                        textAlign: TextAlign.center,
                        style: AppText.body(11, color: p.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.trip, required this.onFlash});
  final Trip trip;
  final ValueChanged<String> onFlash;

  void _showAddSheet(BuildContext context, String tripId) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.lightbulb_outline, color: p.moss),
              title: Text(context.t('td_add_suggestions_title')),
              subtitle: Text(context.t('td_add_suggestions_sub')),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TemplateScreen(tripId: tripId)));
              },
            ),
            ListTile(
              leading: Icon(Icons.backpack_outlined, color: p.rust),
              title: Text(context.t('td_add_mygear_title')),
              subtitle: Text(context.t('td_add_mygear_sub')),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MyGearScreen(tripId: tripId)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsList(
      BuildContext context, AppController c, Trip trip) async {
    final savedTemplate = context.t('td_saved_as_list');
    final field = TextEditingController(text: trip.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('td_saveaslist_title')),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: InputDecoration(labelText: context.t('td_list_name')),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('common_cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, field.text),
              child: Text(context.t('common_save'))),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      c.saveTripAsList(trip.id, name.trim());
      onFlash(savedTemplate.replaceFirst('{name}', name.trim()));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, AppController c, Trip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('td_delete_title')),
        content: Text(
            context.t('td_delete_body').replaceFirst('{name}', trip.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.t('common_cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('common_delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await c.deleteTrip(trip.id);
    // Leave the (now-gone) detail screen and return to the trip list.
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final c = ref.read(appDataProvider.notifier);
    final muted = p.onHeaderMuted;
    final dateLabel = fmtDateRange(trip.startDate, trip.endDate);
    final cd = daysUntil(trip.startDate, trip.endDate);

    Future<void> editBudget() async {
      final controller = TextEditingController(
          text: trip.budget != null ? trip.budget!.toStringAsFixed(0) : '');
      final result = await showDialog<double?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.t('td_budget_title')),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                prefixText: '€ ', hintText: context.t('addtrip_budget_hint')),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, -1.0),
                child: Text(context.t('common_clear'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.t('common_cancel'))),
            FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx, double.tryParse(controller.text.trim())),
                child: Text(context.t('common_save'))),
          ],
        ),
      );
      if (result == null) return;
      c.setBudget(trip.id, result < 0 || result == 0 ? null : result);
    }

    return ContourHeader(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: p.onHeader, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(context.t('td_header_checklist'),
                  style: AppText.body(14, color: p.onHeader)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add, color: p.onHeader, size: 20),
                tooltip: context.t('td_add_items'),
                onPressed: () => _showAddSheet(context, trip.id),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: p.onHeader, size: 20),
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddTripScreen(existing: trip)));
                  } else if (v == 'share') {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ShareScreen(tripId: trip.id)));
                  } else if (v == 'archive') {
                    c.setArchived(trip.id, !trip.archived);
                    onFlash(context.t(
                        trip.archived ? 'td_flash_restored' : 'td_flash_archived'));
                  } else if (v == 'save_list') {
                    _saveAsList(context, c, trip);
                  } else if (v == 'save_file') {
                    saveTripToFile(context, ref, trip);
                  } else if (v == 'delete') {
                    _confirmDelete(context, c, trip);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text('✏️ ${context.t('td_menu_edit')}')),
                  PopupMenuItem(value: 'share', child: Text('📤 ${context.t('td_menu_share')}')),
                  PopupMenuItem(
                      value: 'save_file', child: Text('💾 ${context.t('td_menu_savefile')}')),
                  PopupMenuItem(
                      value: 'save_list', child: Text('📋 ${context.t('td_menu_savelist')}')),
                  PopupMenuItem(
                      value: 'archive',
                      child: Text(trip.archived
                          ? '↩ ${context.t('td_menu_restore')}'
                          : '🗄 ${context.t('td_menu_archive')}')),
                  PopupMenuItem(
                      value: 'delete', child: Text('🗑 ${context.t('td_menu_delete')}')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(trip.name, style: AppText.display(22, color: p.onHeader)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (dateLabel != null)
                Text('🗓 $dateLabel', style: AppText.mono(12, color: muted)),
              if (cd != null && cd.state == CountdownState.upcoming)
                TagPill(
                    text: cd.label,
                    bg: p.rust.withValues(alpha: 0.25),
                    fg: const Color(0xFFF0B692)),
              if (dateLabel != null)
                _HeaderChip(
                  label: trip.calendarSynced
                      ? '📅 ${context.t('td_cal_in')}'
                      : '📅 ${context.t('td_cal_add')}',
                  active: trip.calendarSynced,
                  onTap: () {
                    final s = !trip.calendarSynced;
                    c.setCalendarSynced(trip.id, s);
                    onFlash(context.t(
                        s ? 'td_flash_cal_on' : 'td_flash_cal_off'));
                  },
                ),
              if (dateLabel != null)
                _HeaderChip(
                  label: trip.reminderDaysBefore != null
                      ? '🔔 ${context.t('td_reminder_set').replaceFirst('{d}', '${trip.reminderDaysBefore}')}'
                      : '🔔 ${context.t('td_reminder_me')}',
                  active: trip.reminderDaysBefore != null,
                  onTap: () {
                    final on = trip.reminderDaysBefore == null;
                    c.setReminderDays(trip.id, on ? 3 : null);
                    onFlash(context.t(
                        on ? 'td_flash_reminder_on' : 'td_flash_reminder_off'));
                  },
                ),
            ],
          ),
          if (trip.reminderDaysBefore != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (final d in const [1, 3, 7])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => c.setReminderDays(trip.id, d),
                      child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: trip.reminderDaysBefore == d
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text('${d}d', style: AppText.mono(10, color: muted)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ProgressRidge(pct: trip.readyPercent, onDark: true)),
              const SizedBox(width: 12),
              Text('${trip.readyPercent}%', style: AppText.mono(12, color: p.onHeader)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${context.t('td_packed')} ${fmtWeight(trip.ownedWeightGrams)} · ${context.t('td_full')} ${fmtWeight(trip.fullWeightGrams)}',
            style: AppText.mono(12, color: muted),
          ),
          const SizedBox(height: 12),
          if (trip.budget != null)
            InkWell(
              onTap: editBudget,
              child: BudgetGauge(
                  spent: trip.spent,
                  projected: trip.projected,
                  budget: trip.budget!,
                  onDark: true),
            )
          else
            GestureDetector(
              onTap: editBudget,
              child: Text(context.t('td_set_budget'),
                  style: AppText.mono(12, color: muted).copyWith(
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted)),
            ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? const Color(0x407FB37A)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: AppText.mono(10,
                color: active ? const Color(0xFFB6DCB0) : const Color(0xFFC8CCB8))),
      ),
    );
  }
}

/// Shows the optional planning details (campsite, party size, weather, notes)
/// above the checklist. Renders nothing when the trip has none of them.
class _TripInfoCard extends StatelessWidget {
  const _TripInfoCard({required this.trip});
  final Trip trip;

  Future<void> _openLink(BuildContext context, String raw) async {
    var s = raw.trim();
    if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'https://$s';
    final uri = Uri.tryParse(s);
    var ok = false;
    if (uri != null) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('td_open_link_err'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasCampsite =
        trip.location.trim().isNotEmpty || (trip.locationLink ?? '').trim().isNotEmpty;
    final hasParty = trip.partySize != null;
    final hasWeather = trip.weather.trim().isNotEmpty;
    final hasNotes = trip.notes.trim().isNotEmpty;
    if (!hasCampsite && !hasParty && !hasWeather && !hasNotes) {
      return const SizedBox.shrink();
    }

    Widget line(IconData icon, Widget child) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: p.slate),
              const SizedBox(width: 10),
              Expanded(child: child),
            ],
          ),
        );

    final link = (trip.locationLink ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasCampsite)
              line(
                Icons.place_outlined,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (trip.location.trim().isNotEmpty)
                      Text(trip.location.trim(),
                          style: AppText.body(13.5, color: p.ink)),
                    if (link.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openLink(context, link),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new, size: 12, color: p.rust),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(link,
                                    style: AppText.body(12, color: p.rust),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (hasParty)
              line(
                  Icons.groups_outlined,
                  Text('${trip.partySize} ${context.t(trip.partySize == 1 ? 'td_person' : 'td_people')}',
                      style: AppText.body(13.5, color: p.ink))),
            if (hasWeather)
              line(Icons.cloud_outlined,
                  Text(trip.weather.trim(), style: AppText.body(13.5, color: p.ink))),
            if (hasNotes)
              line(Icons.sticky_note_2_outlined,
                  Text(trip.notes.trim(), style: AppText.body(13.5, color: p.ink, height: 1.4))),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.trip, required this.category});
  final Trip trip;
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final c = ref.read(appDataProvider.notifier);
    return SurfaceCard(
      clip: true,
      child: Column(
        children: [
          InkWell(
            onTap: () => c.toggleCategoryCollapsed(trip.id, category.id),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(category.name,
                        style: AppText.display(16, color: p.ink)),
                  ),
                  Text(fmtWeight(category.weightGrams),
                      style: AppText.mono(12, color: p.inkMuted)),
                  IconButton(
                    icon: Icon(Icons.add, size: 18, color: p.slate),
                    tooltip: context.t('td_add_item'),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ItemEditScreen(
                          tripId: trip.id, categoryId: category.id),
                    )),
                  ),
                  AnimatedRotation(
                    duration: Motion.base,
                    curve: Motion.curve,
                    turns: category.collapsed ? 0.5 : 0,
                    child: Icon(Icons.expand_less, size: 18, color: p.slate),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.curve,
            alignment: Alignment.topCenter,
            child: category.collapsed
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      for (final it in category.items)
                        _ItemRow(
                            trip: trip, categoryId: category.id, item: it),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.trip, required this.categoryId, required this.item});
  final Trip trip;
  final String categoryId;
  final Item item;

  static const _cycle = {
    ItemStatus.owned: ItemStatus.needToBuy,
    ItemStatus.needToBuy: ItemStatus.notNeeded,
    ItemStatus.notNeeded: ItemStatus.owned,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final c = ref.read(appDataProvider.notifier);
    final na = item.status == ItemStatus.notNeeded;
    return Container(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            StatusDot(
              status: item.status,
              onTap: () =>
                  c.setItemStatus(trip.id, categoryId, item.id, _cycle[item.status]!),
            ),
            const SizedBox(width: 12),
            if (item.imageFile != null) ...[
              Opacity(
                opacity: na ? 0.45 : 1,
                child: ProductThumb(item.imageFile, size: 38),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ItemEditScreen(
                      tripId: trip.id, categoryId: categoryId, existing: item),
                )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(item.name,
                              style: AppText.body(13.5,
                                  color: na ? p.slate : p.ink,
                                  decoration: na
                                      ? TextDecoration.lineThrough
                                      : null)),
                        ),
                        if (item.quantity > 1) ...[
                          const SizedBox(width: 6),
                          TagPill(
                              text: '×${item.quantity}',
                              bg: p.slateSoft,
                              fg: p.inkMuted),
                        ],
                      ],
                    ),
                    if (item.note.isNotEmpty)
                      Text(item.note, style: AppText.body(12, color: p.inkMuted)),
                  ],
                ),
              ),
            ),
            if (item.link != null && item.link!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.open_in_new, size: 13, color: p.slate),
              ),
            const SizedBox(width: 8),
            Text(fmtWeight(item.totalWeightGrams),
                style: AppText.mono(12, color: p.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton({required this.onAdd});
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextButton.icon(
      onPressed: () async {
        final field = TextEditingController();
        final name = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.t('td_newcat_title')),
            content: TextField(
                controller: field,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: context.t('td_newcat_hint')),
                onSubmitted: (v) => Navigator.pop(ctx, v)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.t('common_cancel'))),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, field.text),
                  child: Text(context.t('common_add'))),
            ],
          ),
        );
        if (name != null && name.trim().isNotEmpty) onAdd(name.trim());
      },
      icon: Icon(Icons.add, size: 18, color: p.rust),
      label: Text(context.t('td_add_category'), style: AppText.mono(13, color: p.rust)),
    );
  }
}
