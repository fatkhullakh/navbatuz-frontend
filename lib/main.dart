// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/locale_notifier.dart';
import 'l10n/app_localizations.dart';
import 'navigation/nav_root.dart';
import 'screens/auth/login_screen.dart';

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
      },
      initialRoute: '/',
    );
  }
}
