import 'package:besh24_sdk/src/domain/entities/identity.dart';
import 'package:besh24_sdk/src/domain/entities/profile_input.dart';
import 'package:besh24_sdk/src/domain/entities/restock_input.dart';
import 'package:besh24_sdk/src/domain/entities/track_event.dart';
import 'package:besh24_sdk/src/data/models/wire_serializers.dart';
import 'package:flutter_test/flutter_test.dart';

const _identity = Identity(anonymousId: 'anon-1', sessionId: 'sess-1');

void main() {
  group('WireSerializers.trackEvent', () {
    test('emits ISO-8601 UTC ts with a trailing Z and the source', () {
      final event = TrackEvent(
        eventId: 'evt-1',
        type: TrackEventType.cart,
        anonymousId: 'anon-1',
        sessionId: 'sess-1',
        ts: DateTime.utc(2026, 7, 14, 9, 30, 15, 250),
        source: 'app',
        cityId: '3',
        userId: 'u-1',
        payload: {'item_id': 'SKU', 'amount': 2},
      );

      final json = WireSerializers.trackEvent(event);

      expect(json['event_id'], 'evt-1');
      expect(json['type'], 'cart');
      expect(json['anonymous_id'], 'anon-1');
      expect(json['session_id'], 'sess-1');
      expect(json['user_id'], 'u-1');
      expect(json['city_id'], '3');
      expect(json['source'], 'app');
      expect(json['ts'], '2026-07-14T09:30:15.250Z');
      expect((json['ts'] as String).endsWith('Z'), isTrue);
      expect(json['payload'], {'item_id': 'SKU', 'amount': 2});
    });

    test('omits user_id/city_id when absent', () {
      final json = WireSerializers.trackEvent(
        TrackEvent(
          eventId: 'e',
          type: TrackEventType.wish,
          anonymousId: 'a',
          sessionId: 's',
          ts: DateTime.utc(2026),
          source: 'app',
          payload: const {'item_id': '1'},
        ),
      );
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('city_id'), isFalse);
    });
  });

  group('WireSerializers.profile', () {
    test('maps gender to wire value and birthday to ISO with Z', () {
      final json = WireSerializers.profile(
        _identity,
        ProfileInput(
          gender: Gender.female,
          birthday: DateTime.utc(1990, 5, 1),
          email: 'a@b.c',
          cityId: '2',
          userId: 'u-1',
        ),
      );

      expect(json['anonymous_id'], 'anon-1');
      expect(json['gender'], 'female');
      expect(json['birthday'], '1990-05-01T00:00:00.000Z');
      expect(json['email'], 'a@b.c');
      expect(json['city_id'], '2');
      expect(json['user_id'], 'u-1');
    });

    test('genderFromShorthand maps m/f and unknown -> null', () {
      expect(ProfileInput.genderFromShorthand('m'), Gender.male);
      expect(ProfileInput.genderFromShorthand('F'), Gender.female);
      expect(ProfileInput.genderFromShorthand('female'), Gender.female);
      expect(ProfileInput.genderFromShorthand('x'), isNull);
      expect(ProfileInput.genderFromShorthand(null), isNull);
    });
  });

  group('WireSerializers.restock', () {
    test('includes item/city/anon and present contacts', () {
      final json = WireSerializers.restock(
        _identity,
        const RestockInput(itemId: 'p-1', phone: '+7700'),
        '5',
      );
      expect(json['item_id'], 'p-1');
      expect(json['city_id'], '5');
      expect(json['anonymous_id'], 'anon-1');
      expect(json['phone'], '+7700');
      expect(json.containsKey('email'), isFalse);
    });
  });
}
