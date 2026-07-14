import '../../domain/entities/identity.dart';
import '../../domain/entities/profile_input.dart';
import '../../domain/entities/restock_input.dart';
import '../../domain/entities/track_event.dart';

/// Serializes outbound request bodies to the exact wire shapes the backend
/// expects (mirrors the web shim's body construction).
///
/// Timestamps are emitted as ISO-8601 UTC with a trailing `Z`
/// (`DateTime.toUtc().toIso8601String()`), satisfying zod's `.datetime()`.
class WireSerializers {
  const WireSerializers._();

  /// A single tracking event → the object placed inside `{events:[...]}`.
  static Map<String, Object?> trackEvent(TrackEvent e) => {
        'event_id': e.eventId,
        'type': e.type.wire,
        'anonymous_id': e.anonymousId,
        'session_id': e.sessionId,
        'ts': e.ts.toUtc().toIso8601String(),
        'source': e.source,
        if (e.userId != null && e.userId!.isNotEmpty) 'user_id': e.userId,
        if (e.cityId != null && e.cityId!.isNotEmpty) 'city_id': e.cityId,
        'payload': e.payload,
      };

  /// `POST /api/v1/profile` body.
  static Map<String, Object?> profile(Identity identity, ProfileInput p) => {
        'anonymous_id': identity.anonymousId,
        if (p.userId != null && p.userId!.isNotEmpty) 'user_id': p.userId,
        if (p.email != null && p.email!.isNotEmpty) 'email': p.email,
        if (p.phone != null && p.phone!.isNotEmpty) 'phone': p.phone,
        if (p.gender != null) 'gender': p.gender!.wire,
        if (p.birthday != null)
          'birthday': p.birthday!.toUtc().toIso8601String(),
        if (p.cityId != null && p.cityId!.isNotEmpty) 'city_id': p.cityId,
      };

  /// `POST /api/v1/subscriptions/restock` body. [cityId] is already resolved
  /// (input city or the client default).
  static Map<String, Object?> restock(
    Identity identity,
    RestockInput r,
    String cityId,
  ) =>
      {
        'item_id': r.itemId,
        'city_id': cityId,
        'anonymous_id': identity.anonymousId,
        if (r.userId != null && r.userId!.isNotEmpty) 'user_id': r.userId,
        if (r.email != null && r.email!.isNotEmpty) 'email': r.email,
        if (r.phone != null && r.phone!.isNotEmpty) 'phone': r.phone,
      };
}
