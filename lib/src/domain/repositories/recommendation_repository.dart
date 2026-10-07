import '../../core/result.dart';
import '../entities/recommendation_batch.dart';
import '../entities/recommendation_result.dart';

/// Fetches recommendation blocks from `GET /api/v1/recommendations` and
/// `POST /api/v1/recommendations/batch`.
abstract interface class RecommendationRepository {
  /// Requests the block identified by [blockCode] (sent as `besh24_block_id`).
  /// Set [extended] to receive inline catalog fields in the result's
  /// `products` map.
  Future<Result<RecommendationResult>> recommend({
    required String blockCode,
    required String cityId,
    required String source,
    String? anonymousId,
    String? userId,
    String? itemId,
    String? categoryId,
    String? brand,
    List<String>? itemIds,
    List<String>? categoryIds,
    String? searchQuery,
    int? limit,
    bool extended = false,
  });

  /// Resolves [blocks] in one round trip. [extended] applies to the whole
  /// batch.
  Future<Result<RecommendationBatchResult>> recommendBatch({
    required List<RecommendationBlockRequest> blocks,
    required String cityId,
    required String source,
    String? anonymousId,
    String? userId,
    bool extended = false,
  });
}
