import 'package:uuid/uuid.dart';

import '../models/packing_list.dart';
import '../models/template.dart';

/// Built-in premade starting lists offered when creating a trip (design plan:
/// "choose from a premade list"). These are generated fresh (new ids each call)
/// so applying one produces independent trip items.
List<PackingList> builtinPackingLists() {
  const uuid = Uuid();
  TemplateItem it(String name, String note, {int? g}) =>
      TemplateItem(id: uuid.v4(), name: name, note: note, weightGrams: g);
  var order = 0;
  TemplateCategory cat(String name, List<TemplateItem> items) =>
      TemplateCategory(id: uuid.v4(), name: name, order: order++, items: items);

  return [
    PackingList(
      id: 'builtin-tent',
      name: 'Zelt-Camp – Basis',
      description: 'Grundausstattung für ein Wochenende im Zelt',
      builtin: true,
      categories: [
        cat('Unterkunft & Schlafen', [
          it('Zelt', 'Für Personenzahl + 1', g: 1800),
          it('Schlafsack', '3-Jahreszeiten', g: 700),
          it('Isomatte', '', g: 400),
          it('Heringe & Abspannleinen', 'Ersatz einpacken', g: 200),
        ]),
        cat('Kochgeschirr', [
          it('Kochgeschirr-Set', 'Topf + Pfanne', g: 300),
          it('Campingkocher', 'inkl. Gaskartusche', g: 450),
          it('Besteck & Geschirr', '', g: 200),
        ]),
        cat('Sonstiges', [
          it('Stirnlampe', 'Ersatzbatterien', g: 90),
          it('Erste-Hilfe-Set', '', g: 300),
          it('Müllbeutel', 'Leave No Trace', g: 30),
        ]),
      ],
    ),
    PackingList(
      id: 'builtin-van',
      name: 'Van-Trip – Basis',
      description: 'Für die Tour mit Van oder Bus',
      builtin: true,
      categories: [
        cat('Strom & Fahrzeug', [
          it('Powerbank / Solarpanel', '', g: 900),
          it('Nivellierkeile', '', g: 400),
          it('Verdunkelung für Fenster', '', g: 350),
          it('Warndreieck & Verbandskasten', 'Pflicht', g: 700),
        ]),
        cat('Küche', [
          it('Camping-Gasbrenner', '', g: 500),
          it('Kühlbox', '', g: 4000),
          it('Wasserkanister', '', g: 500),
        ]),
        cat('Sonstiges', [
          it('Campingstühle', '', g: 2500),
          it('Markise / Vorzelt', '', g: 3000),
        ]),
      ],
    ),
    PackingList(
      id: 'builtin-wild',
      name: 'Wildcamping – Basis',
      description: 'Leicht & autark unterwegs',
      builtin: true,
      categories: [
        cat('Unterkunft & Schlafen', [
          it('Leichtzelt / Tarp', '', g: 1200),
          it('Schlafsack', 'Komforttemp. beachten', g: 700),
          it('Isomatte', '', g: 400),
        ]),
        cat('Wildnis & Hygiene', [
          it('Wasserfilter', 'Für Bäche & Seen', g: 220),
          it('Falltrowel / Schaufel', 'Leave No Trace', g: 150),
          it('Kartenmaterial / Kompass', '', g: 180),
        ]),
        cat('Verpflegung', [
          it('Trekkingnahrung', 'Nach Tagen planen'),
          it('Kocher (Alkohol/Gas)', '', g: 250),
        ]),
      ],
    ),
  ];
}
