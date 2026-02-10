import 'dart:typed_data';

Future<void> downloadExportBytes(
  String fileName,
  Uint8List bytes,
  String mimeType,
) async {
  throw UnsupportedError('Web export downloader is only available on web.');
}

