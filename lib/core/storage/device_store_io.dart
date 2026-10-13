import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'durable_store.dart';

class DeviceStore implements DurableStore {
  DeviceStore({Future<Directory> Function()? directory})
    : _directory = (directory ?? getApplicationSupportDirectory)();
  final Future<Directory> _directory;
  int _sequence = 0;

  Future<File> _file(String key) async {
    final root = await _directory;
    final directory = Directory('${root.path}/fixpk-offline-v1');
    await directory.create(recursive: true);
    // Encoded names cannot escape the app-private directory.
    return File('${directory.path}/${Uri.encodeComponent(key)}');
  }

  @override
  Future<Uint8List?> read(String key) async {
    final file = await _file(key);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    final target = await _file(key);
    final temporary = File('${target.path}.${_sequence++}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<void> delete(String key) async {
    final file = await _file(key);
    if (await file.exists()) await file.delete();
  }
}
