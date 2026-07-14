import '../../core/result.dart';
import '../../domain/entities/identity.dart';
import '../../domain/entities/profile_input.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/besh24_remote_data_source.dart';
import '../models/wire_serializers.dart';

/// [ProfileRepository] serializing the profile upsert body.
class ProfileRepositoryImpl implements ProfileRepository {
  /// Creates the repository.
  ProfileRepositoryImpl(this._remote);

  final Besh24RemoteDataSource _remote;

  @override
  Future<Result<void>> setProfile(Identity identity, ProfileInput input) {
    return _remote.postProfile(WireSerializers.profile(identity, input));
  }
}
