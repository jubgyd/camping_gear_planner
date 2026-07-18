import 'package:camp_gear_planner/util/link_price.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  double? p(String? s) => LinkPriceService.parsePrice(s);

  group('price parsing', () {
    test('machine format (dot decimal)', () {
      expect(p('129.95'), 129.95);
      expect(p('89'), 89);
      expect(p('7.5'), 7.5);
    });

    test('European format (comma decimal)', () {
      expect(p('89,90'), 89.90);
      expect(p('129,95 €'), 129.95);
      expect(p('€ 12,00'), 12.00);
    });

    test('thousands separators', () {
      expect(p('1.299,00'), 1299.00); // European: dot thousands, comma decimal
      expect(p('1,299.00'), 1299.00); // US: comma thousands, dot decimal
      expect(p(r'$1,299.99'), 1299.99);
    });

    test('comma as thousands without decimals', () {
      expect(p('1,299'), 1299);
    });

    test('currency symbols and whitespace stripped', () {
      expect(p(r'  $129.95 '), 129.95);
      expect(p('USD 45.00'), 45.00);
    });

    test('rejects junk and non-positive values', () {
      expect(p(''), isNull);
      expect(p('free'), isNull);
      expect(p('0'), isNull);
      expect(p(null), isNull);
    });
  });

  group('HTML extraction', () {
    const svc = LinkPriceService();

    test('Open Graph product:price:amount', () {
      final info = svc.extractFrom('''
        <html><head>
          <meta property="og:title" content="Trekkingzelt Ultra 2P">
          <meta property="product:price:amount" content="199.99">
          <meta property="product:price:currency" content="EUR">
        </head><body></body></html>
      ''');
      expect(info.price, 199.99);
      expect(info.currency, 'EUR');
      expect(info.title, 'Trekkingzelt Ultra 2P');
    });

    test('schema.org JSON-LD offers', () {
      final info = svc.extractFrom('''
        <html><head><title>Shop</title>
          <script type="application/ld+json">
          {"@context":"https://schema.org","@type":"Product","name":"Schlafsack",
           "offers":{"@type":"Offer","price":"89.90","priceCurrency":"EUR"}}
          </script>
        </head><body></body></html>
      ''');
      expect(info.price, 89.90);
      expect(info.currency, 'EUR');
    });

    test('microdata itemprop=price', () {
      final info = svc.extractFrom('''
        <html><body>
          <div itemscope itemtype="https://schema.org/Product">
            <span itemprop="price" content="45.50">45,50 €</span>
            <meta itemprop="priceCurrency" content="EUR">
          </div>
        </body></html>
      ''');
      expect(info.price, 45.50);
    });

    test('no price present yields empty result', () {
      final info = svc.extractFrom('<html><body><p>Out of stock</p></body></html>');
      expect(info.hasPrice, isFalse);
      expect(info.price, isNull);
    });
  });

  group('image extraction', () {
    const svc = LinkPriceService();

    test('og:image', () {
      final info = svc.extractFrom('''
        <html><head>
          <meta property="og:image" content="https://cdn.shop/tent.jpg">
        </head><body></body></html>
      ''');
      expect(info.hasImage, isTrue);
      expect(info.imageUrl, 'https://cdn.shop/tent.jpg');
    });

    test('falls back to twitter:image', () {
      final info = svc.extractFrom('''
        <html><head>
          <meta name="twitter:image" content="https://cdn.shop/bag.png">
        </head><body></body></html>
      ''');
      expect(info.imageUrl, 'https://cdn.shop/bag.png');
    });

    test('JSON-LD image as string or ImageObject', () {
      final asString = svc.extractFrom('''
        <html><head>
          <script type="application/ld+json">
          {"@type":"Product","image":"https://cdn.shop/a.jpg"}
          </script>
        </head><body></body></html>
      ''');
      expect(asString.imageUrl, 'https://cdn.shop/a.jpg');

      final asObject = svc.extractFrom('''
        <html><head>
          <script type="application/ld+json">
          {"@type":"Product","image":{"@type":"ImageObject","url":"https://cdn.shop/b.jpg"}}
          </script>
        </head><body></body></html>
      ''');
      expect(asObject.imageUrl, 'https://cdn.shop/b.jpg');
    });

    test('no image present yields hasImage=false', () {
      final info = svc.extractFrom('<html><body><p>hi</p></body></html>');
      expect(info.hasImage, isFalse);
      expect(info.imageUrl, isNull);
    });
  });
}
