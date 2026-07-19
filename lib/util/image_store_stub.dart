// Fallback used only if neither dart:io nor dart:html is available. Mirrors the
// web no-op so the app still compiles and the image feature is simply inert.

class ImageStore {
  ImageStore._();
  static final ImageStore instance = ImageStore._();

  String? get dirPath => null;
  Future<void> init() async {}
  String? pathFor(String filename) => null;
  Future<String?> download(String url, {required String basename}) async => null;
  Future<String?> importFile(String sourcePath,
          {required String basename}) async =>
      null;
  Future<void> delete(String? filename) async {}
}
