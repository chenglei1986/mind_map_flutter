import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class PickedImageFile {
  final String name;
  final Uint8List bytes;

  const PickedImageFile({required this.name, required this.bytes});
}

Future<PickedImageFile?> pickLocalImage() async {
  final files = await pickLocalImages();
  if (files.isEmpty) return null;
  return files.first;
}

Future<List<PickedImageFile>> pickLocalImages() {
  final completer = Completer<List<PickedImageFile>>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*'
    ..multiple = true;

  late web.EventListener onChangeHandler;
  onChangeHandler = ((web.Event _) {
    input.removeEventListener('change', onChangeHandler);

    Future<void> handleChange() async {
      final selected = input.files;
      if (selected == null || selected.length == 0) {
        if (!completer.isCompleted) {
          completer.complete(const []);
        }
        return;
      }

      final picked = <PickedImageFile>[];
      for (int i = 0; i < selected.length; i++) {
        final file = selected.item(i);
        if (file == null) continue;
        final bytes = await _readBytes(file);
        if (bytes == null) continue;
        picked.add(PickedImageFile(name: file.name, bytes: bytes));
      }

      if (!completer.isCompleted) {
        completer.complete(picked);
      }
    }

    unawaited(handleChange());
  }).toJS;
  input.addEventListener('change', onChangeHandler);

  input.click();
  return completer.future;
}

Future<Uint8List?> _readBytes(web.File file) async {
  final completer = Completer<Uint8List?>();
  final reader = web.FileReader();

  late web.EventListener onErrorHandler;
  late web.EventListener onLoadHandler;

  onErrorHandler = ((web.Event _) {
    reader.removeEventListener('error', onErrorHandler);
    reader.removeEventListener('load', onLoadHandler);
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }).toJS;

  onLoadHandler = ((web.Event _) {
    reader.removeEventListener('error', onErrorHandler);
    reader.removeEventListener('load', onLoadHandler);

    final result = reader.result?.dartify();
    if (result is ByteBuffer) {
      if (!completer.isCompleted) {
        completer.complete(result.asUint8List());
      }
      return;
    }
    if (result is Uint8List) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return;
    }
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }).toJS;

  reader.addEventListener('error', onErrorHandler);
  reader.addEventListener('load', onLoadHandler);
  reader.readAsArrayBuffer(file);

  return completer.future;
}
