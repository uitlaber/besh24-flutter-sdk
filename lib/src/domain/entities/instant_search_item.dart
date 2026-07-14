/// A suggestion item from instant (autocomplete) search.
///
/// The backend `GET /api/v1/search/instant` returns rich cards under the
/// `products` key (`SearchInstantProduct`); the SDK normalizes each into this
/// compact shape (`image_url` → [image]). There is no DOM overlay on mobile, so
/// unlike the web shim the SDK parses the product list directly.
class InstantSearchItem {
  /// Creates an instant search item.
  const InstantSearchItem({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.url,
  });

  /// Product id.
  final String id;

  /// Display name.
  final String name;

  /// Price (city-specific).
  final num price;

  /// Image URL, if any (`image_url` on the wire).
  final String? image;

  /// Product page URL, if any.
  final String? url;
}
