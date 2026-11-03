import 'dart:typed_data';

// Non-web no-op implementation. Android uses the native Save As picker.
void downloadBytes(Uint8List bytes, String fileName, String mimeType) {}
