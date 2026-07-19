// Platform-selecting facade for the product thumbnail widget.
//
// Desktop/mobile load the image from disk; the web build (v1) renders nothing.
// Call sites import only this file.
export 'product_thumb_stub.dart'
    if (dart.library.io) 'product_thumb_io.dart'
    if (dart.library.html) 'product_thumb_web.dart';
