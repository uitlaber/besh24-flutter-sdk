import 'dart:convert';

import '../../core/config.dart';
import '../../core/http/besh24_http_client.dart';
import '../../core/logger.dart';
import '../../core/result.dart';
import '../models/identity_model.dart';
import '../models/instant_search_item_model.dart';
import '../models/recommendation_result_model.dart';
import '../models/search_result_model.dart';

/// Talks to the Besh24 HTTP API. Owns URL/query construction, status handling
/// and JSON decoding; returns typed models wrapped in [Result].
///
/// Never throws: transport failures arrive as [NetworkError] from the
/// [Besh24HttpClient], non-2xx as [ApiError], bad bodies as
/// [SerializationError].
class Besh24RemoteDataSource {
  /// Creates the data source.
  Besh24RemoteDataSource({
    required Besh24HttpClient http,
    required this.config,
    Besh24Logger logger = const DefaultBesh24Logger(),
  })  : _http = http,
        _logger = logger;

  final Besh24HttpClient _http;

  /// Client configuration (base URL, cookie behaviour).
  final Besh24Config config;
  final Besh24Logger _logger;

  /// `GET /identity`. When [config.sendCookies] is on and ids are supplied,
  /// resends them so the backend reuses the same identity.
  Future<Result<IdentityModel>> getIdentity({
    String? anonymousId,
    String? sessionId,
  }) async {
    final headers = _headers();
    if (config.sendCookies) {
      final cookie = _cookieHeader(anonymousId, sessionId);
      if (cookie != null) headers['Cookie'] = cookie;
    }
    final res = await _http.get(_uri('/identity'), headers: headers);
    return _decode(res, (json) => IdentityModel.fromJson(json));
  }

  /// `POST /events` (batch). Expects 202.
  Future<Result<void>> postEvents(List<Map<String, Object?>> events) {
    return _postVoid('/events', {'events': events});
  }

  /// `POST /profile`. Expects 200.
  Future<Result<void>> postProfile(Map<String, Object?> body) {
    return _postVoid('/profile', body);
  }

  /// `POST /subscriptions/restock`. Expects 201.
  Future<Result<void>> postRestock(Map<String, Object?> body) {
    return _postVoid('/subscriptions/restock', body);
  }

  /// `POST /push/tokens`. Expects 201 (idempotent upsert).
  Future<Result<void>> postPushToken(Map<String, Object?> body) {
    return _postVoid('/push/tokens', body);
  }

  /// `DELETE /push/tokens`. Expects 200.
  Future<Result<void>> deletePushToken(Map<String, Object?> body) async {
    final res = await _http.delete(
      _uri('/push/tokens'),
      headers: _headers(const {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    switch (res) {
      case Ok<Besh24HttpResponse>(:final value):
        if (value.isOk) return const Ok(null);
        return Err(_apiError(value));
      case Err<Besh24HttpResponse>(:final error):
        return Err(error);
    }
  }

  /// `GET /recommendations`. Set `params['extended'] = 'true'` to receive
  /// inline catalog fields in the response's `products` map.
  Future<Result<RecommendationResultModel>> getRecommendations(
    Map<String, String?> params,
  ) async {
    final res = await _http.get(
      _uri('/recommendations', params),
      headers: _headers(),
    );
    return _decode(res, (json) => RecommendationResultModel.fromJson(json));
  }

  /// `POST /recommendations/batch`. Expects a JSON object body (`request_id`,
  /// `blocks`), decoded but not otherwise interpreted here.
  Future<Result<Map<String, Object?>>> postRecommendationsBatch(
    Map<String, Object?> body,
  ) async {
    final res = await _http.post(
      _uri('/recommendations/batch'),
      headers: _headers(const {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    return _decode(res, (json) => json);
  }

  /// `GET /search`.
  /// `GET /search`. [paramFilters] maps a product characteristic name to
  /// its selected values, sent as repeated `filters[<name>]=v` query keys
  /// (backend §4.4 — values within one characteristic are OR'd, different
  /// characteristics are AND'd).
  Future<Result<SearchResultModel>> getSearch(
    Map<String, String?> params, {
    Map<String, List<String>>? paramFilters,
    Map<String, List<String>>? multiParams,
  }) async {
    final query = <String, Object?>{...params};
    // One value goes as a scalar, several as a repeated key (never joined by
    // a comma: values may contain commas themselves).
    multiParams?.forEach((key, values) {
      if (values.isEmpty) return;
      query[key] = values.length == 1 ? values.first : values;
    });
    if (paramFilters != null) {
      for (final entry in paramFilters.entries) {
        final values =
            entry.value.where((v) => v.isNotEmpty).toList(growable: false);
        if (values.isEmpty) continue;
        query['filters[${entry.key}]'] = values;
      }
    }
    final res = await _http.get(_uri('/search', query), headers: _headers());
    return _decode(res, (json) => SearchResultModel.fromJson(json));
  }

  /// `GET /search/instant`. Reads the `products` array.
  Future<Result<List<InstantSearchItemModel>>> getInstant(
    Map<String, String?> params,
  ) async {
    final res = await _http.get(
      _uri('/search/instant', params),
      headers: _headers(),
    );
    return _decodeList(
      res,
      'products',
      (json) => InstantSearchItemModel.fromJson(json),
    );
  }

  // --- internals ---------------------------------------------------------

  /// Builds the headers sent on every request, always including the tenant
  /// `X-Besh24-Site-Key`. Merges in [extra] (e.g. `Content-Type`).
  Map<String, String> _headers([Map<String, String>? extra]) => {
        'X-Besh24-Site-Key': config.siteKey,
        ...?extra,
      };

  Future<Result<void>> _postVoid(String path, Object body) async {
    final res = await _http.post(
      _uri(path),
      headers: _headers(const {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    switch (res) {
      case Ok<Besh24HttpResponse>(:final value):
        if (value.isOk) return const Ok(null);
        return Err(_apiError(value));
      case Err<Besh24HttpResponse>(:final error):
        return Err(error);
    }
  }

  /// Builds [path] with [query] appended. Values are either a `String`
  /// (dropped if `null`/empty) or a `List<String>` (dropped if empty),
  /// where a list encodes a repeated query key — e.g. `filters[Цвет]` sent
  /// twice for two selected values.
  Uri _uri(String path, [Map<String, Object?>? query]) {
    final base = Uri.parse('${config.baseUrl}$path');
    if (query == null) return base;
    final params = <String, Object>{};
    query.forEach((k, v) {
      if (v is String) {
        if (v.isNotEmpty) params[k] = v;
      } else if (v is List<String>) {
        if (v.isNotEmpty) params[k] = v;
      }
    });
    return base.replace(queryParameters: {...base.queryParameters, ...params});
  }

  String? _cookieHeader(String? anonymousId, String? sessionId) {
    final parts = <String>[
      if (anonymousId != null && anonymousId.isNotEmpty)
        'besh24_aid=$anonymousId',
      if (sessionId != null && sessionId.isNotEmpty) 'besh24_sid=$sessionId',
    ];
    return parts.isEmpty ? null : parts.join('; ');
  }

  ApiError _apiError(Besh24HttpResponse res) => ApiError(
        'besh24 api ${res.statusCode}',
        statusCode: res.statusCode,
        body: res.body,
      );

  Result<T> _decode<T>(
    Result<Besh24HttpResponse> res,
    T Function(Map<String, Object?> json) build,
  ) {
    switch (res) {
      case Ok<Besh24HttpResponse>(:final value):
        if (!value.isOk) return Err(_apiError(value));
        try {
          final decoded = jsonDecode(value.body);
          if (decoded is! Map) {
            return const Err(SerializationError('expected a JSON object'));
          }
          return Ok(build(decoded.cast<String, Object?>()));
        } catch (e) {
          _logger.warn('failed to decode response', e);
          return Err(SerializationError('failed to decode response', cause: e));
        }
      case Err<Besh24HttpResponse>(:final error):
        return Err(error);
    }
  }

  Result<List<T>> _decodeList<T>(
    Result<Besh24HttpResponse> res,
    String key,
    T Function(Map<String, Object?> json) build,
  ) {
    switch (res) {
      case Ok<Besh24HttpResponse>(:final value):
        if (!value.isOk) return Err(_apiError(value));
        try {
          final decoded = jsonDecode(value.body);
          if (decoded is! Map) {
            return const Err(SerializationError('expected a JSON object'));
          }
          final raw = decoded[key];
          final list = raw is List
              ? raw
                  .whereType<Map<String, dynamic>>()
                  .map((e) => build(e.cast<String, Object?>()))
                  .toList(growable: false)
              : <T>[];
          return Ok(list);
        } catch (e) {
          _logger.warn('failed to decode list response', e);
          return Err(SerializationError('failed to decode response', cause: e));
        }
      case Err<Besh24HttpResponse>(:final error):
        return Err(error);
    }
  }
}
