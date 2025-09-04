import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/onboarding_data.dart';
import 'package:frontend/screens/onboarding/onboarding_ui.dart';
import 'package:frontend/screens/onboarding/provider/onboarding_submitter.dart';

/// Toned-down, brand-aligned “Congrats” screen
/// - Uses your palette (Brand.primary, border, surfaceSoft)
/// - Subtle animated gradient + gentle sparkles (no flashy confetti)
/// - Glassy card with small motion + haptic on continue
/// - Keeps ALL original logic intact
class OnboardingCongratsScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const OnboardingCongratsScreen({super.key, required this.onboardingData});

  @override
  State<OnboardingCongratsScreen> createState() =>
      _OnboardingCongratsScreenState();
}

class _OnboardingCongratsScreenState extends State<OnboardingCongratsScreen>
    with TickerProviderStateMixin {
  bool _busy = false;
  String? _error;

  // i18n
  String get _lang =>
      (widget.onboardingData.languageCode ?? 'en').toLowerCase();
  String _t(String en, String ru, String uz) =>
      _lang == 'ru' ? ru : (_lang == 'uz' ? uz : en);

  // Animations (subtle)
  late final AnimationController _bgCtrl; // slow gradient drift
  late final AnimationController _pulseCtrl; // soft pulse on emblem
  late final AnimationController _sparkCtrl; // tiny floating sparkles

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _sparkCtrl.dispose();
    super.dispose();
  }

  Future<void> _finalize() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      OnboardingData d = widget.onboardingData;

      // safe defaults (unchanged logic)
      d = d.copyWith(
        languageCode: (d.languageCode ?? 'ru').toLowerCase(),
        countryIso2: (d.countryIso2 ?? 'UZ').toUpperCase(),
        role: 'OWNER',
      );

      // pull merged data passed as route arguments (if any) — unchanged
      final args =
          (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
      final ownerWorker = args['ownerWorker'] as Map<String, dynamic>?;

      if (ownerWorker != null) {
        d = d.copyWith(
          ownerName: d.ownerName ?? ownerWorker['firstName']?.toString(),
          ownerSurname: d.ownerSurname ?? ownerWorker['lastName']?.toString(),
          ownerEmail: d.ownerEmail ?? ownerWorker['email']?.toString(),
          ownerPhoneDialCode:
              d.ownerPhoneDialCode ?? ownerWorker['phoneDial']?.toString(),
          ownerPhoneNumber:
              d.ownerPhoneNumber ?? ownerWorker['phoneLocal']?.toString(),
          ownerPhoneE164:
              d.ownerPhoneE164 ?? ownerWorker['phoneE164']?.toString(),
          ownerWorkerType: d.ownerWorkerType ?? ownerWorker['type']?.toString(),
          ownerDateOfBirth:
              d.ownerDateOfBirth ?? ownerWorker['dob']?.toString(),
          ownerGender: d.ownerGender ?? ownerWorker['gender']?.toString(),
          ownerAlsoWorker: d.ownerAlsoWorker ?? true,
          ownerWorkerWeeklyHours: d.ownerWorkerWeeklyHours ?? d.weeklyHours,
        );
      }

      // Basic fallbacks — unchanged
      String ownerName = (d.ownerName ?? '').trim();
      String ownerSurname = (d.ownerSurname ?? '').trim();
      String ownerEmail = (d.ownerEmail ?? '').trim();
      String? ownerPhone = (d.ownerPhoneE164 ?? '').trim();

      if (ownerName.isEmpty || ownerSurname.isEmpty) {
        final bn = (d.businessName ?? '').trim();
        if (bn.isNotEmpty) {
          final parts = bn.split(RegExp(r'\s+'));
          ownerName = ownerName.isEmpty ? parts.first : ownerName;
          ownerSurname = ownerSurname.isEmpty
              ? (parts.length > 1 ? parts.sublist(1).join(' ') : 'Owner')
              : ownerSurname;
        } else {
          ownerName = ownerName.isEmpty ? 'Business' : ownerName;
          ownerSurname = ownerSurname.isEmpty ? 'Owner' : ownerSurname;
        }
      }
      if (ownerEmail.isEmpty && (d.businessEmail ?? '').trim().isNotEmpty) {
        ownerEmail = d.businessEmail!.trim();
      }

      String _composeE164(String? dial, String? local) {
        final dcode = (dial ?? '').trim();
        final localDigits = (local ?? '').replaceAll(RegExp(r'[^0-9]'), '');
        if (localDigits.isEmpty) return '';
        final pref =
            dcode.isEmpty ? '+' : (dcode.startsWith('+') ? dcode : '+$dcode');
        return (pref + localDigits).replaceAll(RegExp(r'[^0-9\+]'), '');
      }

      if ((ownerPhone).isEmpty) {
        ownerPhone =
            _composeE164(d.businessPhoneDialCode, d.businessPhoneNumber);
      }

      // keep password as set earlier — unchanged
      if ((d.ownerPassword ?? '').trim().isEmpty) {
        throw StateError('Password is missing. Please set a password.');
      }

      d = d.copyWith(
        ownerName: ownerName,
        ownerSurname: ownerSurname,
        ownerEmail: ownerEmail,
        ownerPhoneE164: ownerPhone.isEmpty ? null : ownerPhone,
      );

      final result = await OnboardingSubmitter().submitAll(d);

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/providers',
        (route) => false,
        arguments: {'providerId': result.providerId},
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headline = _t('All set!', 'Готово!', 'Hammasi tayyor!');
    final subtitle = _t(
      'Tap Continue to finalize setup and open your dashboard.',
      'Нажмите «Продолжить», чтобы завершить настройку и открыть панель.',
      'Sozlashni yakunlash va boshqaruv panelini ochish uchun «Davom etish»ni bosing.',
    );
    final cta = _t('Continue', 'Продолжить', 'Davom etish');

    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      body: Stack(
        children: [
          // Brand gradient (very subtle motion)
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              final t = _bgCtrl.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.6 + t * 0.2, -1),
                    end: Alignment(1, 0.9 - t * 0.2),
                    colors: [
                      // Use your palette family
                      Color.lerp(Brand.surfaceSoft, Brand.border, 0.0)!,
                      Color.lerp(
                          Brand.border, Brand.primary.withOpacity(.08), 0.6)!,
                      Color.lerp(Brand.surfaceSoft,
                          Brand.primary.withOpacity(.10), 0.9)!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Soft sparkle dust using brand hues
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _sparkCtrl,
              builder: (_, __) => CustomPaint(
                painter: _SparklePainter(
                  progress: _sparkCtrl.value,
                  baseColor: Brand.primary,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      const Spacer(),

                      // Glass card with subtle elevation
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Brand.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 20,
                                  spreadRadius: -4,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Brand emblem (check) with gentle pulse
                                AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (_, __) {
                                    final s = 1.0 +
                                        math.sin(_pulseCtrl.value *
                                                math.pi *
                                                2) *
                                            0.03;
                                    return Transform.scale(
                                      scale: s,
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Brand.primary,
                                              Brand.primary.withOpacity(.85),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Brand.primary
                                                  .withOpacity(.28),
                                              blurRadius: 20,
                                              spreadRadius: 1,
                                            )
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          size: 46,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Headline
                                Text(
                                  headline,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .2,
                                    color: Brand.ink,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Subtitle
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Brand.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        _ErrorBanner(text: _error!),
                        const SizedBox(height: 10),
                      ],

                      // CTA (brand button with soft glow)
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: _BrandButton(
                          busy: _busy,
                          label: cta,
                          onPressed: _busy ? null : _finalize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- UI Helpers ----------------------------- */

class _BrandButton extends StatefulWidget {
  final bool busy;
  final String label;
  final VoidCallback? onPressed;
  const _BrandButton({
    required this.busy,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_BrandButton> createState() => _BrandButtonState();
}

class _BrandButtonState extends State<_BrandButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 - t * 2, 0),
              colors: [
                Brand.primary.withOpacity(.95),
                Brand.primary,
                Brand.primary.withOpacity(.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Brand.primary.withOpacity(.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: widget.onPressed,
            child: widget.busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDEE),
        border: Border.all(color: const Color(0xFFFFD5D8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFB00020),
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/* ---------------------------- Painters ---------------------------- */

class _SparklePainter extends CustomPainter {
  final double progress; // 0..1
  final Color baseColor;
  _SparklePainter({required this.progress, required this.baseColor});

  // pre-seeded points for deterministic layout
  static final _pts = List.generate(28, (i) {
    final rnd = math.Random(i * 77);
    return _Pt(
      anchor: Offset(rnd.nextDouble(), rnd.nextDouble()),
      radius: 1.5 + rnd.nextDouble() * 2.2,
      driftX: (rnd.nextDouble() * 2 - 1) * 0.02,
      driftY: (rnd.nextDouble() * 2 - 1) * 0.02,
      phase: rnd.nextDouble() * math.pi * 2,
      alpha: 0.18 + rnd.nextDouble() * 0.12,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.srcOver;
    for (final p in _pts) {
      final x = (p.anchor.dx +
              p.driftX * math.sin(progress * math.pi * 2 + p.phase)) %
          1.2;
      final y = (p.anchor.dy +
              p.driftY * math.cos(progress * math.pi * 2 + p.phase)) %
          1.2;
      final c = Offset((x - 0.1) * size.width, (y - 0.1) * size.height);

      paint
        ..color = baseColor.withOpacity(p.alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(c, p.radius * 1.6, paint);

      paint
        ..color = Colors.white.withOpacity(p.alpha * .8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(c, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.baseColor != baseColor;
}

class _Pt {
  final Offset anchor;
  final double radius;
  final double driftX, driftY;
  final double phase;
  final double alpha;
  _Pt({
    required this.anchor,
    required this.radius,
    required this.driftX,
    required this.driftY,
    required this.phase,
    required this.alpha,
  });
}
