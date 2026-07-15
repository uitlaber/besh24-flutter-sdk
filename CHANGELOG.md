# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and the project adheres to
[Semantic Versioning](https://semver.org/).

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
