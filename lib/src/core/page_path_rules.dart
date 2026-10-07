/// How a route listed in the page-path rule table is treated.
enum PagePathAction {
  /// The `page_open` event is not sent at all.
  block,

  /// The path is cut down to the rule's match: the fact of the visit is kept,
  /// the secret tail of the path (e.g. a bearer token) is not.
  truncate,
}

/// How a rule's `match` is compared with the path.
enum PagePathMatch {
  /// Case-insensitive match of a whole path segment at any depth.
  segment,

  /// Prefix match of the route from the root.
  route,
}

/// One row of the path rule table.
class PagePathRule {
  /// Creates a rule.
  const PagePathRule(this.mode, this.match, this.action);

  /// How [match] is compared with the path.
  final PagePathMatch mode;

  /// Segment name (lower case) or route prefix, depending on [mode].
  final String match;

  /// What to do when the rule matches.
  final PagePathAction action;
}

/// Routes that need special handling in `page_open.path`. Adding a route
/// costs one line here; path *shape* heuristics are intentionally not used.
const List<PagePathRule> pagePathRules = [
  PagePathRule(PagePathMatch.segment, 'reset-password', PagePathAction.block),
  PagePathRule(PagePathMatch.segment, 'password-reset', PagePathAction.block),
  PagePathRule(PagePathMatch.segment, 'verify-email', PagePathAction.block),
  PagePathRule(PagePathMatch.segment, 'verify', PagePathAction.block),
  PagePathRule(PagePathMatch.segment, 'confirm', PagePathAction.block),
  PagePathRule(PagePathMatch.segment, 'auth', PagePathAction.block),
  PagePathRule(PagePathMatch.segment, 'invite', PagePathAction.block),
  PagePathRule(
    PagePathMatch.route,
    '/smart-gifts/receive',
    PagePathAction.truncate,
  ),
];

/// Normalizes raw input to `/segment/segment`: an absolute URL is reduced to
/// its path, query/hash are cut, repeated slashes collapsed and a leading
/// slash ensured. Returns an empty string if nothing is left.
String normalizePagePath(String raw) {
  var s = raw.trim();
  if (RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(s)) {
    final uri = Uri.tryParse(s);
    if (uri != null) s = uri.path;
  }
  s = s.split(RegExp(r'[?#]')).first;
  s = s.replaceAll(RegExp(r'/{2,}'), '/');
  if (s.isNotEmpty && !s.startsWith('/')) s = '/$s';
  return s;
}

/// Applies [rules] to an already normalized [path]. Returns the resulting
/// path, or `null` when the event must not be sent.
String? applyPagePathRules(
  String path, [
  List<PagePathRule> rules = pagePathRules,
]) {
  final segments = path
      .split('/')
      .where((s) => s.isNotEmpty)
      .map((s) => s.toLowerCase())
      .toList(growable: false);
  for (final rule in rules) {
    switch (rule.mode) {
      case PagePathMatch.segment:
        if (rule.action == PagePathAction.block &&
            segments.contains(rule.match)) {
          return null;
        }
      case PagePathMatch.route:
        if (path == rule.match || path.startsWith('${rule.match}/')) {
          return rule.action == PagePathAction.truncate ? rule.match : null;
        }
    }
  }
  return path;
}
