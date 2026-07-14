import 'core/clock.dart';
import 'core/config.dart';
import 'core/http/besh24_http_client.dart';
import 'core/http/http_besh24_http_client.dart';
import 'core/logger.dart';
import 'core/result.dart';
import 'core/storage/besh24_storage.dart';
import 'core/storage/shared_preferences_storage.dart';
import 'core/uuid_gen.dart';
import 'data/datasources/besh24_remote_data_source.dart';
import 'data/datasources/identity_local_data_source.dart';
import 'data/repositories/identity_repository_impl.dart';
import 'data/repositories/profile_repository_impl.dart';
import 'data/repositories/recommendation_repository_impl.dart';
import 'data/repositories/search_repository_impl.dart';
import 'data/repositories/subscription_repository_impl.dart';
import 'data/repositories/tracking_repository_impl.dart';
import 'domain/entities/identity.dart';
import 'domain/entities/instant_search_item.dart';
import 'domain/entities/profile_input.dart';
import 'domain/entities/recommendation_result.dart';
import 'domain/entities/restock_input.dart';
import 'domain/entities/search_result.dart';
import 'domain/entities/track_event.dart';
import 'domain/usecases/ensure_identity.dart';
import 'domain/usecases/get_recommendations.dart';
import 'domain/usecases/search_instant.dart';
import 'domain/usecases/search_usecase.dart';
import 'domain/usecases/set_profile.dart';
import 'domain/usecases/subscribe_restock.dart';
import 'domain/usecases/track_event_usecase.dart';

/// The public entry point of the Besh24 mobile SDK.
///
/// A thin facade that assembles the clean-architecture graph (core → data →
/// domain use-cases) via constructor injection and delegates every call to a
/// single use-case. Internal layers are not exported.
///
/// Lifecycle:
/// ```dart
/// final client = Besh24Client();
/// await client.init(Besh24Config(baseUrl: 'https://besh24.evrika.com/api/v1'));
/// await client.trackView('SKU-1');
/// ```
///
/// ### Resilience contract
/// No public method throws for a server/transport failure. Every request is
/// bounded by [Besh24Config.timeout] (default 10s). On any failure — 4xx/5xx,
/// timeout, dropped connection, malformed/empty JSON — the SDK degrades:
///  * [track] / [setProfile] / [subscribeRestock] return an `Err` [Result] and
///    log via the injected [Besh24Logger] (fire-and-forget: the caller need not
///    await, and nothing propagates to the host app).
///  * [recommend] / [search] / [searchInstant] return an `Ok` with an **empty**
///    result, so UI code that ignores errors still renders safely.
///
/// The only exception a public method throws is a [StateError] when called
/// before [init] — a programming error, not a runtime failure.
class Besh24Client {
  /// Creates an un-initialized client. Optional dependencies are injected for
  /// testing; production code passes nothing and calls [init].
  Besh24Client({
    Besh24HttpClient? httpClient,
    Besh24Storage? storage,
    Clock clock = const SystemClock(),
    UuidGenerator? uuid,
    Besh24Logger logger = const DefaultBesh24Logger(),
  })  : _httpOverride = httpClient,
        _storageOverride = storage,
        _clock = clock,
        _uuid = uuid ?? UuidV4Generator(),
        _logger = logger;

  final Besh24HttpClient? _httpOverride;
  final Besh24Storage? _storageOverride;
  final Clock _clock;
  final UuidGenerator _uuid;
  final Besh24Logger _logger;

  Besh24Config? _config;
  Besh24HttpClient? _ownedHttp;

  late EnsureIdentity _ensureIdentityUseCase;
  late TrackEventUsecase _trackUseCase;
  late SetProfile _setProfileUseCase;
  late GetRecommendations _recommendUseCase;
  late SearchUsecase _searchUseCase;
  late SearchInstant _instantUseCase;
  late SubscribeRestock _restockUseCase;

  Future<Identity>? _identityFuture;
  Identity? _identity;
  String? _userId;
  String? _cityId;

  /// `true` once [init] has completed.
  bool get isInitialized => _config != null;

  /// The current anonymous identity, or `null` before the first
  /// [ensureIdentity].
  Identity? get identity => _identity;

  /// The current source label from [Besh24Config].
  String get source => _config!.source;

  /// Builds the dependency graph from [config] and bootstraps the identity.
  ///
  /// Safe to call once; subsequent calls just re-resolve the identity. Returns
  /// the resolved [Identity].
  Future<Identity> init(Besh24Config config) async {
    if (_config != null) return ensureIdentity();

    _config = config;
    _cityId = config.defaultCityId;

    final http = _httpOverride ??
        (_ownedHttp = HttpBesh24HttpClient(timeout: config.timeout));
    final storage =
        _storageOverride ?? SharedPreferencesStorage(logger: _logger);

    final remote = Besh24RemoteDataSource(
      http: http,
      config: config,
      logger: _logger,
    );
    final local = IdentityLocalDataSource(storage: storage, clock: _clock);
    final identityRepo = IdentityRepositoryImpl(remote: remote, local: local);

    _ensureIdentityUseCase = EnsureIdentity(
      repository: identityRepo,
      clock: _clock,
      uuid: _uuid,
      sessionIdleTimeout: config.sessionIdleTimeout,
    );
    _trackUseCase = TrackEventUsecase(
      repository: TrackingRepositoryImpl(remote),
      clock: _clock,
      uuid: _uuid,
    );
    _setProfileUseCase = SetProfile(ProfileRepositoryImpl(remote));
    _recommendUseCase =
        GetRecommendations(RecommendationRepositoryImpl(remote));
    _searchUseCase = SearchUsecase(SearchRepositoryImpl(remote));
    _instantUseCase = SearchInstant(SearchRepositoryImpl(remote));
    _restockUseCase = SubscribeRestock(
      SubscriptionRepositoryImpl(remote: remote, config: config),
    );

    return ensureIdentity();
  }

  /// Resolves (and caches) the anonymous identity. The underlying `GET
  /// /identity` runs at most once per client instance; the session id is
  /// rotated on the next call after the configured idle window. Never throws —
  /// falls back to a locally generated identity if the graph misbehaves.
  Future<Identity> ensureIdentity() {
    _assertInitialized();
    return _identityFuture ??= _ensureIdentityUseCase.call().then((result) {
      final id = result.valueOrNull ??
          Identity(anonymousId: _uuid.v4(), sessionId: _uuid.v4());
      _identity = id;
      return id;
    }).catchError((Object e) {
      _logger.warn('ensureIdentity degraded to local identity', e);
      final id = Identity(anonymousId: _uuid.v4(), sessionId: _uuid.v4());
      _identity = id;
      return id;
    });
  }

  // --- tracking ----------------------------------------------------------

  /// Tracks an arbitrary event by [type] with a raw [payload]. Prefer the typed
  /// shortcuts below. Fire-and-forget: returns an `Err` (logged) on failure,
  /// never throws.
  Future<Result<void>> track(
    TrackEventType type,
    Map<String, Object?> payload, {
    String? cityId,
  }) {
    return _guard('track:${type.wire}', () async {
      final id = await ensureIdentity();
      return _trackUseCase.call(
        type: type,
        payload: payload,
        identity: id,
        source: source,
        cityId: _resolveCity(cityId),
        userId: _userId,
      );
    });
  }

  /// Tracks a product view. [available] mirrors the shim's `stock`/`available`.
  Future<Result<void>> trackView(
    String itemId, {
    bool available = true,
    String? cityId,
  }) {
    return track(
      TrackEventType.view,
      {'item_id': itemId, 'available': available},
      cityId: cityId,
    );
  }

  /// Tracks a category view.
  Future<Result<void>> trackCategory(String categoryId, {String? cityId}) {
    return track(
      TrackEventType.category,
      {'category_id': categoryId},
      cityId: cityId,
    );
  }

  /// Tracks an add-to-cart.
  Future<Result<void>> trackCart(
    String itemId, {
    num? amount,
    num? price,
    String? cityId,
  }) {
    return track(
      TrackEventType.cart,
      _cartPayload(itemId, amount, price),
      cityId: cityId,
    );
  }

  /// Tracks a remove-from-cart.
  Future<Result<void>> trackRemoveFromCart(
    String itemId, {
    num? amount,
    num? price,
    String? cityId,
  }) {
    return track(
      TrackEventType.removeFromCart,
      _cartPayload(itemId, amount, price),
      cityId: cityId,
    );
  }

  /// Tracks an add-to-wishlist.
  Future<Result<void>> trackWish(String itemId, {String? cityId}) {
    return track(TrackEventType.wish, {'item_id': itemId}, cityId: cityId);
  }

  /// Tracks a remove-from-wishlist.
  Future<Result<void>> trackRemoveWish(String itemId, {String? cityId}) {
    return track(
      TrackEventType.removeWish,
      {'item_id': itemId},
      cityId: cityId,
    );
  }

  /// Tracks a completed purchase.
  Future<Result<void>> trackPurchase({
    required String orderId,
    required num total,
    required List<PurchaseItem> products,
    String? phone,
    String? cityId,
  }) {
    return track(
      TrackEventType.purchase,
      {
        'order_id': orderId,
        'total': total,
        'products': products.map((p) => p.toJson()).toList(growable: false),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
      cityId: cityId,
    );
  }

  /// Tracks a search event (query + result count).
  Future<Result<void>> trackSearch(
    String query,
    int resultsCount, {
    String? cityId,
  }) {
    return track(
      TrackEventType.search,
      {'query': query, 'results_count': resultsCount},
      cityId: cityId,
    );
  }

  Map<String, Object?> _cartPayload(String itemId, num? amount, num? price) => {
        'item_id': itemId,
        if (amount != null) 'amount': amount,
        if (price != null) 'price': price,
      };

  // --- profile -----------------------------------------------------------

  /// Upserts the visitor profile. Remembers `user_id`/`city_id` for subsequent
  /// calls, mirroring the shim's stateful `doProfileSet`. Returns `Err` on
  /// failure, never throws.
  Future<Result<void>> setProfile(ProfileInput input) {
    return _guard('setProfile', () async {
      final id = await ensureIdentity();
      if (input.userId != null && input.userId!.isNotEmpty) {
        _userId = input.userId;
      }
      if (input.cityId != null && input.cityId!.isNotEmpty) {
        _cityId = input.cityId;
      }
      return _setProfileUseCase.call(id, input);
    });
  }

  // --- recommendations ---------------------------------------------------

  /// Fetches a recommendation block by [blockCode] (sent as `besh24_block_id`).
  /// Degrades to an empty result on any failure.
  Future<Result<RecommendationResult>> recommend(
    String blockCode, {
    String? cityId,
    String? itemId,
    String? categoryId,
    String? brand,
    int? limit,
  }) {
    return _guard<RecommendationResult>(
      'recommend:$blockCode',
      () async {
        final id = await ensureIdentity();
        return _recommendUseCase.call(
          blockCode: blockCode,
          identity: id,
          cityId: _resolveCity(cityId),
          source: source,
          userId: _userId,
          itemId: itemId,
          categoryId: categoryId,
          brand: brand,
          limit: limit,
        );
      },
      onError: () => const Ok(
        RecommendationResult(itemIds: [], requestId: ''),
      ),
    );
  }

  // --- search ------------------------------------------------------------

  /// Full-page search for [query]. Degrades to an empty result on failure.
  Future<Result<SearchResult>> search(
    String query, {
    String? cityId,
    String? brand,
    String? category,
    int? page,
    int? perPage,
    int? priceMin,
    int? priceMax,
  }) {
    return _guard<SearchResult>(
      'search',
      () async {
        final id = await ensureIdentity();
        return _searchUseCase.call(
          query: query,
          identity: id,
          cityId: _resolveCity(cityId),
          source: source,
          userId: _userId,
          brand: brand,
          category: category,
          page: page,
          perPage: perPage,
          priceMin: priceMin,
          priceMax: priceMax,
        );
      },
      onError: () => const Ok(SearchResult(items: [], total: 0)),
    );
  }

  /// Instant autocomplete for [query]. [cityId] is mandatory on the wire and
  /// defaults to the configured city. Degrades to an empty list on failure.
  Future<Result<List<InstantSearchItem>>> searchInstant(
    String query, {
    String? cityId,
    int? limit,
  }) {
    return _guard<List<InstantSearchItem>>(
      'searchInstant',
      () async {
        final id = await ensureIdentity();
        return _instantUseCase.call(
          query: query,
          identity: id,
          cityId: _resolveCity(cityId),
          source: source,
          userId: _userId,
          limit: limit,
        );
      },
      onError: () => const Ok<List<InstantSearchItem>>([]),
    );
  }

  // --- subscriptions -----------------------------------------------------

  /// Subscribes to restock notifications for a product. Requires an email or
  /// phone contact. Returns `Err` on failure, never throws.
  Future<Result<void>> subscribeRestock(RestockInput input) {
    return _guard('subscribeRestock', () async {
      final id = await ensureIdentity();
      return _restockUseCase.call(id, input);
    });
  }

  /// Releases the owned HTTP client (if the SDK created one).
  void dispose() {
    _ownedHttp?.close();
    _ownedHttp = null;
  }

  // --- internals ---------------------------------------------------------

  /// Runs [run], catching any leaked exception at the facade boundary. On an
  /// `Err` result or a thrown exception it logs and, when [onError] is given,
  /// returns that safe fallback (used by recommend/search to degrade to empty).
  Future<Result<T>> _guard<T>(
    String op,
    Future<Result<T>> Function() run, {
    Result<T> Function()? onError,
  }) async {
    _assertInitialized();
    try {
      final result = await run();
      if (result.isErr) {
        _logger.warn('$op failed: ${result.errorOrNull}');
        if (onError != null) return onError();
      }
      return result;
    } catch (e) {
      _logger.warn('$op threw unexpectedly', e);
      if (onError != null) return onError();
      return Err(NetworkError('$op failed', cause: e));
    }
  }

  /// Effective city id: explicit [cityId] › profile city › config default.
  String _resolveCity(String? cityId) =>
      cityId ?? _cityId ?? _config!.defaultCityId;

  void _assertInitialized() {
    if (_config == null) {
      throw StateError('Besh24Client.init(config) must be called first');
    }
  }
}

/// One line item of a purchase event.
class PurchaseItem {
  /// Creates a purchase line item.
  const PurchaseItem({required this.id, this.price = 0, this.amount = 1});

  /// Product id.
  final String id;

  /// Unit price.
  final num price;

  /// Quantity.
  final num amount;

  /// Serializes to the `products[]` wire shape.
  Map<String, Object?> toJson() => {
        'id': id,
        'price': price,
        'amount': amount,
      };
}
