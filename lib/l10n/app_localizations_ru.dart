// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get navHome => 'Главная';

  @override
  String get navAppointments => 'Записи';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navAccount => 'Аккаунт';

  @override
  String get home_search_hint => 'Поиск услуг или бизнесов';

  @override
  String get categories => 'Категории';

  @override
  String get no_categories => 'Нет категорий.';

  @override
  String get upcoming_appointment => 'Ближайшая запись';

  @override
  String get no_upcoming => 'Нет ближайших записей.';

  @override
  String get favorites => 'Избранное';

  @override
  String get no_favorites => 'Пока нет избранных.';

  @override
  String get recommended => 'Рекомендовано';

  @override
  String get no_recommended => 'Пока нет рекомендаций.';

  @override
  String get see_all => 'Смотреть все';

  @override
  String get error_home_failed => 'Не удалось загрузить главную. Потяните для обновления.';

  @override
  String get btn_go_appointments => 'Перейти к моим записям →';

  @override
  String get account_title => 'Аккаунт';

  @override
  String get account_personal => 'Личные данные';

  @override
  String get account_personal_sub => 'Имя, Фамилия, Email, Телефон, ДР, Пол';

  @override
  String get account_settings => 'Настройки';

  @override
  String get account_settings_sub => 'Язык, Страна';

  @override
  String get account_change_password => 'Смена пароля';

  @override
  String get account_change_password_sub => 'Обновите пароль';

  @override
  String get account_support => 'Поддержка';

  @override
  String get account_support_sub => 'FAQ, Контакты, Сообщить о проблеме';

  @override
  String get account_other => 'Другое';

  @override
  String get account_other_sub => 'О нас, Условия, Конфиденциальность';

  @override
  String get logout => 'Выйти';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsChangePassword => 'Сменить пароль';

  @override
  String get settings_country => 'Страна';

  @override
  String get settings_country_hint => 'Код страны ISO-2';

  @override
  String get action_save => 'Сохранить';

  @override
  String get action_retry => 'Повторить';

  @override
  String get action_reload => 'Обновить';

  @override
  String get error_generic => 'Что-то пошло не так.';
}
