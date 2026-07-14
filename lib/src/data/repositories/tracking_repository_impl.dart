import '../../core/result.dart';
import '../../domain/entities/track_event.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/besh24_remote_data_source.dart';
import '../models/wire_serializers.dart';

/// [TrackingRepository] serializing events to the batch wire shape.
class TrackingRepositoryImpl implements TrackingRepository {
  /// Creates the repository.
  TrackingRepositoryImpl(this._remote);

  final Besh24RemoteDataSource _remote;

  @override
  Future<Result<void>> track(List<TrackEvent> events) {
    final body = events.map(WireSerializers.trackEvent).toList(growable: false);
    return _remote.postEvents(body);
  }
}
