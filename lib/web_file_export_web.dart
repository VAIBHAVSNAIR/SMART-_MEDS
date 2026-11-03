import 'dart:html' as html;
import 'dart:typed_data';

// Downloads generated files directly through the browser.
void downloadBytes(Uint8List bytes, String fileName, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  Future<void>.delayed(
    const Duration(seconds: 2),
    () => html.Url.revokeObjectUrl(url),
  );
}