/// Abstraction over the current time, injected for testability.
///
/// Event timestamps (`ts`) and the session-idle check both read [nowUtc], so
/// tests can supply a fixed clock and assert exact ISO-8601 output.
abstract interface class Clock {
  /// The current instant in UTC.
  DateTime nowUtc();
}

/// [Clock] backed by the system wall clock.
class SystemClock implements Clock {
  /// Creates a system clock.
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
