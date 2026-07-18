import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_controller.dart';
import '../theme/app_palette.dart';
import '../theme/app_text.dart';
import '../util/backup.dart';
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
                        label: 'Save a backup',
                        subtitle: 'Write all your plans to a file you choose',
                        icon: Icons.save_alt,
                        onTap: () => saveBackup(context, ref)),
                    const SizedBox(height: 8),
                    _ActionRow(
                        label: 'Load a backup',
                        subtitle: 'Restore plans from a saved file',
                        icon: Icons.folder_open,
                        onTap: () => loadBackup(context, ref)),
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
  const _ActionRow({
    required this.label,
    required this.onTap,
    this.subtitle,
    this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: p.slate),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.body(14, color: p.ink)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.body(12, color: p.slate)),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: p.slate),
        ],
      ),
    );
  }
}
