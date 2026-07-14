import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/profile_input.dart';

/// Upserts the visitor profile via `POST /api/v1/profile`.
abstract interface class ProfileRepository {
  /// Sends [input] for the given [identity]. Returns [Ok] on 200.
  Future<Result<void>> setProfile(Identity identity, ProfileInput input);
}
