/// Small JSON coercion helpers shared by the wire models.
///
/// The backend mixes numeric and string typing for ids/prices across the
/// catalog, so parsing is defensive rather than strict.
library;

/// Coerces a JSON value to [num] (defaults to `0`). Accepts int, double, or a
/// numeric string.
num asNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

/// Coerces a JSON value to [int] (defaults to [fallback]).
int asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
