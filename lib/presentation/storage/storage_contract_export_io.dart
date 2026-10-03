import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> _write(String html, String filename) async {
  Directory dir;
  try {
    dir = await getApplicationDocumentsDirectory();
  } catch (_) {
    dir = Directory.systemTemp;
  }
  final file = File(p.join(dir.path, filename));
  await file.writeAsString(html);
  return file;
}

Future<void> _open(File file) async {
  try {
    if (Platform.isMacOS) {
      await Process.start('open', [file.path]);
    } else if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', file.path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [file.path]);
    }
  } catch (_) {}
}

Future<void> printStorageContractHtml(String html, String filename) async {
  await _open(await _write(html, filename));
}

Future<void> downloadStorageContractHtml(String html, String filename) async {
  await _open(await _write(html, filename));
}
