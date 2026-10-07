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
    List<String>? itemIds,
    List<String>? categoryIds,
    String? searchQuery,
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
      // Array context goes as comma-joined lists (the server splits them).
      'cart_item_ids': _csv(itemIds),
      'category_ids': _csv(categoryIds),
      'search_query': _clean(searchQuery),
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

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static String? _csv(List<String>? ids) {
    final list = _cleanList(ids);
    return list.isEmpty ? null : list.join(',');
  }

  static List<String> _cleanList(List<String>? ids) => (ids ?? const [])
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  Map<String, Object?> _blockToJson(RecommendationBlockRequest b) => {
        'block_id': b.blockCode,
        if (b.itemId != null && b.itemId!.isNotEmpty) 'item_id': b.itemId,
        if (b.categoryId != null && b.categoryId!.isNotEmpty)
          'category_id': b.categoryId,
        if (b.brand != null && b.brand!.isNotEmpty) 'brand': b.brand,
        if (_cleanList(b.itemIds ?? b.cartItemIds).isNotEmpty)
          'item_ids': _cleanList(b.itemIds ?? b.cartItemIds),
        if (_cleanList(b.categoryIds).isNotEmpty)
          'category_ids': _cleanList(b.categoryIds),
      };
}
