// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../../services/service_catalog_service.dart';
// import '../../services/provider_public_service.dart';
// import '../../services/worker_public_service.dart';
// import 'review_confirm_screen.dart';

// class BookAppointmentScreen extends StatefulWidget {
//   final String serviceId;
//   const BookAppointmentScreen({super.key, required this.serviceId});

//   @override
//   State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
// }

// class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
//   final _svc = ServiceCatalogService();
//   final _providers = ProviderPublicService();
//   final _workers = WorkerPublicService();

//   ServiceDetail? _service;
//   ProvidersDetails? _provider;
//   String? _selectedWorkerId;
//   DateTime _date = DateTime.now();
//   List<String> _slots = const []; // "HH:mm:ss"
//   String? _selectedStart; // "HH:mm:ss"
//   bool _loadingSlots = false;
//   String? _slotError; // null or "not available"

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     try {
//       final s = await _svc.get(widget.serviceId);
//       final p = await _providers.getDetails(s.providerId);
//       final allowedWorkers =
//           p.workers.where((w) => s.workerIds.contains(w.id)).toList();
//       setState(() {
//         _service = s;
//         _provider = p;
//         _selectedWorkerId =
//             allowedWorkers.isNotEmpty ? allowedWorkers.first.id : null;
//       });
//       if (_selectedWorkerId != null) {
//         _loadSlots();
//       } else {
//         setState(() {
//           _slotError = 'No worker available for this service.';
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load: $e')),
//       );
//     }
//   }

//   Future<void> _loadSlots() async {
//     if (_selectedWorkerId == null || _service == null) return;
//     setState(() {
//       _loadingSlots = true;
//       _slotError = null;
//       _selectedStart = null;
//     });
//     try {
//       final minutes = _service!.duration.inMinutes;
//       final list = await _workers.freeSlots(
//         workerId: _selectedWorkerId!,
//         date: _date,
//         serviceDurationMinutes: minutes,
//       );
//       setState(() => _slots = list);
//       if (list.isEmpty) {
//         setState(() => _slotError = 'Not available this day');
//       }
//     } catch (e) {
//       setState(() => _slotError = 'Failed to load slots');
//     } finally {
//       setState(() => _loadingSlots = false);
//     }
//   }

//   String _priceText(int v) =>
//       NumberFormat.currency(locale: 'en_US', symbol: '', decimalDigits: 0)
//           .format(v);

//   @override
//   Widget build(BuildContext context) {
//     final s = _service;
//     final p = _provider;
//     if (s == null || p == null) {
//       return const Scaffold(
//         appBar: AppBar(title: Text('Book an Appointment')),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     final workers = p.workers.where((w) => s.workerIds.contains(w.id)).toList();
//     final df = DateFormat('EEE, d MMM yyyy');

//     // compute end time preview (if a slot is picked)
//     DateTime? endDateTime;
//     if (_selectedStart != null) {
//       final parts = _selectedStart!.split(':');
//       final start = DateTime(_date.year, _date.month, _date.day,
//           int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
//       endDateTime = start.add(s.duration);
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text('Book an Appointment')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           // Workers row
//           if (workers.isNotEmpty) ...[
//             const Text('Choose staff',
//                 style: TextStyle(fontWeight: FontWeight.w700)),
//             const SizedBox(height: 8),
//             SizedBox(
//               height: 56,
//               child: ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 separatorBuilder: (_, __) => const SizedBox(width: 8),
//                 itemCount: workers.length,
//                 itemBuilder: (_, i) {
//                   final w = workers[i];
//                   final selected = w.id == _selectedWorkerId;
//                   return ChoiceChip(
//                     label: Text(w.name),
//                     selected: selected,
//                     onSelected: (_) {
//                       setState(() => _selectedWorkerId = w.id);
//                       _loadSlots();
//                     },
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 12),
//           ],

//           // Calendar
//           Text(df.format(_date),
//               style: const TextStyle(fontWeight: FontWeight.w700)),
//           const SizedBox(height: 8),
//           CalendarDatePicker(
//             initialDate: _date,
//             firstDate: DateTime.now(),
//             lastDate: DateTime.now().add(const Duration(days: 180)),
//             onDateChanged: (d) {
//               setState(() => _date = d);
//               _loadSlots();
//             },
//           ),
//           const SizedBox(height: 8),

//           // Slots
//           const Text('Available times',
//               style: TextStyle(fontWeight: FontWeight.w700)),
//           const SizedBox(height: 8),
//           if (_loadingSlots) const Center(child: CircularProgressIndicator()),
//           if (!_loadingSlots && _slotError != null)
//             Center(
//                 child: Text(_slotError!,
//                     style: const TextStyle(color: Colors.black54))),
//           if (!_loadingSlots && _slotError == null)
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: _slots.map((t) {
//                 final hhmm = t.substring(0, 5); // HH:mm
//                 final selected = t == _selectedStart;
//                 return ChoiceChip(
//                   label: Text(hhmm),
//                   selected: selected,
//                   onSelected: (_) => setState(() => _selectedStart = t),
//                 );
//               }).toList(),
//             ),
//           const SizedBox(height: 16),

//           // Summary card
//           Card(
//             elevation: 0,
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             child: ListTile(
//               title: Text(s.name),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (_selectedStart != null && endDateTime != null)
//                     Text(
//                       '${_selectedStart!.substring(0, 5)} – '
//                       '${DateFormat('HH:mm').format(endDateTime)}',
//                     ),
//                   if (_selectedWorkerId != null)
//                     Text(
//                         'with ${workers.firstWhere((w) => w.id == _selectedWorkerId!).name}'),
//                 ],
//               ),
//               trailing: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Text(_priceText(s.price),
//                       style: const TextStyle(fontWeight: FontWeight.w700)),
//                   Text('${s.duration.inMinutes} min',
//                       style: const TextStyle(color: Colors.black54)),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//         ],
//       ),
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//           child: ElevatedButton(
//             onPressed: (_selectedWorkerId != null && _selectedStart != null)
//                 ? () {
//                     Navigator.of(context).push(MaterialPageRoute(
//                       builder: (_) => ReviewConfirmScreen(
//                         service: s,
//                         provider: p,
//                         workerId: _selectedWorkerId!,
//                         date: _date,
//                         startTimeHHmmss: _selectedStart!,
//                       ),
//                     ));
//                   }
//                 : null,
//             child: const Text('Book'),
//           ),
//         ),
//       ),
//     );
//   }
// }
