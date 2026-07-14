import 'dart:convert';

import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:besh24_sdk/src/data/datasources/besh24_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

Besh24RemoteDataSource _ds(RecordingHttpClient http) => Besh24RemoteDataSource(
      http: http,
      config: Besh24Config(
        baseUrl: 'https://x.test/api/v1',
        siteKey: 'bsk_test',
      ),
    );

void main() {
  group('Besh24RemoteDataSource URL/query building', () {
    test('recommendations drops null params and keeps present ones', () async {
      final http = RecordingHttpClient(
        responder: (_) => const Ok(
          Besh24HttpResponse(
            statusCode: 200,
            body: '{"items":["1"],"request_id":"r"}',
          ),
        ),
      );

      await _ds(http).getRecommendations({
        'besh24_block_id': 'popular',
        'city_id': '2',
        'source': 'app',
        'anonymous_id': 'anon',
        'user_id': null,
        'limit': '5',
      });

      expect(http.last.url.path, '/api/v1/recommendations');
      expect(http.last.query['besh24_block_id'], 'popular');
      expect(http.last.query['city_id'], '2');
      expect(http.last.query['source'], 'app');
      expect(http.last.query['anonymous_id'], 'anon');
      expect(http.last.query['limit'], '5');
      expect(http.last.query.containsKey('user_id'), isFalse);
    });

    test('events posts a JSON batch body', () async {
      final http = RecordingHttpClient(
        responder: (_) =>
            const Ok(Besh24HttpResponse(statusCode: 202, body: '')),
      );

      final res = await _ds(http).postEvents([
        {'event_id': 'e1', 'type': 'view'},
      ]);

      expect(res, isA<Ok<void>>());
      final body = jsonDecode(http.last.body!) as Map<String, Object?>;
      expect((body['events'] as List).length, 1);
      expect(http.last.headers?['Content-Type'], 'application/json');
    });

    test('identity resends cached ids as a Cookie header', () async {
      final http = RecordingHttpClient(
        responder: (_) => const Ok(
          Besh24HttpResponse(
            statusCode: 200,
            body: '{"anonymous_id":"A","session_id":"S"}',
          ),
        ),
      );

      await _ds(http).getIdentity(anonymousId: 'A', sessionId: 'S');

      expect(http.last.headers?['Cookie'], 'besh24_aid=A; besh24_sid=S');
    });

    test('sends X-Besh24-Site-Key on every request', () async {
      final http = RecordingHttpClient(
        responder: (_) => const Ok(
          Besh24HttpResponse(
            statusCode: 200,
            body: '{"items":["1"],"request_id":"r"}',
          ),
        ),
      );

      await _ds(http).getRecommendations({'city_id': '1'});
      expect(http.last.headers?['X-Besh24-Site-Key'], 'bsk_test');

      await _ds(http).getIdentity();
      expect(http.last.headers?['X-Besh24-Site-Key'], 'bsk_test');

      await _ds(http).postEvents([
        {'event_id': 'e1', 'type': 'view'},
      ]);
      expect(http.last.headers?['X-Besh24-Site-Key'], 'bsk_test');
    });

    test('instant reads the products array', () async {
      final http = RecordingHttpClient(
        responder: (_) => const Ok(
          Besh24HttpResponse(
            statusCode: 200,
            body: '{"products":[{"id":"1","name":"A","price":10,'
                '"image_url":"i","url":"u"}]}',
          ),
        ),
      );

      final res = await _ds(http).getInstant({'q': 'x', 'city_id': '1'});

      final items = (res as Ok).value;
      expect(items.length, 1);
      expect(items.first.image, 'i');
    });
  });

  group('Besh24RemoteDataSource error mapping', () {
    test('maps a 500 to ApiError', () async {
      final http = RecordingHttpClient(
        responder: (_) =>
            const Ok(Besh24HttpResponse(statusCode: 500, body: 'boom')),
      );

      final res = await _ds(http).getSearch({'q': 'x', 'city_id': '1'});

      expect(res.isErr, isTrue);
      final err = res.errorOrNull! as ApiError;
      expect(err.statusCode, 500);
    });

    test('maps malformed JSON to SerializationError', () async {
      final http = RecordingHttpClient(
        responder: (_) =>
            const Ok(Besh24HttpResponse(statusCode: 200, body: 'not json')),
      );

      final res = await _ds(http).getSearch({'q': 'x', 'city_id': '1'});

      expect((res as Err).error, isA<SerializationError>());
    });

    test('passes a transport NetworkError through', () async {
      final http = RecordingHttpClient(
        responder: (_) => const Err(NetworkError('offline')),
      );

      final res = await _ds(http).getRecommendations({'city_id': '1'});

      expect((res as Err).error, isA<NetworkError>());
    });
  });
}
