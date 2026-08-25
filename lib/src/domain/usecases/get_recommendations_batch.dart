import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/recommendation_batch.dart';
import '../repositories/recommendation_repository.dart';

/// Requests N recommendation blocks in one round trip.
class GetRecommendationsBatch {
  /// Creates the use-case.
  GetRecommendationsBatch(this._repository);

  final RecommendationRepository _repository;

  /// Fetches [blocks] for [identity] in [cityId], stamping [source].
  Future<Result<RecommendationBatchResult>> call({
    required List<RecommendationBlockRequest> blocks,
    required Identity identity,
    required String cityId,
    required String source,
    String? userId,
    bool extended = false,
  }) {
    return _repository.recommendBatch(
      blocks: blocks,
      cityId: cityId,
      source: source,
      anonymousId: identity.anonymousId,
      userId: userId,
      extended: extended,
    );
  }
}
