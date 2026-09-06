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

## Resilience

Tracking is fire-and-forget. On any failure the call returns `Err` and logs via
the injected `Besh24Logger`; it never throws and never blocks the UI.
