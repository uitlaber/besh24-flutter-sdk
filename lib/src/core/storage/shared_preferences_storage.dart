import 'package:shared_preferences/shared_preferences.dart';

import '../logger.dart';
import 'besh24_storage.dart';

/// [Besh24Storage] backed by `shared_preferences`.
///
/// All keys are namespaced with a `besh24_sdk.` prefix. Failures are logged and
/// degraded (reads return `null`, writes/deletes are swallowed) so persistence
/// problems never crash the host app.
class SharedPreferencesStorage implements Besh24Storage {
  /// Creates the storage. Inject [preferences] in tests; otherwise it is loaded
  /// lazily via [SharedPreferences.getInstance].
  SharedPreferencesStorage({
    SharedPreferences? preferences,
    Besh24Logger logger = const DefaultBesh24Logger(),
  })  : _preferences = preferences,
        _logger = logger;

  static const _prefix = 'besh24_sdk.';

  SharedPreferences? _preferences;
  final Besh24Logger _logger;

  Future<SharedPreferences?> _prefs() async {
    if (_preferences != null) return _preferences;
    try {
      return _preferences = await SharedPreferences.getInstance();
    } catch (e) {
      _logger.warn('shared_preferences unavailable', e);
      return null;
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final prefs = await _prefs();
      return prefs?.getString('$_prefix$key');
    } catch (e) {
      _logger.warn('storage read failed for $key', e);
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final prefs = await _prefs();
      await prefs?.setString('$_prefix$key', value);
    } catch (e) {
      _logger.warn('storage write failed for $key', e);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final prefs = await _prefs();
      await prefs?.remove('$_prefix$key');
    } catch (e) {
      _logger.warn('storage delete failed for $key', e);
    }
  }
}
