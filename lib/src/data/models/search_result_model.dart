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

/// Wire model for `GET /api/v1/search` → `{items, total, page, facets}`.
class SearchResultModel {
  /// Creates a model.
  const SearchResultModel({
    required this.items,
    required this.total,
    required this.page,
    required this.facets,
  });

  /// Matched products.
  final List<SearchProductModel> items;

  /// Total matches.
  final int total;

  /// Current page.
  final int page;

  /// Raw facets map.
  final Map<String, Object?> facets;

  /// Parses the response body.
  factory SearchResultModel.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map((e) => SearchProductModel.fromJson(e.cast<String, Object?>()))
            .toList(growable: false)
        : const <SearchProductModel>[];
    final facets = json['facets'];
    return SearchResultModel(
      items: items,
      total: asInt(json['total']),
      page: asInt(json['page'], fallback: 1),
      facets: facets is Map ? facets.cast<String, Object?>() : const {},
    );
  }

  /// Maps to a domain [SearchResult].
  SearchResult toEntity() => SearchResult(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        total: total,
        page: page,
        facets: facets,
      );
}
