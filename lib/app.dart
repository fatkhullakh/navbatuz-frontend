import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
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
        '/login': (context) => const LoginScreen(),
        //'/register': (context) => const RegisterScreen(),
      },
    );
  }
}
