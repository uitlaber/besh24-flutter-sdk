import '../../core/result.dart';
import '../entities/identity.dart';

/// Persistence + bootstrap operations for the anonymous identity.
///
/// The session-idle business rule lives in [EnsureIdentity]; this interface
/// only exposes the granular IO primitives it composes.
abstract interface class IdentityRepository {
  /// Loads the cached identity (with its last-seen timestamp), or `null`.
  Future<CachedIdentity?> loadCached();

  /// Fetches identity from `GET /api/v1/identity`, optionally resending the
  /// given ids as cookies so the backend reuses them.
  Future<Result<Identity>> fetchRemote({
    String? anonymousId,
    String? sessionId,
  });

  /// Persists [identity], stamping the last-seen time to now.
  Future<void> save(Identity identity);
}
