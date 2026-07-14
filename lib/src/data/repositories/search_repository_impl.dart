import '../../core/result.dart';
import '../../domain/entities/instant_search_item.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/besh24_remote_data_source.dart';

/// [SearchRepository] mapping search/instant queries and response models.
class SearchRepositoryImpl implements SearchRepository {
  /// Creates the repository.
  SearchRepositoryImpl(this._remote);

  final Besh24RemoteDataSource _remote;

  @override
  Future<Result<SearchResult>> search({
    required String query,
    required String cityId,
    required String source,
    String? anonymousId,
    String? userId,
    String? brand,
    String? category,
    int? page,
    int? perPage,
    int? priceMin,
    int? priceMax,
    String? lang,
  }) async {
    final res = await _remote.getSearch({
      'q': query,
      'city_id': cityId,
      'source': source,
      'anonymous_id': anonymousId,
      'user_id': userId,
      'brand': brand,
      'category': category,
      'page': page?.toString(),
      'per_page': perPage?.toString(),
      'price_min': priceMin?.toString(),
      'price_max': priceMax?.toString(),
      'lang': lang,
    });
    return res.map((m) => m.toEntity());
  }

  @override
  Future<Result<List<InstantSearchItem>>> instant({
    required String query,
    required String cityId,
    required String source,
    String? anonymousId,
    String? userId,
    int? limit,
    String? lang,
  }) async {
    final res = await _remote.getInstant({
      'q': query,
      'city_id': cityId,
      'source': source,
      'anonymous_id': anonymousId,
      'user_id': userId,
      'limit': limit?.toString(),
      'lang': lang,
    });
    return res.map(
      (list) => list.map((m) => m.toEntity()).toList(growable: false),
    );
  }
}
