// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/locale_notifier.dart';
import 'l10n/app_localizations.dart';
import 'navigation/nav_root.dart';
import 'screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_request_screen.dart';
import 'screens/auth/forgot_password_reset_screen.dart';
import 'screens/onboarding/language_screen.dart';
import 'navigation/provider_nav_root.dart';
import 'navigation/worker_nav_root.dart';

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
      locale: ln.locale, // ← switches when you call setLocaleByBackend(...)
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(useMaterial3: true),
      routes: {
        '/': (_) => const LoginScreen(), // or a splash/guard
        '/customers': (_) => const NavRoot(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordRequestScreen(),
        '/providers': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          // Accept either a String id or a map like {'providerId': '...'}
          String? providerId;
          if (args is String) {
            providerId = args;
          } else if (args is Map && args['providerId'] is String) {
            providerId = args['providerId'] as String;
          }
          return ProviderNavRoot(providerId: providerId); // nullable is OK now
        },
        '/workers': (context) => const WorkerNavRoot(),
      },
      initialRoute: '/',
    );
  }
}
