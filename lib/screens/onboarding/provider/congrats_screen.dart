import 'package:flutter/material.dart';
import 'package:frontend/models/onboarding_data.dart';
import 'package:frontend/screens/onboarding/onboarding_ui.dart';
import 'package:frontend/screens/onboarding/provider/onboarding_submitter.dart';

class OnboardingCongratsScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const OnboardingCongratsScreen({super.key, required this.onboardingData});

  @override
  State<OnboardingCongratsScreen> createState() =>
      _OnboardingCongratsScreenState();
}

class _OnboardingCongratsScreenState extends State<OnboardingCongratsScreen> {
  bool _busy = false;
  String? _error;

  String _genTempPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#';
    int seed = DateTime.now().microsecondsSinceEpoch % 9973;
    final b = StringBuffer();
    for (int i = 0; i < 10; i++) {
      seed = (seed * 131 + i) % chars.length;
      b.write(chars[seed]);
    }
    return b.toString();
  }

  Future<void> _finalize() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      OnboardingData d = widget.onboardingData;

      // Hard defaults for language/country/role
      d = d.copyWith(
        languageCode: (d.languageCode ?? 'en').toLowerCase(),
        countryIso2: (d.countryIso2 ?? 'UZ').toUpperCase(),
        role: 'OWNER',
      );

      // Merge owner-worker payload (from previous screen) so DOB+gender are present even if not a worker
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
        );
      }

      // Fallbacks for missing owner fields
      String ownerName = (d.ownerName ?? '').trim();
      String ownerSurname = (d.ownerSurname ?? '').trim();
      String ownerEmail = (d.ownerEmail ?? '').trim();

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

      d = d.copyWith(
        ownerName: ownerName,
        ownerSurname: ownerSurname,
        ownerEmail: ownerEmail,
      );

      // Ensure password (>= 6) but don't overwrite a set one
      if ((d.ownerPassword ?? '').trim().length < 6) {
        d = d.copyWith(ownerPassword: _genTempPassword());
      }

      // Submit the whole flow
      final result = await OnboardingSubmitter().submitAll(d);

      if (!mounted) return;

      // Navigate to provider home with the created provider id
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
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.check_circle,
                  size: 96, color: Color(0xFF34C759)),
              const SizedBox(height: 16),
              const H1('Success!'),
              const SizedBox(height: 8),
              const Sub(
                  'Tap Continue to finalize setup and open your dashboard.'),
              const Spacer(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _finalize,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
