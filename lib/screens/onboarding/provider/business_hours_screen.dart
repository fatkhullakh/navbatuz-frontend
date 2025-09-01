// lib/screens/onboarding/provider/business_hours_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';
import 'services_manage_screen.dart';

class BusinessHoursScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const BusinessHoursScreen({super.key, required this.onboardingData});

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  final _days = const [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY'
  ];
  late Map<String, _Day> _model;

  String get lang => (widget.onboardingData.languageCode ?? 'en').toLowerCase();

  @override
  void initState() {
    super.initState();
    _model = {
      for (final d in _days)
        d: _Day(open: d != 'SUNDAY', start: '10:00', end: '19:00')
    };
    final wh = widget.onboardingData.weeklyHours;
    if (wh != null) {
      for (final e in wh.entries) {
        if (!_days.contains(e.key)) continue;
        if (e.value == 'CLOSED') {
          _model[e.key] = _Day(open: false);
        } else {
          final parts = e.value.split('-');
          _model[e.key] = _Day(open: true, start: parts.first, end: parts.last);
        }
      }
    }
  }

  String dayLabel(String d) => switch (d) {
        'MONDAY' => tr(lang, 'Monday', 'Понедельник', 'Dushanba'),
        'TUESDAY' => tr(lang, 'Tuesday', 'Вторник', 'Seshanba'),
        'WEDNESDAY' => tr(lang, 'Wednesday', 'Среда', 'Chorshanba'),
        'THURSDAY' => tr(lang, 'Thursday', 'Четверг', 'Payshanba'),
        'FRIDAY' => tr(lang, 'Friday', 'Пятница', 'Juma'),
        'SATURDAY' => tr(lang, 'Saturday', 'Суббота', 'Shanba'),
        'SUNDAY' => tr(lang, 'Sunday', 'Воскресенье', 'Yakshanba'),
        _ => d,
      };

  // ---- Scrollable 24h picker (Cupertino wheel) ----
  Future<void> _pickTimeWheel(String day, bool isStart) async {
    final current = _model[day]!;
    final seed = (isStart ? current.start : current.end) ?? '10:00';
    final hour = int.tryParse(seed.split(':')[0]) ?? 10;
    final minute = int.tryParse(seed.split(':')[1]) ?? 0;
    DateTime temp = DateTime(2020, 1, 1, hour, minute);

    final done = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                // header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        isStart
                            ? tr(lang, 'Start time', 'Время начала',
                                'Boshlanish vaqti')
                            : tr(lang, 'End time', 'Время окончания',
                                'Tugash vaqti'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context, temp),
                        child: Text(tr(lang, 'Done', 'Готово', 'Tayyor')),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: temp,
                    onDateTimeChanged: (dt) => temp = dt,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (done != null) {
      final hh = done.hour.toString().padLeft(2, '0');
      final mm = done.minute.toString().padLeft(2, '0');
      final val = '$hh:$mm';
      setState(() {
        if (isStart) {
          _model[day]!.start = val;
        } else {
          _model[day]!.end = val;
        }
      });
    }
  }

  // ---- Quick actions ----
  void _copyMondayToAll() {
    final mon = _model['MONDAY']!;
    if (!mon.open || mon.start == null || mon.end == null) {
      _snack(tr(
          lang,
          'Set Monday start/end first.',
          'Сначала укажите время для понедельника.',
          'Avval dushanba uchun vaqtlarni kiriting.'));
      return;
    }
    setState(() {
      for (final d in _days) {
        _model[d] = _Day(open: true, start: mon.start, end: mon.end);
      }
    });
  }

  void _setMonFriDefault() {
    setState(() {
      for (final d in _days) {
        if (d == 'SATURDAY' || d == 'SUNDAY') {
          _model[d] = _Day(open: false);
        } else {
          _model[d] = _Day(open: true, start: '10:00', end: '20:00');
        }
      }
    });
  }

  bool _validate() {
    for (final d in _days) {
      final m = _model[d]!;
      if (m.open && (m.start == null || m.end == null)) return false;
    }
    return true;
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _timeDec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: const Icon(Icons.access_time),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.primary, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr(lang, 'Step 7 of 7', 'Шаг 7 из 7', '7-bosqich / 7'),
        progress: 7 / 7,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          H1(tr(lang, 'Your Business Hours', 'График работы', 'Ish vaqtlari')),
          const SizedBox(height: 8),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyMondayToAll,
                  icon: const Icon(Icons.copy_all),
                  label: Text(tr(lang, 'Copy Mon → All', 'Копир. Пн → все',
                      'Du → barcha')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _setMonFriDefault,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                      tr(lang, 'Mon–Fri 10–20', 'Пн–Пт 10–20', 'Du–Ju 10–20')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._days.map((d) {
            final m = _model[d]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Brand.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dayLabel(d),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      value: m.open,
                      activeColor: Brand.primary,
                      onChanged: (v) => setState(() => m.open = v),
                    ),
                    if (m.open)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTimeWheel(d, true),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _timeDec(
                                    tr(lang, 'Start', 'Начало', 'Boshlanish')),
                                child: Text(m.start ?? '—'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTimeWheel(d, false),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _timeDec(
                                    tr(lang, 'End', 'Окончание', 'Tugash')),
                                child: Text(m.end ?? '—'),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Brand.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (!_validate()) {
                  _snack(tr(
                      lang,
                      'Please set start and end for all open days.',
                      'Укажите время начала и окончания для всех открытых дней.',
                      'Ochiq kunlar uchun boshlanish va tugash vaqtlarini kiriting.'));
                  return;
                }
                widget.onboardingData.weeklyHours = {
                  for (final d in _days)
                    d: _model[d]!.open
                        ? '${_model[d]!.start}-${_model[d]!.end}'
                        : 'CLOSED'
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServicesManageScreen(
                        onboardingData: widget.onboardingData),
                  ),
                );
              },
              child: Text(tr(lang, 'Continue', 'Продолжить', 'Davom etish')),
            ),
          ),
        ],
      ),
    );
  }
}

class _Day {
  bool open;
  String? start;
  String? end;
  _Day({required this.open, this.start, this.end});

  TimeOfDay? timeOf(bool startFlag) {
    final s = startFlag ? start : end;
    if (s == null || !s.contains(':')) return null;
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }
}
