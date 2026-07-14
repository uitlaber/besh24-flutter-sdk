import '../../core/result.dart';
import '../entities/track_event.dart';

/// Sends batched tracking events to `POST /api/v1/events`.
abstract interface class TrackingRepository {
  /// Delivers [events] as a single batch. Returns [Ok] on 202.
  Future<Result<void>> track(List<TrackEvent> events);
}
