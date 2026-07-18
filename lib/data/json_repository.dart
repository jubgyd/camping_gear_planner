import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_data.dart';
import 'repository.dart';

/// Local-only [Repository] backed by a single human-readable JSON file in the
/// app documents directory (GDD §1, §12). Writes go through a temp file +
/// rename so a crash mid-write can't corrupt the existing data.
class JsonRepository implements Repository {
  JsonRepository({this.fileName = 'camp_gear.json'});

  final String fileName;
  File? _cachedFile;

  Future<File> _file() async {
    if (_cachedFile != null) return _cachedFile!;
    final dir = await getApplicationDocumentsDirectory();
    return _cachedFile = File('${dir.path}${Platform.pathSeparator}$fileName');
  }

  @override
  Future<AppData> load() async {
    final file = await _file();
    if (!await file.exists()) return const AppData();
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const AppData();
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Corrupt file: fall back to empty rather than crashing on launch.
      // A real recovery flow (rename to .bak, notify) is post-MVP.
      return const AppData();
    }
  }

  @override
  Future<void> save(AppData data) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await tmp.writeAsString(encoder.convert(data.toJson()), flush: true);
    await tmp.rename(file.path);
  }
}
