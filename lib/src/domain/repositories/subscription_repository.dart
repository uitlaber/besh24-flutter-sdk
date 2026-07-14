import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/restock_input.dart';

/// Creates restock subscriptions via `POST /api/v1/subscriptions/restock`.
abstract interface class SubscriptionRepository {
  /// Subscribes for [input] under [identity]. Returns [Ok] on 201.
  Future<Result<void>> subscribeRestock(Identity identity, RestockInput input);
}
