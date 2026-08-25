# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and the project adheres to
[Semantic Versioning](https://semver.org/).

## 0.6.0 — 2026-08-25

### Added
- `SearchResult` gained typed facet fields, parsed from `GET /api/v1/search`'s
  `facets`: `brandFacets` (`List<SearchBrandFacet>`), `categoryFacets`
  (`List<SearchCategoryFacet>`, now id/parent/url-aware, not just a name),
  `priceRangeMin`/`priceRangeMax`/`priceMedian`, `priceRanges`
  (`List<SearchPriceRangeBucket>`), and `paramFacets`
  (`List<SearchParamFacet>` — product characteristics with per-value counts,
  optional priority and numeric range). The raw `facets` map is kept
  unchanged as an escape hatch. New entities: `SearchBrandFacet`,
  `SearchCategoryFacet`, `SearchPriceRangeBucket`, `SearchParamFacet`.
- `Besh24Client.search(..., paramFilters: {...})`: narrows full-page search
  by product characteristic (name → selected values, OR within one name,
  AND across names), sent as repeated `filters[<name>]` query keys —
  mirrors the backend's characteristic filter contract (Besh24-293). Use a
  prior `SearchResult.paramFacets` entry's `name` as the key.

### Changed
- Re-verified against a live backend response that an empty `itemIds` from
  `recommend`/`recommendBatch` remains a normal, successful result (no
  server-side padding) — doc comments and `docs/contract-mapping.md` already
  reflected this from 0.5.0; unchanged in this release.

## 0.5.0 — 2026-08-25

### Added
- `Besh24Client.recommend(..., extended: true)`: opts into the backend's
  `extended` recommendations mode, inlining catalog fields (`price`,
  `oldPrice`, `discountPercent`, `available`, `fromDc`, `stock`, `rating`,
  `imageUrl`, ...) for every recommended product directly in the response's
  `products` map — no second lookup call needed. Fields are city-aware,
  resolved against the request's `city_id`. New entity
  `RecommendationEnrichedItem`. `RecommendationResult` gained `title`, `url`
  and `products` fields (all additive/optional).
- `Besh24Client.recommendBatch(blocks, {cityId, extended})`: resolves N
  recommendation blocks in a single `POST /recommendations/batch` round
  trip instead of N calls to `recommend` — the path the web frontend already
  uses for pages with several recommendation widgets. New entities
  `RecommendationBlockRequest` and `RecommendationBatchResult`.
- `Besh24Client.search(..., sort: ...)`: forwards the backend's `sort` query
  param (`relevance` (default), `price_asc`, `price_desc`, `new`), previously
  unreachable from the SDK.

### Changed
- Documented that an empty or short `itemIds`/`items` list from `recommend`,
  `recommendBatch` or `search` is a normal, successful result — the backend
  no longer pads recommendation blocks out to the requested limit. This was
  already the SDK's runtime behavior (it never treated an empty list as an
  error); this release makes the contract explicit in doc comments and
  `docs/contract-mapping.md`.

## 0.4.1 — 2026-07-16

### Changed
- Removed references to a specific client host/name from examples and docs
  (README, getting-started guide, example app, doc comments); replaced with
  the neutral `https://besh24.example.com` placeholder.

## 0.4.0 — 2026-07-16

### Added
- `Besh24Client.registerPushToken({token, platform, userId})`: registers a
  device FCM push token via `POST /push/tokens`. Idempotent upsert on the
  backend, safe to call again (e.g. on `onTokenRefresh`). Returns `Err` on
  failure, never throws.
- `Besh24Client.unregisterPushToken(token)`: revokes a push token via
  `DELETE /push/tokens`, e.g. on logout.
- The SDK does **not** integrate Firebase — the host app obtains the token from
  `FirebaseMessaging` and passes it through as a string. See the README's
  "Push-уведомления (FCM)" section for the full flow.
- `Besh24HttpClient.delete(...)`: new transport method backing the above
  (implemented on `HttpBesh24HttpClient`; custom transports must add it).

## 0.3.0 — 2026-07-14

### Added
- `Besh24Client.setLang(String lang)`: changes the runtime default search
  language (`ru`/`kk`) without re-creating the client. Unsupported values are
  ignored. `Besh24Client.lang` exposes the current effective value. Per-call
  `lang` overrides on `search`/`searchInstant` still take precedence.

## 0.2.0 — 2026-07-14

### Added
- `Besh24Config.siteKey` (required): sent as `X-Besh24-Site-Key` on every
  outbound request, resolving the multi-tenant contract on the public
  `/api/v1/*` endpoints.
- `Besh24Config.lang` (default `ru`): sent as the `lang` query parameter on
  `search`/`searchInstant`. `Besh24Client.search`/`searchInstant` accept an
  optional per-call `lang` override.

## 0.1.0 — 2026-07-14

Initial release.

### Added
- `Besh24Client` facade with `init`, `ensureIdentity`, `track` (+ typed
  shortcuts `trackView` / `trackCategory` / `trackCart` / `trackRemoveFromCart`
  / `trackWish` / `trackRemoveWish` / `trackPurchase` / `trackSearch`),
  `setProfile`, `recommend`, `search`, `searchInstant`, `subscribeRestock`.
- Anonymous identity bootstrap over `GET /identity`, persisted via
  `shared_preferences`, with session rotation after a configurable idle window
  and cookie replay to reuse the anonymous id across launches.
- `source` analytics channel (free-form string, default `app`) stamped into
  every event body and sent as the `source` query parameter on
  recommend/search/instant.
- Clean-architecture layering (domain / data / core), `Result`-based error
  handling, and full dependency injection.
- Resilience contract: no public method throws for a server/transport failure;
  recommend/search/instant degrade to empty results, per-request timeouts.
- Example app and documentation (`docs/`).
