import '../../domain/entities/recommendation_result.dart';

/// Wire model for `GET /api/v1/recommendations` → `{items:[id...], request_id}`.
class RecommendationResultModel {
  /// Creates a model.
  const RecommendationResultModel({
    required this.itemIds,
    required this.requestId,
  });

  /// Ordered product ids.
  final List<String> itemIds;

  /// Request id.
  final String requestId;

  /// Parses the response body. `items` may hold strings or numbers — both are
  /// coerced to strings, matching the catalog's mixed id typing.
  factory RecommendationResultModel.fromJson(Map<String, Object?> json) {
    final raw = json['items'];
    final ids = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    return RecommendationResultModel(
      itemIds: ids,
      requestId: (json['request_id'] ?? '').toString(),
    );
  }

  /// Maps to a domain [RecommendationResult].
  RecommendationResult toEntity() =>
      RecommendationResult(itemIds: itemIds, requestId: requestId);
}
