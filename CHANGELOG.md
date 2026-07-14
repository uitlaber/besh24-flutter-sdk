# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/) and the project adheres to
[Semantic Versioning](https://semver.org/).

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
