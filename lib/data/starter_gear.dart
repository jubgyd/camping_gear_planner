import 'package:uuid/uuid.dart';

import '../models/gear_item.dart';

/// A handful of common camping items to pre-fill the personal gear catalog
/// ("My Gear") on a fresh install, so it isn't empty the first time it's opened.
/// After first run the catalog is fully manual — the user adds/edits/deletes.
/// Categories match the checklist category names used elsewhere so picked gear
/// lands in a sensible group. Content is in German to match the app.
List<GearItem> starterGear() {
  const uuid = Uuid();
  GearItem g(String name, String category,
          {String note = '', int? weight, double? price}) =>
      GearItem(
        id: uuid.v4(),
        name: name,
        category: category,
        note: note,
        weightGrams: weight,
        pricePerUnit: price,
      );

  return [
    // Unterkunft & Schlafen
    g('Zelt (2 Personen)', 'Unterkunft & Schlafen', note: '3-Jahreszeiten', weight: 1800),
    g('Schlafsack', 'Unterkunft & Schlafen', note: 'Komforttemp. 0°C', weight: 900),
    g('Isomatte', 'Unterkunft & Schlafen', note: 'Aufblasbar', weight: 480),
    g('Kopfkissen', 'Unterkunft & Schlafen', note: 'Aufblasbar', weight: 90),

    // Kochgeschirr
    g('Campingkocher', 'Kochgeschirr', note: 'inkl. Gaskartusche', weight: 450),
    g('Kochtopf-Set', 'Kochgeschirr', note: 'Topf + Pfanne', weight: 300),
    g('Besteck & Geschirr', 'Kochgeschirr', weight: 200),
    g('Feuerzeug / Sturmstreichhölzer', 'Kochgeschirr', weight: 30),

    // Wildnis & Hygiene
    g('Erste-Hilfe-Set', 'Wildnis & Hygiene', weight: 300),
    g('Wasserfilter', 'Wildnis & Hygiene', note: 'Für Bäche & Seen', weight: 220),
    g('Mikrofaser-Handtuch', 'Wildnis & Hygiene', weight: 150),

    // Sonstiges
    g('Stirnlampe', 'Sonstiges', note: 'Ersatzbatterien', weight: 90),
    g('Taschenmesser', 'Sonstiges', weight: 120),
    g('Powerbank', 'Sonstiges', note: '20.000 mAh', weight: 350),
    g('Müllbeutel', 'Sonstiges', note: 'Leave No Trace', weight: 30),
  ];
}
