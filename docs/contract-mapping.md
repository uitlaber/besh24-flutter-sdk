# Contract mapping

How each SDK method maps to a Besh24 HTTP endpoint and the exact request shape.
The source of truth is the web shim (`apps/api/src/modules/sdk/besh24.shim.js`)
and the shared zod schemas (`packages/shared`). All paths are relative to
`Besh24Config.baseUrl` (which already includes `/api/v1`).

## Identity

| SDK | Web shim | HTTP | Notes |
| --- | --- | --- | --- |
| `init` / `ensureIdentity` | `ensureIdentity()` | `GET /identity` → `{anonymous_id, session_id}` | Cached ids are resent as `Cookie: besh24_aid=…; besh24_sid=…` so the backend reuses the anonymous id. Session id is dropped from the cookie after `sessionIdleTimeout` to force rotation. |

## Events — `POST /events`

Batch body: `{ "events": [ <event> ] }` → **202**. Every event object:

```jsonc
{
  "event_id": "<uuid v4>",
  "type": "view",
  "anonymous_id": "<from identity>",
  "session_id": "<from identity>",
  "user_id": "<if set via setProfile>",   // omitted when absent
  "city_id": "<resolved city>",           // omitted when absent
  "ts": "2026-07-14T09:30:15.250Z",        // UTC ISO-8601, trailing Z
  "source": "app",                         // Besh24Config.source
  "payload": { /* per type, see below */ }
}
```

| SDK method | `type` | Shim action | `payload` |
| --- | --- | --- | --- |
| `trackView(id, available)` | `view` | `track view` | `{item_id, available}` |
| `trackCategory(id)` | `category` | `track category` | `{category_id}` |
| `trackCart(id, amount, price)` | `cart` | `track cart` | `{item_id, amount?, price?}` |
| `trackRemoveFromCart(...)` | `remove_from_cart` | `track remove_from_cart` | `{item_id, amount?, price?}` |
| `trackWish(id)` | `wish` | `track wish` | `{item_id}` |
| `trackRemoveWish(id)` | `remove_wish` | `track remove_wish` | `{item_id}` |
| `trackPurchase(...)` | `purchase` | `track purchase` | `{order_id, total, products:[{id,price,amount}], phone?}` |
| `trackSearch(q, n)` | `search` | (server-emitted on web) | `{query, results_count}` |

See [`events.md`](events.md) for payload details.

## Profile — `POST /profile`

`setProfile(ProfileInput)` → **200**. Body:

```jsonc
{
  "anonymous_id": "<from identity>",
  "user_id": "…",        // if provided
  "email": "…",
  "phone": "…",
  "gender": "male",       // Gender.male/female → "male"/"female"
  "birthday": "1990-05-01T00:00:00.000Z", // DateTime → UTC ISO with Z
  "city_id": "…"
}
```

Mirrors the shim's `doProfileSet` (`m`/`f` → `male`/`female`, `birthday` →
ISO-8601).

## Recommendations — `GET /recommendations`

`recommend(blockCode, …)` → `{items: [id…], request_id}`. Query params:

| Query | Source |
| --- | --- |
| `besh24_block_id` | `blockCode` (external Rees46 block id / algorithm name) |
| `city_id` | `cityId` › profile city › `defaultCityId` |
| `source` | `Besh24Config.source` |
| `anonymous_id` | identity |
| `user_id` | if set |
| `item_id`, `category_id`, `brand`, `limit` | optional args |
| `extended` | `extended` (default `false`) — see below |

The backend maps `besh24_block_id` to its internal `block` algorithm.

`extended: true` adds a `products` map (id → catalog fields: `name`, `nameKk`,
`slug`, `url`, `imageUrl`, `brand`, `price`, `oldPrice`, `discountPercent`,
`rating`, `badges`, `available`, `fromDc`, `stock`) to the response, resolved
per the request's `city_id`. Parsed into `RecommendationResult.products`
(`RecommendationEnrichedItem`). A product id in `itemIds` without a catalog
entry is simply absent from the map.

## Batch recommendations — `POST /recommendations/batch`

`recommendBatch(blocks, …)` → `{request_id, blocks: {block_id: {...}}}`,
parsed into `RecommendationBatchResult`. Resolves N blocks in one round trip
instead of N calls to `recommend`. Body:

```jsonc
{
  "blocks": [
    {"block_id": "popular"},
    {"block_id": "basket", "item_ids": ["a", "b"]}
  ],
  "city_id": "2",
  "anonymous_id": "<from identity>",
  "user_id": "…",     // if set
  "source": "app",
  "extended": false    // applies to the whole batch
}
```

The backend issues one `request_id` for the whole batch — individual blocks
do not get their own. The SDK copies it into every entry's
`RecommendationResult.requestId` in `RecommendationBatchResult.blocks` for
uniform impression attribution. A block that fails server-side resolves to an
empty `RecommendationResult` rather than failing the whole batch.

## Search — `GET /search`

`search(query, …)` → `{items:[{id,name,price,image,url}], total, page, facets}`.

| Query | Source |
| --- | --- |
| `q` | `query` |
| `city_id` | resolved city |
| `source` | `Besh24Config.source` |
| `anonymous_id` / `user_id` | identity / profile |
| `brand`, `category`, `page`, `per_page`, `price_min`, `price_max`, `sort` | optional args |
| `filters[<name>]` (repeated key, one per selected value) | `paramFilters` — product characteristic name → selected values |

`sort` is one of `relevance` (default), `price_asc`, `price_desc`, `new`.

`filters[brand]`/`filters[category]`/`filters[price]` are a separate bracket
form the backend also accepts for the same `brand`/`category`/`price_min`+
`price_max` filters above; the SDK always sends the flat query params for
those three, not the bracket form. Only free-form product characteristics
(anything that isn't brand/category/price) go through `paramFilters` as
`filters[<name>]`.

`facets` in the response is richer than the raw map exposed for backward
compatibility: `SearchResult` also parses `facets.brand`, `facets.category`,
`facets.price_range`, `facets.price_median`, `facets.price_ranges` and
`facets.params` (product characteristics with per-value counts) into typed
fields — see `docs/api-reference.md`. Filtering results by picking a value
out of `paramFacets` and re-searching with it in `paramFilters` is the
supported discovery loop; there is no separate facet-listing endpoint.

## Instant search — `GET /search/instant`

`searchInstant(query, cityId)` → `{products:[{id,name,price,image_url,url}], …}`.
The SDK reads the **`products`** array (rich cards) and normalizes each into an
`InstantSearchItem` (`image_url` → `image`). There is no DOM overlay on mobile,
so — unlike the web shim — the SDK parses the product list directly.

| Query | Source |
| --- | --- |
| `q` | `query` |
| `city_id` | resolved city (mandatory) |
| `source` | `Besh24Config.source` |
| `anonymous_id` / `user_id` | identity / profile |
| `limit` | optional |

## Restock subscription — `POST /subscriptions/restock`

`subscribeRestock(RestockInput)` → **201**. Requires at least one contact
(`email` or `phone`); otherwise the SDK returns `Err(ValidationError)` without a
request. Body:

```jsonc
{
  "item_id": "SKU-123",
  "city_id": "<input city or defaultCityId>",
  "anonymous_id": "<from identity>",
  "user_id": "…",   // if set
  "email": "…",      // present contact(s) only
  "phone": "…"
}
```

## Notes on deltas vs. the task conspectus

- `search` / `search/instant` use the query key **`q`** (the shim and the shared
  `searchQuerySchema` use `q`, not `search`).
- Recommendations use **`besh24_block_id`** (external id, mapped server-side to
  `block`), matching the shim's `doRecommend`.
- Instant search exposes **`products`**, not `items`.
- A recommendation block (single or batch) may legitimately return an empty or
  short `items`/`itemIds` list — the backend no longer pads results out to the
  requested limit. This is a normal, successful (`Ok`) response, not an error;
  do not treat `itemIds.isEmpty` as a failure signal.
- `source` is an SDK addition (free-form analytics channel) sent on every event
  and on recommend/search/instant. The backend accepts it as an optional field
  (unknown keys are stripped by zod), so it is always safe to send.
