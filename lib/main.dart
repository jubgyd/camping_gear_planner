import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'l10n/app_strings.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'util/image_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final strings = await AppStrings.load();
  // Resolve the product-image directory once so widgets can read paths sync.
  await ImageStore.instance.init();
  runApp(ProviderScope(child: CampGearApp(strings: strings)));
}

class CampGearApp extends ConsumerWidget {
  const CampGearApp({super.key, required this.strings});

  /// Loaded translations: lang code -> (key -> text).
  final Map<String, Map<String, String>> strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final lang = ref.watch(languageProvider);
    return MaterialApp(
      title: 'Camp Gear Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      // Wrap the whole navigator so every screen (incl. pushed routes) can read
      // translations and re-render live when the language toggles.
      builder: (context, child) =>
          AppStrings(lang: lang, maps: strings, child: child!),
      home: const HomeShell(),
    );
  }
}
