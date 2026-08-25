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

/// One brand facet entry (`facets.brand[]`).
class SearchBrandFacet {
  /// Creates a brand facet entry.
  const SearchBrandFacet({required this.value, required this.count});

  /// Brand name.
  final String value;

  /// Number of matches with this brand.
  final int count;
}

/// One category facet entry (`facets.category[]`).
class SearchCategoryFacet {
  /// Creates a category facet entry.
  const SearchCategoryFacet({
    required this.id,
    required this.value,
    this.name,
    this.parent,
    this.url,
    this.urlHandle,
    required this.count,
  });

  /// Category id.
  final String id;

  /// Display value (category name; kept for backward compatibility with
  /// older backend responses where this was the only label field).
  final String value;

  /// Category name, if distinct from [value].
  final String? name;

  /// Parent category name, if any.
  final String? parent;

  /// Category listing URL, if any.
  final String? url;

  /// URL slug, if any.
  final String? urlHandle;

  /// Number of matches in this category.
  final int count;
}

/// One price bucket (`facets.price_ranges[]`).
class SearchPriceRangeBucket {
  /// Creates a price bucket.
  const SearchPriceRangeBucket({this.from, this.to, required this.count});

  /// Lower bound (inclusive), or `null` for the lowest open bucket.
  final num? from;

  /// Upper bound (exclusive), or `null` for the highest open bucket.
  final num? to;

  /// Number of matches in this bucket.
  final int count;
}

/// One product-characteristic facet (`facets.params[]`), e.g. "Цвет",
/// "Диагональ".
class SearchParamFacet {
  /// Creates a characteristic facet.
  const SearchParamFacet({
    required this.name,
    required this.count,
    required this.priority,
    required this.values,
    this.rangeMin,
    this.rangeMax,
  });

  /// Characteristic name. Pass back verbatim as a `filters[<name>]` key to
  /// [Besh24Client.search]'s `paramFilters`.
  final String name;

  /// Number of matches that have this characteristic at all.
  final int count;

  /// Backend-assigned display priority (higher sorts first).
  final int priority;

  /// Value → number of matches with that value.
  final Map<String, int> values;

  /// Lowest numeric value across [values], if the characteristic is
  /// numeric (e.g. "Bluetooth" versions).
  final num? rangeMin;

  /// Highest numeric value across [values], if the characteristic is
  /// numeric.
  final num? rangeMax;
}

/// Result of a full-page search request.
///
/// Mirrors `GET /api/v1/search` → `{items, total, page, facets}`.
class SearchResult {
  /// Creates a search result.
  const SearchResult({
    required this.items,
    required this.total,
    this.page = 1,
    this.facets = const {},
    this.brandFacets = const [],
    this.categoryFacets = const [],
    this.priceRangeMin,
    this.priceRangeMax,
    this.priceMedian,
    this.priceRanges = const [],
    this.paramFacets = const [],
  });

  /// Matched products for the current page.
  final List<SearchProduct> items;

  /// Total number of matches across all pages.
  final int total;

  /// Current page (1-based).
  final int page;

  /// Raw facets map as returned by the backend, kept as an escape hatch for
  /// fields not yet surfaced by the typed facet getters below.
  final Map<String, Object?> facets;

  /// Typed `facets.brand`.
  final List<SearchBrandFacet> brandFacets;

  /// Typed `facets.category`.
  final List<SearchCategoryFacet> categoryFacets;

  /// `facets.price_range.min`, if present.
  final num? priceRangeMin;

  /// `facets.price_range.max`, if present.
  final num? priceRangeMax;

  /// `facets.price_median`, if present.
  final num? priceMedian;

  /// Typed `facets.price_ranges`.
  final List<SearchPriceRangeBucket> priceRanges;

  /// Typed `facets.params` — product characteristics with per-value counts.
  /// Use a facet's [SearchParamFacet.name] as a `filters[<name>]` key when
  /// calling [Besh24Client.search] with `paramFilters` to narrow by it.
  final List<SearchParamFacet> paramFacets;
}
