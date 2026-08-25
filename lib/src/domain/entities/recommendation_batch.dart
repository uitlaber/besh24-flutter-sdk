import 'recommendation_result.dart';

/// One block context inside a `POST /api/v1/recommendations/batch` request.
///
/// Mirrors `recommendationsBatchBlockSchema` in `packages/shared`. Common
/// fields (city, identity, source, `extended`) live on the batch call itself;
/// only per-block overrides are here.
class RecommendationBlockRequest {
  /// Creates a block request. [blockCode] is sent as `block_id` and is also
  /// the key used to look up this block's result in
  /// [RecommendationBatchResult.blocks].
  const RecommendationBlockRequest({
    required this.blockCode,
    this.itemId,
    this.categoryId,
    this.brand,
    this.itemIds,
    this.categoryIds,
  });

  /// Block code (sent as `block_id`).
  final String blockCode;

  /// Product context, e.g. the product page the block renders on.
  final String? itemId;

  /// Category context, e.g. the category page the block renders on.
  final String? categoryId;

  /// Brand context, e.g. the brand page the block renders on.
  final String? brand;

  /// Cart/basket item ids for co-purchase style blocks. Takes priority over
  /// [itemId] when both are set, matching the backend's contract.
  final List<String>? itemIds;

  /// Category set for multi-category blocks (e.g. a catalog menu widget).
  /// Takes priority over [categoryId] when both are set.
  final List<String>? categoryIds;
}

/// Result of a `POST /api/v1/recommendations/batch` request — N blocks
/// resolved in a single round trip.
///
/// The backend issues one `request_id` for the whole batch (individual
/// blocks do not get their own); it is copied into every entry's
/// [RecommendationResult.requestId] in [blocks] for uniform impression
/// attribution.
class RecommendationBatchResult {
  /// Creates a batch result.
  const RecommendationBatchResult({
    required this.requestId,
    required this.blocks,
  });

  /// Batch-level request id.
  final String requestId;

  /// Block code → its result. A block that failed server-side resolves to an
  /// empty [RecommendationResult] rather than being omitted or failing the
  /// whole batch.
  final Map<String, RecommendationResult> blocks;
}
