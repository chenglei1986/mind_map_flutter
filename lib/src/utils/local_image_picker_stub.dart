import 'dart:typed_data';

class PickedImageFile {
  final String name;
  final Uint8List bytes;

  const PickedImageFile({required this.name, required this.bytes});
}

Future<List<PickedImageFile>> pickLocalImages() async {
  return const [];
}

Future<PickedImageFile?> pickLocalImage() async {
  final files = await pickLocalImages();
  return files.isNotEmpty ? files.first : null;
}
