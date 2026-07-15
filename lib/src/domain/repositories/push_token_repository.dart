import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/push_token_input.dart';

/// Registers/revokes device push tokens via `/api/v1/push/tokens`.
abstract interface class PushTokenRepository {
  /// Registers [input] under [identity]. Idempotent upsert; returns [Ok] on
  /// 201.
  Future<Result<void>> registerPushToken(
    Identity identity,
    PushTokenInput input,
  );

  /// Revokes [token]. Returns [Ok] on 200.
  Future<Result<void>> unregisterPushToken(String token);
}
