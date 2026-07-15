import 'dart:convert';

import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

/// Routes responses by path so the whole graph runs against a fake transport.
Result<Besh24HttpResponse> _route(
  RecordedRequest req, {
  Map<String, Result<Besh24HttpResponse>>? overrides,
}) {
  final path = req.url.path;
  final override = overrides?[path];
  if (override != null) return override;
  final body = switch (path) {
    '/api/v1/identity' => '{"anonymous_id":"srv-anon","session_id":"srv-sess"}',
    '/api/v1/recommendations' => '{"items":["1","2"],"request_id":"req-9"}',
    '/api/v1/search' =>
      '{"items":[{"id":"1","name":"A","price":10}],"total":1,"page":1}',
    '/api/v1/search/instant' =>
      '{"products":[{"id":"1","name":"A","price":10,"image_url":"i"}]}',
    _ => '{}',
  };
  final status = switch (path) {
    '/api/v1/events' => 202,
    '/api/v1/subscriptions/restock' => 201,
    '/api/v1/push/tokens' when req.method == 'POST' => 201,
    _ => 200,
  };
  return Ok(Besh24HttpResponse(statusCode: status, body: body));
}

Future<(Besh24Client, RecordingHttpClient, CapturingLogger)> _client({
  String source = 'app',
  Map<String, Result<Besh24HttpResponse>>? overrides,
}) async {
  final http = RecordingHttpClient(
    responder: (req) => _route(req, overrides: overrides),
  );
  final logger = CapturingLogger();
  final client = Besh24Client(
    httpClient: http,
    storage: InMemoryStorage(),
    clock: FixedClock(DateTime.utc(2026, 7, 14, 12)),
    uuid: SequenceUuid(['evt-1', 'evt-2', 'evt-3', 'evt-4']),
    logger: logger,
  );
  await client.init(
    Besh24Config(
      baseUrl: 'https://x.test/api/v1',
      siteKey: 'bsk_test',
      source: source,
    ),
  );
  return (client, http, logger);
}

Map<String, Object?> _lastPostBody(RecordingHttpClient http, String path) {
  final req = http.requests.lastWhere((r) => r.url.path == path);
  return jsonDecode(req.body!) as Map<String, Object?>;
}

void main() {
  test('init resolves and persists the server identity', () async {
    final (client, _, _) = await _client();
    expect(client.identity?.anonymousId, 'srv-anon');
    expect(client.identity?.sessionId, 'srv-sess');
  });

  test('calling before init throws StateError', () {
    expect(() => Besh24Client().trackView('x'), throwsStateError);
  });

  group('tracking', () {
    test('trackView sends a batch of one with identity, source and ISO ts',
        () async {
      final (client, http, _) = await _client();
      await client.trackView('SKU', available: false, cityId: '7');

      final body = _lastPostBody(http, '/api/v1/events');
      final events = body['events'] as List;
      expect(events.length, 1);
      final ev = events.single as Map<String, Object?>;
      expect(ev['type'], 'view');
      expect(ev['anonymous_id'], 'srv-anon');
      expect(ev['session_id'], 'srv-sess');
      expect(ev['source'], 'app');
      expect(ev['city_id'], '7');
      expect((ev['ts'] as String).endsWith('Z'), isTrue);
      expect(ev['payload'], {'item_id': 'SKU', 'available': false});
    });

    test('a custom source lands in the event body', () async {
      final (client, http, _) = await _client(source: 'testweb');
      await client.trackCart('SKU', amount: 2, price: 99);

      final ev = (_lastPostBody(http, '/api/v1/events')['events'] as List)
          .single as Map<String, Object?>;
      expect(ev['source'], 'testweb');
      expect(ev['payload'], {'item_id': 'SKU', 'amount': 2, 'price': 99});
    });

    test('trackPurchase serializes products', () async {
      final (client, http, _) = await _client();
      await client.trackPurchase(
        orderId: 'o-1',
        total: 300,
        products: const [
          PurchaseItem(id: 'a', price: 100, amount: 1),
          PurchaseItem(id: 'b', price: 200, amount: 1),
        ],
        phone: '+7700',
      );

      final ev = (_lastPostBody(http, '/api/v1/events')['events'] as List)
          .single as Map<String, Object?>;
      final payload = ev['payload'] as Map<String, Object?>;
      expect(payload['order_id'], 'o-1');
      expect(payload['total'], 300);
      expect((payload['products'] as List).length, 2);
      expect(payload['phone'], '+7700');
    });
  });

  group('recommend / search / instant', () {
    test('recommend sends besh24_block_id + source and parses ids', () async {
      final (client, http, _) = await _client(source: 'ios');
      final res = await client.recommend('popular', cityId: '2', limit: 5);

      final q = http.requests
          .lastWhere((r) => r.url.path == '/api/v1/recommendations')
          .query;
      expect(q['besh24_block_id'], 'popular');
      expect(q['city_id'], '2');
      expect(q['source'], 'ios');
      expect(q['anonymous_id'], 'srv-anon');
      expect(q['limit'], '5');
      expect((res as Ok).value.itemIds, ['1', '2']);
    });

    test('search sends q + source and parses items/total', () async {
      final (client, http, _) = await _client();
      final res = await client.search('phone', cityId: '3');

      final req =
          http.requests.lastWhere((r) => r.url.path == '/api/v1/search');
      final q = req.query;
      expect(q['q'], 'phone');
      expect(q['source'], 'app');
      expect(q['lang'], 'ru');
      expect(req.headers?['X-Besh24-Site-Key'], 'bsk_test');
      final value = (res as Ok).value;
      expect(value.total, 1);
      expect(value.items.single.id, '1');
    });

    test('search sends an explicit lang override', () async {
      final (client, http, _) = await _client();
      await client.search('phone', cityId: '3', lang: 'kk');

      final q =
          http.requests.lastWhere((r) => r.url.path == '/api/v1/search').query;
      expect(q['lang'], 'kk');
    });

    test('setLang changes the runtime default lang', () async {
      final (client, http, _) = await _client();
      client.setLang('kk');
      await client.search('phone', cityId: '3');

      final q =
          http.requests.lastWhere((r) => r.url.path == '/api/v1/search').query;
      expect(q['lang'], 'kk');
      expect(client.lang, 'kk');
    });

    test('an explicit lang override wins over setLang', () async {
      final (client, http, _) = await _client();
      client.setLang('kk');
      await client.search('phone', cityId: '3', lang: 'ru');

      final q =
          http.requests.lastWhere((r) => r.url.path == '/api/v1/search').query;
      expect(q['lang'], 'ru');
    });

    test('setLang ignores unsupported values', () async {
      final (client, _, _) = await _client();
      client.setLang('kk');
      client.setLang('fr');

      expect(client.lang, 'kk');
    });

    test('searchInstant requires city and parses products', () async {
      final (client, http, _) = await _client();
      final res = await client.searchInstant('ph', cityId: '9');

      final q = http.requests
          .lastWhere((r) => r.url.path == '/api/v1/search/instant')
          .query;
      expect(q['city_id'], '9');
      expect(q['q'], 'ph');
      final items = (res as Ok).value;
      expect(items.single.image, 'i');
    });
  });

  group('profile / restock', () {
    test('setProfile maps gender and remembers user/city', () async {
      final (client, http, _) = await _client();
      await client.setProfile(
        const ProfileInput(userId: 'u-5', gender: Gender.male, cityId: '4'),
      );

      final body = _lastPostBody(http, '/api/v1/profile');
      expect(body['anonymous_id'], 'srv-anon');
      expect(body['user_id'], 'u-5');
      expect(body['gender'], 'male');

      // Remembered user/city are applied to subsequent events.
      await client.trackWish('SKU');
      final ev = (_lastPostBody(http, '/api/v1/events')['events'] as List)
          .single as Map<String, Object?>;
      expect(ev['user_id'], 'u-5');
      expect(ev['city_id'], '4');
    });

    test('subscribeRestock with a contact posts and succeeds', () async {
      final (client, http, _) = await _client();
      final res = await client.subscribeRestock(
        const RestockInput(itemId: 'p-1', email: 'a@b.c'),
      );
      expect(res, isA<Ok<void>>());
      final body = _lastPostBody(http, '/api/v1/subscriptions/restock');
      expect(body['item_id'], 'p-1');
      expect(body['city_id'], '1'); // default city
      expect(body['email'], 'a@b.c');
    });

    test('subscribeRestock without a contact fails without a request',
        () async {
      final (client, http, _) = await _client();
      final res = await client.subscribeRestock(
        const RestockInput(itemId: 'p-1'),
      );
      expect((res as Err).error, isA<ValidationError>());
      expect(
        http.requests.any(
          (r) => r.url.path == '/api/v1/subscriptions/restock',
        ),
        isFalse,
      );
    });
  });

  group('push tokens', () {
    test('registerPushToken posts token/platform/anonymousId', () async {
      final (client, http, _) = await _client();
      final res = await client.registerPushToken(
        token: 'tok-1',
        platform: 'android',
      );

      expect(res, isA<Ok<void>>());
      final req =
          http.requests.lastWhere((r) => r.url.path == '/api/v1/push/tokens');
      expect(req.method, 'POST');
      final body = jsonDecode(req.body!) as Map<String, Object?>;
      expect(body['token'], 'tok-1');
      expect(body['platform'], 'android');
      expect(body['anonymousId'], 'srv-anon');
    });

    test('unregisterPushToken sends a DELETE with the token', () async {
      final (client, http, _) = await _client();
      final res = await client.unregisterPushToken('tok-1');

      expect(res, isA<Ok<void>>());
      final req =
          http.requests.lastWhere((r) => r.url.path == '/api/v1/push/tokens');
      expect(req.method, 'DELETE');
      final body = jsonDecode(req.body!) as Map<String, Object?>;
      expect(body['token'], 'tok-1');
    });

    test('a 500 on registerPushToken returns Err and does not throw', () async {
      final (client, _, logger) = await _client(
        overrides: {
          '/api/v1/push/tokens':
              const Ok(Besh24HttpResponse(statusCode: 500, body: 'boom')),
        },
      );
      final res = await client.registerPushToken(
        token: 'tok-1',
        platform: 'android',
      );
      expect(res, isA<Err<void>>());
      expect(logger.messages, isNotEmpty);
    });
  });

  group('resilience — server failures never crash the host', () {
    test('a 500 on events returns Err, does not throw, and logs', () async {
      final (client, _, logger) = await _client(
        overrides: {
          '/api/v1/events':
              const Ok(Besh24HttpResponse(statusCode: 500, body: 'boom')),
        },
      );
      final res = await client.trackView('SKU');
      expect(res, isA<Err<void>>());
      expect(logger.messages, isNotEmpty);
    });

    test('a transport timeout/loss returns Err from track', () async {
      final (client, _, _) = await _client(
        overrides: {
          '/api/v1/events': const Err(NetworkError('timeout')),
        },
      );
      final res = await client.trackView('SKU');
      expect(res, isA<Err<void>>());
    });

    test('recommend degrades to an empty result on a 500', () async {
      final (client, _, _) = await _client(
        overrides: {
          '/api/v1/recommendations':
              const Ok(Besh24HttpResponse(statusCode: 500, body: 'x')),
        },
      );
      final res = await client.recommend('popular');
      expect((res as Ok).value.itemIds, isEmpty);
    });

    test('search degrades to an empty result on malformed JSON', () async {
      final (client, _, _) = await _client(
        overrides: {
          '/api/v1/search':
              const Ok(Besh24HttpResponse(statusCode: 200, body: 'not json')),
        },
      );
      final res = await client.search('x');
      final value = (res as Ok).value;
      expect(value.items, isEmpty);
      expect(value.total, 0);
    });

    test('searchInstant degrades to an empty list on failure', () async {
      final (client, _, _) = await _client(
        overrides: {
          '/api/v1/search/instant': const Err(NetworkError('down')),
        },
      );
      final res = await client.searchInstant('x', cityId: '1');
      expect((res as Ok).value, isEmpty);
    });
  });
}
