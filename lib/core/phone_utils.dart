/// Very small, dependency-free phone normalizer.
/// Goal: return a single E.164 string like `+998998562585`
/// from things like "+998 99 856 25 85", "00998998562585", "99 856 25 85", etc.
///
/// Assumptions:
/// - Default country is Uzbekistan (UZ, +998) since that’s your main use case.
/// - If the number already has a leading '+', we keep the digits after it.
/// - If it starts with 00, we convert to '+'.
/// - If there’s no country info, we prefix with +998 and keep the last 9 digits
///   (national significant number in UZ).
library;

String normalizePhoneE164(String? raw, {String defaultCountry = 'UZ'}) {
  if (raw == null) return '';
  var s = raw.trim();

  // Digits only (we'll add the '+' back as needed)
  final onlyDigits = s.replaceAll(RegExp(r'\D'), '');
  final hasPlus = s.startsWith('+');

  // "+<digits>" → keep only digits and restore '+'
  if (hasPlus) {
    return onlyDigits.isEmpty ? '' : '+$onlyDigits';
  }

  // "00<country><digits>" → convert to '+'
  if (onlyDigits.startsWith('00')) {
    final rest = onlyDigits.substring(2);
    return rest.isEmpty ? '' : '+$rest';
  }

  // No plus and not 00 → add country if we can.
  switch (defaultCountry.toUpperCase()) {
    case 'UZ':
      // E.164 for UZ is +998 + 9 national digits (total 12 digits after '+').
      if (onlyDigits.length == 12 && onlyDigits.startsWith('998')) {
        return '+$onlyDigits';
      }
      final last9 = onlyDigits.length >= 9
          ? onlyDigits.substring(onlyDigits.length - 9)
          : onlyDigits;
      return last9.isEmpty ? '' : '+998$last9';

    default:
      // As a generic fallback: just prefix a '+'
      return onlyDigits.isEmpty ? '' : '+$onlyDigits';
  }
}
