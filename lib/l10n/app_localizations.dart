import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get navAppointments;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @home_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search services or businesses'**
  String get home_search_hint;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @no_categories.
  ///
  /// In en, this message translates to:
  /// **'No categories.'**
  String get no_categories;

  /// No description provided for @upcoming_appointment.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointment'**
  String get upcoming_appointment;

  /// No description provided for @no_upcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments.'**
  String get no_upcoming;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @no_favorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.'**
  String get no_favorites;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @no_recommended.
  ///
  /// In en, this message translates to:
  /// **'No recommendations right now.'**
  String get no_recommended;

  /// No description provided for @see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get see_all;

  /// No description provided for @error_home_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load home. Pull to refresh.'**
  String get error_home_failed;

  /// No description provided for @btn_go_appointments.
  ///
  /// In en, this message translates to:
  /// **'Go to my appointments →'**
  String get btn_go_appointments;

  /// No description provided for @account_title.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_title;

  /// No description provided for @account_personal.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get account_personal;

  /// No description provided for @account_personal_sub.
  ///
  /// In en, this message translates to:
  /// **'Name, Surname, Email, Phone, Birthday, Gender'**
  String get account_personal_sub;

  /// No description provided for @account_settings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get account_settings;

  /// No description provided for @account_settings_sub.
  ///
  /// In en, this message translates to:
  /// **'Language, Country'**
  String get account_settings_sub;

  /// No description provided for @account_change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get account_change_password;

  /// No description provided for @account_change_password_sub.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get account_change_password_sub;

  /// No description provided for @account_support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get account_support;

  /// No description provided for @account_support_sub.
  ///
  /// In en, this message translates to:
  /// **'FAQ, Contact Us, Report a problem'**
  String get account_support_sub;

  /// No description provided for @account_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get account_other;

  /// No description provided for @account_other_sub.
  ///
  /// In en, this message translates to:
  /// **'About, Terms, Privacy'**
  String get account_other_sub;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settings_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get settings_country;

  /// No description provided for @settings_country_hint.
  ///
  /// In en, this message translates to:
  /// **'Country ISO-2'**
  String get settings_country_hint;

  /// No description provided for @action_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get action_save;

  /// No description provided for @action_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get action_retry;

  /// No description provided for @action_reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get action_reload;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get error_generic;

  /// No description provided for @provider_tab_services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get provider_tab_services;

  /// No description provided for @provider_tab_reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get provider_tab_reviews;

  /// No description provided for @provider_tab_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get provider_tab_details;

  /// No description provided for @provider_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get provider_about;

  /// No description provided for @provider_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get provider_category;

  /// No description provided for @provider_address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get provider_address;

  /// No description provided for @provider_contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get provider_contacts;

  /// No description provided for @provider_email_label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get provider_email_label;

  /// No description provided for @provider_phone_label.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get provider_phone_label;

  /// No description provided for @provider_team.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get provider_team;

  /// No description provided for @provider_hours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get provider_hours;

  /// No description provided for @provider_closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get provider_closed;

  /// No description provided for @provider_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get provider_retry;

  /// No description provided for @provider_no_services.
  ///
  /// In en, this message translates to:
  /// **'No services.'**
  String get provider_no_services;

  /// No description provided for @provider_no_reviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get provider_no_reviews;

  /// No description provided for @provider_book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get provider_book;

  /// No description provided for @provider_free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get provider_free;

  /// No description provided for @provider_favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get provider_favourite;

  /// No description provided for @provider_favourited.
  ///
  /// In en, this message translates to:
  /// **'Favourited'**
  String get provider_favourited;

  /// No description provided for @booking_title.
  ///
  /// In en, this message translates to:
  /// **'Book an Appointment'**
  String get booking_title;

  /// No description provided for @booking_anyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get booking_anyone;

  /// No description provided for @booking_slots_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get booking_slots_retry;

  /// No description provided for @booking_no_slots.
  ///
  /// In en, this message translates to:
  /// **'No free slots for this day.'**
  String get booking_no_slots;

  /// No description provided for @booking_book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get booking_book;

  /// No description provided for @booking_worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get booking_worker;

  /// No description provided for @booking_service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get booking_service;

  /// No description provided for @booking_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get booking_time;

  /// No description provided for @providerTabServices.
  ///
  /// In en, this message translates to:
  /// **'SERVICES'**
  String get providerTabServices;

  /// No description provided for @providerTabReviews.
  ///
  /// In en, this message translates to:
  /// **'REVIEWS'**
  String get providerTabReviews;

  /// No description provided for @providerTabDetails.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get providerTabDetails;

  /// No description provided for @providerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get providerAbout;

  /// No description provided for @providerCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get providerCategory;

  /// No description provided for @providerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get providerAddress;

  /// No description provided for @providerContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get providerContact;

  /// No description provided for @providerWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get providerWorkingHours;

  /// No description provided for @providerWorkers.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get providerWorkers;

  /// No description provided for @providerNoWorkers.
  ///
  /// In en, this message translates to:
  /// **'No staff listed.'**
  String get providerNoWorkers;

  /// No description provided for @providerNoServices.
  ///
  /// In en, this message translates to:
  /// **'No services.'**
  String get providerNoServices;

  /// No description provided for @providerFavourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get providerFavourite;

  /// No description provided for @providerFavourited.
  ///
  /// In en, this message translates to:
  /// **'Favourited'**
  String get providerFavourited;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get noReviewsYet;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @actionBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get actionBook;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get errorGeneric;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @bookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Book an Appointment'**
  String get bookingTitle;

  /// No description provided for @bookingPickWorker.
  ///
  /// In en, this message translates to:
  /// **'Choose a staff'**
  String get bookingPickWorker;

  /// No description provided for @bookingPickTime.
  ///
  /// In en, this message translates to:
  /// **'Choose a time'**
  String get bookingPickTime;

  /// No description provided for @bookingNoSlotsDay.
  ///
  /// In en, this message translates to:
  /// **'No availability for this day.'**
  String get bookingNoSlotsDay;

  /// No description provided for @anyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get anyone;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get pickDate;

  /// No description provided for @withWorker.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get withWorker;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeRange;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and confirm'**
  String get reviewTitle;

  /// No description provided for @howPay.
  ///
  /// In en, this message translates to:
  /// **'How would you like to pay?'**
  String get howPay;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @confirmAndBook.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Book'**
  String get confirmAndBook;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @bookingSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked!'**
  String get bookingSuccessTitle;

  /// No description provided for @bookingSuccessDesc.
  ///
  /// In en, this message translates to:
  /// **'You’re all set. See you soon.'**
  String get bookingSuccessDesc;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'uz': return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
