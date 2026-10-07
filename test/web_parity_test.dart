import 'dart:convert';

import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:besh24_sdk/src/core/page_path_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

Result<Besh24HttpResponse> _route(RecordedRequest req) {
  final body = switch (req.url.path) {
    '/api/v1/identity' => '{"anonymous_id":"srv-anon","session_id":"srv-sess"}',
    '/api/v1/recommendations' => '{"items":["1"],"request_id":"r"}',
    '/api/v1/recommendations/batch' => '{"request_id":"b","blocks":{}}',
    '/api/v1/search' => '{"items":[],"total":0,"page":1}',
    _ => '{}',
  };
  final status = req.url.path == '/api/v1/events' ? 202 : 200;
  return Ok(Besh24HttpResponse(statusCode: status, body: body));
}

Future<(Besh24Client, RecordingHttpClient)> _client() async {
  final http = RecordingHttpClient(responder: _route);
  final client = Besh24Client(
    httpClient: http,
    storage: InMemoryStorage(),
    clock: FixedClock(DateTime.utc(2026, 10, 7, 12)),
    uuid: SequenceUuid(['e1', 'e2', 'e3', 'e4']),
    logger: CapturingLogger(),
  );
  await client.init(
    Besh24Config(baseUrl: 'https://x.test/api/v1', siteKey: 'bsk_test'),
  );
  return (client, http);
}

RecordedRequest _last(RecordingHttpClient http, String path) =>
    http.requests.lastWhere((r) => r.url.path == path);

int _eventRequests(RecordingHttpClient http) =>
    http.requests.where((r) => r.url.path == '/api/v1/events').length;

void main() {
  group('recommend array context', () {
    test('itemIds/categoryIds are comma-joined, searchQuery sent', () async {
      final (c, http) = await _client();
      await c.recommend(
        'blk',
        cityId: '1',
        itemIds: ['10', '20'],
        categoryIds: ['5', '6'],
        searchQuery: ' iphone ',
      );
      final q = _last(http, '/api/v1/recommendations').query;
      expect(q['cart_item_ids'], '10,20');
      expect(q['category_ids'], '5,6');
      expect(q['search_query'], 'iphone');
    });

    test('cartItemIds is an alias of itemIds; itemIds wins', () async {
      final (c, http) = await _client();
      await c.recommend('blk', cityId: '1', cartItemIds: ['7']);
      expect(
        _last(http, '/api/v1/recommendations').query['cart_item_ids'],
        '7',
      );
      await c.recommend('blk', cityId: '1', itemIds: ['1'], cartItemIds: ['7']);
      expect(
        _last(http, '/api/v1/recommendations').query['cart_item_ids'],
        '1',
      );
    });

    test('empty/blank values are not sent', () async {
      final (c, http) = await _client();
      await c.recommend(
        'blk',
        cityId: '1',
        itemIds: ['', ' '],
        categoryIds: [],
        searchQuery: '   ',
      );
      final q = _last(http, '/api/v1/recommendations').query;
      expect(q.containsKey('cart_item_ids'), isFalse);
      expect(q.containsKey('category_ids'), isFalse);
      expect(q.containsKey('search_query'), isFalse);
    });

    test('batch blocks carry cleaned arrays and cartItemIds alias', () async {
      final (c, http) = await _client();
      await c.recommendBatch(
        [
          const RecommendationBlockRequest(
            blockCode: 'a',
            itemIds: ['1', ' ', '2'],
            categoryIds: ['9'],
          ),
          const RecommendationBlockRequest(blockCode: 'b', cartItemIds: ['3']),
          const RecommendationBlockRequest(
            blockCode: 'c',
            itemIds: [''],
            categoryIds: [],
          ),
        ],
        cityId: '1',
      );
      final blocks =
          (jsonDecode(_last(http, '/api/v1/recommendations/batch').body!)
              as Map)['blocks'] as List;
      expect(blocks[0], {
        'block_id': 'a',
        'item_ids': ['1', '2'],
        'category_ids': ['9'],
      });
      expect(blocks[1], {
        'block_id': 'b',
        'item_ids': ['3'],
      });
      expect(blocks[2], {'block_id': 'c'});
    });
  });

  group('search brands/categories', () {
    test('several values go as repeated keys, not comma-joined', () async {
      final (c, http) = await _client();
      await c.search(
        'tv',
        cityId: '1',
        brands: ['Apple', 'Samsung'],
        categories: ['a', 'b'],
      );
      final all = _last(http, '/api/v1/search').url.queryParametersAll;
      expect(all['brand'], ['Apple', 'Samsung']);
      expect(all['category'], ['a', 'b']);
    });

    test(
      'single brand/category keep working; merged without duplicates',
      () async {
        final (c, http) = await _client();
        await c.search('tv', cityId: '1', brand: 'LG', category: 'c1');
        var all = _last(http, '/api/v1/search').url.queryParametersAll;
        expect(all['brand'], ['LG']);
        expect(all['category'], ['c1']);

        await c.search(
          'tv',
          cityId: '1',
          brand: 'LG',
          brands: ['LG', 'Sony'],
          categories: ['c2'],
        );
        all = _last(http, '/api/v1/search').url.queryParametersAll;
        expect(all['brand'], ['LG', 'Sony']);
        expect(all['category'], ['c2']);
      },
    );

    test('empty lists and blanks are not sent', () async {
      final (c, http) = await _client();
      await c.search('tv', cityId: '1', brands: [], categories: ['', ' ']);
      final all = _last(http, '/api/v1/search').url.queryParametersAll;
      expect(all.containsKey('brand'), isFalse);
      expect(all.containsKey('category'), isFalse);
    });
  });

  group('page_open path rules', () {
    test('blocked segment: nothing is sent, call succeeds', () async {
      final (c, http) = await _client();
      final before = _eventRequests(http);
      for (final p in const [
        '/reset-password/TOKEN',
        '/kz/Reset-Password/TOKEN',
        'https://evrika.com//auth/login?x=1',
        '/verify-email/abc',
      ]) {
        expect(await c.trackPageOpen(p), isA<Ok<void>>());
      }
      expect(_eventRequests(http), before);
    });

    test('smart-gifts/receive/<guid> is truncated', () async {
      final (c, http) = await _client();
      await c.trackPageOpen('/smart-gifts/receive/3fa85f64-5717?x=1#h');
      final ev =
          (jsonDecode(_last(http, '/api/v1/events').body!)['events'] as List)
              .single as Map;
      expect(ev['payload'], {'path': '/smart-gifts/receive'});
    });

    test('catalog slugs and similar pages are kept whole', () async {
      final (c, http) = await _client();
      await c.trackPageOpen('/catalog/almaty/shiny/p/michelin-primacy-4');
      var ev =
          (jsonDecode(_last(http, '/api/v1/events').body!)['events'] as List)
              .single as Map;
      expect(ev['payload'], {
        'path': '/catalog/almaty/shiny/p/michelin-primacy-4',
      });
      await c.trackPageOpen('reset-password-info');
      ev = (jsonDecode(_last(http, '/api/v1/events').body!)['events'] as List)
          .single as Map;
      expect(ev['payload'], {'path': '/reset-password-info'});
    });

    test('absolute URL is reduced to path', () {
      expect(normalizePagePath('https://evrika.com/a//b?x#y'), '/a/b');
      expect(
        applyPagePathRules('/smart-gifts/receive'),
        '/smart-gifts/receive',
      );
      expect(
        applyPagePathRules('/smart-gifts/received/x'),
        '/smart-gifts/received/x',
      );
    });
  });
}
