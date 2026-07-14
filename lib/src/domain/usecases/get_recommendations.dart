import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/recommendation_result.dart';
import '../repositories/recommendation_repository.dart';

/// Requests a recommendation block — mirrors the shim's `doRecommend`.
class GetRecommendations {
  /// Creates the use-case.
  GetRecommendations(this._repository);

  final RecommendationRepository _repository;

  /// Fetches [blockCode] for [identity] in [cityId], stamping [source].
  Future<Result<RecommendationResult>> call({
    required String blockCode,
    required Identity identity,
    required String cityId,
    required String source,
    String? userId,
    String? itemId,
    String? categoryId,
    String? brand,
    int? limit,
  }) {
    return _repository.recommend(
      blockCode: blockCode,
      cityId: cityId,
      source: source,
      anonymousId: identity.anonymousId,
      userId: userId,
      itemId: itemId,
      categoryId: categoryId,
      brand: brand,
      limit: limit,
    );
  }
}
