import '../../core/result.dart';
import '../entities/instant_search_item.dart';
import '../entities/search_result.dart';

/// Full-page and instant search over `GET /api/v1/search[/instant]`.
abstract interface class SearchRepository {
  /// Full-page search. [query] is sent as `q`.
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
  });

  /// Instant autocomplete. [cityId] is mandatory on the wire.
  Future<Result<List<InstantSearchItem>>> instant({
    required String query,
    required String cityId,
    required String source,
    String? anonymousId,
    String? userId,
    int? limit,
    String? lang,
  });
}
