// lib/navbat_uz_app.dart  (your existing file; showing only the routes map)
import 'package:flutter/material.dart';
import 'package:frontend/screens/onboarding/language_screen.dart';
import 'package:frontend/screens/search/universal_search_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/provider/provider_dashboard.dart';
import 'screens/auth/register_screen.dart';
import 'screens/test/test_customer_home.dart';
import 'navigation/nav_root.dart';
import 'screens/appointments/appointments_screen.dart';
import 'screens/auth/forgot_password_request_screen.dart';
import 'screens/providers/provider_screen.dart';
import 'screens/providers/providers_list_screen.dart';
import 'screens/search/service_search_screen.dart'; // <-- ADD

class NavbatUzApp extends StatelessWidget {
  const NavbatUzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavbatUz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      initialRoute: '/login',
      routes: {
        '/onboarding': (context) => const LanguageSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/customers': (context) => const NavRoot(),
        '/providers': (context) => const ProviderDashboard(),
        '/register': (context) => const RegisterScreen(),
        '/test-customer-home': (context) => FoodAppHomeScreen1(),
        '/customer-appointments': (_) => const AppointmentsScreen(),
        '/forgot-password': (_) => const ForgotPasswordRequestScreen(),
        '/provider': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return ProviderScreen(providerId: id);
        },
        '/providers-list': (context) {
          final args =
              (ModalRoute.of(context)!.settings.arguments as Map?) ?? {};
          final filter = args['filter']?.toString();
          final categoryId = args['categoryId']?.toString();
          return ProvidersListScreen(filter: filter, categoryId: categoryId);
        },

        '/search': (context) => const UniversalSearchScreen(),

        // NEW search route
        '/search-services': (context) => const ServiceSearchScreen(),
      },
    );
  }
}
