import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Besh24Config', () {
    test('strips trailing slashes from baseUrl', () {
      final config = Besh24Config(
        baseUrl: 'https://x.test/api/v1///',
        siteKey: 'bsk_test',
      );
      expect(config.baseUrl, 'https://x.test/api/v1');
    });

    test('defaults source to "app"', () {
      final config = Besh24Config(
        baseUrl: 'https://x.test/api/v1',
        siteKey: 'bsk_test',
      );
      expect(config.source, 'app');
    });

    test('keeps a custom source', () {
      final config = Besh24Config(
        baseUrl: 'https://x.test/api/v1',
        siteKey: 'bsk_test',
        source: 'testweb',
      );
      expect(config.source, 'testweb');
    });

    test('trims and falls back to "app" for a blank source', () {
      expect(
        Besh24Config(
          baseUrl: 'https://x.test',
          siteKey: 'bsk_test',
          source: '   ',
        ).source,
        'app',
      );
      expect(
        Besh24Config(
          baseUrl: 'https://x.test',
          siteKey: 'bsk_test',
          source: '  ios ',
        ).source,
        'ios',
      );
    });

    test('defaults timeout to 10s and idle to 30m', () {
      final config =
          Besh24Config(baseUrl: 'https://x.test', siteKey: 'bsk_test');
      expect(config.timeout, const Duration(seconds: 10));
      expect(config.sessionIdleTimeout, const Duration(minutes: 30));
    });

    test('keeps the configured siteKey', () {
      final config =
          Besh24Config(baseUrl: 'https://x.test', siteKey: 'bsk_evrika_9f3c1a2b');
      expect(config.siteKey, 'bsk_evrika_9f3c1a2b');
    });

    test('defaults lang to "ru"', () {
      final config =
          Besh24Config(baseUrl: 'https://x.test', siteKey: 'bsk_test');
      expect(config.lang, 'ru');
    });

    test('keeps a custom lang', () {
      final config = Besh24Config(
        baseUrl: 'https://x.test',
        siteKey: 'bsk_test',
        lang: 'kk',
      );
      expect(config.lang, 'kk');
    });

    test('trims and falls back to "ru" for a blank lang', () {
      expect(
        Besh24Config(baseUrl: 'https://x.test', siteKey: 'bsk_test', lang: '  ')
            .lang,
        'ru',
      );
    });
  });
}
