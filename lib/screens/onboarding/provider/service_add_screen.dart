// lib/screens/onboarding/provider/service_add_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/service_draft.dart';
import '../onboarding_ui.dart';

class ServiceAddScreen extends StatefulWidget {
  final String lang;
  final ServiceDraft? existing; // edit mode if present
  final ServiceCategory? defaultCategory; // suggested category
  const ServiceAddScreen({
    super.key,
    required this.lang,
    this.existing,
    this.defaultCategory,
  });

  @override
  State<ServiceAddScreen> createState() => _ServiceAddScreenState();
}

class _ServiceAddScreenState extends State<ServiceAddScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();

  // Base slots + we’ll inject current duration if missing (for edit safety)
  final List<int> _baseDurations = const [
    15,
    20,
    25,
    30,
    40,
    45,
    50,
    60,
    75,
    90,
    120
  ];
  late List<int> _durations;
  late int _duration;
  late ServiceCategory _category;

  String get lang => widget.lang.toLowerCase();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _category = e?.category ?? widget.defaultCategory ?? ServiceCategory.OTHER;
    _duration = e?.durationMinutes ?? 60;
    _durations = (_baseDurations.toSet()..add(_duration)).toList()..sort();

    _name.text = e?.name ?? '';
    _price.text = (e?.price?.toStringAsFixed(0) ?? '');
    _desc.text = e?.description ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Brand.primary, width: 1.5),
        ),
      );

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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: Brand.surfaceSoft,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          isEdit
              ? tr(lang, 'Edit Service', 'Редактировать услугу',
                  'Xizmatni tahrirlash')
              : tr(lang, 'Add Service', 'Добавить услугу', 'Xizmat qo‘shish'),
          style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Brand.ink),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category
            DropdownButtonFormField<ServiceCategory>(
              value: _category,
              isExpanded: true,
              decoration:
                  _dec(tr(lang, 'Category *', 'Категория *', 'Kategoriya *')),
              items: ServiceCategory.values
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(catLabel(c))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
              validator: (v) => v == null
                  ? tr(lang, 'Required', 'Обязательно', 'Majburiy')
                  : null,
            ),
            const SizedBox(height: 12),

            // Name
            TextFormField(
              controller: _name,
              decoration: _dec(tr(lang, 'Service name *', 'Название услуги *',
                  'Xizmat nomi *')),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr(lang, 'Required', 'Обязательно', 'Majburiy')
                  : null,
            ),
            const SizedBox(height: 12),

            // Duration dropdown – safe for edit values
            DropdownButtonFormField<int>(
              value: _duration,
              isExpanded: true,
              items: _durations
                  .map((d) => DropdownMenuItem<int>(
                        value: d,
                        child: Text('$d ${tr(lang, "min", "мин", "daq")}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _duration = v ?? _duration),
              decoration:
                  _dec(tr(lang, 'Duration', 'Длительность', 'Davomiylik')),
            ),
            const SizedBox(height: 12),

            // Price (digits only)
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  _dec('${tr(lang, 'Price *', 'Цена *', 'Narx *')} (UZS)'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? tr(lang, 'Required', 'Обязательно', 'Majburiy')
                  : null,
            ),
            const SizedBox(height: 12),

            // Description (optional)
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: _dec(tr(lang, 'Description (optional)',
                  'Описание (необязательно)', 'Tavsif (ixtiyoriy)')),
            ),
            const SizedBox(height: 20),

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
                  if (!_form.currentState!.validate()) return;
                  final draft = ServiceDraft(
                    name: _name.text.trim(),
                    durationMinutes: _duration,
                    price: double.tryParse(_price.text.trim()) ?? 0.0,
                    category: _category,
                    description:
                        _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                  );
                  Navigator.pop(context, draft);
                },
                child: Text(isEdit
                    ? tr(lang, 'Save', 'Сохранить', 'Saqlash')
                    : tr(lang, 'Add', 'Добавить', 'Qo‘shish')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
