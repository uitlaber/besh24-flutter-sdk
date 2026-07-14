import 'dart:developer' as developer;

/// Sink for the SDK's diagnostic messages.
///
/// The SDK never crashes the host app: failures are logged through a
/// [Besh24Logger] and surfaced as [Result] errors. Provide a custom logger to
/// route messages into your own observability stack.
abstract interface class Besh24Logger {
  /// Records a non-fatal [message], optionally with the originating [error].
  void warn(String message, [Object? error]);
}

/// Default logger writing to `dart:developer` under the `besh24_sdk` name.
class DefaultBesh24Logger implements Besh24Logger {
  /// Creates a logger; pass `silent: true` to suppress output entirely.
  const DefaultBesh24Logger({this.silent = false});

  /// When `true`, [warn] does nothing.
  final bool silent;

  @override
  void warn(String message, [Object? error]) {
    if (silent) return;
    developer.log(message, name: 'besh24_sdk', error: error);
  }
}
