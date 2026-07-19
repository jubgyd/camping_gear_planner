// Platform-selecting facade for the product-image store.
//
// Desktop/mobile (dart.library.io) get the real on-disk implementation; the web
// build (dart.library.html) gets a no-op so no `dart:io`/`path_provider` code is
// pulled into the browser bundle. UI code imports only this file and uses
// `ImageStore.instance`.
export 'image_store_stub.dart'
    if (dart.library.io) 'image_store_io.dart'
    if (dart.library.html) 'image_store_web.dart';
