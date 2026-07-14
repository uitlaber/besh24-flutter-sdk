import 'package:uuid/uuid.dart';

/// Generates identifiers for events and local fallback identities.
///
/// Wrapped behind an interface so tests can inject deterministic ids.
abstract interface class UuidGenerator {
  /// Returns a new random UUID v4 string.
  String v4();
}

/// [UuidGenerator] backed by `package:uuid`.
class UuidV4Generator implements UuidGenerator {
  /// Creates a generator.
  UuidV4Generator([Uuid? uuid]) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  @override
  String v4() => _uuid.v4();
}
