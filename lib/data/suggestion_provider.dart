import 'package:uuid/uuid.dart';

import '../models/template.dart';

/// Source of starter/suggested gear (GDD §13). Today it returns a static seeded
/// list (style-tagged per the design plan); a future version can implement the
/// same interface with an LLM call without changing how the UI consumes it.
abstract interface class SuggestionProvider {
  List<TemplateCategory> starterLibrary();
}

/// Ships the pre-filled starter library (GDD §10, §14.4). Items are tagged with
/// camp styles so the suggestions view can filter to the trip's style; an empty
/// tag list means "universal". Content is in German to match the plan.
class StaticSuggestionProvider implements SuggestionProvider {
  const StaticSuggestionProvider();

  @override
  List<TemplateCategory> starterLibrary() {
    const uuid = Uuid();
    TemplateItem item(String name, String note,
            {int? g, List<String> styles = const []}) =>
        TemplateItem(
            id: uuid.v4(), name: name, note: note, weightGrams: g, styles: styles);

    var order = 0;
    TemplateCategory cat(String name, List<TemplateItem> items) =>
        TemplateCategory(id: uuid.v4(), name: name, order: order++, items: items);

    return [
      cat('Unterkunft & Schlafen', [
        item('Zelt', 'Größe für Personenzahl + 1', g: 1800, styles: ['tent']),
        item('Hängematte', 'Mit Baumgurten', g: 600, styles: ['hammock']),
        item('Regen-Tarp', 'Über der Hängematte spannen',
            g: 450, styles: ['hammock']),
        item('Schlafsack', 'Komforttemp. 5°C unter erwarteter Mindesttemp.',
            g: 700, styles: ['tent', 'hammock', 'wild']),
        item('Hüttenschlafsack', 'Inlet, in vielen Hütten Pflicht',
            g: 250, styles: ['hut']),
        item('Erste-Hilfe-Set', 'Universal für jeden Trip', g: 300),
      ]),
      cat('Strom & Fahrzeug', [
        item('Powerbank / Solarpanel', 'Für Kühlbox & Geräte unterwegs',
            g: 900, styles: ['van']),
        item('Nivellierkeile', 'Für unebenen Untergrund',
            g: 400, styles: ['van']),
        item('Verdunkelung für Fenster', 'Für ungestörten Schlaf',
            g: 350, styles: ['van']),
      ]),
      cat('Wildnis & Hygiene', [
        item('Falltrowel / Schaufel', 'Leave No Trace', g: 150, styles: ['wild']),
        item('Wasserfilter', 'Für Bäche & Seen', g: 220, styles: ['wild']),
        item('Kartenmaterial / Kompass', 'Kein Netz garantiert',
            g: 180, styles: ['wild']),
      ]),
      cat('Komfort', [
        item('Lichterkette', 'Stimmungslicht fürs Zelt/Vorzelt',
            g: 250, styles: ['glamping']),
        item('Kühlbox mit Kompressor', 'Für längere Standzeiten',
            g: 4000, styles: ['glamping', 'van']),
        item('Bequeme Isomatte', 'Statt Standard-Isomatte',
            g: 1200, styles: ['glamping']),
      ]),
      cat('Kochgeschirr', [
        item('Kochgeschirr-Set', 'Titan, leicht',
            g: 300, styles: ['tent', 'wild', 'hammock']),
        item('Camping-Gasbrenner', 'Für Van-Küche', g: 500, styles: ['van']),
      ]),
    ];
  }
}
