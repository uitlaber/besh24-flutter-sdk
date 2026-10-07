# besh24_sdk

Typed Dart/Flutter client for the **Besh24** tracking, recommendations and
search backend — the mobile counterpart of the web `window.besh24` JS shim. It
mirrors the same HTTP contract (`/api/v1/*`), so analytics, recommendations and
search behave identically across web and app.

- **Identity handled for you** — bootstraps and persists the anonymous id via
  `shared_preferences`, rotates the session after idle, and stamps every event.
- **Resilient by design** — no public method throws for a server/transport
  failure; calls return a `Result`, and recommend/search degrade to empty
  results so the UI never breaks.
- **Clean architecture** — domain / data / core layers, dependencies pointing
  inward, everything injectable and testable.

## Installation

This package is distributed as a Git dependency:

```yaml
dependencies:
  besh24_sdk:
    git:
      url: https://github.com/besh24/besh24_flutter_sdk.git
      ref: v0.1.0
```

Then:

```bash
flutter pub get
```

## Quickstart

```dart
import 'package:besh24_sdk/besh24_sdk.dart';

final client = Besh24Client();

await client.init(
  Besh24Config(
    baseUrl: 'https://besh24.example.com/api/v1', // must include /api/v1
    siteKey: 'bsk_demo_9f3c1a2b', // tenant key, sent as X-Besh24-Site-Key
    defaultCityId: '1',
    source: 'app', // free-form analytics label: 'app', 'ios', 'testweb', …
    lang: 'ru', // search language: 'ru' | 'kk'
  ),
);

// Tracking (fire-and-forget; errors are logged, never thrown).
await client.trackView('SKU-123', available: true);
await client.trackCart('SKU-123', amount: 1, price: 4990);
await client.trackPurchase(
  orderId: 'ORDER-1',
  total: 4990,
  products: const [PurchaseItem(id: 'SKU-123', price: 4990, amount: 1)],
);

// Recommendations — returns an ordered list of product ids. An empty list is
// a normal, successful result (no candidates matched), not an error.
final recs = await client.recommend('popular', limit: 8);
final ids = recs.valueOrNull?.itemIds ?? const [];

// extended: true inlines catalog fields (price, availability, stock, ...) —
// skip a second lookup call.
final extended = await client.recommend('popular', limit: 8, extended: true);
final product = extended.valueOrNull?.products?['SKU-123'];

// Array context: cart items / several categories / the search query of the
// current page (for `search_also_bought` blocks). Blank values are dropped.
final alsoBought = await client.recommend(
  'search_also_bought',
  itemIds: ['SKU-1', 'SKU-2'], // alias: cartItemIds
  categoryIds: ['10', '11'],
  searchQuery: 'телефон',
);

// Batch — resolve several blocks (e.g. a whole page) in one round trip.
final batch = await client.recommendBatch(
  const [
    RecommendationBlockRequest(blockCode: 'popular'),
    RecommendationBlockRequest(blockCode: 'also_bought', itemId: 'SKU-123'),
  ],
  cityId: '1',
);
final popularIds = batch.valueOrNull?.blocks['popular']?.itemIds ?? const [];

// Search.
final page = await client.search('телефон', cityId: '1', sort: 'price_asc');
final instant = await client.searchInstant('теле', cityId: '1');

// Facets on `page.valueOrNull` let the app render filter chips and narrow
// the next search by product characteristic — brand/category filters use
// `brand`/`category` above, not `paramFilters`.
final colorFacets =
    page.valueOrNull?.paramFacets.where((f) => f.name == 'Цвет');
final narrowed = await client.search(
  'телефон',
  cityId: '1',
  paramFilters: {'Цвет': ['Чёрный']},
);

// Several brands / categories at once (merged with `brand`/`category`;
// sent as a repeated query key).
final multi = await client.search(
  'телевизор',
  cityId: '1',
  brands: ['Samsung', 'LG'],
  categories: ['15', '16'],
);

// Switch the runtime default language when the user changes locale — no
// per-call override needed afterwards.
client.setLang('kk');

// Profile + restock subscription.
await client.setProfile(ProfileInput(email: 'a@b.c', gender: Gender.male));
await client.subscribeRestock(
  const RestockInput(itemId: 'SKU-123', email: 'a@b.c'),
);

// Push token registration (see "Push-уведомления (FCM)" below for the flow).
await client.registerPushToken(token: fcmToken, platform: 'android');
await client.unregisterPushToken(fcmToken);
```

## Methods

| Method | Endpoint | Notes |
| --- | --- | --- |
| `init(config)` | `GET /identity` | Builds the graph and bootstraps identity. |
| `ensureIdentity()` | `GET /identity` | Cached; runs at most once per instance. |
| `track(type, payload)` | `POST /events` | Generic; prefer the typed shortcuts. |
| `trackView` / `trackCategory` / `trackCart` / `trackRemoveFromCart` / `trackWish` / `trackRemoveWish` / `trackPurchase` / `trackSearch` | `POST /events` | Typed event helpers. |
| `trackRecommendationClick({block, itemId})` | `POST /events` | Click on a product inside a recommendation block; empty `block`/`itemId` is rejected locally. |
| `trackVisit()` | `POST /events` | Session start; no payload. |
| `trackPageOpen(path)` | `POST /events` | Opened a page. `path` is normalized locally (query/hash stripped, absolute URL reduced to its path); a path that's empty afterwards is rejected locally. Routes that carry secrets in the path (`reset-password`, `auth`, ...) are not reported, and `/smart-gifts/receive/<token>` is cut to `/smart-gifts/receive`. |
| `trackReview(itemId, {rating})` | `POST /events` | Left a review. `rating` must be `1`..`5`; an out-of-range value is dropped from the payload but the event is still sent. |
| `setProfile(input)` | `POST /profile` | Remembers `user_id`/`city_id`. |
| `recommend(blockCode, …)` | `GET /recommendations` | `blockCode` → `besh24_block_id`. `extended: true` inlines catalog fields (price, availability, stock, ...) in `products`. |
| `recommendBatch(blocks, …)` | `POST /recommendations/batch` | N blocks in one round trip; results keyed by block code. |
| `search(query, …)` | `GET /search` | `query` → `q`. Accepts `sort` (`relevance`/`price_asc`/`price_desc`/`new`) and `paramFilters` (product characteristic name → selected values) to narrow by facets from a prior `SearchResult.paramFacets`. |
| `searchInstant(query, cityId)` | `GET /search/instant` | `city_id` mandatory. |
| `subscribeRestock(input)` | `POST /subscriptions/restock` | Requires email or phone. |
| `setLang(lang)` | — | Changes the runtime default `lang` (`ru`/`kk`) used by `search`/`searchInstant` when no per-call override is given. Unsupported values are ignored. |
| `registerPushToken({token, platform, userId})` | `POST /push/tokens` | Idempotent upsert; safe to call again on `onTokenRefresh`. |
| `unregisterPushToken(token)` | `DELETE /push/tokens` | Revokes a token, e.g. on logout. |

See [`docs/contract-mapping.md`](docs/contract-mapping.md) for the full
method → endpoint → payload table, and [`docs/events.md`](docs/events.md) for
event payload shapes.

## Configuration

| `Besh24Config` field | Default | Purpose |
| --- | --- | --- |
| `baseUrl` | — (required) | Full API base incl. `/api/v1`. |
| `siteKey` | — (required) | Tenant key, sent as `X-Besh24-Site-Key` on every request. |
| `defaultCityId` | `'1'` | City used when a call omits `cityId`. |
| `source` | `'app'` | Analytics channel stamped on every event/query. |
| `lang` | `'ru'` | Search language (`ru`/`kk`), sent as `lang` on `search`/`searchInstant`; overridable per call. |
| `timeout` | `10s` | Per-request network timeout. |
| `sessionIdleTimeout` | `30m` | Idle window before the session id rotates. |
| `sendCookies` | `true` | Resend `besh24_aid`/`besh24_sid` on `GET /identity`. |

## Push-уведомления (FCM)

The SDK does **not** depend on `firebase_messaging` or integrate Firebase in
any way — it only exposes the two backend calls that register/revoke a
device's push token. Your app is responsible for obtaining the token from
Firebase and feeding it to the SDK:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// 1. Get the current token from Firebase and register it with Besh24.
final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await client.registerPushToken(
    token: token,
    platform: 'android', // or 'ios'
    userId: currentUserId, // optional, if the visitor is authenticated
  );
}

// 2. Firebase rotates tokens occasionally — re-register on refresh.
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  client.registerPushToken(token: newToken, platform: 'android');
});

// 3. On logout, revoke the token so the device stops receiving pushes tied
//    to the previous visitor.
await client.unregisterPushToken(token);
```

`registerPushToken` is an idempotent upsert on the backend, so calling it
again with the same token (e.g. on every app start) is safe. Both calls
follow the SDK's resilience contract — `Err` on failure, never throws.

## Why `package:http`?

The SDK's transport needs are a handful of GET/POST calls, and `http` ships an
official `MockClient` (`package:http/testing`) that makes request-shape
assertions trivial in tests. The transport is abstracted behind
`Besh24HttpClient`, so you can inject a `dio`-based implementation if you prefer
— pass it to `Besh24Client(httpClient: …)`.

## Error handling

Every call returns a `Result<T>` (`Ok` / `Err`). Failures are values:

```dart
final res = await client.recommend('popular');
switch (res) {
  case Ok(:final value):
    render(value.itemIds); // empty list on a degraded call
  case Err(:final error):
    // recommend/search never reach here — they degrade to Ok(empty).
}
```

`track`, `setProfile` and `subscribeRestock` return `Err` on failure (and log via
the injected `Besh24Logger`); `recommend`, `search` and `searchInstant` return an
`Ok` with an empty result. Nothing propagates to the host app.

## Development

```bash
flutter pub get
dart analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

## License

MIT © Besh24 — see [LICENSE](LICENSE).
