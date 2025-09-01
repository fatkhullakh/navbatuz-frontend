// lib/screens/onboarding/provider/owner_worker_question_screen.dart
import 'package:flutter/material.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';
import 'owner_worker_setup_screen.dart';

class OwnerWorkerQuestionScreen extends StatelessWidget {
  final OnboardingData onboardingData;
  const OwnerWorkerQuestionScreen({super.key, required this.onboardingData});

  String get lang => (onboardingData.languageCode ?? 'en').toLowerCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr(lang, 'Final step', 'Финальный шаг', 'Yakuniy bosqich'),
        progress: 1.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            H1(tr(lang, 'Are you also a worker?', 'Вы тоже мастер/специалист?',
                'Siz ham usta/mutaxassismisiz?')),
            const SizedBox(height: 8),
            Sub(tr(
              lang,
              'If yes, we’ll add you as a staff member. Your services and hours will be copied.',
              'Если да, добавим вас как сотрудника. Услуги и часы скопируем.',
              'Ha bo‘lsa, sizni xodim sifatida qo‘shamiz. Xizmatlar va ish vaqtlari ko‘chiriladi.',
            )),
            const Spacer(),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerWorkerInfoScreen(
                        onboardingData: onboardingData,
                      ),
                      settings: RouteSettings(arguments: {
                        'asWorker': true, // ← YES path
                      }),
                    ),
                  );
                },
                child: Text(tr(lang, 'Yes, I’m also a worker',
                    'Да, я тоже работаю', 'Ha, men ham ishlayman')),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Brand.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  // IMPORTANT: still collect personal info (DOB + gender),
                  // just don’t create a worker later.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OwnerWorkerInfoScreen(
                        onboardingData: onboardingData,
                      ),
                      settings: const RouteSettings(arguments: {
                        'asWorker': false, // ← NO path, but same form
                      }),
                    ),
                  );
                },
                child: Text(
                  tr(lang, 'No, continue', 'Нет, продолжить',
                      'Yo‘q, davom etish'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
