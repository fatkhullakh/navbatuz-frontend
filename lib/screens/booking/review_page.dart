// import 'package:flutter/material.dart';
// import '../../services/booking_api.dart';
// import '../../l10n/app_localizations.dart';
// import 'success_page.dart';

// class BookingReviewPage extends StatefulWidget {
//   final ServiceDetails service;
//   final String workerId;
//   final DateTime startAt;

//   const BookingReviewPage({
//     super.key,
//     required this.service,
//     required this.workerId,
//     required this.startAt,
//   });

//   @override
//   State<BookingReviewPage> createState() => _BookingReviewPageState();
// }

// class _BookingReviewPageState extends State<BookingReviewPage> {
//   final api = BookingApi();
//   bool submitting = false;
//   String? error;
//   String payment = 'cash'; // cash only for now

//   @override
//   Widget build(BuildContext context) {
//     final t = AppLocalizations.of(context)!;
//     final s = widget.service;

//     return Scaffold(
//       appBar: AppBar(title: Text(t.reviewTitle), leading: const BackButton()),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _header(t),
//           const SizedBox(height: 12),
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(children: [
//                       Expanded(
//                           child: Text(s.name,
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.w600))),
//                       Text('${s.price.toStringAsFixed(0)} sum'),
//                     ]),
//                     const SizedBox(height: 4),
//                     Text('${t.withWorker} ${_workerShort(widget.workerId)}'),
//                     Text(
//                         '${t.timeRange}: ${_fmtRange(widget.startAt, s.duration)}'),
//                     const Divider(height: 20),
//                     Row(
//                       children: [
//                         Expanded(child: Text(t.subtotal)),
//                         Text('${s.price.toStringAsFixed(0)} sum',
//                             style:
//                                 const TextStyle(fontWeight: FontWeight.w600)),
//                       ],
//                     ),
//                   ]),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(t.howPay, style: Theme.of(context).textTheme.titleMedium),
//           const SizedBox(height: 8),
//           RadioListTile<String>(
//             value: 'cash',
//             groupValue: payment,
//             onChanged: (v) => setState(() => payment = v!),
//             title: Text(t.payCash),
//           ),
//           const SizedBox(height: 24),
//           if (error != null)
//             Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Text(error!, style: const TextStyle(color: Colors.red)),
//             ),
//           ElevatedButton(
//             onPressed: submitting ? null : _submit,
//             child: submitting
//                 ? const SizedBox(
//                     height: 18,
//                     width: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2))
//                 : Text(t.confirmAndBook),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _header(AppLocalizations t) {
//     final d = widget.startAt;
//     final dateStr =
//         '${_weekday(d.weekday)}, ${_pad(d.day)}.${_pad(d.month)}.${d.year} | ${_pad(d.hour)}:${_pad(d.minute)}';
//     return Text(dateStr,
//         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
//   }

//   Future<void> _submit() async {
//     setState(() {
//       submitting = true;
//       error = null;
//     });
//     try {
//       await api.createAppointment(
//         serviceId: widget.service.id,
//         workerId: widget.workerId,
//         startDateTime: widget.startAt,
//       );
//       if (!mounted) return;
//       Navigator.of(context).pushReplacement(MaterialPageRoute(
//         builder: (_) => const BookingSuccessPage(),
//       ));
//     } catch (e) {
//       setState(() {
//         error = e.toString();
//       });
//     } finally {
//       setState(() {
//         submitting = false;
//       });
//     }
//   }

//   String _workerShort(String id) => 'ID ${id.substring(0, 4).toUpperCase()}';
//   String _fmtRange(DateTime start, Duration dur) {
//     final end = start.add(dur);
//     return '${_pad(start.hour)}:${_pad(start.minute)} - ${_pad(end.hour)}:${_pad(end.minute)}';
//   }

//   String _weekday(int w) =>
//       const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
//   String _pad(int v) => v.toString().padLeft(2, '0');
// }
