// Web build: `file_picker` (v8) does NOT implement `saveFile` on web — its base
// class throws `UnimplementedError`. So the app must hand the bytes to the
// browser itself, which [downloadTextFile] does. The native read/write helpers
// below are never exercised on web (import reads in-memory bytes); they exist
// only to satisfy the shared interface without pulling in `dart:io`.
//
// The browser bindings are declared inline with dart:js_interop rather than
// pulled from package:web, whose pinned version here lacks the Web Share API.
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

Future<void> saveTextFile(String path, String text) async {
  // no-op: web writes go through downloadTextFile / the browser.
}

Future<String> readTextFile(String path) async =>
    throw UnsupportedError('readTextFile is not used on web');

bool get isMobilePlatform => false;

/// Hands a text file to the browser to save.
///
/// On iOS (including an installed home-screen PWA) this opens the native share
/// sheet when available, so the backup can go to Files / AirDrop / Mail. On
/// desktop browsers, where files can't be shared, it falls back to a normal
/// download.
///
/// Returns `false` only when the share sheet was offered and the user dismissed
/// it (so the caller can skip the "saved" confirmation); `true` otherwise.
Future<bool> downloadTextFile(String fileName, String text) async {
  final part = Uint8List.fromList(utf8.encode(text)).toJS;

  // 1) Native share sheet, when the browser can share a file (iOS Safari/PWA).
  // If canShare/share are absent the call throws and we fall through.
  try {
    final file = _File(<JSAny>[part].toJS, fileName);
    final data = _ShareData(files: <JSAny>[file].toJS);
    if (_navigator.canShare(data)) {
      try {
        await _navigator.share(data).toDart;
        return true;
      } catch (_) {
        return false; // user dismissed the share sheet (or share failed)
      }
    }
  } catch (_) {
    // Share API unavailable or marshalling failed — fall through to a download.
  }

  // 2) Fallback: trigger a normal download (desktop browsers).
  final blob = _Blob(<JSAny>[part].toJS);
  final url = _URL.createObjectURL(blob);
  final anchor = _document.createElement('a')
    ..href = url
    ..download = fileName;
  _document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  _URL.revokeObjectURL(url);
  return true;
}

// --- Minimal browser bindings ------------------------------------------------

@JS('navigator')
external _Navigator get _navigator;

@JS('document')
external _Document get _document;

extension type _Navigator._(JSObject _) implements JSObject {
  external bool canShare(JSAny data);
  external JSPromise<JSAny?> share(JSAny data);
}

extension type _Document._(JSObject _) implements JSObject {
  external _Element createElement(String localName);
  external _Element? get body;
}

extension type _Element._(JSObject _) implements JSObject {
  external set href(String value);
  external set download(String value);
  external void click();
  external void appendChild(_Element node);
  external void remove();
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts);
}

@JS('File')
extension type _File._(JSObject _) implements JSObject {
  external factory _File(JSArray<JSAny> parts, String name);
}

@JS('URL')
extension type _URL._(JSObject _) implements JSObject {
  external static String createObjectURL(JSObject obj);
  external static void revokeObjectURL(String url);
}

extension type _ShareData._(JSObject _) implements JSObject {
  external factory _ShareData({JSArray<JSAny> files});
}
