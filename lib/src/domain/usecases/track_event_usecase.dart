import '../../core/clock.dart';
import '../../core/result.dart';
import '../../core/uuid_gen.dart';
import '../entities/identity.dart';
import '../entities/track_event.dart';
import '../repositories/tracking_repository.dart';

/// Builds a single tracking event from the current identity and sends it as a
/// batch of one — mirroring the shim's `doTrack` → `POST /events {events:[ev]}`.
///
/// The `event_id` (UUID v4), `ts` (UTC), identity ids and [source] are stamped
/// here; the caller supplies only the event [type] and its typed [payload].
class TrackEventUsecase {
  /// Creates the use-case.
  TrackEventUsecase({
    required TrackingRepository repository,
    required Clock clock,
    required UuidGenerator uuid,
  })  : _repository = repository,
        _clock = clock,
        _uuid = uuid;

  final TrackingRepository _repository;
  final Clock _clock;
  final UuidGenerator _uuid;

  /// Tracks a single event.
  Future<Result<void>> call({
    required TrackEventType type,
    required Map<String, Object?> payload,
    required Identity identity,
    required String source,
    required String cityId,
    String? userId,
  }) {
    final event = TrackEvent(
      eventId: _uuid.v4(),
      type: type,
      anonymousId: identity.anonymousId,
      sessionId: identity.sessionId,
      ts: _clock.nowUtc(),
      source: source,
      payload: payload,
      userId: userId,
      cityId: cityId,
    );
    return _repository.track([event]);
  }
}
