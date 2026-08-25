import '../../core/result.dart';
import '../../domain/entities/recommendation_batch.dart';
import '../../domain/entities/recommendation_result.dart';
import '../../domain/repositories/recommendation_repository.dart';
import '../datasources/besh24_remote_data_source.dart';
import '../models/recommendation_result_model.dart';

/// [RecommendationRepository] mapping the query and response models.
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
    bool extended = false,
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
      if (extended) 'extended': 'true',
    });
    return res.map((m) => m.toEntity());
  }

  @override
  Future<Result<RecommendationBatchResult>> recommendBatch({
    required List<RecommendationBlockRequest> blocks,
    required String cityId,
    required String source,
    String? anonymousId,
    String? userId,
    bool extended = false,
  }) async {
    final res = await _remote.postRecommendationsBatch({
      'blocks': blocks.map(_blockToJson).toList(growable: false),
      'city_id': cityId,
      'source': source,
      if (anonymousId != null && anonymousId.isNotEmpty)
        'anonymous_id': anonymousId,
      if (userId != null && userId.isNotEmpty) 'user_id': userId,
      'extended': extended,
    });
    return res.map(
      (json) => RecommendationsBatchResultModel.fromJson(json).toEntity(),
    );
  }

  Map<String, Object?> _blockToJson(RecommendationBlockRequest b) => {
        'block_id': b.blockCode,
        if (b.itemId != null && b.itemId!.isNotEmpty) 'item_id': b.itemId,
        if (b.categoryId != null && b.categoryId!.isNotEmpty)
          'category_id': b.categoryId,
        if (b.brand != null && b.brand!.isNotEmpty) 'brand': b.brand,
        if (b.itemIds != null && b.itemIds!.isNotEmpty) 'item_ids': b.itemIds,
        if (b.categoryIds != null && b.categoryIds!.isNotEmpty)
          'category_ids': b.categoryIds,
      };
}
