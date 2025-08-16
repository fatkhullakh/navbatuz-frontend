// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navAppointments => 'Appointments';

  @override
  String get navSearch => 'Search';

  @override
  String get navAccount => 'Account';

  @override
  String get home_search_hint => 'Search services or businesses';

  @override
  String get categories => 'Categories';

  @override
  String get no_categories => 'No categories.';

  @override
  String get upcoming_appointment => 'Upcoming appointment';

  @override
  String get no_upcoming => 'No upcoming appointments.';

  @override
  String get favorites => 'Favorites';

  @override
  String get no_favorites => 'No favorites yet.';

  @override
  String get recommended => 'Recommended';

  @override
  String get no_recommended => 'No recommendations right now.';

  @override
  String get see_all => 'See all';

  @override
  String get error_home_failed => 'Failed to load home. Pull to refresh.';

  @override
  String get btn_go_appointments => 'Go to my appointments →';

  @override
  String get account_title => 'Account';

  @override
  String get account_personal => 'Personal Info';

  @override
  String get account_personal_sub => 'Name, Surname, Email, Phone, Birthday, Gender';

  @override
  String get account_settings => 'Account Settings';

  @override
  String get account_settings_sub => 'Language, Country';

  @override
  String get account_change_password => 'Change Password';

  @override
  String get account_change_password_sub => 'Update your password';

  @override
  String get account_support => 'Support';

  @override
  String get account_support_sub => 'FAQ, Contact Us, Report a problem';

  @override
  String get account_other => 'Other';

  @override
  String get account_other_sub => 'About, Terms, Privacy';

  @override
  String get logout => 'Log out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settings_country => 'Country';

  @override
  String get settings_country_hint => 'Country ISO-2';

  @override
  String get action_save => 'Save';

  @override
  String get action_retry => 'Retry';

  @override
  String get action_reload => 'Reload';

  @override
  String get error_generic => 'Something went wrong.';
}
