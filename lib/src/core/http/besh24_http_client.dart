import '../result.dart';

/// Minimal HTTP response consumed by the data layer.
class Besh24HttpResponse {
  /// Creates a response.
  const Besh24HttpResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
  });

  /// HTTP status code.
  final int statusCode;

  /// Raw response body.
  final String body;

  /// Response headers (lower-cased keys).
  final Map<String, String> headers;

  /// `true` for 2xx status codes.
  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Transport abstraction so the SDK is independent of a concrete HTTP package.
///
/// The default implementation ([HttpBesh24HttpClient]) is built on
/// `package:http`; swap in your own for `dio`, interceptors or testing.
/// Implementations must not throw — transport failures are returned as an
/// [Err] with a [NetworkError].
abstract interface class Besh24HttpClient {
  /// Performs a GET request.
  Future<Result<Besh24HttpResponse>> get(
    Uri url, {
    Map<String, String>? headers,
  });

  /// Performs a POST request with a JSON [body].
  Future<Result<Besh24HttpResponse>> post(
    Uri url, {
    Map<String, String>? headers,
    String? body,
  });

  /// Performs a DELETE request with a JSON [body].
  Future<Result<Besh24HttpResponse>> delete(
    Uri url, {
    Map<String, String>? headers,
    String? body,
  });

  /// Releases any underlying resources.
  void close();
}
