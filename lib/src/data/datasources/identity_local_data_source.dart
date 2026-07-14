import '../../core/clock.dart';
import '../../core/storage/besh24_storage.dart';
import '../../domain/entities/identity.dart';

/// Persists the anonymous identity (+ last-seen time) in [Besh24Storage].
///
/// Keys: `anonymous_id`, `session_id`, `last_seen` (ISO-8601). The last-seen
/// timestamp drives the session-idle rule in [EnsureIdentity].
class IdentityLocalDataSource {
  /// Creates the data source.
  IdentityLocalDataSource({
    required Besh24Storage storage,
    required Clock clock,
  })  : _storage = storage,
        _clock = clock;

  final Besh24Storage _storage;
  final Clock _clock;

  static const _kAnon = 'anonymous_id';
  static const _kSession = 'session_id';
  static const _kLastSeen = 'last_seen';

  /// Reads the cached identity, or `null` when absent/incomplete.
  Future<CachedIdentity?> read() async {
    final anon = await _storage.read(_kAnon);
    final session = await _storage.read(_kSession);
    if (anon == null || anon.isEmpty || session == null || session.isEmpty) {
      return null;
    }
    final lastSeenRaw = await _storage.read(_kLastSeen);
    final lastSeen =
        DateTime.tryParse(lastSeenRaw ?? '')?.toUtc() ?? _clock.nowUtc();
    return CachedIdentity(
      identity: Identity(anonymousId: anon, sessionId: session),
      lastSeenAt: lastSeen,
    );
  }

  /// Persists [identity], stamping last-seen to now.
  Future<void> write(Identity identity) async {
    await _storage.write(_kAnon, identity.anonymousId);
    await _storage.write(_kSession, identity.sessionId);
    await _storage.write(_kLastSeen, _clock.nowUtc().toIso8601String());
  }
}
