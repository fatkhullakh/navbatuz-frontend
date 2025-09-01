import 'package:flutter/material.dart';
import 'package:frontend/models/service_draft.dart';
import '../../../models/onboarding_data.dart';
import '../onboarding_ui.dart';
import 'service_add_screen.dart';

class ServicesManageScreen extends StatefulWidget {
  final OnboardingData onboardingData;
  const ServicesManageScreen({super.key, required this.onboardingData});

  @override
  State<ServicesManageScreen> createState() => _ServicesManageScreenState();
}

class _ServicesManageScreenState extends State<ServicesManageScreen> {
  String get lang => (widget.onboardingData.languageCode ?? 'en').toLowerCase();
  String get catCode =>
      (widget.onboardingData.providerCategoryCode ?? 'OTHER').toUpperCase();

  // --- Provider category -> default ServiceCategory for new items ---
  ServiceCategory get _defaultCategory {
    switch (catCode) {
      case 'BARBERSHOP':
        return ServiceCategory.BARBERSHOP;
      case 'DENTAL':
        return ServiceCategory.DENTAL;
      case 'CLINIC':
        return ServiceCategory.CLINIC;
      case 'SPA':
        return ServiceCategory.SPA;
      case 'GYM':
        return ServiceCategory.GYM;
      case 'NAIL_SALON':
        return ServiceCategory.NAIL_SALON;
      case 'BEAUTY_CLINIC':
        return ServiceCategory.BEAUTY_CLINIC;
      case 'BEAUTY_SALON':
        return ServiceCategory.BEAUTY_SALON;
      case 'TATTOO':
      case 'TATTOO_STUDIO':
        return ServiceCategory.TATTOO_STUDIO;
      case 'MASSAGE':
      case 'MASSAGE_CENTER':
        return ServiceCategory.MASSAGE_CENTER;
      case 'PHYSIO':
      case 'PHYSIOTHERAPY_CLINIC':
        return ServiceCategory.PHYSIOTHERAPY_CLINIC;
      case 'MAKEUP':
      case 'MAKEUP_STUDIO':
        return ServiceCategory.MAKEUP_STUDIO;
      default:
        return ServiceCategory.OTHER;
    }
  }

  // --- i18n for categories ---
  String catLabel(ServiceCategory c) {
    switch (lang) {
      case 'ru':
        return {
          ServiceCategory.BARBERSHOP: 'Барбершоп',
          ServiceCategory.DENTAL: 'Стоматология',
          ServiceCategory.CLINIC: 'Клиника',
          ServiceCategory.SPA: 'Спа',
          ServiceCategory.GYM: 'Фитнес/зал',
          ServiceCategory.NAIL_SALON: 'Ногтевой салон',
          ServiceCategory.BEAUTY_CLINIC: 'Косметология',
          ServiceCategory.BEAUTY_SALON: 'Салон красоты',
          ServiceCategory.TATTOO_STUDIO: 'Тату-студия',
          ServiceCategory.MASSAGE_CENTER: 'Массаж',
          ServiceCategory.PHYSIOTHERAPY_CLINIC: 'Физиотерапия',
          ServiceCategory.MAKEUP_STUDIO: 'Макияж',
          ServiceCategory.OTHER: 'Другое',
        }[c]!;
      case 'uz':
        return {
          ServiceCategory.BARBERSHOP: 'Barbershop',
          ServiceCategory.DENTAL: 'Stomatologiya',
          ServiceCategory.CLINIC: 'Klinika',
          ServiceCategory.SPA: 'Spa',
          ServiceCategory.GYM: 'Sport zali',
          ServiceCategory.NAIL_SALON: 'Manikyur saloni',
          ServiceCategory.BEAUTY_CLINIC: 'Goʻzallik klinikasi',
          ServiceCategory.BEAUTY_SALON: 'Goʻzallik saloni',
          ServiceCategory.TATTOO_STUDIO: 'Tatu studiyasi',
          ServiceCategory.MASSAGE_CENTER: 'Massaj markazi',
          ServiceCategory.PHYSIOTHERAPY_CLINIC: 'Fizioterapiya',
          ServiceCategory.MAKEUP_STUDIO: 'Vizaj studiyasi',
          ServiceCategory.OTHER: 'Boshqa',
        }[c]!;
      default:
        return {
          ServiceCategory.BARBERSHOP: 'Barbershop',
          ServiceCategory.DENTAL: 'Dental',
          ServiceCategory.CLINIC: 'Clinic',
          ServiceCategory.SPA: 'Spa',
          ServiceCategory.GYM: 'Gym',
          ServiceCategory.NAIL_SALON: 'Nail salon',
          ServiceCategory.BEAUTY_CLINIC: 'Beauty clinic',
          ServiceCategory.BEAUTY_SALON: 'Beauty salon',
          ServiceCategory.TATTOO_STUDIO: 'Tattoo studio',
          ServiceCategory.MASSAGE_CENTER: 'Massage center',
          ServiceCategory.PHYSIOTHERAPY_CLINIC: 'Physiotherapy',
          ServiceCategory.MAKEUP_STUDIO: 'Makeup studio',
          ServiceCategory.OTHER: 'Other',
        }[c]!;
    }
  }

  // ---- Templates with default descriptions (EN/RU/UZ) ----
  List<_SvcT> get _templates {
    final map = <String, List<_SvcT>>{
      'BARBERSHOP': [
        _SvcT(
          en: 'Men’s haircut',
          ru: 'Мужская стрижка',
          uz: 'Erkaklar sochi',
          dur: 45,
          price: 80000,
          cat: ServiceCategory.BARBERSHOP,
          den: 'Classic cut and styling.',
          dru: 'Классическая стрижка и укладка.',
          duz: 'Klassik soch olish va yasalish.',
        ),
        _SvcT(
          en: 'Beard trim',
          ru: 'Стрижка бороды',
          uz: 'Soqolni olish',
          dur: 20,
          price: 40000,
          cat: ServiceCategory.BARBERSHOP,
          den: 'Beard shaping and line-up.',
          dru: 'Оформление бороды и контуров.',
          duz: 'Soqol shakllantirish va kontur.',
        ),
        _SvcT(
          en: 'Haircut + beard',
          ru: 'Стрижка + борода',
          uz: 'Soch + soqol',
          dur: 60,
          price: 110000,
          cat: ServiceCategory.BARBERSHOP,
          den: 'Full combo service.',
          dru: 'Полный комплекс.',
          duz: 'To‘liq kombinatsiya xizmati.',
        ),
      ],
      'NAIL_SALON': [
        _SvcT(
          en: 'Manicure',
          ru: 'Маникюр',
          uz: 'Manikyur',
          dur: 60,
          price: 90000,
          cat: ServiceCategory.NAIL_SALON,
          den: 'Classic manicure with care.',
          dru: 'Классический маникюр с уходом.',
          duz: 'Klassik parvarishli manikyur.',
        ),
        _SvcT(
          en: 'Gel polish',
          ru: 'Гель-лак',
          uz: 'Gel lak',
          dur: 60,
          price: 120000,
          cat: ServiceCategory.NAIL_SALON,
          den: 'Gel coating, single color.',
          dru: 'Покрытие гелем, один цвет.',
          duz: 'Gel qoplama, bitta rang.',
        ),
      ],
      'DENTAL': [
        _SvcT(
          en: 'Consultation',
          ru: 'Консультация',
          uz: 'Konsultatsiya',
          dur: 20,
          price: 50000,
          cat: ServiceCategory.DENTAL,
          den: 'Initial oral exam and advice.',
          dru: 'Первичный осмотр и рекомендации.',
          duz: 'Dastlabki ko‘rik va tavsiyalar.',
        ),
        _SvcT(
          en: 'Teeth cleaning',
          ru: 'Гигиена (чистка)',
          uz: 'Tish tozalash',
          dur: 45,
          price: 200000,
          cat: ServiceCategory.DENTAL,
          den: 'Scaling + polishing.',
          dru: 'Снятие налёта и полировка.',
          duz: 'Tozalash va jilolash.',
        ),
      ],
      'SPA': [
        _SvcT(
          en: 'Relax massage',
          ru: 'Релакс массаж',
          uz: 'Relaks massaj',
          dur: 60,
          price: 180000,
          cat: ServiceCategory.SPA,
          den: 'Stress relief full-body.',
          dru: 'Расслабляющий массаж всего тела.',
          duz: 'Stressni kamaytiruvchi to‘liq massaj.',
        ),
      ],
      'MASSAGE': [
        _SvcT(
          en: 'Back massage',
          ru: 'Массаж спины',
          uz: 'Bel massaji',
          dur: 40,
          price: 120000,
          cat: ServiceCategory.MASSAGE_CENTER,
          den: 'Focused back relief.',
          dru: 'Снятие напряжения спины.',
          duz: 'Bel sohasida bo‘shashtirish.',
        ),
      ],
      'TATTOO': [
        _SvcT(
          en: 'Consult & sketch',
          ru: 'Консульт. и эскиз',
          uz: 'Konsult. va sketch',
          dur: 30,
          price: 100000,
          cat: ServiceCategory.TATTOO_STUDIO,
          den: 'Design discussion & draft.',
          dru: 'Обсуждение дизайна и эскиз.',
          duz: 'Dizayn va eskiz kelishuvi.',
        ),
      ],
      'CLINIC': [
        _SvcT(
          en: 'Doctor consult',
          ru: 'Приём врача',
          uz: 'Shifokor qabul',
          dur: 20,
          price: 70000,
          cat: ServiceCategory.CLINIC,
          den: 'General consultation.',
          dru: 'Общая консультация.',
          duz: 'Umumiy konsultatsiya.',
        ),
      ],
      'PHYSIO': [
        _SvcT(
          en: 'Physio session',
          ru: 'Физио-сеанс',
          uz: 'Fizio seans',
          dur: 45,
          price: 150000,
          cat: ServiceCategory.PHYSIOTHERAPY_CLINIC,
          den: 'Therapeutic session.',
          dru: 'Лечебный сеанс.',
          duz: 'Davolovchi seans.',
        ),
      ],
      'MAKEUP': [
        _SvcT(
          en: 'Day makeup',
          ru: 'Дневной макияж',
          uz: 'Kunduzgi makiyaj',
          dur: 60,
          price: 180000,
          cat: ServiceCategory.MAKEUP_STUDIO,
          den: 'Natural daytime look.',
          dru: 'Натуральный дневной образ.',
          duz: 'Tabiiy kunduzgi ko‘rinish.',
        ),
      ],
      'GYM': [
        _SvcT(
          en: 'Personal training',
          ru: 'Персональная тренировка',
          uz: 'Shaxsiy mashg‘ulot',
          dur: 60,
          price: 150000,
          cat: ServiceCategory.GYM,
          den: '1:1 guided workout.',
          dru: 'Персональное занятие.',
          duz: 'Murabbiy bilan 1:1.',
        ),
      ],
      'BEAUTY_CLINIC': [
        _SvcT(
          en: 'Facial cleansing',
          ru: 'Чистка лица',
          uz: 'Yuz tozalash',
          dur: 60,
          price: 200000,
          cat: ServiceCategory.BEAUTY_CLINIC,
          den: 'Deep pore cleansing.',
          dru: 'Глубокая чистка пор.',
          duz: 'Terlardagi chuqur tozalash.',
        ),
      ],
      'OTHER': [
        _SvcT(
          en: 'Consultation',
          ru: 'Консультация',
          uz: 'Konsultatsiya',
          dur: 20,
          price: 50000,
          cat: ServiceCategory.OTHER,
          den: 'Short consult.',
          dru: 'Короткая консультация.',
          duz: 'Qisqa konsultatsiya.',
        ),
      ],
    };

    final key = map.containsKey(catCode) ? catCode : 'OTHER';
    return map[key]!;
  }

  String _n(_SvcT t) => lang == 'ru' ? t.ru : (lang == 'uz' ? t.uz : t.en);
  String _d(_SvcT t) => lang == 'ru' ? t.dru : (lang == 'uz' ? t.duz : t.den);

  void _quickAdd(_SvcT t) {
    setState(() {
      widget.onboardingData.services.add(ServiceDraft(
        name: _n(t),
        durationMinutes: t.dur,
        price: t.price.toDouble(),
        category: t.cat,
        description: _d(t),
      ));
    });
  }

  Future<void> _addManual() async {
    final draft = await Navigator.push<ServiceDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceAddScreen(
          lang: lang,
          defaultCategory: _defaultCategory,
        ),
      ),
    );
    if (draft != null) {
      setState(() => widget.onboardingData.services.add(draft));
    }
  }

  Future<void> _editAt(int index) async {
    final existing = widget.onboardingData.services[index];
    final updated = await Navigator.push<ServiceDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceAddScreen(
          lang: lang,
          existing: existing,
          defaultCategory: existing.category,
        ),
      ),
    );
    if (updated != null) {
      setState(() => widget.onboardingData.services[index] = updated);
    }
  }

  void _finish() {
    Navigator.pushNamed(
      context,
      '/onboarding/provider/owner-worker',
      arguments: widget.onboardingData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.onboardingData.services;

    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: StepAppBar(
        stepLabel: tr(lang, 'Step 7 of 7', 'Шаг 7 из 7', '7-bosqich / 7'),
        progress: 1.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          H1(tr(
              lang, 'Add Services', 'Добавьте услуги', 'Xizmatlarni qo‘shing')),
          const SizedBox(height: 8),
          Sub(tr(
              lang,
              'You can add more later in Manage → Services.',
              'Вы сможете добавить позже в «Управление → Услуги».',
              'Keyinroq “Boshqaruv → Xizmatlar”da qo‘shishingiz mumkin.')),
          const SizedBox(height: 16),

          // Quick templates
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Brand.border),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr(lang, 'Quick add (recommended)', 'Быстрое добавление',
                        'Tez qo‘shish (tavsiya)'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: Brand.ink),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _templates.map((t) {
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Brand.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                        onPressed: () => _quickAdd(t),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_n(t),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('${t.dur} min • ${t.price} UZS',
                                style: const TextStyle(
                                    color: Brand.subtle, fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ]),
          ),

          const SizedBox(height: 16),

          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Brand.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.design_services_outlined, color: Brand.subtle),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(lang, 'No services yet', 'Пока нет услуг',
                        'Hali xizmat yo‘q'),
                    style: const TextStyle(color: Brand.subtle),
                  ),
                ),
              ]),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = list[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Brand.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(s.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${s.durationMinutes} min • ${s.price?.toStringAsFixed(0) ?? 0} UZS'),
                          const SizedBox(height: 2),
                          Text(catLabel(s.category),
                              style: const TextStyle(
                                  color: Brand.subtle, fontSize: 12)),
                          if ((s.description ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(s.description!,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip:
                                tr(lang, 'Edit', 'Редактировать', 'Tahrirlash'),
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editAt(i),
                          ),
                          IconButton(
                            tooltip: tr(lang, 'Delete', 'Удалить', 'O‘chirish'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() => list.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addManual,
                icon: const Icon(Icons.add),
                label: Text(tr(
                    lang, 'Add service', 'Добавить услугу', 'Xizmat qo‘shish')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _finish,
                child: Text(tr(lang, 'Finish', 'Готово', 'Tugatish')),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _SvcT {
  final String en, ru, uz;
  final String den, dru, duz; // descriptions
  final int dur; // minutes
  final int price; // UZS integer
  final ServiceCategory cat;
  _SvcT({
    required this.en,
    required this.ru,
    required this.uz,
    required this.dur,
    required this.price,
    required this.cat,
    required this.den,
    required this.dru,
    required this.duz,
  });
}
