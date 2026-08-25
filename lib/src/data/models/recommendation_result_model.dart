import '../../domain/entities/recommendation_batch.dart';
import '../../domain/entities/recommendation_result.dart';
import 'json_coerce.dart';

/// Wire model for one entry of an `extended` response's `products` map.
class RecommendationEnrichedItemModel {
  /// Creates a model.
  const RecommendationEnrichedItemModel({
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

  /// Product id.
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

  /// Stock count for the request's city, or `null` if unknown.
  final int? stock;

  /// Parses one `products[id]` entry.
  factory RecommendationEnrichedItemModel.fromJson(
    String id,
    Map<String, Object?> json,
  ) {
    final stockRaw = json['stock'];
    return RecommendationEnrichedItemModel(
      id: id,
      name: (json['name'] ?? '').toString(),
      nameKk: json['nameKk'] as String?,
      slug: json['slug'] as String?,
      url: json['url'] as String?,
      imageUrl: json['imageUrl'] as String?,
      brand: json['brand'] as String?,
      price: asNum(json['price']),
      oldPrice: json['oldPrice'] == null ? null : asNum(json['oldPrice']),
      discountPercent: json['discountPercent'] == null
          ? null
          : asNum(json['discountPercent']),
      rating: json['rating'] == null ? null : asNum(json['rating']),
      badges: json['badges'],
      available: json['available'] == true,
      fromDc: json['fromDc'] == true,
      stock: stockRaw == null ? null : asInt(stockRaw),
    );
  }

  /// Maps to a domain [RecommendationEnrichedItem].
  RecommendationEnrichedItem toEntity() => RecommendationEnrichedItem(
        id: id,
        name: name,
        nameKk: nameKk,
        slug: slug,
        url: url,
        imageUrl: imageUrl,
        brand: brand,
        price: price,
        oldPrice: oldPrice,
        discountPercent: discountPercent,
        rating: rating,
        badges: badges,
        available: available,
        fromDc: fromDc,
        stock: stock,
      );
}

/// Wire model for `GET /api/v1/recommendations` → `{items, request_id,
/// title?, url?, products?}`, and for one entry of a batch response's
/// `blocks` map (same shape, minus `request_id`).
class RecommendationResultModel {
  /// Creates a model.
  const RecommendationResultModel({
    required this.itemIds,
    required this.requestId,
    this.title,
    this.url,
    this.products,
  });

  /// Ordered product ids.
  final List<String> itemIds;

  /// Request id.
  final String requestId;

  /// Block title, if any.
  final String? title;

  /// Link associated with [title], if any.
  final String? url;

  /// Id → catalog fields, present only when `extended` was requested.
  final Map<String, RecommendationEnrichedItemModel>? products;

  /// Parses the response body of `GET /api/v1/recommendations`.
  factory RecommendationResultModel.fromJson(Map<String, Object?> json) {
    return RecommendationResultModel(
      itemIds: _parseItemIds(json['items']),
      requestId: (json['request_id'] ?? '').toString(),
      title: json['title'] as String?,
      url: json['url'] as String?,
      products: _parseProducts(json['products']),
    );
  }

  /// Parses one entry of a batch response's `blocks` map, which has no
  /// `request_id` of its own — [requestId] is supplied by the caller (the
  /// batch-level id).
  factory RecommendationResultModel.fromBatchBlockJson(
    Map<String, Object?> json,
    String requestId,
  ) {
    return RecommendationResultModel(
      itemIds: _parseItemIds(json['items']),
      requestId: requestId,
      title: json['title'] as String?,
      url: json['url'] as String?,
      products: _parseProducts(json['products']),
    );
  }

  /// `items` may hold strings or numbers — both are coerced to strings,
  /// matching the catalog's mixed id typing.
  static List<String> _parseItemIds(Object? raw) => raw is List
      ? raw.map((e) => e.toString()).toList(growable: false)
      : const <String>[];

  static Map<String, RecommendationEnrichedItemModel>? _parseProducts(
    Object? raw,
  ) {
    if (raw is! Map) return null;
    final result = <String, RecommendationEnrichedItemModel>{};
    raw.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = RecommendationEnrichedItemModel.fromJson(
          key.toString(),
          value.cast<String, Object?>(),
        );
      }
    });
    return result;
  }

  /// Maps to a domain [RecommendationResult].
  RecommendationResult toEntity() => RecommendationResult(
        itemIds: itemIds,
        requestId: requestId,
        title: title,
        url: url,
        products: products?.map((k, v) => MapEntry(k, v.toEntity())),
      );
}

/// Wire model for `POST /api/v1/recommendations/batch` →
/// `{request_id, blocks: {block_id: {...}}}`.
class RecommendationsBatchResultModel {
  /// Creates a model.
  const RecommendationsBatchResultModel({
    required this.requestId,
    required this.blocks,
  });

  /// Batch-level request id.
  final String requestId;

  /// Block code → its parsed result.
  final Map<String, RecommendationResultModel> blocks;

  /// Parses the response body.
  factory RecommendationsBatchResultModel.fromJson(Map<String, Object?> json) {
    final requestId = (json['request_id'] ?? '').toString();
    final rawBlocks = json['blocks'];
    final blocks = <String, RecommendationResultModel>{};
    if (rawBlocks is Map) {
      rawBlocks.forEach((key, value) {
        if (value is Map) {
          blocks[key.toString()] = RecommendationResultModel.fromBatchBlockJson(
            value.cast<String, Object?>(),
            requestId,
          );
        }
      });
    }
    return RecommendationsBatchResultModel(
      requestId: requestId,
      blocks: blocks,
    );
  }

  /// Maps to a domain [RecommendationBatchResult].
  RecommendationBatchResult toEntity() => RecommendationBatchResult(
        requestId: requestId,
        blocks: blocks.map((k, v) => MapEntry(k, v.toEntity())),
      );
}
