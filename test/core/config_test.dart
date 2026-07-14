import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Besh24Config', () {
    test('strips trailing slashes from baseUrl', () {
      final config = Besh24Config(baseUrl: 'https://x.test/api/v1///');
      expect(config.baseUrl, 'https://x.test/api/v1');
    });

    test('defaults source to "app"', () {
      final config = Besh24Config(baseUrl: 'https://x.test/api/v1');
      expect(config.source, 'app');
    });

    test('keeps a custom source', () {
      final config =
          Besh24Config(baseUrl: 'https://x.test/api/v1', source: 'testweb');
      expect(config.source, 'testweb');
    });

    test('trims and falls back to "app" for a blank source', () {
      expect(
        Besh24Config(baseUrl: 'https://x.test', source: '   ').source,
        'app',
      );
      expect(
        Besh24Config(baseUrl: 'https://x.test', source: '  ios ').source,
        'ios',
      );
    });

    test('defaults timeout to 10s and idle to 30m', () {
      final config = Besh24Config(baseUrl: 'https://x.test');
      expect(config.timeout, const Duration(seconds: 10));
      expect(config.sessionIdleTimeout, const Duration(minutes: 30));
    });
  });
}
