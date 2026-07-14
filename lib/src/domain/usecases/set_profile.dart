import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/profile_input.dart';
import '../repositories/profile_repository.dart';

/// Upserts the visitor profile — mirrors the shim's `doProfileSet`.
class SetProfile {
  /// Creates the use-case.
  SetProfile(this._repository);

  final ProfileRepository _repository;

  /// Sends [input] for [identity].
  Future<Result<void>> call(Identity identity, ProfileInput input) =>
      _repository.setProfile(identity, input);
}
