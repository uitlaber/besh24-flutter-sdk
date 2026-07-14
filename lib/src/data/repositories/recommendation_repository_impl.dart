import '../../core/result.dart';
import '../../domain/entities/recommendation_result.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/besh24_remote_data_source.dart';

/// [RecommendationRepository] mapping the query and response model.
class RecommendationRepositoryImpl implements RecommendationRepository {
  /// Creates the repository.
  RecommendationRepositoryImpl(this._remote);

  final Besh24RemoteDataSource _remote;

  @override
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
  }) async {
    final res = await _remote.getRecommendations({
      'besh24_block_id': blockCode,
      'city_id': cityId,
      'source': source,
      'anonymous_id': anonymousId,
      'user_id': userId,
      'item_id': itemId,
      'category_id': categoryId,
      'brand': brand,
      'limit': limit?.toString(),
    });
    return res.map((m) => m.toEntity());
  }
}
