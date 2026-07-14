import '../../domain/entities/instant_search_item.dart';
import 'json_coerce.dart';

/// Wire model for one entry of the `products` array in
/// `GET /api/v1/search/instant`.
///
/// The instant response returns rich cards under `products` (not `items`); the
/// backend field is `image_url`, normalized to [image].
class InstantSearchItemModel {
  /// Creates a model.
  const InstantSearchItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.url,
  });

  /// Product id.
  final String id;

  /// Display name.
  final String name;

  /// Price.
  final num price;

  /// Image URL (`image_url` on the wire).
  final String? image;

  /// Product URL.
  final String? url;

  /// Parses one `products[]` entry. Accepts both `image_url` and `image`.
  factory InstantSearchItemModel.fromJson(Map<String, Object?> json) =>
      InstantSearchItemModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        price: asNum(json['price']),
        image: (json['image_url'] ?? json['image']) as String?,
        url: json['url'] as String?,
      );

  /// Maps to a domain [InstantSearchItem].
  InstantSearchItem toEntity() => InstantSearchItem(
        id: id,
        name: name,
        price: price,
        image: image,
        url: url,
      );
}
