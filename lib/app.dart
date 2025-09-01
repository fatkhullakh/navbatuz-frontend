import 'package:flutter/material.dart';
import 'package:frontend/screens/search/search_screen.dart';

import 'models/onboarding_data.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/provider/business_address_screen.dart';
import 'screens/onboarding/provider/business_type_screen.dart';
import 'screens/onboarding/provider/congrats_screen.dart';
import 'screens/onboarding/provider/owner_worker_question_screen.dart';
import 'screens/onboarding/provider/owner_worker_setup_screen.dart';
import 'screens/onboarding/provider/provider_about_screen.dart';
import 'screens/onboarding/provider/provider_email_screen.dart';
import 'screens/onboarding/provider/provider_location_screen.dart';
import 'screens/onboarding/provider/provider_password_screen.dart';
import 'screens/onboarding/provider/team_size_screen.dart';

import 'navigation/provider_nav_root.dart';
import 'navigation/worker_nav_root.dart';
import 'navigation/nav_root.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_request_screen.dart';
import 'screens/test/test_customer_home.dart';
import 'screens/appointments/appointments_screen.dart';
import 'screens/providers/provider_screen.dart';
import 'screens/providers/providers_list_screen.dart';
import 'screens/search/universal_search_screen.dart';
import 'screens/search/service_search_screen.dart';

import 'screens/onboarding/provider/business_hours_screen.dart';
import 'screens/onboarding/provider/services_manage_screen.dart';
import 'screens/onboarding/provider/service_add_screen.dart';

OnboardingData _extractOnboarding(Object? arg) {
  if (arg is OnboardingData) return arg;
  if (arg is Map && arg['onboarding'] is OnboardingData) {
    return arg['onboarding'] as OnboardingData;
  }
  throw ArgumentError(
      'Expected OnboardingData or {onboarding: OnboardingData}');
}

class NavbatUzApp extends StatelessWidget {
  const NavbatUzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavbatUz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const LanguageSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordRequestScreen(),

        '/customers': (context) => const NavRoot(),

        // Providers root → ProviderNavRoot(providerId)
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

        // Misc/customer flows
        '/test-customer-home': (context) => FoodAppHomeScreen1(),
        '/customer-appointments': (_) => const AppointmentsScreen(),
        '/provider': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return ProviderScreen(providerId: id);
        },
        '/providers-list': (context) {
          final args =
              (ModalRoute.of(context)!.settings.arguments as Map?) ?? const {};
          final filter = args['filter']?.toString();
          final categoryId = args['categoryId']?.toString();
          return ProvidersListScreen(filter: filter, categoryId: categoryId);
        },
        '/search': (context) => const SearchScreen(),
        '/search-services': (context) => const SearchScreen(),
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
