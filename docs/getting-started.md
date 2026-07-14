# Getting started

## 1. Add the dependency

```yaml
dependencies:
  besh24_sdk:
    git:
      url: https://github.com/besh24/besh24_flutter_sdk.git
      ref: v0.1.0
```

```bash
flutter pub get
```

## 2. Create and initialize the client

Create **one** client for the app lifetime (e.g. in a provider / singleton) and
`init` it once at startup:

```dart
final client = Besh24Client();

await client.init(
  Besh24Config(
    baseUrl: 'https://besh24.evrika.com/api/v1', // full URL incl. /api/v1
    defaultCityId: '1',
    source: 'app',
  ),
);
```

`init` performs `GET /identity`, persists the returned `anonymous_id` /
`session_id` in `shared_preferences`, and returns the resolved `Identity`. On a
network failure it degrades to a locally generated identity so tracking still
works offline.

## 3. Track behavior

```dart
await client.trackView('SKU-123');
await client.trackCategory('phones');
await client.trackCart('SKU-123', amount: 1, price: 4990);
await client.trackWish('SKU-123');
await client.trackPurchase(
  orderId: 'ORDER-1',
  total: 4990,
  products: const [PurchaseItem(id: 'SKU-123', price: 4990, amount: 1)],
);
```

Tracking is fire-and-forget — you may `await` the returned `Result` to inspect
the outcome, or ignore it. Failures are logged, never thrown.

## 4. Recommendations & search

```dart
final recs = await client.recommend('popular', limit: 8);
for (final id in recs.valueOrNull?.itemIds ?? const []) {
  // fetch/render your product card for `id`
}

final page = await client.search('телефон', cityId: '1');
final total = page.valueOrNull?.total ?? 0;

final suggestions = await client.searchInstant('теле', cityId: '1');
```

The backend returns product **ids** for recommendations (card enrichment is your
app's job) and compact product cards for search.

## 5. Identify the user & subscribe to restock

```dart
await client.setProfile(
  ProfileInput(
    userId: 'user-42',
    email: 'a@b.c',
    gender: Gender.male,
    birthday: DateTime.utc(1990, 5, 1),
    cityId: '1',
  ),
);

await client.subscribeRestock(
  const RestockInput(itemId: 'SKU-123', email: 'a@b.c'),
);
```

Once `setProfile` is called with a `userId` / `cityId`, those values are
remembered and attached to subsequent events and queries.

## 6. Custom storage / transport (optional)

All infrastructure is injectable. For example, to run headless or in tests:

```dart
final client = Besh24Client(
  httpClient: myHttpClient,     // implements Besh24HttpClient (e.g. dio)
  storage: InMemoryStorage(),   // or your own Besh24Storage
  logger: DefaultBesh24Logger(silent: true),
);
```

See [`api-reference.md`](api-reference.md) for the full surface.
