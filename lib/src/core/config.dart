/// Search languages accepted by the backend.
const supportedLangs = {'ru', 'kk'};

/// Normalizes a language code to one of [supportedLangs], falling back to
/// [fallback] for anything empty or unsupported. Shared by [Besh24Config]'s
/// constructor and [Besh24Client.setLang].
String sanitizeLang(String? lang, {String fallback = 'ru'}) {
  final trimmed = lang?.trim().toLowerCase() ?? '';
  return supportedLangs.contains(trimmed) ? trimmed : fallback;
}

/// Immutable configuration for [Besh24Client].
///
/// [baseUrl] is the analogue of the web shim's `window.BESH24_API_BASE`: the
/// full API base including the `/api/v1` prefix, e.g.
/// `https://besh24.example.com/api/v1`.
class Besh24Config {
  /// Creates a configuration. [baseUrl] is sanitized (trailing slashes
  /// stripped) and [source] is sanitized (trimmed; empty falls back to `app`).
  Besh24Config({
    required String baseUrl,
    required this.siteKey,
    this.shopKey,
    this.defaultCityId = '1',
    this.timeout = const Duration(seconds: 10),
    this.sessionIdleTimeout = const Duration(minutes: 30),
    this.sendCookies = true,
    String source = 'app',
    String? lang,
  })  : baseUrl = _stripTrailingSlashes(baseUrl),
        source = _sanitizeSource(source),
        lang = sanitizeLang(lang);

  /// Full API base URL including `/api/v1` (trailing slashes trimmed).
  final String baseUrl;

  /// Tenant site key sent as `X-Besh24-Site-Key` on every request (mirrors the
  /// web shim's `window.BESH24_SITE_KEY`), e.g. `bsk_demo_9f3c1a2b`.
  final String siteKey;

  /// Optional shop key forwarded to `init` (mirrors the shim's `shopKey`).
  final String? shopKey;

  /// City used when no explicit `city_id` is supplied to a call.
  final String defaultCityId;

  /// Per-request network timeout.
  final Duration timeout;

  /// Idle window after which a fresh session id is requested on the next
  /// [Besh24Client.ensureIdentity]. Mirrors the backend's 30-minute rule.
  final Duration sessionIdleTimeout;

  /// When `true`, cached `besh24_aid`/`besh24_sid` are resent as a `Cookie`
  /// header on `GET /identity` so the backend reuses the same identity across
  /// launches (equivalent to the web shim's `credentials: 'include'`).
  final bool sendCookies;

  /// Free-form analytics source stamped into every event body and sent as the
  /// `source` query parameter on recommend/search/instant. Defaults to `app`;
  /// consumers may use any non-empty label (`ios`, `testweb`, …).
  final String source;

  /// Search language (`ru` or `kk`) sent as the `lang` query parameter on
  /// search/instant-search calls. Defaults to `ru`; per-call overrides are
  /// supported by [Besh24Client.search]/[Besh24Client.searchInstant].
  final String lang;

  static String _stripTrailingSlashes(String url) =>
      url.replaceFirst(RegExp(r'/+$'), '');

  static String _sanitizeSource(String source) {
    final trimmed = source.trim();
    return trimmed.isEmpty ? 'app' : trimmed;
  }
}
