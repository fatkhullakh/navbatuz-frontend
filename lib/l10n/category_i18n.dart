import 'app_localizations.dart';

class CategoryOption {
  final String id;
  final String label;
  const CategoryOption(this.id, this.label);
}

class CategoryI18n {
  /// Order here = order in the dropdown.
  static const List<String> _ids = <String>[
    'CLINIC',
    'BARBERSHOP',
    'BEAUTY_SALON',
    'SPA',
    'DENTAL',
    'GYM',
    'TATTOO',
    'NAIL_SALON',
    'MASSAGE',
    'OTHER',
  ];

  static List<CategoryOption> options(AppLocalizations t) {
    return _ids.map((id) => CategoryOption(id, label(t, id))).toList();
  }

  static String label(AppLocalizations t, String id) {
    switch (id) {
      case 'CLINIC':
        return t.category_clinic ?? 'Clinic';
      case 'BARBERSHOP':
        return t.category_barbershop ?? 'Barbershop';
      case 'BEAUTY_SALON':
        return t.category_beauty_salon ?? 'Beauty salon';
      case 'SPA':
        return t.category_spa ?? 'Spa';
      case 'DENTAL':
        return t.category_dental ?? 'Dental';
      case 'GYM':
        return t.category_gym ?? 'Gym / Fitness';
      case 'TATTOO':
        return t.category_tattoo ?? 'Tattoo studio';
      case 'NAIL_SALON':
        return t.category_nail_salon ?? 'Nail salon';
      case 'MASSAGE':
        return t.category_massage ?? 'Massage';
      case 'OTHER':
        return t.category_other ?? 'Other';
      default:
        return _humanize(id);
    }
  }

  static String _humanize(String s) {
    return s
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
