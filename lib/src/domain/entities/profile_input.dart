/// Visitor gender, as accepted by `POST /api/v1/profile`.
///
/// The web shim maps `m`/`f` to `male`/`female`; the SDK exposes the canonical
/// values directly and lets [ProfileInput.genderFromShorthand] accept the
/// shorthand for convenience.
enum Gender {
  /// Male (`male` on the wire).
  male,

  /// Female (`female` on the wire).
  female;

  /// The wire value.
  String get wire => name;
}

/// Input for a profile upsert (`POST /api/v1/profile`).
///
/// `anonymous_id` is injected by the client from the current identity, so it is
/// not part of this value object. [birthday] is a plain `DateTime`; the data
/// layer serializes it to an ISO-8601 UTC string with a `Z` suffix.
class ProfileInput {
  /// Creates a profile input.
  const ProfileInput({
    this.userId,
    this.email,
    this.phone,
    this.birthday,
    this.gender,
    this.cityId,
  });

  /// Authenticated user id (promotes the guest profile).
  final String? userId;

  /// Email contact.
  final String? email;

  /// Phone contact.
  final String? phone;

  /// Birthday (date-only is fine; time is zeroed in UTC).
  final DateTime? birthday;

  /// Gender.
  final Gender? gender;

  /// City id.
  final String? cityId;

  /// Parses `m`/`male`/`f`/`female` (case-insensitive) into a [Gender], or
  /// `null` if unrecognized — mirrors the shim's `mapGender`.
  static Gender? genderFromShorthand(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'm':
      case 'male':
        return Gender.male;
      case 'f':
      case 'female':
        return Gender.female;
      default:
        return null;
    }
  }
}
