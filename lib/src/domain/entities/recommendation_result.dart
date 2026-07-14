/// Result of a recommendations request.
///
/// Mirrors `GET /api/v1/recommendations` → `{items: [id...], request_id}`. The
/// backend returns an ordered list of product ids only; card enrichment (name,
/// price, image) is the app's responsibility, exactly as in the web contract.
class RecommendationResult {
  /// Creates a recommendation result.
  const RecommendationResult({required this.itemIds, required this.requestId});

  /// Ordered product ids to display.
  final List<String> itemIds;

  /// Server-issued request id, echoed back for impression attribution.
  final String requestId;
}
