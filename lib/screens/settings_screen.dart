import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_data.dart';
import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/file_access.dart';
import '../util/motion.dart';
import '../widgets/contour_header.dart';
import '../widgets/ui_kit.dart';
import 'lists_screen.dart';
import 'my_gear_screen.dart';
import 'template_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final data = ref.watch(appDataProvider).valueOrNull;
    final c = ref.read(appDataProvider.notifier);
    final settings = data?.settings;

    return Column(
      children: [
        ContourHeader(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 22),
          child: Text('Settings', style: AppText.display(26, color: p.bg)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ContentColumn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CardSection(
                      title: 'Language',
                      child: _SegRow(
                        options: const [('en', '🇬🇧 English'), ('de', '🇩🇪 Deutsch')],
                        selected: settings?.language ?? 'de',
                        onSelect: c.setLanguage,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CardSection(
                      title: 'Appearance',
                      child: _SegRow(
                        options: const [('light', 'Light'), ('dark', 'Dark')],
                        selected:
                            (settings?.darkMode ?? false) ? 'dark' : 'light',
                        onSelect: (v) => c.setDarkMode(v == 'dark'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ActionRow(
                      label: 'My Gear',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const MyGearScreen())),
                    ),
                    const SizedBox(height: 8),
                    _ActionRow(
                      label: 'Lists',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ListsScreen())),
                    ),
                    const SizedBox(height: 8),
                    _ActionRow(
                      label: 'Suggestions library',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TemplateScreen())),
                    ),
                    const SizedBox(height: 8),
                    _ActionRow(
                        label: 'Export data (JSON)',
                        onTap: () => _export(context, ref)),
                    const SizedBox(height: 8),
                    _ActionRow(
                        label: 'Import data (JSON)',
                        onTap: () => _import(context, ref)),
                    const SizedBox(height: 8),
                    _ActionRow(
                      label: 'About',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Camp Gear Planner',
                        applicationVersion: '0.2.0',
                        children: [
                          const Text(
                              'Offline camping-trip gear planner — checklists, packing weight, budgets, and a shopping list.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final data = ref.read(appDataProvider).valueOrNull;
    if (data == null) return;
    final json = const JsonEncoder.withIndent('  ').convert(data.toJson());
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Camp Gear data',
      fileName: 'camp_gear_backup.json',
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
    if (path == null) return;
    if (!kIsWeb && !isMobilePlatform) await saveTextFile(path, json);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Data exported')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'], withData: true);
    final file = result?.files.firstOrNull;
    if (file == null) return;

    AppData incoming;
    try {
      final raw = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await readTextFile(file.path!);
      incoming = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid or malformed JSON file')));
      }
      return;
    }
    if (!context.mounted) return;

    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import mode'),
        content: const Text(
            'Replace all wipes current data. Merge adds trips/templates by id and skips duplicates.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, 'merge'), child: const Text('Merge')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, 'replace'),
              child: const Text('Replace all')),
        ],
      ),
    );
    if (mode == null) return;

    final c = ref.read(appDataProvider.notifier);
    final count = mode == 'replace'
        ? await c.replaceAll(incoming)
        : await c.mergeFrom(incoming);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              mode == 'replace' ? 'Replaced with $count trips' : 'Merged $count new trips')));
    }
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.body(14, color: p.ink)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SegRow extends StatelessWidget {
  const _SegRow({required this.options, required this.selected, required this.onSelect});
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final o in options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(o.$1),
                child: AnimatedContainer(duration: Motion.base, curve: Motion.curve,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == o.$1 ? p.selectedBg : p.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: selected == o.$1 ? p.selectedBg : p.border,
                        width: 1.5),
                  ),
                  child: Text(o.$2,
                      style: AppText.body(12.5,
                          color: selected == o.$1 ? p.bg : p.ink)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.body(14, color: p.ink)),
          Icon(Icons.chevron_right, size: 18, color: p.slate),
        ],
      ),
    );
  }
}
