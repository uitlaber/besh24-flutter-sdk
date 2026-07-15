import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/push_token_input.dart';
import '../repositories/push_token_repository.dart';

/// Registers a device push token for the current identity.
class RegisterPushToken {
  /// Creates the use-case.
  RegisterPushToken(this._repository);

  final PushTokenRepository _repository;

  /// Sends [input] for [identity]. Rejects an empty token.
  Future<Result<void>> call(Identity identity, PushTokenInput input) async {
    if (input.token.isEmpty) {
      return const Err(
        ValidationError('push token registration requires a token'),
      );
    }
    return _repository.registerPushToken(identity, input);
  }
}
