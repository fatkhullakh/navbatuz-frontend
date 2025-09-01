import 'package:flutter/material.dart';

/// Country ISO-2 -> localized country names (for resolving from a localized string)
const Map<String, Map<String, String>> kCountryNames = {
  'UZ': {'en': 'Uzbekistan', 'ru': 'Узбекистан', 'uz': 'O‘zbekiston'},
  'KZ': {'en': 'Kazakhstan', 'ru': 'Казахстан', 'uz': 'Qozog‘iston'},
  'KG': {'en': 'Kyrgyzstan', 'ru': 'Киргизия', 'uz': 'Qirg‘iziston'},
  'RU': {'en': 'Russia', 'ru': 'Россия', 'uz': 'Rossiya'},
  'TJ': {'en': 'Tajikistan', 'ru': 'Таджикистан', 'uz': 'Tojikiston'},
  'TM': {'en': 'Turkmenistan', 'ru': 'Туркменистан', 'uz': 'Turkmaniston'},
};

class GeoDistrict {
  final String code; // e.g., UZ-TAS-CHIL
  final String en; // English name (for DB)
  final Map<String, String> i18n; // {'ru': 'Чиланзар', 'uz': 'Chilonzor'}

  const GeoDistrict({required this.code, required this.en, required this.i18n});

  String nameForLang(String lang) => i18n[lang] ?? en;
}

class GeoCity {
  final String code; // e.g., UZ-TASHKENT
  final String en; // English name (for DB)
  final Map<String, String> i18n; // {'ru': 'Ташкент', 'uz': 'Toshkent'}
  final List<GeoDistrict> districts;

  const GeoCity({
    required this.code,
    required this.en,
    required this.i18n,
    required this.districts,
  });

  String nameForLang(String lang) => i18n[lang] ?? en;
}

/// Country ISO-2 -> list of cities (canonical)
final Map<String, List<GeoCity>> kGeo = {
  // -------- UZBEKISTAN (sample — extend as needed) --------
  'UZ': [
    GeoCity(
      code: 'UZ-TASHKENT',
      en: 'Tashkent',
      i18n: {'ru': 'Ташкент', 'uz': 'Toshkent'},
      districts: [
        GeoDistrict(
            code: 'UZ-TAS-MIR',
            en: 'Mirabad',
            i18n: {'ru': 'Мирабадский', 'uz': 'Mirobod'}),
        GeoDistrict(
            code: 'UZ-TAS-SER',
            en: 'Sergeli',
            i18n: {'ru': 'Сергели', 'uz': 'Sergeli'}),
        GeoDistrict(
            code: 'UZ-TAS-CHIL',
            en: 'Chilanzar',
            i18n: {'ru': 'Чиланзар', 'uz': 'Chilonzor'}),
        GeoDistrict(
            code: 'UZ-TAS-YUN',
            en: 'Yunusabad',
            i18n: {'ru': 'Юнусабад', 'uz': 'Yunusobod'}),
        GeoDistrict(
            code: 'UZ-TAS-SHA',
            en: 'Shaykhantakhur',
            i18n: {'ru': 'Шайхантахур', 'uz': 'Shayxontohur'}),
        GeoDistrict(
            code: 'UZ-TAS-YAK',
            en: 'Yakkasaray',
            i18n: {'ru': 'Яккасарай', 'uz': 'Yakkasaroy'}),
      ],
    ),
    GeoCity(
      code: 'UZ-SAMARKAND',
      en: 'Samarkand',
      i18n: {'ru': 'Самарканд', 'uz': 'Samarqand'},
      districts: [
        GeoDistrict(
            code: 'UZ-SAM-SAM',
            en: 'Samarkand District',
            i18n: {'ru': 'Самаркандский', 'uz': 'Samarqand tumani'}),
        GeoDistrict(
            code: 'UZ-SAM-KAT',
            en: 'Kattakurgan',
            i18n: {'ru': 'Катта-Курган', 'uz': 'Kattaqo‘rg‘on'}),
        GeoDistrict(
            code: 'UZ-SAM-PAS',
            en: 'Pastdargom',
            i18n: {'ru': 'Пастдаргомский', 'uz': 'Pastdarg‘om'}),
        GeoDistrict(
            code: 'UZ-SAM-NAR',
            en: 'Narpay',
            i18n: {'ru': 'Нарпайский', 'uz': 'Narpay'}),
      ],
    ),
    GeoCity(
      code: 'UZ-BUKHARA',
      en: 'Bukhara',
      i18n: {'ru': 'Бухара', 'uz': 'Buxoro'},
      districts: [
        GeoDistrict(
            code: 'UZ-BUK-BUK',
            en: 'Bukhara District',
            i18n: {'ru': 'Бухарский', 'uz': 'Buxoro tumani'}),
        GeoDistrict(
            code: 'UZ-BUK-GIJ',
            en: 'Gijduvan',
            i18n: {'ru': 'Гиждуван', 'uz': 'G‘ijduvon'}),
        GeoDistrict(
            code: 'UZ-BUK-KAR',
            en: 'Karakul',
            i18n: {'ru': 'Каракуль', 'uz': 'Qorako‘l'}),
      ],
    ),
    // Add Namangan, Andijan, Fergana, etc.
  ],

  // -------- KAZAKHSTAN (sample) --------
  'KZ': [
    GeoCity(
      code: 'KZ-ALMATY',
      en: 'Almaty',
      i18n: {'ru': 'Алматы', 'uz': 'Almati'},
      districts: [
        GeoDistrict(
            code: 'KZ-ALM-ALT',
            en: 'Alatau',
            i18n: {'ru': 'Алатауский', 'uz': 'Alatau'}),
        GeoDistrict(
            code: 'KZ-ALM-ALM',
            en: 'Almaly',
            i18n: {'ru': 'Алмалинский', 'uz': 'Almali'}),
        GeoDistrict(
            code: 'KZ-ALM-AUE',
            en: 'Auezov',
            i18n: {'ru': 'Ауэзовский', 'uz': 'Auezov'}),
      ],
    ),
    GeoCity(
      code: 'KZ-ASTANA',
      en: 'Astana',
      i18n: {'ru': 'Астана', 'uz': 'Astana'},
      districts: [
        GeoDistrict(
            code: 'KZ-AST-YES',
            en: 'Yesil',
            i18n: {'ru': 'Есильский', 'uz': 'Yesil'}),
        GeoDistrict(
            code: 'KZ-AST-SAR',
            en: 'Saryarka',
            i18n: {'ru': 'Сарыаркинский', 'uz': 'Saryarqa'}),
      ],
    ),
  ],

  // -------- RUSSIA (sample) --------
  'RU': [
    GeoCity(
      code: 'RU-MOSCOW',
      en: 'Moscow',
      i18n: {'ru': 'Москва', 'uz': 'Moskva'},
      districts: [
        GeoDistrict(
            code: 'RU-MOW-CAO',
            en: 'Central',
            i18n: {'ru': 'ЦАО', 'uz': 'TsAO'}),
        GeoDistrict(
            code: 'RU-MOW-SAO',
            en: 'Northern',
            i18n: {'ru': 'САО', 'uz': 'SAO'}),
        GeoDistrict(
            code: 'RU-MOW-YUAO',
            en: 'Southern Administrative Okrug',
            i18n: {'ru': 'ЮАО', 'uz': 'YuAO'}),
      ],
    ),
    GeoCity(
      code: 'RU-SPB',
      en: 'Saint Petersburg',
      i18n: {'ru': 'Санкт-Петербург', 'uz': 'Sankt-Peterburg'},
      districts: [
        GeoDistrict(
            code: 'RU-SPB-ADM',
            en: 'Admiralteysky',
            i18n: {'ru': 'Адмиралтейский', 'uz': 'Admiralteyskiy'}),
        GeoDistrict(
            code: 'RU-SPB-CEN',
            en: 'Central',
            i18n: {'ru': 'Центральный', 'uz': 'Markaziy'}),
      ],
    ),
  ],

  // TODO: add KG, TJ, TM similarly (pattern identical)
};

/// Utility: resolve a country ISO-2 code from a localized name.
/// If not found, returns null.
String? countryCodeFromLocalizedName(String localized) {
  final q = localized.trim().toLowerCase();
  for (final e in kCountryNames.entries) {
    if (e.value.values.any((n) => n.toLowerCase() == q)) return e.key;
  }
  return null;
}
