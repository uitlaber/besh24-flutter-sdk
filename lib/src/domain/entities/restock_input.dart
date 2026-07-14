/// Input for a restock subscription (`POST /api/v1/subscriptions/restock`).
///
/// At least one contact ([email] or [phone]) is required — the notification
/// channel is chosen from whichever is present. `anonymous_id` is injected from
/// the current identity.
class RestockInput {
  /// Creates a restock subscription input.
  const RestockInput({
    required this.itemId,
    this.cityId,
    this.email,
    this.phone,
    this.userId,
  });

  /// Product id to watch.
  final String itemId;

  /// City id; defaults to the client's configured city when omitted.
  final String? cityId;

  /// Email contact.
  final String? email;

  /// Phone contact.
  final String? phone;

  /// Authenticated user id, if known.
  final String? userId;

  /// `true` when at least one contact channel is supplied.
  bool get hasContact =>
      (email != null && email!.isNotEmpty) ||
      (phone != null && phone!.isNotEmpty);
}
