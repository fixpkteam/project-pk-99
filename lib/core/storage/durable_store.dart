import 'dart:convert';
import 'dart:typed_data';

/// Writes must be durable before completing; failed writes must preserve the
/// previous value. Used for critical outbox data, not SharedPreferences.
abstract interface class DurableStore {
  Future<Uint8List?> read(String key);
  Future<void> write(String key, Uint8List bytes);
  Future<void> delete(String key);
}

extension JsonStore on DurableStore {
  Future<dynamic> readJson(String key) async {
    final bytes = await read(key);
    return bytes == null ? null : jsonDecode(utf8.decode(bytes));
  }

  Future<void> writeJson(String key, Object? value) =>
      write(key, Uint8List.fromList(utf8.encode(jsonEncode(value))));
}
