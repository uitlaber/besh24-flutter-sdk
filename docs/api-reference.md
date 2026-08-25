# API reference

The public surface is exported from `package:besh24_sdk/besh24_sdk.dart`.
Internal layers (`src/data`, `src/domain/usecases`, …) are not exported.

## `Besh24Client`

| Member | Signature | Description |
| --- | --- | --- |
| constructor | `Besh24Client({Besh24HttpClient? httpClient, Besh24Storage? storage, Clock clock, UuidGenerator? uuid, Besh24Logger logger})` | Creates an un-initialized client; all dependencies are injectable. |
| `init` | `Future<Identity> init(Besh24Config config)` | Builds the graph and bootstraps identity. Call once. |
| `ensureIdentity` | `Future<Identity> ensureIdentity()` | Resolves + caches identity (runs `GET /identity` at most once). |
| `isInitialized` | `bool` | `true` after `init`. |
| `identity` | `Identity?` | Current identity, or `null` before first `ensureIdentity`. |
| `source` | `String` | Configured analytics source. |
| `track` | `Future<Result<void>> track(TrackEventType type, Map<String, Object?> payload, {String? cityId})` | Generic event. |
| `trackView` | `Future<Result<void>> trackView(String itemId, {bool available = true, String? cityId})` | Product view. |
| `trackCategory` | `Future<Result<void>> trackCategory(String categoryId, {String? cityId})` | Category view. |
| `trackCart` | `Future<Result<void>> trackCart(String itemId, {num? amount, num? price, String? cityId})` | Add to cart. |
| `trackRemoveFromCart` | same as `trackCart` | Remove from cart. |
| `trackWish` | `Future<Result<void>> trackWish(String itemId, {String? cityId})` | Add to wishlist. |
| `trackRemoveWish` | `Future<Result<void>> trackRemoveWish(String itemId, {String? cityId})` | Remove from wishlist. |
| `trackPurchase` | `Future<Result<void>> trackPurchase({required String orderId, required num total, required List<PurchaseItem> products, String? phone, String? cityId})` | Completed purchase. |
| `trackSearch` | `Future<Result<void>> trackSearch(String query, int resultsCount, {String? cityId})` | Search event. |
| `setProfile` | `Future<Result<void>> setProfile(ProfileInput input)` | Upserts the profile; remembers `user_id`/`city_id`. |
| `recommend` | `Future<Result<RecommendationResult>> recommend(String blockCode, {String? cityId, String? itemId, String? categoryId, String? brand, int? limit, bool extended = false})` | Recommendation block. `extended: true` inlines catalog fields in `products`. |
| `recommendBatch` | `Future<Result<RecommendationBatchResult>> recommendBatch(List<RecommendationBlockRequest> blocks, {String? cityId, bool extended = false})` | N recommendation blocks in one round trip. |
| `search` | `Future<Result<SearchResult>> search(String query, {String? cityId, String? brand, String? category, int? page, int? perPage, int? priceMin, int? priceMax, String? lang, String? sort})` | Full-page search. |
| `searchInstant` | `Future<Result<List<InstantSearchItem>>> searchInstant(String query, {String? cityId, int? limit, String? lang})` | Autocomplete. |
| `subscribeRestock` | `Future<Result<void>> subscribeRestock(RestockInput input)` | Restock subscription (needs a contact). |
| `dispose` | `void dispose()` | Closes the owned HTTP client. |

## Result & errors

`Result<T>` is a sealed type with `Ok<T>(value)` and `Err<T>(error)`. Helpers:
`isOk`, `isErr`, `valueOrNull`, `errorOrNull`, `map`.

`Besh24Error` variants: `NetworkError`, `ApiError` (`statusCode`, `body`),
`SerializationError`, `StorageError`, `ValidationError`.

## Entities

- `Identity { anonymousId, sessionId }`
- `RecommendationResult { itemIds: List<String>, requestId, title?, url?, products?: Map<String, RecommendationEnrichedItem> }` — `products` present only when `extended: true` was requested.
- `RecommendationEnrichedItem { id, name, nameKk?, slug?, url?, imageUrl?, brand?, price, oldPrice?, discountPercent?, rating?, badges?, available, fromDc, stock? }`
- `RecommendationBlockRequest { blockCode, itemId?, categoryId?, brand?, itemIds?, categoryIds? }`
- `RecommendationBatchResult { requestId, blocks: Map<String, RecommendationResult> }` — keyed by `blockCode`; every entry's `requestId` is the batch-level id.
- `SearchResult { items: List<SearchProduct>, total, page, facets }`
- `SearchProduct { id, name, price, image?, url? }`
- `InstantSearchItem { id, name, price, image?, url? }`
- `ProfileInput { userId?, email?, phone?, birthday?, gender?, cityId? }`
  with `Gender { male, female }` and `ProfileInput.genderFromShorthand('m'|'f')`
- `RestockInput { itemId, cityId?, email?, phone?, userId? }`
- `TrackEventType { view, category, cart, removeFromCart, wish, removeWish, purchase, search }`
- `PurchaseItem { id, price, amount }`

## Configuration — `Besh24Config`

`baseUrl` (required), `shopKey?`, `defaultCityId = '1'`, `timeout = 10s`,
`sessionIdleTimeout = 30m`, `sendCookies = true`, `source = 'app'`.

## Infrastructure interfaces (injectable)

- `Besh24HttpClient` / `HttpBesh24HttpClient` (default, on `package:http`)
- `Besh24Storage` / `SharedPreferencesStorage` (default) / `InMemoryStorage`
- `Clock` / `SystemClock`
- `UuidGenerator` / `UuidV4Generator`
- `Besh24Logger` / `DefaultBesh24Logger`
