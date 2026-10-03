// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:js_util' as js;

Future<void> printStorageContractHtml(String htmlDoc, String filename) async {
  final frame = html.IFrameElement()
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0'
    ..srcdoc = htmlDoc;
  html.document.body?.append(frame);
  await Future<void>.delayed(const Duration(milliseconds: 240));
  try {
    final win = frame.contentWindow;
    if (win != null) {
      js.callMethod(win, 'print', []);
    } else {
      html.window.print();
    }
  } catch (_) {
    html.window.print();
  }
  await Future<void>.delayed(const Duration(milliseconds: 800));
  frame.remove();
}

Future<void> downloadStorageContractHtml(String htmlDoc, String filename) async {
  final bytes = html.Blob([htmlDoc], 'text/html;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
