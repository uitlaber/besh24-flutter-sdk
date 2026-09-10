# Events

All events are delivered via `POST /events` as a batch (`{events:[…]}`) and
accepted with **202**. The SDK builds one event per typed call. Common fields
(`event_id`, `anonymous_id`, `session_id`, `user_id?`, `city_id?`, `ts`,
`source`) are described in [`contract-mapping.md`](contract-mapping.md); this
page focuses on the per-type `payload`.

`event_id` is a UUID v4; `ts` is UTC ISO-8601 with a trailing `Z`.

## `view`

Product page view.

```dart
await client.trackView('SKU-123', available: true);
```

```json
{ "item_id": "SKU-123", "available": true }
```

`available` mirrors the shim's `stock`/`available` flag (whether the product is
in stock in the current city).

## `category`

Category page view.

```dart
await client.trackCategory('phones');
```

```json
{ "category_id": "phones" }
```

## `cart` / `remove_from_cart`

Add/remove a product to/from the cart. `amount` and `price` are optional.

```dart
await client.trackCart('SKU-123', amount: 2, price: 4990);
await client.trackRemoveFromCart('SKU-123');
```

```json
{ "item_id": "SKU-123", "amount": 2, "price": 4990 }
```

## `wish` / `remove_wish`

Add/remove a product to/from the wishlist.

```dart
await client.trackWish('SKU-123');
await client.trackRemoveWish('SKU-123');
```

```json
{ "item_id": "SKU-123" }
```

## `purchase`

A completed order. `phone` is optional.

```dart
await client.trackPurchase(
  orderId: 'ORDER-1',
  total: 9980,
  products: const [
    PurchaseItem(id: 'SKU-123', price: 4990, amount: 1),
    PurchaseItem(id: 'SKU-456', price: 4990, amount: 1),
  ],
  phone: '+77001234567',
);
```

```json
{
  "order_id": "ORDER-1",
  "total": 9980,
  "products": [
    { "id": "SKU-123", "price": 4990, "amount": 1 },
    { "id": "SKU-456", "price": 4990, "amount": 1 }
  ],
  "phone": "+77001234567"
}
```

## `search`

A search performed by the user (query + number of results shown).

```dart
await client.trackSearch('телефон', 42);
```

```json
{ "query": "телефон", "results_count": 42 }
```

> Note: `search`, `search/instant` and `recommend` HTTP calls also emit their own
> server-side analytics; `trackSearch` is for cases where you render results
> yourself and want to record the interaction explicitly.

## `recommendation_click`

A click on a product rendered inside a recommendation block. Feeds the block's
own click statistics, so `block` must be the same identifier passed to
`recommend` and `itemId` the product exactly as it came back in that block.

```dart
await client.trackRecommendationClick(block: 'popular', itemId: 'SKU-123');
```

```json
{ "block": "popular", "item_id": "SKU-123" }
```

> Both fields are required. An empty (or blank) `block`/`itemId` returns
> `Err(ValidationError)` without a request — a click on an unmarked card must
> not produce wire noise.

## `visit`

Landed on the site (session start). Not about a product or a page — the base
event fields (`anonymous_id`/`session_id`/`ts`/`source`) already carry
everything meaningful, so the payload is empty.

```dart
await client.trackVisit();
```

```json
{}
```

## `page_open`

Opened a page, identified by its path. The server strips any query string and
hash from `path` and rejects the event if nothing is left afterwards; the SDK
does the same normalization locally and returns `Err(ValidationError)` without
a request when the result would be empty — a path like `'?ref=x'` never
reaches the wire.

```dart
await client.trackPageOpen('/catalog/42');
```

```json
{ "path": "/catalog/42" }
```

## `review`

Left a review on a product. `rating`, if given, must be an integer `1`..`5`.

```dart
await client.trackReview('SKU-123', rating: 5);
```

```json
{ "item_id": "SKU-123", "rating": 5 }
```

> An out-of-range `rating` (e.g. `0` or `6`) is dropped from the payload, not
> the whole event — matching the web shim, which sends `review` without the
> invalid key rather than discarding the signal.

## Resilience

Tracking is fire-and-forget. On any failure the call returns `Err` and logs via
the injected `Besh24Logger`; it never throws and never blocks the UI.
