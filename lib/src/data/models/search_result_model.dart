import '../../domain/entities/search_result.dart';
import 'json_coerce.dart';

/// Wire model for a full-page search product card.
class SearchProductModel {
  /// Creates a model.
  const SearchProductModel({
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

  /// Price.
  final num price;

  /// Image URL.
  final String? image;

  /// Product URL.
  final String? url;

  /// Parses one `items[]` entry.
  factory SearchProductModel.fromJson(Map<String, Object?> json) =>
      SearchProductModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        price: asNum(json['price']),
        image: json['image'] as String?,
        url: json['url'] as String?,
      );

  /// Maps to a domain [SearchProduct].
  SearchProduct toEntity() =>
      SearchProduct(id: id, name: name, price: price, image: image, url: url);
}

/// Parses `facets.brand[]`.
List<SearchBrandFacet> _parseBrandFacets(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<Object?, Object?>>()
      .map((e) => e.cast<String, Object?>())
      .map(
        (e) => SearchBrandFacet(
          value: (e['value'] ?? '').toString(),
          count: asInt(e['count']),
        ),
      )
      .toList(growable: false);
}

/// Parses `facets.category[]`.
List<SearchCategoryFacet> _parseCategoryFacets(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<Object?, Object?>>()
      .map((e) => e.cast<String, Object?>())
      .map(
        (e) => SearchCategoryFacet(
          id: (e['id'] ?? '').toString(),
          value: (e['value'] ?? '').toString(),
          name: e['name'] as String?,
          parent: e['parent'] as String?,
          url: e['url'] as String?,
          urlHandle: e['url_handle'] as String?,
          count: asInt(e['count']),
        ),
      )
      .toList(growable: false);
}

/// Parses `facets.price_ranges[]`.
List<SearchPriceRangeBucket> _parsePriceRanges(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<Object?, Object?>>()
      .map((e) => e.cast<String, Object?>())
      .map(
        (e) => SearchPriceRangeBucket(
          from: e['from'] == null ? null : asNum(e['from']),
          to: e['to'] == null ? null : asNum(e['to']),
          count: asInt(e['count']),
        ),
      )
      .toList(growable: false);
}

/// Parses `facets.params[]`.
List<SearchParamFacet> _parseParamFacets(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<Object?, Object?>>()
      .map((e) => e.cast<String, Object?>())
      .map((e) {
    final rawValues = e['values'];
    final values = <String, int>{
      if (rawValues is Map)
        for (final entry in rawValues.entries)
          entry.key.toString(): asInt(entry.value),
    };
    final ranges = e['ranges'];
    num? rangeMin;
    num? rangeMax;
    if (ranges is Map) {
      if (ranges['min'] != null) rangeMin = asNum(ranges['min']);
      if (ranges['max'] != null) rangeMax = asNum(ranges['max']);
    }
    return SearchParamFacet(
      name: (e['name'] ?? '').toString(),
      count: asInt(e['count']),
      priority: asInt(e['priority']),
      values: values,
      rangeMin: rangeMin,
      rangeMax: rangeMax,
    );
  }).toList(growable: false);
}

/// Wire model for `GET /api/v1/search` → `{items, total, page, facets}`.
class SearchResultModel {
  /// Creates a model.
  const SearchResultModel({
    required this.items,
    required this.total,
    required this.page,
    required this.facets,
    required this.brandFacets,
    required this.categoryFacets,
    this.priceRangeMin,
    this.priceRangeMax,
    this.priceMedian,
    required this.priceRanges,
    required this.paramFacets,
  });

  /// Matched products.
  final List<SearchProductModel> items;

  /// Total matches.
  final int total;

  /// Current page.
  final int page;

  /// Raw facets map.
  final Map<String, Object?> facets;

  /// Parsed `facets.brand`.
  final List<SearchBrandFacet> brandFacets;

  /// Parsed `facets.category`.
  final List<SearchCategoryFacet> categoryFacets;

  /// `facets.price_range.min`.
  final num? priceRangeMin;

  /// `facets.price_range.max`.
  final num? priceRangeMax;

  /// `facets.price_median`.
  final num? priceMedian;

  /// Parsed `facets.price_ranges`.
  final List<SearchPriceRangeBucket> priceRanges;

  /// Parsed `facets.params`.
  final List<SearchParamFacet> paramFacets;

  /// Parses the response body.
  factory SearchResultModel.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map((e) => SearchProductModel.fromJson(e.cast<String, Object?>()))
            .toList(growable: false)
        : const <SearchProductModel>[];
    final rawFacets = json['facets'];
    final facets = rawFacets is Map
        ? rawFacets.cast<String, Object?>()
        : const <String, Object?>{};
    final priceRange = facets['price_range'];
    num? priceRangeMin;
    num? priceRangeMax;
    if (priceRange is Map) {
      if (priceRange['min'] != null) priceRangeMin = asNum(priceRange['min']);
      if (priceRange['max'] != null) priceRangeMax = asNum(priceRange['max']);
    }
    return SearchResultModel(
      items: items,
      total: asInt(json['total']),
      page: asInt(json['page'], fallback: 1),
      facets: facets,
      brandFacets: _parseBrandFacets(facets['brand']),
      categoryFacets: _parseCategoryFacets(facets['category']),
      priceRangeMin: priceRangeMin,
      priceRangeMax: priceRangeMax,
      priceMedian:
          facets['price_median'] == null ? null : asNum(facets['price_median']),
      priceRanges: _parsePriceRanges(facets['price_ranges']),
      paramFacets: _parseParamFacets(facets['params']),
    );
  }

  /// Maps to a domain [SearchResult].
  SearchResult toEntity() => SearchResult(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        total: total,
        page: page,
        facets: facets,
        brandFacets: brandFacets,
        categoryFacets: categoryFacets,
        priceRangeMin: priceRangeMin,
        priceRangeMax: priceRangeMax,
        priceMedian: priceMedian,
        priceRanges: priceRanges,
        paramFacets: paramFacets,
      );
}
