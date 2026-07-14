import '../../core/result.dart';
import '../../domain/entities/identity.dart';
import '../../domain/repositories/identity_repository.dart';
import '../datasources/besh24_remote_data_source.dart';
import '../datasources/identity_local_data_source.dart';

/// [IdentityRepository] over the remote + local identity data sources.
class IdentityRepositoryImpl implements IdentityRepository {
  /// Creates the repository.
  IdentityRepositoryImpl({
    required Besh24RemoteDataSource remote,
    required IdentityLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final Besh24RemoteDataSource _remote;
  final IdentityLocalDataSource _local;

  @override
  Future<CachedIdentity?> loadCached() => _local.read();

  @override
  Future<Result<Identity>> fetchRemote({
    String? anonymousId,
    String? sessionId,
  }) async {
    final res = await _remote.getIdentity(
      anonymousId: anonymousId,
      sessionId: sessionId,
    );
    switch (res) {
      case Ok(:final value):
        final entity = value.toEntity();
        if (entity == null) {
          return const Err(
            SerializationError('identity response missing ids'),
          );
        }
        return Ok(entity);
      case Err(:final error):
        return Err(error);
    }
  }

  @override
  Future<void> save(Identity identity) => _local.write(identity);
}
