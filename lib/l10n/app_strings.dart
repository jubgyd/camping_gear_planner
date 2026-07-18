import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Simple JSON-backed translations. The text lives in editable asset files
/// `assets/i18n/en.json` and `assets/i18n/de.json` (flat "key": "text" maps).
/// To translate the app you only edit those two files — no code changes.
///
/// Look text up anywhere with `context.t('some_key')`. Missing keys fall back
/// to English, then to the key itself, so nothing ever crashes on a typo.
class AppStrings extends InheritedWidget {
  const AppStrings({
    super.key,
    required this.lang,
    required this.maps,
    required super.child,
  });

  /// Active language code ('de' or 'en').
  final String lang;

  /// lang code -> (key -> text).
  final Map<String, Map<String, String>> maps;

  String t(String key) {
    return maps[lang]?[key] ?? maps['en']?[key] ?? key;
  }

  static AppStrings of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppStrings>();
    assert(s != null, 'AppStrings.of() called with no AppStrings in the tree');
    return s!;
  }

  /// Loads both language files once at startup.
  static Future<Map<String, Map<String, String>>> load() async {
    Future<Map<String, String>> read(String code) async {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, '$v'));
    }

    return {
      'en': await read('en'),
      'de': await read('de'),
    };
  }

  @override
  bool updateShouldNotify(AppStrings old) => old.lang != lang || old.maps != maps;
}

extension TranslateX on BuildContext {
  /// Shorthand: `context.t('key')`.
  String t(String key) => AppStrings.of(this).t(key);
}
