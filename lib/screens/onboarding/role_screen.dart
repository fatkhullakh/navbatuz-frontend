import 'package:flutter/material.dart';
import '../../models/onboarding_data.dart';

class RoleSelectionScreen extends StatelessWidget {
  final OnboardingData onboardingData;
  const RoleSelectionScreen({super.key, required this.onboardingData});

  void finishOnboarding(BuildContext context, String role) {
    onboardingData.role = role;
    Navigator.pushNamed(context, '/register', arguments: onboardingData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Brand.surfaceSoft,
      appBar: _StepAppBar(stepLabel: 'Step 5 of 5', progress: 1.0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _H1('Who are you?'),
            const SizedBox(height: 8),
            const _Sub('We’ll tailor the app based on your role.'),
            const SizedBox(height: 24),
            _RoleCard(
              color: _Brand.primary,
              icon: Icons.person,
              title: "I'm a Customer",
              subtitle:
                  'Book appointments with salons, clinics, gyms, and more.',
              onTap: () => finishOnboarding(context, 'CUSTOMER'),
            ),
            const SizedBox(height: 14),
            _RoleCard(
              color: Colors.deepOrange,
              icon: Icons.storefront,
              title: "I'm a Service Provider",
              subtitle:
                  'Manage schedule, staff, and bookings for your business.',
              onTap: () => finishOnboarding(context, 'PROVIDER_OWNER'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------- UI Helpers ------------------------------ */
class _Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class _RoleCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RoleCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _Brand.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Brand.border),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _Brand.ink)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(color: _Brand.subtle)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _Brand.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stepLabel;
  final double progress;
  const _StepAppBar({required this.stepLabel, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(stepLabel,
          style: const TextStyle(color: _Brand.subtle, fontSize: 16)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: _Brand.border,
          valueColor: const AlwaysStoppedAnimation<Color>(_Brand.primary),
          minHeight: 4,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _H1 extends StatelessWidget {
  final String text;
  const _H1(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w800, color: _Brand.ink));
}

class _Sub extends StatelessWidget {
  final String text;
  const _Sub(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14, color: _Brand.subtle));
}
