import 'dart:async';

import 'package:http/http.dart' as http;

import '../result.dart';
import 'besh24_http_client.dart';

/// [Besh24HttpClient] implemented on top of `package:http`.
///
/// We chose `http` over `dio` deliberately: the SDK's needs are a handful of
/// GET/POST calls, and `http` ships an official `MockClient` (`http/testing`)
/// that makes request-shape assertions trivial without extra mocking layers.
class HttpBesh24HttpClient implements Besh24HttpClient {
  /// Wraps an existing [http.Client] (inject `MockClient` in tests) and applies
  /// [timeout] to every request.
  HttpBesh24HttpClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Per-request timeout.
  final Duration timeout;

  @override
  Future<Result<Besh24HttpResponse>> get(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return _send(() => _client.get(url, headers: headers));
  }

  @override
  Future<Result<Besh24HttpResponse>> post(
    Uri url, {
    Map<String, String>? headers,
    String? body,
  }) {
    return _send(() => _client.post(url, headers: headers, body: body));
  }

  @override
  Future<Result<Besh24HttpResponse>> delete(
    Uri url, {
    Map<String, String>? headers,
    String? body,
  }) {
    return _send(() => _client.delete(url, headers: headers, body: body));
  }

  Future<Result<Besh24HttpResponse>> _send(
    Future<http.Response> Function() run,
  ) async {
    try {
      final res = await run().timeout(timeout);
      return Ok(
        Besh24HttpResponse(
          statusCode: res.statusCode,
          body: res.body,
          headers: res.headers,
        ),
      );
    } on TimeoutException catch (e) {
      return Err(NetworkError('request timed out', cause: e));
    } catch (e) {
      return Err(NetworkError('http request failed', cause: e));
    }
  }

  @override
  void close() => _client.close();
}
