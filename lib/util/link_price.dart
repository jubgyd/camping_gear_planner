import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

/// What a product page yielded: a price (if one was found) and the title.
class LinkInfo {
  const LinkInfo({this.price, this.currency, this.title});
  final double? price;
  final String? currency;
  final String? title;

  bool get hasPrice => price != null;
}

/// Fetches a product page and tries to read its price + title from standard
/// metadata: Open Graph (`og:price:amount` / `product:price:amount`),
/// schema.org JSON-LD `offers.price`, and microdata `itemprop="price"`.
///
/// Works on desktop/mobile. On the web build cross-origin requests are blocked
/// by CORS and this throws — callers treat a throw as "no price found".
/// Big retailers that render prices with JavaScript or block bots (Amazon, …)
/// will also legitimately return no price.
class LinkPriceService {
  const LinkPriceService();

  Future<LinkInfo> fetch(String rawUrl) async {
    final uri = _normalize(rawUrl);
    if (uri == null) return const LinkInfo();

    final res = await http
        .get(uri, headers: const {
          // A browser-ish UA; some shops serve a stripped page to unknown bots.
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/122.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml',
          'Accept-Language': 'de,en;q=0.8',
        })
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) return const LinkInfo();
    return extractFrom(res.body);
  }

  /// Reads price + title out of a page's HTML. Split from [fetch] so the
  /// extraction can be tested without a network round-trip.
  LinkInfo extractFrom(String body) {
    final doc = html.parse(body);
    final price = _fromMeta(doc) ?? _fromJsonLd(doc) ?? _fromMicrodata(doc);
    return LinkInfo(
      price: price?.$1,
      currency: price?.$2 ?? _currencyMeta(doc),
      title: _title(doc),
    );
  }

  // --- URL ---------------------------------------------------------------

  Uri? _normalize(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'https://$s';
    }
    final uri = Uri.tryParse(s);
    if (uri == null || uri.host.isEmpty) return null;
    return uri;
  }

  // --- Title -------------------------------------------------------------

  String? _title(Document doc) {
    final og = _metaContent(doc, property: 'og:title');
    if (og != null && og.trim().isNotEmpty) return og.trim();
    final t = doc.querySelector('title')?.text.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // --- Open Graph / meta -------------------------------------------------

  (double, String?)? _fromMeta(Document doc) {
    for (final prop in const [
      'product:price:amount',
      'og:price:amount',
      'og:product:price:amount',
    ]) {
      final v = _metaContent(doc, property: prop);
      final p = _parsePrice(v);
      if (p != null) return (p, _currencyMeta(doc));
    }
    // Some shops use <meta itemprop="price" content="...">
    final ip = doc.querySelector('meta[itemprop="price"]')?.attributes['content'];
    final p = _parsePrice(ip);
    if (p != null) return (p, _currencyMeta(doc));
    return null;
  }

  String? _currencyMeta(Document doc) {
    for (final prop in const [
      'product:price:currency',
      'og:price:currency',
    ]) {
      final v = _metaContent(doc, property: prop);
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    final ip =
        doc.querySelector('meta[itemprop="priceCurrency"]')?.attributes['content'];
    return (ip != null && ip.trim().isNotEmpty) ? ip.trim() : null;
  }

  String? _metaContent(Document doc, {required String property}) {
    // property=... (Open Graph) and name=... (some sites) both occur.
    final el = doc.querySelector('meta[property="$property"]') ??
        doc.querySelector('meta[name="$property"]');
    return el?.attributes['content'];
  }

  // --- JSON-LD schema.org ------------------------------------------------

  (double, String?)? _fromJsonLd(Document doc) {
    for (final script
        in doc.querySelectorAll('script[type="application/ld+json"]')) {
      final raw = script.text.trim();
      if (raw.isEmpty) continue;
      dynamic data;
      try {
        data = jsonDecode(raw);
      } catch (_) {
        continue;
      }
      final hit = _searchJson(data);
      if (hit != null) return hit;
    }
    return null;
  }

  /// Walks arbitrary decoded JSON looking for an `offers`/price structure.
  (double, String?)? _searchJson(dynamic node) {
    if (node is List) {
      for (final e in node) {
        final r = _searchJson(e);
        if (r != null) return r;
      }
      return null;
    }
    if (node is Map) {
      // An offer object: { price: ..., priceCurrency: ... }
      if (node.containsKey('price')) {
        final p = _parsePrice(node['price']?.toString());
        if (p != null) return (p, node['priceCurrency']?.toString());
      }
      // Nested offers.
      for (final key in const ['offers', 'aggregateOffer', 'aggregateOffers']) {
        if (node.containsKey(key)) {
          final r = _searchJson(node[key]);
          if (r != null) return r;
        }
      }
      // Fall back to scanning every value.
      for (final v in node.values) {
        if (v is Map || v is List) {
          final r = _searchJson(v);
          if (r != null) return r;
        }
      }
    }
    return null;
  }

  // --- Microdata ---------------------------------------------------------

  (double, String?)? _fromMicrodata(Document doc) {
    final el = doc.querySelector('[itemprop="price"]');
    if (el == null) return null;
    final raw = el.attributes['content'] ?? el.text;
    final p = _parsePrice(raw);
    if (p == null) return null;
    final cur = doc.querySelector('[itemprop="priceCurrency"]');
    return (p, cur?.attributes['content'] ?? cur?.text.trim());
  }

  // --- Price parsing -----------------------------------------------------

  double? _parsePrice(String? raw) => parsePrice(raw);

  /// Parses a price string into a double. Handles machine formats ("129.95")
  /// and messy human ones ("1.299,00 €", "€ 89,90", "$129.95").
  static double? parsePrice(String? raw) {
    if (raw == null) return null;
    // Keep digits, separators, minus.
    var s = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (s.isEmpty) return null;

    final hasDot = s.contains('.');
    final hasComma = s.contains(',');
    if (hasDot && hasComma) {
      // The right-most separator is the decimal point; the other groups digits.
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.'); // European 1.299,00
      } else {
        s = s.replaceAll(',', ''); // US 1,299.00
      }
    } else if (hasComma) {
      // Only a comma: decimal if it looks like cents (,00), else thousands.
      final parts = s.split(',');
      if (parts.length == 2 && parts.last.length == 2) {
        s = '${parts.first}.${parts.last}';
      } else {
        s = s.replaceAll(',', '');
      }
    }
    final val = double.tryParse(s);
    if (val == null || val <= 0 || val > 1000000) return null;
    return double.parse(val.toStringAsFixed(2));
  }
}
