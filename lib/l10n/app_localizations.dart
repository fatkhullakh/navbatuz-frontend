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
  /// **'Manage'**
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

  /// No description provided for @appointment_details_title.
  ///
  /// In en, this message translates to:
  /// **'Appointment Details'**
  String get appointment_details_title;

  /// No description provided for @appointments_upcoming_title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get appointments_upcoming_title;

  /// No description provided for @appointments_finished_title.
  ///
  /// In en, this message translates to:
  /// **'Finished Appointments'**
  String get appointments_finished_title;

  /// No description provided for @appointments_empty.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any appointments yet.'**
  String get appointments_empty;

  /// No description provided for @appointment_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment'**
  String get appointment_cancel_button;

  /// No description provided for @appointment_cancel_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel appointment?'**
  String get appointment_cancel_confirm_title;

  /// No description provided for @appointment_cancel_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get appointment_cancel_confirm_body;

  /// No description provided for @appointment_cancel_confirm_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get appointment_cancel_confirm_yes;

  /// No description provided for @appointment_cancel_success.
  ///
  /// In en, this message translates to:
  /// **'Appointment canceled'**
  String get appointment_cancel_success;

  /// No description provided for @appointment_cancel_too_late.
  ///
  /// In en, this message translates to:
  /// **'Too late to cancel.'**
  String get appointment_cancel_too_late;

  /// No description provided for @appointment_cancel_too_late_with_window.
  ///
  /// In en, this message translates to:
  /// **'Too late to cancel (within {minutes} min window).'**
  String appointment_cancel_too_late_with_window(Object minutes);

  /// No description provided for @appointment_cancel_failed_generic.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed: {code}'**
  String appointment_cancel_failed_generic(Object code);

  /// No description provided for @appointment_cancel_failed_unknown.
  ///
  /// In en, this message translates to:
  /// **'Cancel failed. Please try again.'**
  String get appointment_cancel_failed_unknown;

  /// No description provided for @error_session_expired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get error_session_expired;

  /// No description provided for @appointment_staff_label.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get appointment_staff_label;

  /// No description provided for @common_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get common_no;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get common_cancelling;

  /// No description provided for @common_service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get common_service;

  /// No description provided for @common_provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get common_provider;

  /// No description provided for @providers_title.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers_title;

  /// No description provided for @favorites_title.
  ///
  /// In en, this message translates to:
  /// **'Favorite shops'**
  String get favorites_title;

  /// No description provided for @favorites_empty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any favorites yet.'**
  String get favorites_empty;

  /// No description provided for @providers_empty.
  ///
  /// In en, this message translates to:
  /// **'No providers to show.'**
  String get providers_empty;

  /// No description provided for @error_favorites_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load favorites.'**
  String get error_favorites_failed;

  /// No description provided for @favorites_added_snack.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favorites_added_snack;

  /// No description provided for @favorites_removed_snack.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favorites_removed_snack;

  /// No description provided for @favorites_toggle_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not update favorite. Please try again.'**
  String get favorites_toggle_failed;

  /// No description provided for @providers.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providers;

  /// No description provided for @no_results.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get no_results;

  /// No description provided for @no_favorites.
  ///
  /// In en, this message translates to:
  /// **'You have no favorite shops yet.'**
  String get no_favorites;

  /// No description provided for @remove_from_favorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get remove_from_favorites;

  /// No description provided for @error_generic.
  ///
  /// In en, this message translates to:
  /// **'Provider is not selected'**
  String get error_generic;

  /// No description provided for @provider_change_logo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get provider_change_logo;

  /// No description provided for @action_pick_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get action_pick_from_gallery;

  /// No description provided for @action_take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get action_take_photo;

  /// No description provided for @provider_logo_updated.
  ///
  /// In en, this message translates to:
  /// **'Logo updated'**
  String get provider_logo_updated;

  /// No description provided for @error_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get error_upload_failed;

  /// No description provided for @action_change_photo.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get action_change_photo;

  /// No description provided for @action_remove_photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get action_remove_photo;

  /// No description provided for @action_view_photo.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get action_view_photo;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @cat_barbershop.
  ///
  /// In en, this message translates to:
  /// **'Barbershop'**
  String get cat_barbershop;

  /// No description provided for @cat_dental.
  ///
  /// In en, this message translates to:
  /// **'Dental'**
  String get cat_dental;

  /// No description provided for @cat_clinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get cat_clinic;

  /// No description provided for @cat_spa.
  ///
  /// In en, this message translates to:
  /// **'Spa'**
  String get cat_spa;

  /// No description provided for @cat_gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get cat_gym;

  /// No description provided for @cat_nail_salon.
  ///
  /// In en, this message translates to:
  /// **'Nail salon'**
  String get cat_nail_salon;

  /// No description provided for @cat_beauty_clinic.
  ///
  /// In en, this message translates to:
  /// **'Beauty clinic'**
  String get cat_beauty_clinic;

  /// No description provided for @cat_tattoo_studio.
  ///
  /// In en, this message translates to:
  /// **'Tattoo studio'**
  String get cat_tattoo_studio;

  /// No description provided for @cat_massage_center.
  ///
  /// In en, this message translates to:
  /// **'Massage center'**
  String get cat_massage_center;

  /// No description provided for @cat_physiotherapy_clinic.
  ///
  /// In en, this message translates to:
  /// **'Physiotherapy'**
  String get cat_physiotherapy_clinic;

  /// No description provided for @cat_makeup_studio.
  ///
  /// In en, this message translates to:
  /// **'Makeup studio'**
  String get cat_makeup_studio;

  /// No description provided for @appointments_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointments'**
  String get appointments_upcoming;

  /// No description provided for @appointments_finished.
  ///
  /// In en, this message translates to:
  /// **'Finished Appointments'**
  String get appointments_finished;

  /// No description provided for @appointment_action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get appointment_action_cancel;

  /// No description provided for @appointment_action_book_again.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get appointment_action_book_again;

  /// No description provided for @provider_nav_appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get provider_nav_appointments;

  /// No description provided for @provider_nav_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get provider_nav_dashboard;

  /// No description provided for @provider_nav_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get provider_nav_manage;

  /// No description provided for @provider_nav_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get provider_nav_account;

  /// No description provided for @provider_appt_today_title.
  ///
  /// In en, this message translates to:
  /// **'Today’s schedule'**
  String get provider_appt_today_title;

  /// No description provided for @provider_appt_today_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Hook this up to your provider/worker appointments.'**
  String get provider_appt_today_subtitle;

  /// No description provided for @common_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get common_coming_soon;

  /// No description provided for @provider_dashboard_coming_soon_desc.
  ///
  /// In en, this message translates to:
  /// **'Analytics and revenue overview will be here.'**
  String get provider_dashboard_coming_soon_desc;

  /// No description provided for @provider_manage_services_title.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get provider_manage_services_title;

  /// No description provided for @provider_manage_services_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, edit and sort services'**
  String get provider_manage_services_subtitle;

  /// No description provided for @provider_manage_business_title.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get provider_manage_business_title;

  /// No description provided for @provider_manage_business_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, description, address, contacts'**
  String get provider_manage_business_subtitle;

  /// No description provided for @provider_manage_staff_title.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get provider_manage_staff_title;

  /// No description provided for @provider_manage_staff_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add/edit workers and assign services'**
  String get provider_manage_staff_subtitle;

  /// No description provided for @provider_manage_hours_title.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get provider_manage_hours_title;

  /// No description provided for @provider_manage_hours_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set weekly hours and overrides'**
  String get provider_manage_hours_subtitle;

  /// No description provided for @provider_action_add_service.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get provider_action_add_service;

  /// No description provided for @provider_action_add_staff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get provider_action_add_staff;

  /// No description provided for @provider_account_hint.
  ///
  /// In en, this message translates to:
  /// **'Profile, language, logout…'**
  String get provider_account_hint;

  /// No description provided for @provider_services_hint.
  ///
  /// In en, this message translates to:
  /// **'List and create/edit services'**
  String get provider_services_hint;

  /// No description provided for @provider_business_hint.
  ///
  /// In en, this message translates to:
  /// **'Name, description, address, email, phone, logo'**
  String get provider_business_hint;

  /// No description provided for @provider_staff_hint.
  ///
  /// In en, this message translates to:
  /// **'List workers, add/edit, assign services'**
  String get provider_staff_hint;

  /// No description provided for @provider_hours_hint.
  ///
  /// In en, this message translates to:
  /// **'Weekly grid editor and exceptions'**
  String get provider_hours_hint;

  /// No description provided for @services_title.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services_title;

  /// No description provided for @action_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get action_refresh;

  /// No description provided for @search_services_hint.
  ///
  /// In en, this message translates to:
  /// **'Search services…'**
  String get search_services_hint;

  /// No description provided for @no_data.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get no_data;

  /// No description provided for @service_create.
  ///
  /// In en, this message translates to:
  /// **'Create service'**
  String get service_create;

  /// No description provided for @main_details_required.
  ///
  /// In en, this message translates to:
  /// **'Main details'**
  String get main_details_required;

  /// No description provided for @service_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get service_name;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @service_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get service_duration;

  /// No description provided for @service_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get service_description;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @not_set.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get not_set;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @add_photo.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get add_photo;

  /// No description provided for @image_updated.
  ///
  /// In en, this message translates to:
  /// **'Image updated'**
  String get image_updated;

  /// No description provided for @image_removed.
  ///
  /// In en, this message translates to:
  /// **'Image removed'**
  String get image_removed;

  /// No description provided for @error_upload_image.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get error_upload_image;

  /// No description provided for @error_remove_image.
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get error_remove_image;

  /// No description provided for @manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage_title;

  /// No description provided for @manage_services_title.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get manage_services_title;

  /// No description provided for @manage_services_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, edit, and organize services'**
  String get manage_services_subtitle;

  /// No description provided for @manage_business_info_title.
  ///
  /// In en, this message translates to:
  /// **'Business info'**
  String get manage_business_info_title;

  /// No description provided for @manage_business_info_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, contacts, address, about'**
  String get manage_business_info_subtitle;

  /// No description provided for @manage_staff_title.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get manage_staff_title;

  /// No description provided for @manage_staff_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite and manage workers'**
  String get manage_staff_subtitle;

  /// No description provided for @manage_hours_title.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get manage_hours_title;

  /// No description provided for @manage_hours_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set business schedule and breaks'**
  String get manage_hours_subtitle;

  /// No description provided for @prov_nav_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get prov_nav_dashboard;

  /// No description provided for @prov_nav_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get prov_nav_manage;

  /// No description provided for @action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get action_delete;

  /// No description provided for @action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get action_cancel;

  /// No description provided for @confirm_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete service?'**
  String get confirm_delete_title;

  /// No description provided for @confirm_delete_msg.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirm_delete_msg;

  /// No description provided for @staff_members.
  ///
  /// In en, this message translates to:
  /// **'Staff members'**
  String get staff_members;

  /// No description provided for @action_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get action_add;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @working_hours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get working_hours;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @select_time.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get select_time;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @action_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get action_done;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @copy_monday_to_all.
  ///
  /// In en, this message translates to:
  /// **'Copy Monday to all'**
  String get copy_monday_to_all;

  /// No description provided for @close_all.
  ///
  /// In en, this message translates to:
  /// **'Close all'**
  String get close_all;

  /// No description provided for @mon_fri.
  ///
  /// In en, this message translates to:
  /// **'Mon–Fri'**
  String get mon_fri;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @business_info.
  ///
  /// In en, this message translates to:
  /// **'Business info'**
  String get business_info;

  /// No description provided for @change_logo.
  ///
  /// In en, this message translates to:
  /// **'Change logo'**
  String get change_logo;

  /// No description provided for @remove_logo.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove_logo;

  /// No description provided for @provider_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get provider_name;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @team_size.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get team_size;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @address_line1.
  ///
  /// In en, this message translates to:
  /// **'Address line 1'**
  String get address_line1;

  /// No description provided for @address_line2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2'**
  String get address_line2;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @country_iso2.
  ///
  /// In en, this message translates to:
  /// **'Country ISO2'**
  String get country_iso2;

  /// No description provided for @postal_code.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postal_code;

  /// No description provided for @use_current_location.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get use_current_location;

  /// No description provided for @location_permission_needed.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get location_permission_needed;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @business_info_title.
  ///
  /// In en, this message translates to:
  /// **'Business info'**
  String get business_info_title;

  /// No description provided for @business_details_tab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get business_details_tab;

  /// No description provided for @business_photos_tab.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get business_photos_tab;

  /// No description provided for @business_location_tab.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get business_location_tab;

  /// No description provided for @business_details_title.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get business_details_title;

  /// No description provided for @company_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get company_name_label;

  /// No description provided for @invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalid_email;

  /// No description provided for @logo_title.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get logo_title;

  /// No description provided for @upload_logo.
  ///
  /// In en, this message translates to:
  /// **'Upload logo'**
  String get upload_logo;

  /// No description provided for @take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get take_photo;

  /// No description provided for @gallery_title.
  ///
  /// In en, this message translates to:
  /// **'Portfolio / Interior'**
  String get gallery_title;

  /// No description provided for @add_photos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get add_photos;

  /// No description provided for @gallery_hint.
  ///
  /// In en, this message translates to:
  /// **'Upload interior/portfolio photos (not persisted yet).'**
  String get gallery_hint;

  /// No description provided for @location_details_title.
  ///
  /// In en, this message translates to:
  /// **'Location details'**
  String get location_details_title;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @pin_on_map_title.
  ///
  /// In en, this message translates to:
  /// **'Pin location (lat, lng)'**
  String get pin_on_map_title;

  /// No description provided for @set_pin.
  ///
  /// In en, this message translates to:
  /// **'Set pin'**
  String get set_pin;

  /// No description provided for @set_coordinates_title.
  ///
  /// In en, this message translates to:
  /// **'Set coordinates'**
  String get set_coordinates_title;

  /// No description provided for @latitude_label.
  ///
  /// In en, this message translates to:
  /// **'Latitude (-90..90)'**
  String get latitude_label;

  /// No description provided for @longitude_label.
  ///
  /// In en, this message translates to:
  /// **'Longitude (-180..180)'**
  String get longitude_label;

  /// No description provided for @use_this_pin.
  ///
  /// In en, this message translates to:
  /// **'Use this pin'**
  String get use_this_pin;

  /// No description provided for @enter_valid_numbers.
  ///
  /// In en, this message translates to:
  /// **'Enter valid numbers'**
  String get enter_valid_numbers;

  /// No description provided for @out_of_range.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get out_of_range;

  /// No description provided for @phone_enter_digits_range.
  ///
  /// In en, this message translates to:
  /// **'Enter {min}–{max} digits'**
  String phone_enter_digits_range(Object max, Object min);

  /// No description provided for @location_services_disabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get location_services_disabled;

  /// No description provided for @location_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get location_permission_denied;

  /// No description provided for @no_pin_set.
  ///
  /// In en, this message translates to:
  /// **'No pin set'**
  String get no_pin_set;

  /// No description provided for @pick_location_title.
  ///
  /// In en, this message translates to:
  /// **'Pick location'**
  String get pick_location_title;

  /// No description provided for @business_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Business settings'**
  String get business_settings_title;

  /// No description provided for @business_details_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, description, email, phone, category, logo'**
  String get business_details_subtitle;

  /// No description provided for @select_category.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get select_category;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @location_pick_on_map.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get location_pick_on_map;

  /// No description provided for @location_no_pin.
  ///
  /// In en, this message translates to:
  /// **'No pin set'**
  String get location_no_pin;

  /// No description provided for @working_hours_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set business hours'**
  String get working_hours_subtitle;

  /// No description provided for @staff_title.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff_title;

  /// No description provided for @staff_add_member.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staff_add_member;

  /// No description provided for @staff_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search name or phone…'**
  String get staff_search_hint;

  /// No description provided for @staff_show_inactive.
  ///
  /// In en, this message translates to:
  /// **'Show inactive'**
  String get staff_show_inactive;

  /// No description provided for @staff_invite_title.
  ///
  /// In en, this message translates to:
  /// **'Invite staff'**
  String get staff_invite_title;

  /// No description provided for @staff_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit staff'**
  String get staff_edit_title;

  /// No description provided for @staff_role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staff_role;

  /// No description provided for @role_owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get role_owner;

  /// No description provided for @role_receptionist.
  ///
  /// In en, this message translates to:
  /// **'Receptionist'**
  String get role_receptionist;

  /// No description provided for @role_worker.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get role_worker;

  /// No description provided for @staff_remove_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get staff_remove_confirm_title;

  /// No description provided for @staff_remove_confirm_msg.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get staff_remove_confirm_msg;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @action_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get action_remove;

  /// No description provided for @action_deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get action_deactivate;

  /// No description provided for @action_activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get action_activate;

  /// No description provided for @person_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get person_name;

  /// No description provided for @manage_services.
  ///
  /// In en, this message translates to:
  /// **'Manage services'**
  String get manage_services;

  /// No description provided for @edit_availability.
  ///
  /// In en, this message translates to:
  /// **'Edit availability'**
  String get edit_availability;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @invite_worker_title.
  ///
  /// In en, this message translates to:
  /// **'Add & Invite worker'**
  String get invite_worker_title;

  /// No description provided for @personal_info.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get personal_info;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get last_name;

  /// No description provided for @upload_avatar.
  ///
  /// In en, this message translates to:
  /// **'Upload avatar'**
  String get upload_avatar;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @create_send_invite.
  ///
  /// In en, this message translates to:
  /// **'Create & send invite'**
  String get create_send_invite;

  /// No description provided for @invite_sent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get invite_sent;

  /// No description provided for @working_this_day.
  ///
  /// In en, this message translates to:
  /// **'Working this day'**
  String get working_this_day;

  /// No description provided for @breaks_title.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get breaks_title;

  /// No description provided for @add_break.
  ///
  /// In en, this message translates to:
  /// **'Add break'**
  String get add_break;

  /// No description provided for @select_date.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get select_date;

  /// No description provided for @weekly_schedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly_schedule;

  /// No description provided for @exceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get exceptions;

  /// No description provided for @exception_for_day.
  ///
  /// In en, this message translates to:
  /// **'Exception for this day'**
  String get exception_for_day;

  /// No description provided for @delete_exception_title.
  ///
  /// In en, this message translates to:
  /// **'Remove exception?'**
  String get delete_exception_title;

  /// No description provided for @delete_exception_msg.
  ///
  /// In en, this message translates to:
  /// **'This will delete the exception for this day.'**
  String get delete_exception_msg;

  /// No description provided for @breaks_for_day.
  ///
  /// In en, this message translates to:
  /// **'Breaks for this day'**
  String get breaks_for_day;

  /// No description provided for @no_breaks.
  ///
  /// In en, this message translates to:
  /// **'No breaks.'**
  String get no_breaks;

  /// No description provided for @delete_break_title.
  ///
  /// In en, this message translates to:
  /// **'Delete break?'**
  String get delete_break_title;

  /// No description provided for @delete_break_msg.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get delete_break_msg;

  /// No description provided for @buffer_minutes.
  ///
  /// In en, this message translates to:
  /// **'Buffer (min)'**
  String get buffer_minutes;

  /// No description provided for @activated.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get activated;

  /// No description provided for @deactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get deactivated;

  /// No description provided for @invite_flow_placeholder.
  ///
  /// In en, this message translates to:
  /// **'This screen will register a new user (name, contacts, avatar), assign a role and send credentials via email/SMS.'**
  String get invite_flow_placeholder;

  /// No description provided for @staff_only_available.
  ///
  /// In en, this message translates to:
  /// **'Show only available'**
  String get staff_only_available;

  /// No description provided for @tab_week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get tab_week;

  /// No description provided for @tab_exceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions'**
  String get tab_exceptions;

  /// No description provided for @tab_breaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get tab_breaks;

  /// No description provided for @copy_mon_all.
  ///
  /// In en, this message translates to:
  /// **'Copy Mon → All'**
  String get copy_mon_all;

  /// No description provided for @copy_mon_fri.
  ///
  /// In en, this message translates to:
  /// **'Copy Mon → Fri'**
  String get copy_mon_fri;

  /// No description provided for @copied_mon_all.
  ///
  /// In en, this message translates to:
  /// **'Copied Monday to all days'**
  String get copied_mon_all;

  /// No description provided for @copied_mon_fri.
  ///
  /// In en, this message translates to:
  /// **'Copied Monday to Mon–Fri'**
  String get copied_mon_fri;

  /// No description provided for @buffer_min_short.
  ///
  /// In en, this message translates to:
  /// **'Buffer (min)'**
  String get buffer_min_short;

  /// No description provided for @delete_exception.
  ///
  /// In en, this message translates to:
  /// **'Delete this exception'**
  String get delete_exception;

  /// No description provided for @no_breaks_day.
  ///
  /// In en, this message translates to:
  /// **'No breaks for this day.'**
  String get no_breaks_day;

  /// No description provided for @break_added.
  ///
  /// In en, this message translates to:
  /// **'Break added'**
  String get break_added;

  /// No description provided for @only_available.
  ///
  /// In en, this message translates to:
  /// **'Only available'**
  String get only_available;

  /// No description provided for @time_select_title.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get time_select_title;

  /// No description provided for @step_personal.
  ///
  /// In en, this message translates to:
  /// **'Personal & contact'**
  String get step_personal;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @worker_type.
  ///
  /// In en, this message translates to:
  /// **'Worker type'**
  String get worker_type;

  /// No description provided for @action_invite.
  ///
  /// In en, this message translates to:
  /// **'Create & send invite'**
  String get action_invite;

  /// No description provided for @invite_sent_title.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent'**
  String get invite_sent_title;

  /// No description provided for @login_email.
  ///
  /// In en, this message translates to:
  /// **'Login (email)'**
  String get login_email;

  /// No description provided for @temp_password.
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get temp_password;

  /// No description provided for @invite_note_change_password.
  ///
  /// In en, this message translates to:
  /// **'They will be asked to change the password on first login.'**
  String get invite_note_change_password;

  /// No description provided for @date_of_birth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get date_of_birth;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appointments_title.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments_title;

  /// No description provided for @no_workers_selected.
  ///
  /// In en, this message translates to:
  /// **'No workers selected'**
  String get no_workers_selected;

  /// No description provided for @no_appointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments'**
  String get no_appointments;

  /// No description provided for @new_appointment.
  ///
  /// In en, this message translates to:
  /// **'New appointment'**
  String get new_appointment;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @guest_details.
  ///
  /// In en, this message translates to:
  /// **'Guest details'**
  String get guest_details;

  /// No description provided for @required_field.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required_field;

  /// No description provided for @fill_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fill_all_fields;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @reschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get reschedule;

  /// No description provided for @no_free_slots.
  ///
  /// In en, this message translates to:
  /// **'No free slots'**
  String get no_free_slots;

  /// No description provided for @calendar_view.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar_view;

  /// No description provided for @list_view.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list_view;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @weekday_mon_short.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekday_mon_short;

  /// No description provided for @weekday_tue_short.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekday_tue_short;

  /// No description provided for @weekday_wed_short.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekday_wed_short;

  /// No description provided for @weekday_thu_short.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekday_thu_short;

  /// No description provided for @weekday_fri_short.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekday_fri_short;

  /// No description provided for @weekday_sat_short.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekday_sat_short;

  /// No description provided for @weekday_sun_short.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekday_sun_short;

  /// No description provided for @no_items.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get no_items;

  /// No description provided for @break_label.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get break_label;

  /// No description provided for @common_guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get common_guest;

  /// No description provided for @common_customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get common_customer;

  /// No description provided for @status_no_show.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get status_no_show;

  /// No description provided for @status_label.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status_label;

  /// No description provided for @status_booked.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get status_booked;

  /// No description provided for @status_completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get status_completed;

  /// No description provided for @status_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get status_cancelled;

  /// No description provided for @status_rescheduled.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled'**
  String get status_rescheduled;

  /// No description provided for @action_mark_no_show.
  ///
  /// In en, this message translates to:
  /// **'Mark no-show'**
  String get action_mark_no_show;

  /// No description provided for @action_undo_no_show.
  ///
  /// In en, this message translates to:
  /// **'Undo no-show'**
  String get action_undo_no_show;

  /// No description provided for @toast_marked_no_show.
  ///
  /// In en, this message translates to:
  /// **'Marked as no-show'**
  String get toast_marked_no_show;

  /// No description provided for @toast_undo_no_show.
  ///
  /// In en, this message translates to:
  /// **'No-show undone'**
  String get toast_undo_no_show;

  /// No description provided for @appointment_no_actions.
  ///
  /// In en, this message translates to:
  /// **'No actions available for this status.'**
  String get appointment_no_actions;

  /// No description provided for @walk_in.
  ///
  /// In en, this message translates to:
  /// **'Walk-in'**
  String get walk_in;

  /// No description provided for @pick_client.
  ///
  /// In en, this message translates to:
  /// **'Pick client'**
  String get pick_client;

  /// No description provided for @pick_from_contacts.
  ///
  /// In en, this message translates to:
  /// **'Pick from contacts'**
  String get pick_from_contacts;

  /// No description provided for @no_services_assigned.
  ///
  /// In en, this message translates to:
  /// **'No services are assigned to this worker.'**
  String get no_services_assigned;

  /// No description provided for @contacts_not_supported.
  ///
  /// In en, this message translates to:
  /// **'Contacts not supported on this platform'**
  String get contacts_not_supported;

  /// No description provided for @contacts_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission denied. Enable it in Settings > App > Permissions.'**
  String get contacts_permission_denied;

  /// No description provided for @no_provider_for_clients.
  ///
  /// In en, this message translates to:
  /// **'No provider to list clients from'**
  String get no_provider_for_clients;

  /// No description provided for @choose_service_validation.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get choose_service_validation;

  /// No description provided for @breaksTitle.
  ///
  /// In en, this message translates to:
  /// **'Add / Manage breaks'**
  String get breaksTitle;

  /// No description provided for @workerLabel.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get workerLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @todayButton.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayButton;

  /// No description provided for @timeStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timeStartLabel;

  /// No description provided for @timeEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get timeEndLabel;

  /// No description provided for @saveBreakBtn.
  ///
  /// In en, this message translates to:
  /// **'Save break'**
  String get saveBreakBtn;

  /// No description provided for @savingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingEllipsis;

  /// No description provided for @existingBreaksTitle.
  ///
  /// In en, this message translates to:
  /// **'Existing breaks'**
  String get existingBreaksTitle;

  /// No description provided for @noBreaksForDay.
  ///
  /// In en, this message translates to:
  /// **'No breaks for this day.'**
  String get noBreaksForDay;

  /// No description provided for @breakSaved.
  ///
  /// In en, this message translates to:
  /// **'Break saved'**
  String get breakSaved;

  /// No description provided for @breakDeleted.
  ///
  /// In en, this message translates to:
  /// **'Break deleted'**
  String get breakDeleted;

  /// No description provided for @breakSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String breakSaveFailed(String error);

  /// No description provided for @breakDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String breakDeleteFailed(String error);

  /// No description provided for @breakRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Choose worker, start and end time'**
  String get breakRequiredFields;

  /// No description provided for @breakEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get breakEndAfterStart;

  /// No description provided for @pickTime5mTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick time (5-min)'**
  String get pickTime5mTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @owner_worker_profile.
  ///
  /// In en, this message translates to:
  /// **'Your worker profile'**
  String get owner_worker_profile;

  /// No description provided for @me_label.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me_label;

  /// No description provided for @status_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get status_inactive;

  /// No description provided for @my_availability.
  ///
  /// In en, this message translates to:
  /// **'My availability'**
  String get my_availability;

  /// No description provided for @my_services.
  ///
  /// In en, this message translates to:
  /// **'My services'**
  String get my_services;

  /// No description provided for @work_as_staff_title.
  ///
  /// In en, this message translates to:
  /// **'Work as staff'**
  String get work_as_staff_title;

  /// No description provided for @worker_type_label.
  ///
  /// In en, this message translates to:
  /// **'Worker type'**
  String get worker_type_label;

  /// No description provided for @initial_status_label.
  ///
  /// In en, this message translates to:
  /// **'Initial status'**
  String get initial_status_label;

  /// No description provided for @enable_me_as_worker.
  ///
  /// In en, this message translates to:
  /// **'Enable me as a worker'**
  String get enable_me_as_worker;

  /// No description provided for @enabling_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Enabling…'**
  String get enabling_ellipsis;

  /// No description provided for @reenable_me.
  ///
  /// In en, this message translates to:
  /// **'Re-enable me'**
  String get reenable_me;

  /// No description provided for @reenabling_ellipsis.
  ///
  /// In en, this message translates to:
  /// **'Re-enabling…'**
  String get reenabling_ellipsis;

  /// No description provided for @removed_from_team_hint.
  ///
  /// In en, this message translates to:
  /// **'You are currently removed from the team.'**
  String get removed_from_team_hint;

  /// No description provided for @enable_hint_after.
  ///
  /// In en, this message translates to:
  /// **'You’ll be able to set your hours and assign services to yourself after enabling.'**
  String get enable_hint_after;

  /// No description provided for @owner_enabled_as_worker.
  ///
  /// In en, this message translates to:
  /// **'You are now enabled as a worker'**
  String get owner_enabled_as_worker;

  /// No description provided for @worker_profile_reenabled.
  ///
  /// In en, this message translates to:
  /// **'Worker profile re-enabled'**
  String get worker_profile_reenabled;

  /// No description provided for @http_error.
  ///
  /// In en, this message translates to:
  /// **'{msg}'**
  String http_error(String msg);

  /// No description provided for @worker_status_available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get worker_status_available;

  /// No description provided for @worker_status_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get worker_status_unavailable;

  /// No description provided for @worker_status_on_break.
  ///
  /// In en, this message translates to:
  /// **'On break'**
  String get worker_status_on_break;

  /// No description provided for @worker_status_on_leave.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get worker_status_on_leave;

  /// No description provided for @action_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get action_edit;

  /// No description provided for @deleted_ok.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted_ok;

  /// No description provided for @activated_ok.
  ///
  /// In en, this message translates to:
  /// **'Activated'**
  String get activated_ok;

  /// No description provided for @deactivated_ok.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get deactivated_ok;

  /// No description provided for @failed_with_reason.
  ///
  /// In en, this message translates to:
  /// **'{reason}'**
  String failed_with_reason(String reason);

  /// No description provided for @missing_service_id.
  ///
  /// In en, this message translates to:
  /// **'Missing service id'**
  String get missing_service_id;

  /// No description provided for @filter_active_only.
  ///
  /// In en, this message translates to:
  /// **'Active only'**
  String get filter_active_only;

  /// No description provided for @no_services_yet.
  ///
  /// In en, this message translates to:
  /// **'No services yet'**
  String get no_services_yet;

  /// No description provided for @services_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {# service} other {# services}}'**
  String services_count(int count);

  /// No description provided for @status_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get status_active;

  /// No description provided for @duration_hm.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String duration_hm(String h, String m);

  /// No description provided for @duration_h.
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String duration_h(String h);

  /// No description provided for @duration_m.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String duration_m(String m);

  /// No description provided for @currency_sum.
  ///
  /// In en, this message translates to:
  /// **'sum'**
  String get currency_sum;

  /// No description provided for @unit_service_singular.
  ///
  /// In en, this message translates to:
  /// **'service'**
  String get unit_service_singular;

  /// No description provided for @unit_service_plural.
  ///
  /// In en, this message translates to:
  /// **'services'**
  String get unit_service_plural;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @category_clinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get category_clinic;

  /// No description provided for @category_barbershop.
  ///
  /// In en, this message translates to:
  /// **'Barbershop'**
  String get category_barbershop;

  /// No description provided for @category_beauty_salon.
  ///
  /// In en, this message translates to:
  /// **'Beauty salon'**
  String get category_beauty_salon;

  /// No description provided for @category_spa.
  ///
  /// In en, this message translates to:
  /// **'Spa'**
  String get category_spa;

  /// No description provided for @category_dental.
  ///
  /// In en, this message translates to:
  /// **'Dental'**
  String get category_dental;

  /// No description provided for @category_gym.
  ///
  /// In en, this message translates to:
  /// **'Gym / Fitness'**
  String get category_gym;

  /// No description provided for @category_tattoo.
  ///
  /// In en, this message translates to:
  /// **'Tattoo studio'**
  String get category_tattoo;

  /// No description provided for @category_nail_salon.
  ///
  /// In en, this message translates to:
  /// **'Nail salon'**
  String get category_nail_salon;

  /// No description provided for @category_massage.
  ///
  /// In en, this message translates to:
  /// **'Massage'**
  String get category_massage;

  /// No description provided for @category_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get category_other;

  /// Snackbar after user selects a location on the map
  ///
  /// In en, this message translates to:
  /// **'Location pinned'**
  String get location_pinned;

  /// Snackbar asking user to select a location before saving
  ///
  /// In en, this message translates to:
  /// **'Please pin location on the map'**
  String get pick_on_map_first;

  /// Section title for address inputs
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Section title for the map picker / coordinates
  ///
  /// In en, this message translates to:
  /// **'Map pin'**
  String get map_pin;

  /// Button label to open the map picker
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pick_on_map;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @on_break.
  ///
  /// In en, this message translates to:
  /// **'On break'**
  String get on_break;

  /// No description provided for @on_leave.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get on_leave;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @show_inactive_workers.
  ///
  /// In en, this message translates to:
  /// **'Show inactive workers'**
  String get show_inactive_workers;

  /// No description provided for @show_inactive_receptionists.
  ///
  /// In en, this message translates to:
  /// **'Show inactive receptionists'**
  String get show_inactive_receptionists;

  /// No description provided for @receptionist.
  ///
  /// In en, this message translates to:
  /// **'Receptionist'**
  String get receptionist;

  /// No description provided for @add_staff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get add_staff;

  /// No description provided for @add_worker.
  ///
  /// In en, this message translates to:
  /// **'Add worker'**
  String get add_worker;

  /// No description provided for @add_receptionist.
  ///
  /// In en, this message translates to:
  /// **'Add receptionist'**
  String get add_receptionist;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @remove_worker_q.
  ///
  /// In en, this message translates to:
  /// **'Remove worker?'**
  String get remove_worker_q;

  /// No description provided for @remove_worker_desc.
  ///
  /// In en, this message translates to:
  /// **'The worker will be removed from the team (their account will not be deleted).'**
  String get remove_worker_desc;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removed_from_team.
  ///
  /// In en, this message translates to:
  /// **'Removed from team'**
  String get removed_from_team;

  /// No description provided for @worker_activated.
  ///
  /// In en, this message translates to:
  /// **'Worker activated'**
  String get worker_activated;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @change_status.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get change_status;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @danger_zone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get danger_zone;

  /// No description provided for @remove_from_team.
  ///
  /// In en, this message translates to:
  /// **'Remove from team'**
  String get remove_from_team;

  /// No description provided for @reactivate_worker.
  ///
  /// In en, this message translates to:
  /// **'Reactivate worker'**
  String get reactivate_worker;

  /// No description provided for @edit_worker.
  ///
  /// In en, this message translates to:
  /// **'Edit worker'**
  String get edit_worker;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @gender_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get gender_male;

  /// No description provided for @gender_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get gender_female;

  /// No description provided for @gender_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get gender_other;

  /// No description provided for @phone_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get phone_hint;

  /// No description provided for @email_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter email address'**
  String get email_hint;

  /// No description provided for @role_worker_type.
  ///
  /// In en, this message translates to:
  /// **'Worker type'**
  String get role_worker_type;

  /// No description provided for @role_barber.
  ///
  /// In en, this message translates to:
  /// **'Barber'**
  String get role_barber;

  /// No description provided for @role_hairdresser.
  ///
  /// In en, this message translates to:
  /// **'Hairdresser'**
  String get role_hairdresser;

  /// No description provided for @role_dentist.
  ///
  /// In en, this message translates to:
  /// **'Dentist'**
  String get role_dentist;

  /// No description provided for @role_doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get role_doctor;

  /// No description provided for @role_nurser.
  ///
  /// In en, this message translates to:
  /// **'Nurse'**
  String get role_nurser;

  /// No description provided for @role_spa_therapist.
  ///
  /// In en, this message translates to:
  /// **'Spa therapist'**
  String get role_spa_therapist;

  /// No description provided for @role_masseuse.
  ///
  /// In en, this message translates to:
  /// **'Masseuse'**
  String get role_masseuse;

  /// No description provided for @role_nail_technician.
  ///
  /// In en, this message translates to:
  /// **'Nail technician'**
  String get role_nail_technician;

  /// No description provided for @role_cosmetologist.
  ///
  /// In en, this message translates to:
  /// **'Cosmetologist'**
  String get role_cosmetologist;

  /// No description provided for @role_tattoo_artist.
  ///
  /// In en, this message translates to:
  /// **'Tattoo artist'**
  String get role_tattoo_artist;

  /// No description provided for @role_personal_trainer.
  ///
  /// In en, this message translates to:
  /// **'Personal trainer'**
  String get role_personal_trainer;

  /// No description provided for @role_makeup_artist.
  ///
  /// In en, this message translates to:
  /// **'Makeup artist'**
  String get role_makeup_artist;

  /// No description provided for @role_physiotherapist.
  ///
  /// In en, this message translates to:
  /// **'Physiotherapist'**
  String get role_physiotherapist;

  /// No description provided for @role_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get role_general;

  /// No description provided for @role_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get role_other;

  /// No description provided for @hire_date.
  ///
  /// In en, this message translates to:
  /// **'Hire date'**
  String get hire_date;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @edit_receptionist.
  ///
  /// In en, this message translates to:
  /// **'Edit receptionist'**
  String get edit_receptionist;

  /// No description provided for @reactivate_receptionist.
  ///
  /// In en, this message translates to:
  /// **'Reactivate receptionist'**
  String get reactivate_receptionist;

  /// No description provided for @receptionist_reactivated.
  ///
  /// In en, this message translates to:
  /// **'Receptionist reactivated'**
  String get receptionist_reactivated;

  /// No description provided for @remove_receptionist_q.
  ///
  /// In en, this message translates to:
  /// **'Remove receptionist?'**
  String get remove_receptionist_q;

  /// No description provided for @remove_receptionist_desc.
  ///
  /// In en, this message translates to:
  /// **'The receptionist will be removed from the team (their account will not be deleted).'**
  String get remove_receptionist_desc;

  /// No description provided for @only_active.
  ///
  /// In en, this message translates to:
  /// **'Only active'**
  String get only_active;

  /// No description provided for @only_assigned.
  ///
  /// In en, this message translates to:
  /// **'Only assigned'**
  String get only_assigned;

  /// No description provided for @service_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive service'**
  String get service_inactive;

  /// No description provided for @selected_n.
  ///
  /// In en, this message translates to:
  /// **'Selected: {n}'**
  String selected_n(int n);

  /// No description provided for @assign_visible.
  ///
  /// In en, this message translates to:
  /// **'Assign visible'**
  String get assign_visible;

  /// No description provided for @remove_visible.
  ///
  /// In en, this message translates to:
  /// **'Remove visible'**
  String get remove_visible;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @removed.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get removed;

  /// No description provided for @added_n_services.
  ///
  /// In en, this message translates to:
  /// **'Added {n} services'**
  String added_n_services(int n);

  /// No description provided for @removed_n_services.
  ///
  /// In en, this message translates to:
  /// **'Removed {n} services'**
  String removed_n_services(int n);

  /// No description provided for @no_services_found.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get no_services_found;

  /// No description provided for @no_services_found_caption.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search query.'**
  String get no_services_found_caption;

  /// No description provided for @current_password.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get current_password;

  /// No description provided for @current_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get current_password_hint;

  /// No description provided for @current_password_required.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get current_password_required;

  /// No description provided for @current_password_incorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get current_password_incorrect;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get new_password;

  /// No description provided for @new_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get new_password_hint;

  /// No description provided for @confirm_new_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirm_new_password;

  /// No description provided for @confirm_new_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter new password'**
  String get confirm_new_password_hint;
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
