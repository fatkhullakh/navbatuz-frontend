// lib/screens/onboarding/role_screen.dart
import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';
import 'onboarding_ui.dart';
import 'provider/business_type_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final OnboardingData onboardingData;
  const RoleSelectionScreen({super.key, required this.onboardingData});

  void _goCustomer(BuildContext context) {
    onboardingData.role = 'CUSTOMER';
    Navigator.pushNamed(context, '/register', arguments: onboardingData);
  }

  void _goWorker(BuildContext context) {
    onboardingData.role = 'WORKER';
    Navigator.pushNamed(context, '/login', arguments: {'fromOnboarding': true});
  }

  void _goProvider(BuildContext context) {
    onboardingData.role = 'OWNER';
    Navigator.pushNamed(
      context,
      '/onboarding/provider/email',
      arguments: onboardingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = onboardingData.languageCode ?? 'en';
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr(lang, 'Step 5 of 5', 'Шаг 5 из 5', '5-bosqich / 5'),
        progress: 1.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            H1(tr(lang, 'Who are you?', 'Кто вы?', 'Siz kimsiz?')),
            const SizedBox(height: 8),
            Sub(tr(
              lang,
              'We’ll tailor the app based on your role.',
              'Мы настроим приложение под вашу роль.',
              'Ilovani rolingizga moslaymiz.',
            )),
            const SizedBox(height: 24),

            // Customer
            OptionCard(
              icon: Icons.person,
              title: tr(lang, "I'm a Customer", 'Я — клиент', 'Men mijozman'),
              subtitle: tr(
                lang,
                'Book appointments with salons, clinics, gyms, and more.',
                'Записывайтесь в салоны, клиники, фитнес и др.',
                'Salon, klinika, fitnes va boshqalarga yoziling.',
              ),
              onTap: () => _goCustomer(context),
            ),
            const SizedBox(height: 14),

            // Provider
            OptionCard(
              icon: Icons.storefront,
              iconBg: Colors.orange.withOpacity(.15),
              iconColor: Colors.deepOrange,
              title: tr(lang, "I'm a Service Provider", 'Я — владелец бизнеса',
                  'Men xizmat ko‘rsatuvchiman'),
              subtitle: tr(
                lang,
                'Manage schedule, staff, and bookings for your business.',
                'Управляйте расписанием, персоналом и записями.',
                'Jadval, xodimlar va bronlarni boshqaring.',
              ),
              onTap: () => _goProvider(context),
            ),
            const SizedBox(height: 14),

            // Worker
            OptionCard(
              icon: Icons.badge_outlined,
              iconBg: Colors.teal.withOpacity(.15),
              iconColor: Colors.teal,
              title: tr(lang, "I'm a Worker", 'Я — сотрудник', 'Men xodimman'),
              subtitle: tr(
                lang,
                'Sign in with credentials your employer sent you.',
                'Войдите по данным, отправленным работодателем.',
                'Ish beruvchingiz yuborgan ma’lumotlar bilan kiring.',
              ),
              onTap: () => _goWorker(context),
            ),
          ],
        ),
      ),
    );
  }
}
