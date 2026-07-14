import '../../core/config.dart';
import '../../core/result.dart';
import '../../domain/entities/identity.dart';
import '../../domain/entities/restock_input.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/besh24_remote_data_source.dart';
import '../models/wire_serializers.dart';

/// [SubscriptionRepository] resolving the city default and serializing the body.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  /// Creates the repository.
  SubscriptionRepositoryImpl({
    required Besh24RemoteDataSource remote,
    required Besh24Config config,
  })  : _remote = remote,
        _config = config;

  final Besh24RemoteDataSource _remote;
  final Besh24Config _config;

  @override
  Future<Result<void>> subscribeRestock(Identity identity, RestockInput input) {
    final cityId = (input.cityId != null && input.cityId!.isNotEmpty)
        ? input.cityId!
        : _config.defaultCityId;
    return _remote.postRestock(
      WireSerializers.restock(identity, input, cityId),
    );
  }
}
