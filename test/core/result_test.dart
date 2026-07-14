import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok exposes value and no error', () {
      const r = Ok<int>(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.errorOrNull, isNull);
    });

    test('Err exposes error and no value', () {
      const r = Err<int>(NetworkError('boom'));
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.errorOrNull, isA<NetworkError>());
    });

    test('map transforms Ok and preserves Err', () {
      expect(const Ok<int>(2).map((v) => v * 10).valueOrNull, 20);
      const err = Err<int>(ValidationError('x'));
      expect(err.map((v) => v * 10).errorOrNull, isA<ValidationError>());
    });
  });
}
