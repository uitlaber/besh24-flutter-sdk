import '../../core/result.dart';
import '../../domain/entities/identity.dart';
import '../../domain/entities/push_token_input.dart';
import '../../domain/repositories/push_token_repository.dart';
import '../datasources/besh24_remote_data_source.dart';
import '../models/wire_serializers.dart';

/// [PushTokenRepository] serializing the request bodies.
class PushTokenRepositoryImpl implements PushTokenRepository {
  /// Creates the repository.
  PushTokenRepositoryImpl(this._remote);

  final Besh24RemoteDataSource _remote;

  @override
  Future<Result<void>> registerPushToken(
    Identity identity,
    PushTokenInput input,
  ) {
    return _remote.postPushToken(
      WireSerializers.pushToken(identity, input),
    );
  }

  @override
  Future<Result<void>> unregisterPushToken(String token) {
    return _remote.deletePushToken({'token': token});
  }
}
