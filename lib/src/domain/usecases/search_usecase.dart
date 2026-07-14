import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/search_result.dart';
import '../repositories/search_repository.dart';

/// Full-page search — mirrors the shim's `doSearch`.
class SearchUsecase {
  /// Creates the use-case.
  SearchUsecase(this._repository);

  final SearchRepository _repository;

  /// Searches for [query] for [identity] in [cityId].
  Future<Result<SearchResult>> call({
    required String query,
    required Identity identity,
    required String cityId,
    required String source,
    String? userId,
    String? brand,
    String? category,
    int? page,
    int? perPage,
    int? priceMin,
    int? priceMax,
  }) {
    return _repository.search(
      query: query,
      cityId: cityId,
      source: source,
      anonymousId: identity.anonymousId,
      userId: userId,
      brand: brand,
      category: category,
      page: page,
      perPage: perPage,
      priceMin: priceMin,
      priceMax: priceMax,
    );
  }
}
