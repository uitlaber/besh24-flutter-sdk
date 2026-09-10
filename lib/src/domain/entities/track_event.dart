/// The set of tracking event types accepted by `POST /api/v1/events`.
///
/// Mirrors `EVENT_TYPES` in `packages/shared` and the `buildTrackEvent` switch
/// in the web shim.
enum TrackEventType {
  /// Product page view.
  view,

  /// Category page view.
  category,

  /// Add to cart.
  cart,

  /// Remove from cart.
  removeFromCart,

  /// Add to wishlist.
  wish,

  /// Remove from wishlist.
  removeWish,

  /// Completed purchase.
  purchase,

  /// Search performed.
  search,

  /// Click on a product inside a recommendation block.
  recommendationClick,

  /// Landed on the site (session start). No product/page context.
  visit,

  /// Opened a page, identified by its path.
  pageOpen,

  /// Left a review for a product.
  review;

  /// The wire value sent in the event `type` field (snake_case).
  String get wire => switch (this) {
        TrackEventType.view => 'view',
        TrackEventType.category => 'category',
        TrackEventType.cart => 'cart',
        TrackEventType.removeFromCart => 'remove_from_cart',
        TrackEventType.wish => 'wish',
        TrackEventType.removeWish => 'remove_wish',
        TrackEventType.purchase => 'purchase',
        TrackEventType.search => 'search',
        TrackEventType.recommendationClick => 'recommendation_click',
        TrackEventType.visit => 'visit',
        TrackEventType.pageOpen => 'page_open',
        TrackEventType.review => 'review',
      };

  /// Parses a wire [value] into a [TrackEventType], or `null` if unknown.
  static TrackEventType? fromWire(String value) {
    for (final t in TrackEventType.values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// A fully-formed tracking event ready to be batched to the backend.
///
/// Built by [TrackEventUsecase] from the current [Identity] plus a per-type
/// payload; the [source] channel is stamped on every event.
class TrackEvent {
  /// Creates a tracking event.
  const TrackEvent({
    required this.eventId,
    required this.type,
    required this.anonymousId,
    required this.sessionId,
    required this.ts,
    required this.source,
    required this.payload,
    this.userId,
    this.cityId,
  });

  /// UUID v4 uniquely identifying this event.
  final String eventId;

  /// Event type.
  final TrackEventType type;

  /// Anonymous device id.
  final String anonymousId;

  /// Session id.
  final String sessionId;

  /// Event timestamp (UTC; serialized as ISO-8601 with a `Z` suffix).
  final DateTime ts;

  /// Analytics source channel (e.g. `app`).
  final String source;

  /// Type-specific payload.
  final Map<String, Object?> payload;

  /// Authenticated user id, if known.
  final String? userId;

  /// City context id, if known.
  final String? cityId;
}
