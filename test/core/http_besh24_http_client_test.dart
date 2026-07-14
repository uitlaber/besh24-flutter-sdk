import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpBesh24HttpClient', () {
    test('returns Ok with body and status on success', () async {
      final mock = MockClient((req) async => http.Response('{"ok":true}', 200));
      final client = HttpBesh24HttpClient(client: mock);

      final res = await client.get(Uri.parse('https://x.test/identity'));

      expect(res, isA<Ok<Besh24HttpResponse>>());
      final value = (res as Ok<Besh24HttpResponse>).value;
      expect(value.statusCode, 200);
      expect(value.isOk, isTrue);
      expect(value.body, '{"ok":true}');
    });

    test('a 500 still resolves as Ok(response) — status handled upstream',
        () async {
      final mock = MockClient((req) async => http.Response('boom', 500));
      final client = HttpBesh24HttpClient(client: mock);

      final res = await client.get(Uri.parse('https://x.test/x'));

      final value = (res as Ok<Besh24HttpResponse>).value;
      expect(value.statusCode, 500);
      expect(value.isOk, isFalse);
    });

    test('maps a transport exception to NetworkError', () async {
      final mock = MockClient((req) async => throw Exception('offline'));
      final client = HttpBesh24HttpClient(client: mock);

      final res = await client.post(
        Uri.parse('https://x.test/events'),
        body: '{}',
      );

      expect(res, isA<Err<Besh24HttpResponse>>());
      expect((res as Err).error, isA<NetworkError>());
    });

    test('maps a timeout to NetworkError', () async {
      final mock = MockClient((req) async {
        await Future<void>.delayed(const Duration(seconds: 5));
        return http.Response('{}', 200);
      });
      final client = HttpBesh24HttpClient(
        client: mock,
        timeout: const Duration(milliseconds: 50),
      );

      final res = await client.get(Uri.parse('https://x.test/x'));

      expect(res, isA<Err<Besh24HttpResponse>>());
      expect((res as Err).error, isA<NetworkError>());
    });
  });
}
