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
    List<String>? brands,
    List<String>? categories,
    int? page,
    int? perPage,
    int? priceMin,
    int? priceMax,
    String? lang,
    String? sort,
    Map<String, List<String>>? paramFilters,
  }) async {
    final res = await _remote.getSearch(
      {
        'q': query,
        'city_id': cityId,
        'source': source,
        'anonymous_id': anonymousId,
        'user_id': userId,
        'page': page?.toString(),
        'per_page': perPage?.toString(),
        'price_min': priceMin?.toString(),
        'price_max': priceMax?.toString(),
        'lang': lang,
        'sort': sort,
      },
      paramFilters: paramFilters,
      multiParams: {
        'brand': _merge(brand, brands),
        'category': _merge(category, categories),
      },
    );
    return res.map((m) => m.toEntity());
  }

  /// Merges the single value and its plural alias into one list without
  /// duplicates, dropping blanks (same semantics as the web shim).
  static List<String> _merge(String? single, List<String>? many) {
    final out = <String>[];
    for (final v in [if (single != null) single, ...?many]) {
      final t = v.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }
    return out;
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
