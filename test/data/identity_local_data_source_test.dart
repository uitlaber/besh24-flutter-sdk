import 'package:besh24_sdk/besh24_sdk.dart';
import 'package:besh24_sdk/src/data/datasources/identity_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  group('IdentityLocalDataSource', () {
    late InMemoryStorage storage;
    late FixedClock clock;
    late IdentityLocalDataSource ds;
    final now = DateTime.utc(2026, 7, 14, 12);

    setUp(() {
      storage = InMemoryStorage();
      clock = FixedClock(now);
      ds = IdentityLocalDataSource(storage: storage, clock: clock);
    });

    test('read returns null when nothing is stored', () async {
      expect(await ds.read(), isNull);
    });

    test('write then read round-trips identity and last-seen', () async {
      await ds.write(const Identity(anonymousId: 'A', sessionId: 'S'));

      final cached = await ds.read();
      expect(cached, isNotNull);
      expect(
        cached!.identity,
        const Identity(anonymousId: 'A', sessionId: 'S'),
      );
      expect(cached.lastSeenAt, now);
    });

    test('read returns null when an id is partially stored', () async {
      await storage.write('anonymous_id', 'A');
      expect(await ds.read(), isNull);
    });
  });
}
