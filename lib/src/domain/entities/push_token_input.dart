/// Input for registering a device push token
/// (`POST /api/v1/push/tokens`).
///
/// The SDK does not integrate Firebase itself: the host app obtains [token]
/// from `FirebaseMessaging` and passes it through. `anonymous_id` is injected
/// from the current identity.
class PushTokenInput {
  /// Creates a push token registration input.
  const PushTokenInput({
    required this.token,
    required this.platform,
    this.userId,
  });

  /// The FCM device token.
  final String token;

  /// Device platform (e.g. `android`, `ios`).
  final String platform;

  /// Authenticated user id, if known.
  final String? userId;
}
