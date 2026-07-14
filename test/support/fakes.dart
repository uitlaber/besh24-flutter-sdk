import 'package:besh24_sdk/besh24_sdk.dart';

/// A recorded outbound request, captured by [RecordingHttpClient].
class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.url,
    this.headers,
    this.body,
  });

  final String method;
  final Uri url;
  final Map<String, String>? headers;
  final String? body;

  /// Decoded query parameters of the request URL.
  Map<String, String> get query => url.queryParameters;
}

/// [Besh24HttpClient] test double that records every request and returns a
/// programmable response.
class RecordingHttpClient implements Besh24HttpClient {
  RecordingHttpClient({this.responder});

  /// Produces the response for a given recorded request. Defaults to `200 {}`.
  Result<Besh24HttpResponse> Function(RecordedRequest req)? responder;

  final List<RecordedRequest> requests = [];

  /// The most recently recorded request.
  RecordedRequest get last => requests.last;

  Result<Besh24HttpResponse> _respond(RecordedRequest req) {
    requests.add(req);
    final r = responder?.call(req);
    return r ?? const Ok(Besh24HttpResponse(statusCode: 200, body: '{}'));
  }

  @override
  Future<Result<Besh24HttpResponse>> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return _respond(
      RecordedRequest(method: 'GET', url: url, headers: headers),
    );
  }

  @override
  Future<Result<Besh24HttpResponse>> post(
    Uri url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    return _respond(
      RecordedRequest(method: 'POST', url: url, headers: headers, body: body),
    );
  }

  @override
  void close() {}
}

/// Deterministic [Clock] returning a fixed, advanceable instant.
class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  set now(DateTime value) => _now = value.toUtc();

  @override
  DateTime nowUtc() => _now.toUtc();
}

/// [UuidGenerator] returning a predictable sequence of ids.
class SequenceUuid implements UuidGenerator {
  SequenceUuid([this._ids = const ['uuid-1', 'uuid-2', 'uuid-3']]);

  final List<String> _ids;
  int _i = 0;

  @override
  String v4() {
    final id = _ids[_i % _ids.length];
    _i++;
    return id;
  }
}

/// [Besh24Logger] that captures messages for assertions.
class CapturingLogger implements Besh24Logger {
  final List<String> messages = [];

  @override
  void warn(String message, [Object? error]) {
    messages.add(message);
  }
}
