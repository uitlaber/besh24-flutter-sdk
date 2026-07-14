/// A single product card in full-page search results.
///
/// Mirrors `SearchProductSummary` in `packages/shared`.
class SearchProduct {
  /// Creates a search product.
  const SearchProduct({
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

  /// Image URL, if any.
  final String? image;

  /// Product page URL, if any.
  final String? url;
}

/// Result of a full-page search request.
///
/// Mirrors `GET /api/v1/search` → `{items, total, page, facets}`. Only the
/// stable fields are surfaced; the raw facet map is exposed as [facets].
class SearchResult {
  /// Creates a search result.
  const SearchResult({
    required this.items,
    required this.total,
    this.page = 1,
    this.facets = const {},
  });

  /// Matched products for the current page.
  final List<SearchProduct> items;

  /// Total number of matches across all pages.
  final int total;

  /// Current page (1-based).
  final int page;

  /// Raw facets map as returned by the backend (`brand`, `category`,
  /// `price_range`).
  final Map<String, Object?> facets;
}
