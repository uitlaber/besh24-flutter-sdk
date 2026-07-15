import '../../core/result.dart';
import '../repositories/push_token_repository.dart';

/// Revokes a device push token.
class UnregisterPushToken {
  /// Creates the use-case.
  UnregisterPushToken(this._repository);

  final PushTokenRepository _repository;

  /// Revokes [token]. Rejects an empty token.
  Future<Result<void>> call(String token) async {
    if (token.isEmpty) {
      return const Err(
        ValidationError('push token revocation requires a token'),
      );
    }
    return _repository.unregisterPushToken(token);
  }
}
