import 'package:flutter/material.dart';
import 'package:frontend/screens/appointments/appointments_screen.dart';
import 'package:frontend/screens/providers/provider_screen.dart';
import 'package:frontend/screens/providers/providers_list_screen.dart';
import 'package:frontend/screens/search/search_screen.dart';
import 'package:frontend/screens/search/service_search_screen.dart';
import 'package:frontend/screens/search/universal_search_screen.dart';
import 'package:provider/provider.dart';

import 'core/locale_notifier.dart';
import 'l10n/app_localizations.dart';

// Base shells/screens
import 'navigation/nav_root.dart';
import 'navigation/provider_nav_root.dart';
import 'navigation/worker_nav_root.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_request_screen.dart';

// Onboarding flow
import 'models/onboarding_data.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/provider/business_type_screen.dart';
import 'screens/onboarding/provider/provider_about_screen.dart';
import 'screens/onboarding/provider/provider_location_screen.dart';
import 'screens/onboarding/provider/business_hours_screen.dart';
import 'screens/onboarding/provider/services_manage_screen.dart';
import 'screens/onboarding/provider/service_add_screen.dart';
import 'screens/onboarding/provider/business_address_screen.dart';
import 'screens/onboarding/provider/team_size_screen.dart';
import 'screens/onboarding/provider/provider_email_screen.dart';
import 'screens/onboarding/provider/provider_password_screen.dart';
import 'screens/onboarding/provider/owner_worker_question_screen.dart';
import 'screens/onboarding/provider/owner_worker_setup_screen.dart';
import 'screens/onboarding/provider/congrats_screen.dart';

OnboardingData _extractOnboarding(Object? arg) {
  if (arg is OnboardingData) return arg;
  if (arg is Map && arg['onboarding'] is OnboardingData) {
    return arg['onboarding'] as OnboardingData;
  }
  throw ArgumentError(
      'Expected OnboardingData or {onboarding: OnboardingData}');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ln = context.watch<LocaleNotifier>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NavbatUz',
      locale: ln.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (_) => const LanguageSelectionScreen(),

        // Customers root
        '/customers': (_) => const NavRoot(),

        // Auth
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordRequestScreen(),
        '/search': (_) => const SearchScreen(),
        '/search-services': (_) => const SearchScreen(),
        '/providers-list': (context) {
          final args =
              (ModalRoute.of(context)!.settings.arguments as Map?) ?? const {};
          final filter = args['filter']?.toString();
          final categoryId = args['categoryId']?.toString();
          return ProvidersListScreen(filter: filter, categoryId: categoryId);
        },
        '/provider': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return ProviderScreen(providerId: id);
        },

// Other flows you navigate to
        '/customer-appointments': (_) => const AppointmentsScreen(),
// '/test-customer-home': (_) => FoodAppHomeScreen1(), // if used

        // Providers root (→ ProviderNavRoot)
        '/providers': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          String? providerId;
          if (args is String) {
            providerId = args;
          } else if (args is Map && args['providerId'] is String) {
            providerId = args['providerId'] as String;
          }
          return ProviderNavRoot(providerId: providerId);
        },

        // Workers root
        '/workers': (context) {
          final args =
              (ModalRoute.of(context)!.settings.arguments as Map?) ?? const {};
          final workerId = (args['workerId'] ?? '') as String;
          return WorkerNavRoot(workerId: workerId);
        },
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding/provider/category':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProviderCategoryScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/about':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProviderAboutScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/location':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProviderBusinessLocationScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/hours':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BusinessHoursScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/services':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ServicesManageScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/service/add':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ServiceAddScreen(
                lang: (settings.arguments as String?) ?? 'en',
              ),
            );
          case '/onboarding/provider/address':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BusinessAddressScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/team-size':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => TeamSizeScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/email':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProviderEmailScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/set-password':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => ProviderSetPasswordScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/owner-worker':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => OwnerWorkerQuestionScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/owner-setup':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => OwnerWorkerInfoScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
          case '/onboarding/provider/congrats':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => OnboardingCongratsScreen(
                onboardingData: _extractOnboarding(settings.arguments),
              ),
            );
        }
        return null;
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Routing error')),
          body: Center(child: Text('Unknown route: ${settings.name}')),
        ),
      ),
    );
  }
}
