import '../../core/result.dart';
import '../entities/recommendation_result.dart';

/// Fetches recommendation blocks from `GET /api/v1/recommendations`.
abstract interface class RecommendationRepository {
  /// Requests the block identified by [blockCode] (sent as `besh24_block_id`).
  Future<Result<RecommendationResult>> recommend({
    required String blockCode,
    required String cityId,
    required String source,
    String? anonymousId,
    String? userId,
    String? itemId,
    String? categoryId,
    String? brand,
    int? limit,
  });
}
