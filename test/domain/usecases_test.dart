import 'package:besh24_sdk/src/core/result.dart';
import 'package:besh24_sdk/src/domain/entities/identity.dart';
import 'package:besh24_sdk/src/domain/entities/restock_input.dart';
import 'package:besh24_sdk/src/domain/entities/track_event.dart';
import 'package:besh24_sdk/src/domain/repositories/subscription_repository.dart';
import 'package:besh24_sdk/src/domain/repositories/tracking_repository.dart';
import 'package:besh24_sdk/src/domain/usecases/subscribe_restock.dart';
import 'package:besh24_sdk/src/domain/usecases/track_event_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/fakes.dart';

class _MockTrackingRepository extends Mock implements TrackingRepository {}

class _MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

const _identity = Identity(anonymousId: 'anon-1', sessionId: 'sess-1');

void main() {
  setUpAll(() {
    registerFallbackValue(_identity);
    registerFallbackValue(const RestockInput(itemId: 'x'));
  });

  group('TrackEventUsecase', () {
    test('stamps id/ts/source/identity and batches a single event', () async {
      final repo = _MockTrackingRepository();
      final captured = <List<TrackEvent>>[];
      when(() => repo.track(any())).thenAnswer((inv) async {
        captured.add(inv.positionalArguments.first as List<TrackEvent>);
        return const Ok(null);
      });

      final usecase = TrackEventUsecase(
        repository: repo,
        clock: FixedClock(DateTime.utc(2026, 1, 2, 3, 4, 5)),
        uuid: SequenceUuid(['evt-1']),
      );

      await usecase.call(
        type: TrackEventType.view,
        payload: {'item_id': 'SKU', 'available': true},
        identity: _identity,
        source: 'testweb',
        cityId: '7',
        userId: 'u-9',
      );

      expect(captured.single.length, 1);
      final ev = captured.single.single;
      expect(ev.eventId, 'evt-1');
      expect(ev.type, TrackEventType.view);
      expect(ev.anonymousId, 'anon-1');
      expect(ev.sessionId, 'sess-1');
      expect(ev.source, 'testweb');
      expect(ev.cityId, '7');
      expect(ev.userId, 'u-9');
      expect(ev.ts, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });
  });

  group('SubscribeRestock', () {
    test('rejects input with no contact without hitting the repository',
        () async {
      final repo = _MockSubscriptionRepository();
      final result = await SubscribeRestock(repo)
          .call(_identity, const RestockInput(itemId: 'p'));

      expect(result, isA<Err<void>>());
      expect((result as Err).error, isA<ValidationError>());
      verifyNever(() => repo.subscribeRestock(any(), any()));
    });

    test('delegates when a contact is present', () async {
      final repo = _MockSubscriptionRepository();
      when(() => repo.subscribeRestock(any(), any()))
          .thenAnswer((_) async => const Ok(null));

      final result = await SubscribeRestock(repo).call(
        _identity,
        const RestockInput(itemId: 'p', email: 'a@b.c'),
      );

      expect(result, isA<Ok<void>>());
      verify(() => repo.subscribeRestock(_identity, any())).called(1);
    });
  });
}
