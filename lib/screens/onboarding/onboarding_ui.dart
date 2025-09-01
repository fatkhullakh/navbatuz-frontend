// lib/screens/onboarding/onboarding_ui.dart
import 'package:flutter/material.dart';

class Brand {
  static const primary = Color(0xFF6A89A7);
  static const accentSoft = Color(0xFFBDDDFC);
  static const ink = Color(0xFF384959);
  static const border = Color(0xFFE6ECF2);
  static const subtle = Color(0xFF7C8B9B);
  static const surfaceSoft = Color(0xFFF6F9FC);
}

class StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stepLabel;
  final double progress;
  const StepAppBar(
      {super.key, required this.stepLabel, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(stepLabel,
          style: const TextStyle(color: Brand.subtle, fontSize: 16)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Brand.border,
          valueColor: const AlwaysStoppedAnimation<Color>(Brand.primary),
          minHeight: 4,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconBg;
  final Color? iconColor;
  final VoidCallback onTap;
  const OptionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.iconBg,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
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
                  color: (iconBg ?? Brand.accentSoft),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Brand.border),
                ),
                child: Icon(icon, color: iconColor ?? Brand.primary, size: 28),
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
                            color: Brand.ink)),
                    if ((subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: const TextStyle(color: Brand.subtle)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Brand.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class H1 extends StatelessWidget {
  final String text;
  const H1(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: Brand.ink),
      );
}

class Sub extends StatelessWidget {
  final String text;
  const Sub(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 14, color: Brand.subtle));
}

/// Very small i18n helper for onboarding texts
String tr(String lang, String en, String ru, [String? uz]) {
  final l = (lang).toLowerCase();
  if (l == 'ru') return ru;
  if (l == 'uz' && uz != null) return uz;
  return en;
}
