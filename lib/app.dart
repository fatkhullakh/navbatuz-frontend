import 'package:flutter/material.dart';
import 'package:frontend/screens/onboarding/language_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/provider/provider_dashboard.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/test/test_customer_home.dart';
import 'navigation/nav_root.dart';
import 'screens/appointments/appointments_screen.dart';
import 'screens/auth/forgot_password_request_screen.dart';
import 'screens/providers/provider_screen.dart';

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
        '/customers': (context) => const NavRoot(),
        '/providers': (context) => const ProviderDashboard(),
        '/register': (context) => const RegisterScreen(),
        //'/change-password': (context) => ChangePasswordScreen(),
        '/test-customer-home': (context) => FoodAppHomeScreen1(),
        '/customer-appointments': (_) => const AppointmentsScreen(),
        '/forgot-password': (_) => const ForgotPasswordRequestScreen(),
        // '/forgot-password/verify' is pushed via MaterialPageRoute with email arg
        '/provider': (context) {
          final id = ModalRoute.of(context)!.settings.arguments as String;
          return ProviderScreen(providerId: id);
        },
        // '/service': (context) => ServiceDetailsScreen(...), // when ready
      },
    );
  }
}
