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

    test('title/url are absent when not present on the wire', () {
      final model = RecommendationResultModel.fromJson({
        'items': ['1'],
        'request_id': 'req-1',
      });
      expect(model.title, isNull);
      expect(model.url, isNull);
      expect(model.products, isNull);
    });

    test('parses the extended products map', () {
      final model = RecommendationResultModel.fromJson({
        'items': ['1', '2'],
        'request_id': 'req-1',
        'title': 'Хиты',
        'url': '/hits',
        'products': {
          '1': {
            'name': 'Phone',
            'nameKk': 'Телефон',
            'price': 100,
            'oldPrice': 150,
            'discountPercent': 33,
            'rating': 4.5,
            'available': true,
            'fromDc': true,
            'stock': 7,
          },
        },
      });
      expect(model.title, 'Хиты');
      expect(model.url, '/hits');
      final entity = model.toEntity();
      final product = entity.products!['1']!;
      expect(product.name, 'Phone');
      expect(product.nameKk, 'Телефон');
      expect(product.price, 100);
      expect(product.oldPrice, 150);
      expect(product.discountPercent, 33);
      expect(product.available, isTrue);
      expect(product.fromDc, isTrue);
      expect(product.stock, 7);
      // '2' has no catalog entry — absent from the map, not a zeroed entry.
      expect(entity.products!.containsKey('2'), isFalse);
    });

    test('a null stock stays null, not zero', () {
      final model = RecommendationResultModel.fromJson({
        'items': ['1'],
        'request_id': 'req-1',
        'products': {
          '1': {
            'name': 'Phone',
            'price': 100,
            'available': false,
            'fromDc': false,
            'stock': null,
          },
        },
      });
      expect(model.products!['1']!.stock, isNull);
    });
  });

  group('RecommendationsBatchResultModel', () {
    test('parses blocks keyed by block_id and stamps the batch request id', () {
      final model = RecommendationsBatchResultModel.fromJson({
        'request_id': 'req-batch',
        'blocks': {
          'popular': {
            'items': ['1', '2'],
          },
          'basket': {
            'items': ['3'],
            'products': {
              '3': {
                'name': 'X',
                'price': 10,
                'available': true,
                'fromDc': false,
              },
            },
          },
        },
      });
      final entity = model.toEntity();
      expect(entity.requestId, 'req-batch');
      expect(entity.blocks['popular']!.itemIds, ['1', '2']);
      expect(entity.blocks['popular']!.requestId, 'req-batch');
      expect(entity.blocks['basket']!.products!['3']!.name, 'X');
    });

    test('defaults to empty blocks for a missing blocks key', () {
      final model = RecommendationsBatchResultModel.fromJson(const {});
      expect(model.blocks, isEmpty);
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

    test('parses typed facets from a real backend response shape', () {
      final model = SearchResultModel.fromJson({
        'items': const [],
        'total': 103,
        'page': 1,
        'facets': {
          'brand': [
            {'value': 'Apple', 'count': 103},
          ],
          'category': [
            {
              'id': '184',
              'value': 'Чехлы',
              'name': 'Чехлы',
              'parent': 'Аксессуары для телефонов',
              'url': 'https://back.evrika.com/catalog/chehly/c184',
              'url_handle': 'chehly',
              'count': 27,
            },
          ],
          'price_range': {'min': 4990, 'max': 1067990},
          'price_ranges': [
            {'to': 100000, 'count': 54},
            {'from': 100000, 'to': 250000, 'count': 14},
            {'from': 1000000, 'count': 2},
          ],
          'price_median': 84490,
          'params': [
            {
              'name': 'Wi-Fi',
              'count': 30,
              'priority': 1000,
              'values': {'Wi-Fi 7': 12, '802.11ax': 6},
            },
            {
              'name': 'Bluetooth',
              'count': 8,
              'priority': 993,
              'values': {'5.3': 8},
              'ranges': {'min': 5.3, 'max': 5.3},
            },
          ],
        },
      });
      final entity = model.toEntity();

      expect(entity.brandFacets, hasLength(1));
      expect(entity.brandFacets.single.value, 'Apple');
      expect(entity.brandFacets.single.count, 103);

      expect(entity.categoryFacets.single.id, '184');
      expect(entity.categoryFacets.single.parent, 'Аксессуары для телефонов');
      expect(entity.categoryFacets.single.urlHandle, 'chehly');
      expect(entity.categoryFacets.single.count, 27);

      expect(entity.priceRangeMin, 4990);
      expect(entity.priceRangeMax, 1067990);
      expect(entity.priceMedian, 84490);
      expect(entity.priceRanges, hasLength(3));
      expect(entity.priceRanges.first.from, isNull);
      expect(entity.priceRanges.first.to, 100000);
      expect(entity.priceRanges.last.to, isNull);

      expect(entity.paramFacets, hasLength(2));
      final wifi = entity.paramFacets.first;
      expect(wifi.name, 'Wi-Fi');
      expect(wifi.priority, 1000);
      expect(wifi.values, {'Wi-Fi 7': 12, '802.11ax': 6});
      expect(wifi.rangeMin, isNull);
      final bluetooth = entity.paramFacets.last;
      expect(bluetooth.rangeMin, 5.3);
      expect(bluetooth.rangeMax, 5.3);
    });

    test('defaults typed facets to empty when facets is missing/malformed', () {
      final model = SearchResultModel.fromJson({
        'items': const [],
        'total': 0,
        'page': 1,
      });
      final entity = model.toEntity();
      expect(entity.brandFacets, isEmpty);
      expect(entity.categoryFacets, isEmpty);
      expect(entity.priceRanges, isEmpty);
      expect(entity.paramFacets, isEmpty);
      expect(entity.priceRangeMin, isNull);
      expect(entity.priceMedian, isNull);
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
