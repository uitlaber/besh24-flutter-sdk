import 'besh24_storage.dart';

/// In-memory [Besh24Storage] with no persistence across process restarts.
///
/// Used as a test double and as a safe fallback when `shared_preferences` is
/// unavailable (e.g. pure-Dart contexts).
class InMemoryStorage implements Besh24Storage {
  /// Creates an in-memory store, optionally seeded with [seed].
  InMemoryStorage([Map<String, String>? seed]) : _data = {...?seed};

  final Map<String, String> _data;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}
