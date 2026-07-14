/// Key/value persistence abstraction for identity caching.
///
/// The default implementation ([SharedPreferencesStorage]) is backed by
/// `shared_preferences`; [InMemoryStorage] is provided for tests and headless
/// use. Implementations must not throw — surface failures by returning `null`
/// (reads) or swallowing (writes) where a crash would otherwise leak.
abstract interface class Besh24Storage {
  /// Reads the value stored under [key], or `null` if absent.
  Future<String?> read(String key);

  /// Writes [value] under [key].
  Future<void> write(String key, String value);

  /// Removes [key].
  Future<void> delete(String key);
}
