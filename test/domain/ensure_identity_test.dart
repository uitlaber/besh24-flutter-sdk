import 'package:besh24_sdk/src/core/result.dart';
import 'package:besh24_sdk/src/domain/entities/identity.dart';
import 'package:besh24_sdk/src/domain/repositories/identity_repository.dart';
import 'package:besh24_sdk/src/domain/usecases/ensure_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

class _MockIdentityRepository extends Mock implements IdentityRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Identity(anonymousId: 'a', sessionId: 's'),
    );
  });

  late _MockIdentityRepository repo;
  late FixedClock clock;
  late SequenceUuid uuid;

  const idle = Duration(minutes: 30);
  final now = DateTime.utc(2026, 7, 14, 12);

  EnsureIdentity build() => EnsureIdentity(
        repository: repo,
        clock: clock,
        uuid: uuid,
        sessionIdleTimeout: idle,
      );

  setUp(() {
    repo = _MockIdentityRepository();
    clock = FixedClock(now);
    uuid = SequenceUuid(['gen-anon', 'gen-session']);
    when(() => repo.save(any())).thenAnswer((_) async {});
  });

  test('with no cache, fetches with null ids and saves the result', () async {
    when(() => repo.loadCached()).thenAnswer((_) async => null);
    when(
      () => repo.fetchRemote(
        anonymousId: any(named: 'anonymousId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer(
      (_) async => const Ok(Identity(anonymousId: 'A', sessionId: 'S')),
    );

    final result = await build().call();

    expect((result as Ok<Identity>).value.anonymousId, 'A');
    verify(() => repo.fetchRemote(anonymousId: null, sessionId: null))
        .called(1);
    verify(() => repo.save(const Identity(anonymousId: 'A', sessionId: 'S')))
        .called(1);
  });

  test('with a fresh cache, resends both cached ids', () async {
    when(() => repo.loadCached()).thenAnswer(
      (_) async => CachedIdentity(
        identity: const Identity(anonymousId: 'A', sessionId: 'S'),
        lastSeenAt: now.subtract(const Duration(minutes: 5)),
      ),
    );
    when(
      () => repo.fetchRemote(
        anonymousId: any(named: 'anonymousId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer(
      (_) async => const Ok(Identity(anonymousId: 'A', sessionId: 'S')),
    );

    await build().call();

    verify(() => repo.fetchRemote(anonymousId: 'A', sessionId: 'S')).called(1);
  });

  test('with a stale cache, drops the session id to force rotation', () async {
    when(() => repo.loadCached()).thenAnswer(
      (_) async => CachedIdentity(
        identity: const Identity(anonymousId: 'A', sessionId: 'OLD'),
        lastSeenAt: now.subtract(const Duration(minutes: 45)),
      ),
    );
    when(
      () => repo.fetchRemote(
        anonymousId: any(named: 'anonymousId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer(
      (_) async => const Ok(Identity(anonymousId: 'A', sessionId: 'NEW')),
    );

    await build().call();

    verify(() => repo.fetchRemote(anonymousId: 'A', sessionId: null)).called(1);
  });

  test('on remote failure with a cache, degrades to the cached identity',
      () async {
    const cached = Identity(anonymousId: 'A', sessionId: 'S');
    when(() => repo.loadCached()).thenAnswer(
      (_) async => CachedIdentity(identity: cached, lastSeenAt: now),
    );
    when(
      () => repo.fetchRemote(
        anonymousId: any(named: 'anonymousId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => const Err(NetworkError('down')));

    final result = await build().call();

    expect((result as Ok<Identity>).value, cached);
    verify(() => repo.save(cached)).called(1);
  });

  test('on remote failure with no cache, generates a local identity', () async {
    when(() => repo.loadCached()).thenAnswer((_) async => null);
    when(
      () => repo.fetchRemote(
        anonymousId: any(named: 'anonymousId'),
        sessionId: any(named: 'sessionId'),
      ),
    ).thenAnswer((_) async => const Err(NetworkError('down')));

    final result = await build().call();

    final id = (result as Ok<Identity>).value;
    expect(id.anonymousId, 'gen-anon');
    expect(id.sessionId, 'gen-session');
    verify(() => repo.save(id)).called(1);
  });
}
