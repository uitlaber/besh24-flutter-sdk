import '../../domain/entities/identity.dart';

/// Wire model for `GET /api/v1/identity`.
class IdentityModel {
  /// Creates a model.
  const IdentityModel({this.anonymousId, this.sessionId});

  /// `anonymous_id` from the response (nullable — middleware may omit).
  final String? anonymousId;

  /// `session_id` from the response.
  final String? sessionId;

  /// Parses the `{anonymous_id, session_id}` body.
  factory IdentityModel.fromJson(Map<String, Object?> json) => IdentityModel(
        anonymousId: json['anonymous_id'] as String?,
        sessionId: json['session_id'] as String?,
      );

  /// Maps to a domain [Identity]. Both ids must be present.
  Identity? toEntity() {
    final a = anonymousId;
    final s = sessionId;
    if (a == null || a.isEmpty || s == null || s.isEmpty) return null;
    return Identity(anonymousId: a, sessionId: s);
  }
}
