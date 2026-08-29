Future<void> writeBytesToFileImpl(String path, List<int> bytes) async {
  // No-op: en web, FilePicker.saveFile(bytes: ...) ya dispara la descarga.
}
