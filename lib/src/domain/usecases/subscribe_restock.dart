import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/restock_input.dart';
import '../repositories/subscription_repository.dart';

/// Creates a restock subscription — mirrors the shim's `doSubscribeTrigger`
/// (`subscribe_trigger product_available`).
class SubscribeRestock {
  /// Creates the use-case.
  SubscribeRestock(this._repository);

  final SubscriptionRepository _repository;

  /// Subscribes for [input] under [identity]. Rejects input with no contact.
  Future<Result<void>> call(Identity identity, RestockInput input) async {
    if (!input.hasContact) {
      return const Err(
        ValidationError('restock subscription requires email or phone'),
      );
    }
    return _repository.subscribeRestock(identity, input);
  }
}
