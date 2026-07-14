/// Anonymous device/session identity issued by the backend.
///
/// Mirrors `GET /api/v1/identity` → `{anonymous_id, session_id}`. Both ids are
/// carried explicitly in every event body and in recommend/search query params.
class Identity {
  /// Creates an identity.
  const Identity({required this.anonymousId, required this.sessionId});

  /// Long-lived anonymous device id (`besh24_aid`).
  final String anonymousId;

  /// Current session id (`besh24_sid`), rotated after idle.
  final String sessionId;

  @override
  bool operator ==(Object other) =>
      other is Identity &&
      other.anonymousId == anonymousId &&
      other.sessionId == sessionId;

  @override
  int get hashCode => Object.hash(anonymousId, sessionId);

  @override
  String toString() => 'Identity($anonymousId, $sessionId)';
}

/// A cached [Identity] together with the last time it was persisted, used by
/// [EnsureIdentity] to apply the session-idle rule.
class CachedIdentity {
  /// Creates a cached identity.
  const CachedIdentity({required this.identity, required this.lastSeenAt});

  /// The stored identity.
  final Identity identity;

  /// When the identity was last written (UTC).
  final DateTime lastSeenAt;
}
