// Static reference data for trip metadata (design-plan extension): destination
// country, season, camping style, and party type. Each carries a stable
// code/key used as the persisted value so labels/emoji can change without
// breaking saved data.
import 'package:collection/collection.dart';

class Country {
  const Country(this.code, this.flag, this.name);
  final String code;
  final String flag;
  final String name;

  static const all = [
    Country('DE', '🇩🇪', 'Deutschland'),
    Country('NO', '🇳🇴', 'Norwegen'),
    Country('SE', '🇸🇪', 'Schweden'),
    Country('AT', '🇦🇹', 'Österreich'),
    Country('IT', '🇮🇹', 'Italien'),
    Country('IS', '🇮🇸', 'Island'),
    Country('CH', '🇨🇭', 'Schweiz'),
    Country('FR', '🇫🇷', 'Frankreich'),
    Country('HR', '🇭🇷', 'Kroatien'),
    Country('FI', '🇫🇮', 'Finnland'),
  ];

  static Country? byCode(String? code) =>
      code == null ? null : all.where((c) => c.code == code).firstOrNull;
}

class Season {
  const Season(this.key, this.label, this.icon);
  final String key;
  final String label;
  final String icon;

  static const all = [
    Season('spring', 'Frühling', '🌱'),
    Season('summer', 'Sommer', '☀️'),
    Season('autumn', 'Herbst', '🍂'),
    Season('winter', 'Winter', '❄️'),
  ];

  static Season? byKey(String? key) =>
      key == null ? null : all.where((s) => s.key == key).firstOrNull;
}

class CampStyle {
  const CampStyle(this.key, this.label, this.icon);
  final String key;
  final String label;
  final String icon;

  static const all = [
    CampStyle('tent', 'Zelten', '⛺'),
    CampStyle('wild', 'Wildcamping', '🌲'),
    CampStyle('van', 'Van / Bus', '🚐'),
    CampStyle('glamping', 'Glamping', '✨'),
    CampStyle('hammock', 'Hängematte', '🪢'),
    CampStyle('hut', 'Hütte', '🛖'),
  ];

  static CampStyle? byKey(String? key) =>
      key == null ? null : all.where((c) => c.key == key).firstOrNull;
}

class TripType {
  const TripType(this.key, this.label);
  final String key;
  final String label;

  static const all = [
    TripType('solo', 'Solo'),
    TripType('duo', 'Zu zweit'),
    TripType('family', 'Familie'),
    TripType('group', 'Gruppe'),
  ];

  static TripType? byKey(String? key) =>
      key == null ? null : all.where((t) => t.key == key).firstOrNull;
}
