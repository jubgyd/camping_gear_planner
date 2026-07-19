import 'package:uuid/uuid.dart';

import '../models/packing_list.dart';
import '../models/template.dart';

/// Built-in premade starting lists offered when creating a trip (design plan:
/// "choose from a premade list"). These are generated fresh (new ids each call)
/// so applying one produces independent trip items.
///
/// Content is German to match the app's primary language. The season kits and
/// the "Komplettliste" are composed from the shared category builders below so
/// there's a single source of truth per category.
const _u = Uuid();

TemplateItem _it(String name, {String note = '', int? g}) =>
    TemplateItem(id: _u.v4(), name: name, note: note, weightGrams: g);

/// Builds a list, numbering categories by their position.
PackingList _list(
  String id,
  String name,
  String description,
  List<TemplateCategory> cats,
) =>
    PackingList(
      id: id,
      name: name,
      description: description,
      builtin: true,
      categories: [
        for (var i = 0; i < cats.length; i++)
          TemplateCategory(
              id: cats[i].id, name: cats[i].name, order: i, items: cats[i].items),
      ],
    );

TemplateCategory _cat(String name, List<TemplateItem> items) =>
    TemplateCategory(id: _u.v4(), name: name, items: items);

List<PackingList> builtinPackingLists() => [
      _tentBasic(),
      _vanBasic(),
      _wildBasic(),
      _complete(),
      _seasonKit('spring'),
      _seasonKit('summer'),
      _seasonKit('autumn'),
      _seasonKit('winter'),
    ];

// ---------------------------------------------------------------------------
// Shared category builders (fresh items each call).
// ---------------------------------------------------------------------------

TemplateCategory _katUnterkunft({bool winter = false}) => _cat('Unterkunft', [
      winter
          ? _it('4-Jahreszeiten-Zelt', note: 'Wintertauglich, verstärkt', g: 2600)
          : _it('Zelt', note: 'Für Personenzahl + 1', g: 1800),
      _it('Zeltunterlage / Footprint', g: 300),
      _it('Heringe & Abspannleinen', note: 'Ersatz einpacken', g: 200),
      if (winter) _it('Schneeheringe / Schneeanker', g: 300),
      _it('Tarp / Sonnensegel', g: 600),
      _it('Zelt-Reparaturset', note: 'Gestängehülse, Flicken', g: 80),
    ]);

TemplateCategory _katSchlafen({required String bagNote, bool winter = false}) =>
    _cat('Schlafen', [
      _it('Schlafsack', note: bagNote, g: winter ? 1400 : 700),
      _it('Isomatte', note: winter ? 'Hoher R-Wert' : '', g: 400),
      if (winter) _it('Schaumstoff-Unterlage', note: 'Zusätzliche Isolierung', g: 300),
      _it('Schlafsack-Inlett', g: 200),
      _it('Kopfkissen', note: 'Aufblasbar oder komprimierbar', g: 120),
      _it('Ohrstöpsel & Schlafmaske', g: 30),
    ]);

TemplateCategory _katKueche({bool car = false}) => _cat('Küche & Kochen', [
      _it('Campingkocher', note: 'inkl. Gaskartusche', g: 450),
      _it('Feuerzeug & Sturmstreichhölzer', g: 30),
      _it('Kochgeschirr-Set', note: 'Topf + Pfanne', g: 300),
      _it('Kochbesteck', note: 'Pfannenwender, Kelle', g: 150),
      _it('Messer & Schneidebrett', g: 200),
      _it('Essgeschirr & Besteck', g: 250),
      _it('Faltschüssel / Spüle', g: 150),
      _it('Spülmittel (biologisch) & Schwamm', g: 100),
      _it('Geschirrtuch', g: 50),
      _it('Kaffeezubereiter', note: 'French Press / Handfilter', g: 200),
      _it('Dosen- & Flaschenöffner', g: 40),
      _it('Müllbeutel', note: 'Leave No Trace', g: 30),
      if (car) _it('Kühlbox', note: 'inkl. Kühlakkus', g: 4000),
      if (car) _it('Campingtisch', g: 2500),
    ]);

TemplateCategory _katVerpflegung({bool car = false}) =>
    _cat('Verpflegung & Wasser', [
      _it('Wasserflaschen / Trinkblase', g: 200),
      _it('Wasserfilter / Entkeimungstabletten', g: 220),
      if (car) _it('Wasserkanister', g: 500),
      _it('Verpflegung', note: 'Nach Tagen planen'),
      _it('Snacks', note: 'Riegel, Nüsse, Trockenobst'),
      _it('Öl, Salz, Pfeffer & Gewürze', g: 150),
      _it('Kaffee / Tee'),
      _it('Elektrolyte'),
    ]);

TemplateCategory _katKleidung(String season) {
  final items = <TemplateItem>[
    _it('Funktionsunterwäsche', note: 'Feuchtigkeitsableitend'),
    _it('T-Shirts / Longsleeve'),
    _it('Wander- / Trekkinghose'),
    _it('Unterwäsche', note: 'Schnelltrocknend'),
    _it('Socken', note: 'Wolle, mehrere Paar'),
    _it('Regenjacke & Regenhose'),
    _it('Fleece / Isolationsjacke'),
    _it('Buff / Halstuch'),
    _it('Schlafkleidung'),
  ];
  switch (season) {
    case 'summer':
      items.insertAll(2, [
        _it('Kurze Hose'),
        _it('Sonnenhut / Cap'),
        _it('Badesachen'),
      ]);
      break;
    case 'winter':
      items.addAll([
        _it('Thermounterwäsche', note: 'Merino / warm'),
        _it('Daunen- / Winterjacke'),
        _it('Warme Handschuhe'),
        _it('Wintermütze'),
        _it('Balaklava / Gesichtsschutz'),
      ]);
      break;
    case 'autumn':
      items.addAll([
        _it('Warme Mütze & Handschuhe'),
        _it('Zusätzliche warme Schicht'),
      ]);
      break;
    case 'spring':
    default:
      items.addAll([
        _it('Warme Mütze', note: 'Kühle Nächte'),
        _it('Zusätzliche Zwischenschicht'),
      ]);
  }
  return _cat('Kleidung', items);
}

TemplateCategory _katSchuhe({bool winter = false}) => _cat('Schuhe', [
      winter
          ? _it('Isolierte Winterstiefel')
          : _it('Wanderschuhe / Trailrunner', note: 'Eingelaufen'),
      _it('Campingschuhe / Sandalen'),
      if (winter) _it('Gamaschen'),
      _it('Ersatzschnürsenkel', g: 20),
    ]);

TemplateCategory _katNav() => _cat('Navigation & Sicherheit', [
      _it('Karte & Kompass', g: 180),
      _it('Handy mit Offline-Karten'),
      _it('Trillerpfeife', g: 15),
      _it('Tourenplan hinterlegen', note: 'Bei Person zu Hause'),
      _it('Genehmigungen / Reservierung'),
    ]);

TemplateCategory _katLicht() => _cat('Licht & Strom', [
      _it('Stirnlampe', note: 'Ersatzbatterien', g: 90),
      _it('Campinglampe / Laterne', g: 200),
      _it('Powerbank & Ladekabel', g: 350),
      _it('Ersatzbatterien', g: 60),
    ]);

TemplateCategory _katFeuer({bool car = false}) => _cat('Feuer', [
      _it('Sturmstreichhölzer / Feuerzeug', g: 30),
      _it('Anzünder / Zunder', g: 60),
      _it('Brennholz', note: 'Vor Ort kaufen'),
      if (car) _it('Beil / Klappsäge', g: 600),
      _it('Feuerhandschuhe', g: 100),
    ]);

TemplateCategory _katWerkzeug() => _cat('Werkzeug & Reparatur', [
      _it('Multitool / Taschenmesser', g: 150),
      _it('Panzertape / Reparaturtape', g: 80),
      _it('Paracord / Seil', g: 120),
      _it('Kabelbinder & Sicherheitsnadeln', g: 30),
      _it('Nähset', g: 30),
      _it('Trekkingstöcke', g: 500),
      _it('Klappspaten / Trowel', note: 'Leave No Trace', g: 150),
    ]);

TemplateCategory _katGesundheit() => _cat('Gesundheit & Hygiene', [
      _it('Erste-Hilfe-Set', g: 300),
      _it('Persönliche Medikamente'),
      _it('Schmerzmittel & Antihistaminikum'),
      _it('Sonnencreme & Lippenpflege (LSF)', g: 100),
      _it('Zeckenzange', g: 20),
      _it('Handdesinfektion & Feuchttücher', g: 100),
      _it('Zahnbürste & Zahnpasta', g: 60),
      _it('Seife (biologisch) & Mikrofaserhandtuch', g: 150),
      _it('Toilettenpapier & Beutel', g: 100),
      _it('Brille / Kontaktlinsen + Lösung'),
    ]);

TemplateCategory _katKomfort({bool car = false}) => _cat('Komfort & Camp', [
      if (car) _it('Campingstühle', g: 2500),
      _it('Picknickdecke', g: 600),
      _it('Bücher / Karten- & Brettspiele'),
      _it('Fernglas', g: 300),
      _it('Notizbuch & Stift', g: 100),
      _it('Kamera'),
    ]);

TemplateCategory _katSchutz() => _cat('Sonnen- & Insektenschutz', [
      _it('Sonnenbrille', g: 30),
      _it('Sonnenhut'),
      _it('Insektenschutzmittel', g: 80),
      _it('Moskito- / Kopfnetz', g: 40),
    ]);

TemplateCategory _katDokumente() => _cat('Dokumente & Geld', [
      _it('Ausweis / Führerschein'),
      _it('Bargeld & Karten'),
      _it('Reservierung / Parkausweis'),
      _it('Versicherungs- & Notfallkontakte'),
    ]);

TemplateCategory _katPack() => _cat('Pack & Organisation', [
      _it('Rucksack', note: 'Haupt- + Tagesrucksack', g: 2000),
      _it('Regenhülle für Rucksack', g: 100),
      _it('Packsäcke / Dry Bags', g: 150),
      _it('Kompressionssäcke', g: 100),
      _it('Karabiner', g: 60),
    ]);

TemplateCategory _katWinterExtras() => _cat('Winter-Extras', [
      _it('Schneeschuhe / Grödel / Steigeisen', g: 900),
      _it('Skibrille', g: 120),
      _it('Hand- & Fußwärmer'),
      _it('Daunenschuhe', g: 200),
      _it('Schneeschaufel', g: 600),
      _it('Thermosflasche', g: 300),
      _it('Flüssigbrennstoffkocher', note: 'Kältetauglich', g: 400),
    ]);

TemplateCategory _katSommerExtras() => _cat('Sommer-Extras', [
      _it('Schnelltrocken-Handtuch', g: 150),
      _it('Pop-up-Moskitozelt'),
      _it('Zusätzliches Wasser', note: 'Hitze einplanen'),
      _it('Sonnensegel gegen Hitze', g: 600),
    ]);

// ---------------------------------------------------------------------------
// The three original starter lists.
// ---------------------------------------------------------------------------

PackingList _tentBasic() => _list(
      'builtin-tent',
      'Zelt-Camp – Basis',
      'Grundausstattung für ein Wochenende im Zelt',
      [
        _cat('Unterkunft & Schlafen', [
          _it('Zelt', note: 'Für Personenzahl + 1', g: 1800),
          _it('Schlafsack', note: '3-Jahreszeiten', g: 700),
          _it('Isomatte', g: 400),
          _it('Heringe & Abspannleinen', note: 'Ersatz einpacken', g: 200),
        ]),
        _cat('Kochgeschirr', [
          _it('Kochgeschirr-Set', note: 'Topf + Pfanne', g: 300),
          _it('Campingkocher', note: 'inkl. Gaskartusche', g: 450),
          _it('Besteck & Geschirr', g: 200),
        ]),
        _cat('Sonstiges', [
          _it('Stirnlampe', note: 'Ersatzbatterien', g: 90),
          _it('Erste-Hilfe-Set', g: 300),
          _it('Müllbeutel', note: 'Leave No Trace', g: 30),
        ]),
      ],
    );

PackingList _vanBasic() => _list(
      'builtin-van',
      'Van-Trip – Basis',
      'Für die Tour mit Van oder Bus',
      [
        _cat('Strom & Fahrzeug', [
          _it('Powerbank / Solarpanel', g: 900),
          _it('Nivellierkeile', g: 400),
          _it('Verdunkelung für Fenster', g: 350),
          _it('Warndreieck & Verbandskasten', note: 'Pflicht', g: 700),
        ]),
        _cat('Küche', [
          _it('Camping-Gasbrenner', g: 500),
          _it('Kühlbox', g: 4000),
          _it('Wasserkanister', g: 500),
        ]),
        _cat('Sonstiges', [
          _it('Campingstühle', g: 2500),
          _it('Markise / Vorzelt', g: 3000),
        ]),
      ],
    );

PackingList _wildBasic() => _list(
      'builtin-wild',
      'Wildcamping – Basis',
      'Leicht & autark unterwegs',
      [
        _cat('Unterkunft & Schlafen', [
          _it('Leichtzelt / Tarp', g: 1200),
          _it('Schlafsack', note: 'Komforttemp. beachten', g: 700),
          _it('Isomatte', g: 400),
        ]),
        _cat('Wildnis & Hygiene', [
          _it('Wasserfilter', note: 'Für Bäche & Seen', g: 220),
          _it('Falltrowel / Schaufel', note: 'Leave No Trace', g: 150),
          _it('Kartenmaterial / Kompass', g: 180),
        ]),
        _cat('Verpflegung', [
          _it('Trekkingnahrung', note: 'Nach Tagen planen'),
          _it('Kocher (Alkohol/Gas)', g: 250),
        ]),
      ],
    );

// ---------------------------------------------------------------------------
// The master "everything" list and the four season kits.
// ---------------------------------------------------------------------------

PackingList _complete() => _list(
      'builtin-complete',
      'Komplettliste – Alles',
      'Alle Kategorien & Gegenstände – kopieren und nach Bedarf kürzen',
      [
        _katUnterkunft(),
        _katSchlafen(bagNote: '3-Jahreszeiten'),
        _katKueche(car: true),
        _katVerpflegung(car: true),
        _katKleidung('spring'),
        _katSchuhe(),
        _katNav(),
        _katLicht(),
        _katFeuer(car: true),
        _katWerkzeug(),
        _katGesundheit(),
        _katKomfort(car: true),
        _katSchutz(),
        _katDokumente(),
        _katPack(),
        _katWinterExtras(),
        _katSommerExtras(),
      ],
    );

PackingList _seasonKit(String season) {
  final winter = season == 'winter';
  final meta = switch (season) {
    'spring' => ('builtin-season-spring', 'Frühling 🌱',
        'Komplettes Kit für Frühlingstouren – wechselhaft & nass'),
    'summer' => ('builtin-season-summer', 'Sommer ☀️',
        'Komplettes Kit für Sommertouren – Sonne, Hitze & Insekten'),
    'autumn' => ('builtin-season-autumn', 'Herbst 🍂',
        'Komplettes Kit für Herbsttouren – kühl, nass & früh dunkel'),
    _ => ('builtin-season-winter', 'Winter ❄️',
        'Komplettes Kit für Winter- & Schneetouren'),
  };

  final bagNote = switch (season) {
    'summer' => 'Sommer / leicht',
    'winter' => 'Winter, Komfort ~ -10 °C',
    _ => '3-Jahreszeiten',
  };

  return _list(meta.$1, meta.$2, meta.$3, [
    _katUnterkunft(winter: winter),
    _katSchlafen(bagNote: bagNote, winter: winter),
    _katKueche(),
    _katVerpflegung(),
    _katKleidung(season),
    _katSchuhe(winter: winter),
    _katNav(),
    _katLicht(),
    _katGesundheit(),
    if (season == 'summer') _katSchutz(),
    _katKomfort(),
    _katPack(),
    if (winter) _katWinterExtras(),
    if (season == 'summer') _katSommerExtras(),
  ]);
}
