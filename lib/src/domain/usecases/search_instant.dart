import '../../core/result.dart';
import '../entities/identity.dart';
import '../entities/instant_search_item.dart';
import '../repositories/search_repository.dart';

/// Instant autocomplete search — mirrors the shim's `runInstant` (without the
/// DOM overlay, which does not exist on mobile).
class SearchInstant {
  /// Creates the use-case.
  SearchInstant(this._repository);

  final SearchRepository _repository;

  /// Autocompletes [query] for [identity] in [cityId] (city is mandatory).
  Future<Result<List<InstantSearchItem>>> call({
    required String query,
    required Identity identity,
    required String cityId,
    required String source,
    String? userId,
    int? limit,
    String? lang,
  }) {
    return _repository.instant(
      query: query,
      cityId: cityId,
      source: source,
      anonymousId: identity.anonymousId,
      userId: userId,
      limit: limit,
      lang: lang,
    );
  }
}
