import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Stores downloaded product images as files on disk. The app data itself lives
/// in shared_preferences (small JSON), so images are kept out-of-band here and
/// referenced by filename only — that keeps saved data and backups small.
///
/// Files live in `<app-support>/product_images/`. [init] must run once at
/// startup so [dirPath] / [pathFor] can be read synchronously by widgets.
class ImageStore {
  ImageStore._();
  static final ImageStore instance = ImageStore._();

  static const _subdir = 'product_images';
  static const _maxBytes = 6 * 1024 * 1024; // ignore anything over ~6 MB

  String? _dirPath;

  /// Absolute path of the images directory, or null before [init] (e.g. tests).
  String? get dirPath => _dirPath;

  /// Resolves and creates the images directory. Safe to call more than once.
  Future<void> init() async {
    if (_dirPath != null) return;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}${Platform.pathSeparator}$_subdir');
      if (!await dir.exists()) await dir.create(recursive: true);
      _dirPath = dir.path;
    } catch (_) {
      // Non-fatal: without a directory, image features simply no-op.
      _dirPath = null;
    }
  }

  /// Absolute path for a stored [filename], or null if the store isn't ready.
  String? pathFor(String filename) {
    final d = _dirPath;
    if (d == null || filename.isEmpty) return null;
    return '$d${Platform.pathSeparator}$filename';
  }

  /// Downloads [url] into `<basename>.<ext>` and returns the stored filename,
  /// or null on any failure (non-image, too big, network/CORS error). Never
  /// throws — callers treat null as "no image".
  Future<String?> download(String url, {required String basename}) async {
    final dir = _dirPath;
    if (dir == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return null;

    try {
      final res = await http.get(uri, headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/122.0 Safari/537.36',
        'Accept': 'image/avif,image/webp,image/png,image/jpeg,*/*',
      }).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) return null;
      final bytes = res.bodyBytes;
      if (bytes.isEmpty || bytes.length > _maxBytes) return null;

      final ext = _extension(res.headers['content-type'], uri);
      if (ext == null) return null; // not a recognised image type

      final filename = '$basename.$ext';
      final file = File('$dir${Platform.pathSeparator}$filename');
      await file.writeAsBytes(bytes, flush: true);
      return filename;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a stored image, ignoring errors (e.g. already gone).
  Future<void> delete(String? filename) async {
    if (filename == null || filename.isEmpty) return;
    final path = pathFor(filename);
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Picks a file extension from the content-type, falling back to the URL.
  /// Returns null for content that isn't a decodable image.
  String? _extension(String? contentType, Uri uri) {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('jpeg') || ct.contains('jpg')) return 'jpg';
    if (ct.contains('png')) return 'png';
    if (ct.contains('webp')) return 'webp';
    if (ct.contains('gif')) return 'gif';
    if (ct.contains('bmp')) return 'bmp';

    // Fall back to the URL's extension when the header is missing/generic.
    final path = uri.path.toLowerCase();
    for (final e in const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp']) {
      if (path.endsWith('.$e')) return e == 'jpeg' ? 'jpg' : e;
    }
    // If the server said it's an image but gave an unknown subtype, keep it as
    // jpg (Flutter's decoder sniffs the actual bytes anyway).
    if (ct.startsWith('image/')) return 'jpg';
    return null;
  }
}
