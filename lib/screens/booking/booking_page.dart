// import 'package:flutter/material.dart';
// import '../../services/booking_api.dart';
// import '../../l10n/app_localizations.dart'; // your localization helper if any
// import 'review_page.dart';

// class BookingPage extends StatefulWidget {
//   final String serviceId;
//   const BookingPage({super.key, required this.serviceId});

//   @override
//   State<BookingPage> createState() => _BookingPageState();
// }

// class _BookingPageState extends State<BookingPage> {
//   final api = BookingApi();

//   ServiceDetails? service;
//   bool loading = true;
//   String? error;

//   // UI selections
//   String? selectedWorkerId; // null means "Anyone" -> we map to first worker
//   DateTime selectedDate = DateTime.now();
//   String? selectedSlot; // "HH:mm:ss"
//   List<String> slots = [];
//   bool slotsLoading = false;
//   String? slotsError;

//   @override
//   void initState() {
//     super.initState();
//     _loadService();
//   }

//   Future<void> _loadService() async {
//     setState(() {
//       loading = true;
//       error = null;
//     });
//     try {
//       final s = await api.getService(widget.serviceId);
//       service = s;
//       // default worker = Anyone (we’ll map to first worker if needed)
//       selectedWorkerId = null;
//       await _loadSlots();
//       setState(() {
//         loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         loading = false;
//         error = e.toString();
//       });
//     }
//   }

//   String _effectiveWorkerId() {
//     // If "Anyone", just use first worker for slot lookup.
//     // Later you can implement backend /free-slots/anyone if you want.
//     return selectedWorkerId ??
//         (service!.workerIds.isNotEmpty ? service!.workerIds.first : '');
//   }

//   Future<void> _loadSlots() async {
//     if (service == null || service!.workerIds.isEmpty) {
//       setState(() {
//         slots = [];
//         selectedSlot = null;
//       });
//       return;
//     }
//     setState(() {
//       slotsLoading = true;
//       slotsError = null;
//       selectedSlot = null;
//     });
//     try {
//       final list = await api.getFreeSlots(
//         workerId: _effectiveWorkerId(),
//         date: selectedDate,
//         serviceDurationMinutes: service!.durationMinutes,
//       );
//       setState(() {
//         slots = list;
//       });
//     } catch (e) {
//       setState(() {
//         slotsError = e.toString();
//         slots = [];
//       });
//     } finally {
//       setState(() {
//         slotsLoading = false;
//       });
//     }
//   }

//   void _onPickDate(DateTime d) async {
//     setState(() {
//       selectedDate = d;
//     });
//     await _loadSlots();
//   }

//   void _onPickWorker(String? workerId) async {
//     setState(() {
//       selectedWorkerId = workerId;
//     });
//     await _loadSlots();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = AppLocalizations.of(context)!; // assuming arb is wired

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(t.bookingTitle),
//         leading: const BackButton(),
//       ),
//       bottomNavigationBar: _bottomBar(context, t),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : error != null
//               ? _errorView(t, error!, onRetry: _loadService)
//               : _content(t),
//     );
//   }

//   Widget _content(AppLocalizations t) {
//     final s = service!;
//     return ListView(
//       padding: const EdgeInsets.all(16),
//       children: [
//         // Worker chooser
//         Text(t.bookingPickWorker,
//             style: Theme.of(context).textTheme.titleMedium),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 76,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: [
//               _workerChip(
//                 label: t.anyone,
//                 selected: selectedWorkerId == null,
//                 onTap: () => _onPickWorker(null),
//               ),
//               for (final w in s.workerIds)
//                 _workerChip(
//                   label: _shortWorker(
//                       w), // replace with real names if you have them
//                   selected: selectedWorkerId == w,
//                   onTap: () => _onPickWorker(w),
//                 ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),

//         // Calendar
//         Text(t.pickDate, style: Theme.of(context).textTheme.titleMedium),
//         const SizedBox(height: 8),
//         CalendarDatePicker(
//           firstDate: DateTime.now().subtract(const Duration(days: 0)),
//           lastDate: DateTime.now().add(const Duration(days: 120)),
//           initialDate: selectedDate,
//           onDateChanged: _onPickDate,
//         ),
//         const SizedBox(height: 12),

//         // Slots
//         Text(t.bookingPickTime, style: Theme.of(context).textTheme.titleMedium),
//         const SizedBox(height: 8),
//         if (slotsLoading)
//           const Padding(
//             padding: EdgeInsets.symmetric(vertical: 24),
//             child: Center(child: CircularProgressIndicator()),
//           )
//         else if (slotsError != null)
//           _errorView(t, t.errorGeneric, onRetry: _loadSlots)
//         else if (slots.isEmpty)
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             child: Text(t.bookingNoSlotsDay),
//           )
//         else
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: [
//               for (final s in slots)
//                 ChoiceChip(
//                   label: Text(s.substring(0, 5)), // "HH:mm"
//                   selected: selectedSlot == s,
//                   onSelected: (_) => setState(() {
//                     selectedSlot = s;
//                   }),
//                 ),
//             ],
//           ),

//         const SizedBox(height: 16),

//         // Service summary card
//         _serviceCard(s),
//       ],
//     );
//   }

//   Widget _workerChip(
//       {required String label,
//       required bool selected,
//       required VoidCallback onTap}) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: GestureDetector(
//         onTap: onTap,
//         child: Column(
//           children: [
//             CircleAvatar(
//                 radius: 24, child: Text(label.characters.first.toUpperCase())),
//             const SizedBox(height: 6),
//             Text(label,
//                 style: TextStyle(
//                     fontWeight:
//                         selected ? FontWeight.bold : FontWeight.normal)),
//           ],
//         ),
//       ),
//     );
//   }

//   String _shortWorker(String id) {
//     // Replace with actual worker name lookup if you have it already.
//     final short = id.substring(0, 4).toUpperCase();
//     return 'ID $short';
//     // If you store names, map here.
//   }

//   Widget _serviceCard(ServiceDetails s) {
//     final t = AppLocalizations.of(context)!;
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(s.name,
//                         style: const TextStyle(fontWeight: FontWeight.w600)),
//                     const SizedBox(height: 4),
//                     Text('${s.duration.inMinutes}m'),
//                   ]),
//             ),
//             Text('${_fmtMoney(s.price)} sum'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _bottomBar(BuildContext context, AppLocalizations t) {
//     final s = service;
//     return SafeArea(
//       child: Container(
//         padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
//         decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.surface,
//             boxShadow: [
//               BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.05)),
//             ]),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text('${_fmtMoney(s?.price ?? 0)} sum',
//                         style: const TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                     Text('${s?.duration.inMinutes ?? 0}m',
//                         style: const TextStyle(fontSize: 12)),
//                   ]),
//             ),
//             ElevatedButton(
//               onPressed: (s != null &&
//                       selectedSlot != null &&
//                       (s.workerIds.isNotEmpty))
//                   ? () {
//                       final start = DateTime(
//                         selectedDate.year,
//                         selectedDate.month,
//                         selectedDate.day,
//                         int.parse(selectedSlot!.substring(0, 2)),
//                         int.parse(selectedSlot!.substring(3, 5)),
//                       );
//                       final workerToUse = _effectiveWorkerId();
//                       Navigator.of(context).push(MaterialPageRoute(
//                         builder: (_) => BookingReviewPage(
//                           service: s,
//                           workerId: workerToUse,
//                           startAt: start,
//                         ),
//                       ));
//                     }
//                   : null,
//               child: Text(t.booking_book),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _errorView(AppLocalizations t, String message,
//       {required VoidCallback onRetry}) {
//     return Center(
//       child: Column(mainAxisSize: MainAxisSize.min, children: [
//         Text(message),
//         const SizedBox(height: 8),
//         OutlinedButton(onPressed: onRetry, child: Text(t.actionRetry)),
//       ]),
//     );
//   }

//   String _fmtMoney(num v) => v.toStringAsFixed(0);
// }
