/// Catalog fields for one recommended product, present only when a request
/// opted into `extended: true`.
///
/// Mirrors `RecommendationsEnrichedItem` in `packages/shared`. Price/
/// availability/stock are city-aware (resolved against the request's
/// `city_id`, falling back to the product's global values server-side).
class RecommendationEnrichedItem {
  /// Creates an enriched item.
  const RecommendationEnrichedItem({
    required this.id,
    required this.name,
    this.nameKk,
    this.slug,
    this.url,
    this.imageUrl,
    this.brand,
    required this.price,
    this.oldPrice,
    this.discountPercent,
    this.rating,
    this.badges,
    required this.available,
    required this.fromDc,
    this.stock,
  });

  /// Product id (matches an entry in the parent [RecommendationResult.itemIds]).
  final String id;

  /// Display name (`ru`).
  final String name;

  /// Display name (`kk`), if translated.
  final String? nameKk;

  /// URL slug, if any.
  final String? slug;

  /// Product page URL, if any.
  final String? url;

  /// Product image URL, if any.
  final String? imageUrl;

  /// Brand name, if any.
  final String? brand;

  /// Current price for the request's city.
  final num price;

  /// Pre-discount price, if the product is discounted.
  final num? oldPrice;

  /// Discount percentage, if any.
  final num? discountPercent;

  /// Rating, if any.
  final num? rating;

  /// Raw badges payload, backend-defined shape.
  final Object? badges;

  /// Whether the product is available in the request's city.
  final bool available;

  /// Whether the product ships from a distribution center (per-city).
  final bool fromDc;

  /// Stock count for the request's city, or `null` if unknown (not `0`).
  final int? stock;
}

/// Result of a recommendations request.
///
/// Mirrors `GET /api/v1/recommendations` → `{items, request_id, title?, url?,
/// products?}`. By default only an ordered list of product ids is returned;
/// card enrichment (name, price, image) is the app's responsibility. Pass
/// `extended: true` to [Besh24Client.recommend] to receive [products] inline
/// instead of making a second lookup call.
///
/// An empty [itemIds] is a normal, valid response (e.g. no candidates matched
/// the block's rules) — it is not distinguishable from a degraded/error
/// result at this layer; callers that need to tell the two apart should
/// inspect the [Result] returned by [Besh24Client.recommend] rather than the
/// emptiness of this list.
class RecommendationResult {
  /// Creates a recommendation result.
  const RecommendationResult({
    required this.itemIds,
    required this.requestId,
    this.title,
    this.url,
    this.products,
  });

  /// Ordered product ids to display.
  final List<String> itemIds;

  /// Server-issued request id, echoed back for impression attribution.
  final String requestId;

  /// Block title (`set_title` rule action or the block's own title), if any.
  final String? title;

  /// Link associated with [title], if any.
  final String? url;

  /// Id → catalog fields, present only when the request set `extended: true`.
  /// A product id in [itemIds] without a catalog entry is simply absent here.
  final Map<String, RecommendationEnrichedItem>? products;
}
