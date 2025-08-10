import 'package:flutter/material.dart';
import 'package:frontend/screens/onboarding/language_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/provider/provider_dashboard.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/test/test_customer_home.dart';

// import 'screens/register_screen.dart';

class NavbatUzApp extends StatelessWidget {
  const NavbatUzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavbatUz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/login',
      routes: {
        '/onboarding': (context) => const LanguageSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/customers': (context) => const FoodAppHomeScreen(),
        '/providers': (context) => const ProviderDashboard(),
        '/register': (context) => const RegisterScreen(),
        '/change-password': (context) => ChangePasswordScreen(),
        '/test-customer-home': (context) => FoodAppHomeScreen1(),
      },
    );
  }
}
