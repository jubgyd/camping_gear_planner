// Web build: there is no local filesystem, so the product-image feature is
// inert. Every method matches the IO signature but does nothing and returns
// null, which callers already interpret as "no image". No dart:io import.

class ImageStore {
  ImageStore._();
  static final ImageStore instance = ImageStore._();

  /// Always null on web — no on-disk image directory exists.
  String? get dirPath => null;

  /// Nothing to resolve; succeeds so startup code can await it unconditionally.
  Future<void> init() async {}

  /// No stored images on web.
  String? pathFor(String filename) => null;

  /// Image download is disabled on web (v1); reports "no image".
  Future<String?> download(String url, {required String basename}) async => null;

  /// Local file import is disabled on web (v1); reports "no image".
  Future<String?> importFile(String sourcePath,
          {required String basename}) async =>
      null;

  /// Nothing to delete on web.
  Future<void> delete(String? filename) async {}
}
