import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/api_service.dart';
import '../../../../services/media/upload_service.dart';
import '../../../../services/providers/provider_staff_service.dart';

class ProviderWorkerInviteScreen extends StatefulWidget {
  final String providerId;
  const ProviderWorkerInviteScreen({super.key, required this.providerId});

  @override
  State<ProviderWorkerInviteScreen> createState() =>
      _ProviderWorkerInviteScreenState();
}

class _ProviderWorkerInviteScreenState
    extends State<ProviderWorkerInviteScreen> {
  final _dio = ApiService.client;
  final _uploads = UploadService();
  final _svc = ProviderStaffService();

  // step 1: personal
  final _name = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  String? _avatarUrl;
  final _role = TextEditingController(
      text: 'WORKER'); // e.g. BARBER depending on provider category
  final _form1 = GlobalKey<FormState>();

  // step 2: services
  bool _loadingServices = true;
  final List<_Svc> _all = [];
  final Set<String> _selected = {};

  // step 3: planned availability
  final _days = <_Planned>[
    _Planned('MONDAY'),
    _Planned('TUESDAY'),
    _Planned('WEDNESDAY'),
    _Planned('THURSDAY'),
    _Planned('FRIDAY'),
    _Planned('SATURDAY'),
    _Planned('SUNDAY'),
  ];

  bool _submitting = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      final rAll =
          await _dio.get('/services/provider/all/${widget.providerId}');
      final list = (rAll.data as List?) ?? [];
      _all
        ..clear()
        ..addAll(list.whereType<Map>().map((m0) {
          final m = m0.cast<String, dynamic>();
          return _Svc(
            id: (m['id'] ?? '').toString(),
            name: (m['name'] ?? '').toString(),
            isActive: (m['isActive'] ?? true) == true,
          );
        }))
        ..sort((a, b) => a.name.compareTo(b.name));
    } finally {
      if (mounted) setState(() => _loadingServices = false);
    }
  }

  Future<void> _pickAvatar() async {
    final up =
        await _uploads.pickAndUpload(scope: UploadScope.user, ownerId: 'temp');
    if (up == null) return;
    setState(() => _avatarUrl = ApiService.normalizeMediaUrl(up.url) ?? up.url);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final t = AppLocalizations.of(context)!;

    if (_step == 0 && !(_form1.currentState?.validate() ?? false)) return;

    if (_step < 2) {
      setState(() => _step += 1);
      return;
    }

    setState(() => _submitting = true);
    try {
      // Aggregate payload to one endpoint.
      final req = InviteWorkerRequest(
        providerId: widget.providerId,
        workerType: _role.text.trim(),
        user: NewUser(
          name: _name.text.trim(),
          surname: _surname.text.trim(),
          email: _email.text.trim(),
          phoneNumber: _phone.text.trim(),
          avatarUrl: _avatarUrl,
        ),
        serviceIds: _selected.toList(),
        planned: _days
            .where((d) => d.working && d.start != null && d.end != null)
            .map((d) => PlannedDay(
                day: d.day, start: d.start, end: d.end, working: true))
            .toList(),
      );

      // Adjust URL if your backend picks a different path.
      await _svc.inviteAndRegister(req);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invite_sent ?? 'Invitation sent')),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final body = e.response?.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed ($code): $body')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.invite_worker_title ?? 'Invite worker')),
      body: Stepper(
        currentStep: _step,
        type: StepperType.vertical,
        onStepCancel: _step == 0 ? null : () => setState(() => _step -= 1),
        onStepContinue: _submit,
        controlsBuilder: (ctx, details) => Row(
          children: [
            FilledButton(
                onPressed: _submitting ? null : details.onStepContinue,
                child: Text(_step < 2
                    ? (t.next ?? 'Next')
                    : (t.create_send_invite ?? 'Create & send invite'))),
            const SizedBox(width: 8),
            if (_step > 0)
              OutlinedButton(
                  onPressed: details.onStepCancel,
                  child: Text(t.back ?? 'Back')),
          ],
        ),
        steps: [
          Step(
            title: Text(t.personal_info ?? 'Personal info'),
            isActive: _step >= 0,
            content: Form(
              key: _form1,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFF2F4F7),
                        backgroundImage: (_avatarUrl ?? '').isEmpty
                            ? null
                            : NetworkImage(_avatarUrl!),
                        child: (_avatarUrl ?? '').isEmpty
                            ? const Icon(Icons.person_outline)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: Text(t.upload_avatar ?? 'Upload avatar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                        labelText: t.first_name ?? 'First name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (t.required ?? 'Required')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _surname,
                    decoration:
                        InputDecoration(labelText: t.last_name ?? 'Last name'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (t.required ?? 'Required')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: t.email ?? 'Email'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return t.required ?? 'Required';
                      final ok =
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);
                      return ok ? null : (t.invalid_email ?? 'Invalid email');
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: t.phone ?? 'Phone'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (t.required ?? 'Required')
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _role,
                    decoration: const InputDecoration(labelText: 'Worker type'),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: Text(t.services_title ?? 'Services'),
            isActive: _step >= 1,
            content: _loadingServices
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator())
                : Column(
                    children: _all.map((s) {
                      final checked = _selected.contains(s.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(s.id);
                          } else {
                            _selected.remove(s.id);
                          }
                        }),
                        title: Text(s.name, overflow: TextOverflow.ellipsis),
                        subtitle:
                            s.isActive ? null : const Text('Service inactive'),
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    }).toList(),
                  ),
          ),
          Step(
            title: Text(t.working_hours ?? 'Working hours'),
            isActive: _step >= 2,
            content: Column(
              children: _days
                  .map((d) => Card(
                        elevation: 0,
                        child: ListTile(
                          title: Text(_localizeDay(context, d.day)),
                          subtitle: Text(d.working
                              ? ((d.start != null && d.end != null)
                                  ? '${d.start} – ${d.end}'
                                  : (t.not_set ?? 'Not set'))
                              : (t.closed ?? 'Closed')),
                          trailing: Switch(
                              value: d.working,
                              onChanged: (v) => setState(() => d.working = v)),
                          onTap: () async {
                            final range = await _pickRange(
                                context, d.start ?? '09:00', d.end ?? '18:00');
                            if (range != null)
                              setState(() {
                                d.start = range.$1;
                                d.end = range.$2;
                                d.working = true;
                              });
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _localizeDay(BuildContext ctx, String d) {
    final t = AppLocalizations.of(ctx)!;
    switch (d) {
      case 'MONDAY':
        return t.dayMonday ?? 'Monday';
      case 'TUESDAY':
        return t.dayTuesday ?? 'Tuesday';
      case 'WEDNESDAY':
        return t.dayWednesday ?? 'Wednesday';
      case 'THURSDAY':
        return t.dayThursday ?? 'Thursday';
      case 'FRIDAY':
        return t.dayFriday ?? 'Friday';
      case 'SATURDAY':
        return t.daySaturday ?? 'Saturday';
      case 'SUNDAY':
        return t.daySunday ?? 'Sunday';
      default:
        return d;
    }
  }

  Future<(String, String)?> _pickRange(
      BuildContext context, String s, String e) async {
    final start = await _pickTime(
        context, AppLocalizations.of(context)!.start ?? 'Start', s);
    if (start == null) return null;
    final end =
        await _pickTime(context, AppLocalizations.of(context)!.end ?? 'End', e);
    if (end == null) return null;
    return (start, end);
  }

  Future<String?> _pickTime(
      BuildContext context, String title, String initial) async {
    int h = int.tryParse(initial.split(':').first) ?? 9;
    int m = int.tryParse(initial.split(':').elementAt(1)) ?? 0;
    return await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context,
                            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'),
                        child: Text(AppLocalizations.of(context)!.action_done ??
                            'Done'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Row(children: [
                    Expanded(
                        child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController:
                          FixedExtentScrollController(initialItem: h),
                      onSelectedItemChanged: (i) => h = i,
                      children: List.generate(
                          24,
                          (i) => Center(
                              child: Text(i.toString().padLeft(2, '0')))),
                    )),
                    const Text(':', style: TextStyle(fontSize: 22)),
                    Expanded(
                        child: CupertinoPicker(
                      itemExtent: 40,
                      scrollController:
                          FixedExtentScrollController(initialItem: m),
                      onSelectedItemChanged: (i) => m = i,
                      children: List.generate(
                          60,
                          (i) => Center(
                              child: Text(i.toString().padLeft(2, '0')))),
                    )),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Svc {
  final String id;
  final String name;
  final bool isActive;
  _Svc({required this.id, required this.name, required this.isActive});
}

class _Planned {
  final String day;
  bool working = false;
  String? start;
  String? end;
  _Planned(this.day);
}
