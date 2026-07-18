// Platform-selecting facade for native file writes used by data export/import.
//
// The web build resolves to file_access_web (no dart:io); IO platforms resolve
// to file_access_io. UI code imports only this file.
export 'file_access_stub.dart'
    if (dart.library.io) 'file_access_io.dart'
    if (dart.library.html) 'file_access_web.dart';
