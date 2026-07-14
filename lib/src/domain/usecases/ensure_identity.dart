import '../../core/clock.dart';
import '../../core/result.dart';
import '../../core/uuid_gen.dart';
import '../entities/identity.dart';
import '../repositories/identity_repository.dart';

/// Bootstraps and caches the anonymous identity.
///
/// Business rules (mirroring the backend + web shim):
///  * Fetch `GET /identity` once, resending cached ids so the backend reuses the
///    same anonymous id across launches.
///  * If the cached identity has been idle longer than [sessionIdleTimeout],
///    drop the session id from the request so the backend mints a fresh one
///    (30-minute rule).
///  * Never fail: on a network error, fall back to the cached identity, or —
///    if there is none — a locally generated one, so events still carry ids.
class EnsureIdentity {
  /// Creates the use-case.
  EnsureIdentity({
    required IdentityRepository repository,
    required Clock clock,
    required UuidGenerator uuid,
    required this.sessionIdleTimeout,
  })  : _repository = repository,
        _clock = clock,
        _uuid = uuid;

  final IdentityRepository _repository;
  final Clock _clock;
  final UuidGenerator _uuid;

  /// Idle window after which the session id is rotated.
  final Duration sessionIdleTimeout;

  /// Resolves the current [Identity], persisting the result. Always [Ok].
  Future<Result<Identity>> call() async {
    final cached = await _repository.loadCached();

    final String? anonymousId = cached?.identity.anonymousId;
    String? sessionId = cached?.identity.sessionId;

    if (cached != null) {
      final idle = _clock.nowUtc().difference(cached.lastSeenAt);
      if (idle >= sessionIdleTimeout) {
        // Expired session: force the backend to issue a new one.
        sessionId = null;
      }
    }

    final remote = await _repository.fetchRemote(
      anonymousId: anonymousId,
      sessionId: sessionId,
    );

    switch (remote) {
      case Ok<Identity>(:final value):
        await _repository.save(value);
        return Ok(value);
      case Err<Identity>():
        // Degrade gracefully — never crash the host app.
        final fallback = cached?.identity ??
            Identity(anonymousId: _uuid.v4(), sessionId: _uuid.v4());
        await _repository.save(fallback);
        return Ok(fallback);
    }
  }
}
