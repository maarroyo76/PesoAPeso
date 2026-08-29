import 'dart:io';

Future<void> writeBytesToFileImpl(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes);
}
