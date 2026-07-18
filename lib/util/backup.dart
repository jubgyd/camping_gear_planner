import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_data.dart';
import '../models/trip.dart';
import '../state/app_controller.dart';
import 'file_access.dart';

/// Save / load the user's plans to a file location of their choosing.
///
/// A saved file is always an [AppData] JSON document — a whole-library backup
/// and a single-trip "plan" share the same shape, so [loadBackup] can restore
/// either one. Files pick their location through the platform Save-As dialog.

/// Serializes [data] and lets the user choose where to write it.
Future<void> _saveToFile(
  BuildContext context,
  AppData data, {
  required String dialogTitle,
  required String fileName,
  required String doneMessage,
}) async {
  final json = const JsonEncoder.withIndent('  ').convert(data.toJson());
  final path = await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    // Mobile/web write here directly; desktop returns a path and we write below.
    bytes: Uint8List.fromList(utf8.encode(json)),
  );
  if (path == null) return; // user cancelled the dialog
  if (!kIsWeb && !isMobilePlatform) await saveTextFile(path, json);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(doneMessage)));
  }
}

/// Save the entire library — every trip, gear item, list and setting.
Future<void> saveBackup(BuildContext context, WidgetRef ref) async {
  final data = ref.read(appDataProvider).valueOrNull;
  if (data == null) return;
  await _saveToFile(
    context,
    data,
    dialogTitle: 'Save a backup of all your plans',
    fileName: 'camp-gear-backup-${_dateStamp()}.json',
    doneMessage: 'Backup saved',
  );
}

/// Save a single trip to its own file — shareable, and loadable via [loadBackup].
Future<void> saveTripToFile(
    BuildContext context, WidgetRef ref, Trip trip) async {
  await _saveToFile(
    context,
    AppData(trips: [trip]),
    dialogTitle: 'Save “${trip.name}” to a file',
    fileName: '${_slug(trip.name)}.json',
    doneMessage: 'Plan saved',
  );
}

/// Let the user pick a saved file and merge or replace their data with it.
Future<void> loadBackup(BuildContext context, WidgetRef ref) async {
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
          const SnackBar(content: Text('Invalid or unreadable file')));
    }
    return;
  }
  if (!context.mounted) return;

  final mode = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Load into your plans'),
      content: const Text(
          'Merge adds any new trips/lists and keeps what you already have. '
          'Replace all wipes your current data and loads only this file.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: const Text('Merge')),
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
        content: Text(mode == 'replace'
            ? 'Loaded — now $count trips'
            : 'Merged $count new trips')));
  }
}

String _dateStamp() {
  final d = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// A filesystem-friendly default filename from a trip name (German-aware).
String _slug(String name) {
  final s = name
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'camp-plan' : s;
}
