import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';
import 'repository.dart';

/// Cross-platform [Repository] (web, desktop, mobile) that stores the full
/// [AppData] JSON blob under a single key via `shared_preferences`.
///
/// This keeps the GDD §13 persistence seam: the file-based [json_repository]
/// remains an alternative implementation that can be swapped in without
/// touching any UI or state code. `shared_preferences` is used as the default
/// because it works on every target including web, where `dart:io` file access
/// is unavailable.
class PrefsRepository implements Repository {
  PrefsRepository({this.key = 'camp_gear_data_v1'});

  final String key;

  @override
  Future<AppData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const AppData();
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const AppData();
    }
  }

  @override
  Future<void> save(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data.toJson()));
  }
}
