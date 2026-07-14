import 'package:besh24_sdk/src/data/models/identity_model.dart';
import 'package:besh24_sdk/src/data/models/instant_search_item_model.dart';
import 'package:besh24_sdk/src/data/models/recommendation_result_model.dart';
import 'package:besh24_sdk/src/data/models/search_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdentityModel', () {
    test('parses ids and maps to entity', () {
      final model = IdentityModel.fromJson(
        {'anonymous_id': 'A', 'session_id': 'S'},
      );
      expect(model.toEntity()!.anonymousId, 'A');
    });

    test('returns null entity when an id is missing', () {
      expect(IdentityModel.fromJson({'anonymous_id': 'A'}).toEntity(), isNull);
      expect(IdentityModel.fromJson(const {}).toEntity(), isNull);
    });
  });

  group('RecommendationResultModel', () {
    test('coerces mixed id types to strings', () {
      final model = RecommendationResultModel.fromJson({
        'items': ['a', 2, 3.0],
        'request_id': 'req-1',
      });
      expect(model.itemIds, ['a', '2', '3.0']);
      expect(model.requestId, 'req-1');
    });

    test('defaults to an empty list for a missing items key', () {
      final model = RecommendationResultModel.fromJson(const {});
      expect(model.itemIds, isEmpty);
      expect(model.requestId, '');
    });
  });

  group('SearchResultModel', () {
    test('parses items, total and page', () {
      final model = SearchResultModel.fromJson({
        'items': [
          {'id': '1', 'name': 'A', 'price': 100, 'image': 'i', 'url': 'u'},
          {'id': 2, 'name': 'B', 'price': '200'},
        ],
        'total': 2,
        'page': 1,
        'facets': {'brand': []},
      });
      expect(model.total, 2);
      final entity = model.toEntity();
      expect(entity.items.first.id, '1');
      expect(entity.items[1].id, '2');
      expect(entity.items[1].price, 200);
      expect(entity.facets['brand'], isA<List<Object?>>());
    });
  });

  group('InstantSearchItemModel', () {
    test('normalizes image_url to image', () {
      final model = InstantSearchItemModel.fromJson({
        'id': 9,
        'name': 'Phone',
        'price': 1499.5,
        'image_url': 'https://img/p.jpg',
        'url': '/p/9',
      });
      final entity = model.toEntity();
      expect(entity.id, '9');
      expect(entity.image, 'https://img/p.jpg');
      expect(entity.price, 1499.5);
      expect(entity.url, '/p/9');
    });
  });
}
