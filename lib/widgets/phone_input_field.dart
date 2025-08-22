import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneCountry {
  final String iso2; // "UZ"
  final String name; // "Uzbekistan"
  final String dial; // "+998"
  final int nsnMin; // national significant number length min
  final int nsnMax; // max
  final String flag; // emoji flag
  final String? sample; // hint sample (optional)
  const PhoneCountry({
    required this.iso2,
    required this.name,
    required this.dial,
    required this.nsnMin,
    required this.nsnMax,
    required this.flag,
    this.sample,
  });
}

// Central Asia (+ neighbors: RU, TR). Tweak lengths if you want stricter rules by operator.
const kPhoneCountries = <PhoneCountry>[
  PhoneCountry(
      iso2: 'UZ',
      name: 'Uzbekistan',
      dial: '+998',
      nsnMin: 9,
      nsnMax: 9,
      flag: '🇺🇿',
      sample: '90 123 45 67'),
  PhoneCountry(
      iso2: 'KZ',
      name: 'Kazakhstan',
      dial: '+7',
      nsnMin: 10,
      nsnMax: 10,
      flag: '🇰🇿',
      sample: '701 234 56 78'),
  PhoneCountry(
      iso2: 'KG',
      name: 'Kyrgyzstan',
      dial: '+996',
      nsnMin: 9,
      nsnMax: 9,
      flag: '🇰🇬',
      sample: '700 123 456'),
  PhoneCountry(
      iso2: 'TJ',
      name: 'Tajikistan',
      dial: '+992',
      nsnMin: 9,
      nsnMax: 9,
      flag: '🇹🇯',
      sample: '92 123 4567'),
  PhoneCountry(
      iso2: 'TM',
      name: 'Turkmenistan',
      dial: '+993',
      nsnMin: 8,
      nsnMax: 8,
      flag: '🇹🇲',
      sample: '61 234 567'),
  PhoneCountry(
      iso2: 'RU',
      name: 'Russia',
      dial: '+7',
      nsnMin: 10,
      nsnMax: 10,
      flag: '🇷🇺',
      sample: '912 345 67 89'),
  PhoneCountry(
      iso2: 'TR',
      name: 'Türkiye',
      dial: '+90',
      nsnMin: 10,
      nsnMax: 10,
      flag: '🇹🇷',
      sample: '530 123 45 67'),
];

class PhoneInputValue {
  final PhoneCountry country;
  final String nsn; // digits only
  const PhoneInputValue({required this.country, required this.nsn});

  String get e164 => '${country.dial}$nsn';
  bool get isValid =>
      nsn.length >= country.nsnMin && nsn.length <= country.nsnMax;
}

class PhoneInputField extends StatefulWidget {
  final PhoneCountry? initialCountry;
  final String? initialNsn; // digits only
  final String label;
  final ValueChanged<PhoneInputValue>? onChanged;
  final String? Function(PhoneInputValue)? validator;

  const PhoneInputField({
    super.key,
    this.initialCountry,
    this.initialNsn,
    this.onChanged,
    this.validator,
    this.label = 'Phone',
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late PhoneCountry _country;
  late TextEditingController _ctrl;
  late List<TextInputFormatter> _formatters;

  @override
  void initState() {
    super.initState();
    _country = widget.initialCountry ?? kPhoneCountries.first;
    _ctrl = TextEditingController(text: _digitsOnly(widget.initialNsn ?? ''));
    _formatters = _mkFormatters(_country);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<TextInputFormatter> _mkFormatters(PhoneCountry c) => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(c.nsnMax),
      ];

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  void _emit() {
    widget.onChanged?.call(PhoneInputValue(country: _country, nsn: _ctrl.text));
  }

  String? _validate() {
    final v = PhoneInputValue(country: _country, nsn: _ctrl.text);
    if (widget.validator != null) return widget.validator!(v);
    if (!v.isValid) {
      return 'Enter ${_country.nsnMin}–${_country.nsnMax} digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hint = _country.sample ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Flexible(
              flex: 4,
              child: InkWell(
                onTap: () async {
                  final sel = await showModalBottomSheet<PhoneCountry>(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => ListView(
                      children: [
                        const SizedBox(height: 8),
                        for (final c in kPhoneCountries)
                          ListTile(
                            leading: Text(c.flag,
                                style: const TextStyle(fontSize: 20)),
                            title: Text(c.name),
                            subtitle: Text(c.dial),
                            onTap: () => Navigator.of(ctx).pop(c),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                  if (sel != null) {
                    setState(() {
                      _country = sel;
                      // re-limit length if needed
                      final now = _digitsOnly(_ctrl.text);
                      _ctrl.text = (now.length > sel.nsnMax)
                          ? now.substring(0, sel.nsnMax)
                          : now;
                      _formatters = _mkFormatters(sel);
                    });
                    _emit();
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  child: Row(
                    children: [
                      Text(_country.flag, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(_country.dial,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 10,
              child: TextFormField(
                controller: _ctrl,
                onChanged: (_) => _emit(),
                keyboardType: TextInputType.number,
                inputFormatters: _formatters,
                validator: (_) => _validate(),
                decoration: InputDecoration(
                  hintText: hint.isEmpty ? null : hint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
