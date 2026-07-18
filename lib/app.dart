import 'package:flutter/material.dart';

import 'screens/camps_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shopping_screen.dart';
import 'theme/app_palette.dart';
import 'theme/app_text.dart';
import 'widgets/ui_kit.dart';

/// Root shell with the three tabs (GDD §9: Camps · Shopping · Settings).
/// Responsive: a side rail + centered content on wide desktop windows, a bottom
/// nav on narrow ones.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [CampsScreen(), ShoppingScreen(), SettingsScreen()];
  static const _dests = [
    (icon: Icons.terrain_outlined, sel: Icons.terrain, label: 'Camps'),
    (
      icon: Icons.shopping_bag_outlined,
      sel: Icons.shopping_bag,
      label: 'Shopping'
    ),
    (icon: Icons.settings_outlined, sel: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final body = IndexedStack(index: _index, children: _tabs);

    if (isWide(context)) {
      return Scaffold(
        body: Row(
          children: [
            _SideRail(
              index: _index,
              onSelect: (i) => setState(() => _index = i),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        backgroundColor: p.surface,
        indicatorColor: p.mossSoft,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _dests)
            NavigationDestination(
              icon: Icon(d.icon, color: p.slate),
              selectedIcon: Icon(d.sel, color: p.rust),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({required this.index, required this.onSelect});
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 208,
      color: p.headerBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Row(
                children: [
                  const Text('⛰', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('Camp Gear',
                        style: AppText.display(18, color: p.bg)),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < _HomeShellState._dests.length; i++)
              _RailItem(
                dest: _HomeShellState._dests[i],
                active: i == index,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.dest, required this.active, required this.onTap});
  final ({IconData icon, IconData sel, String label}) dest;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = active ? p.rust : const Color(0xFFC8CCB8);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: active ? Colors.white.withValues(alpha: 0.06) : null,
        child: Row(
          children: [
            Icon(active ? dest.sel : dest.icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(dest.label, style: AppText.mono(13, color: color)),
          ],
        ),
      ),
    );
  }
}
