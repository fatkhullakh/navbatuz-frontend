// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../../../../l10n/app_localizations.dart';
// import '../../../../services/manage_services_service.dart';
// import '../../../../services/api_service.dart';
// import 'service_edit_screen.dart';

// class ProviderServicesListScreen extends StatefulWidget {
//   final String providerId;
//   const ProviderServicesListScreen({super.key, required this.providerId});

//   @override
//   State<ProviderServicesListScreen> createState() =>
//       _ProviderServicesListScreenState();
// }

// class _ProviderServicesListScreenState
//     extends State<ProviderServicesListScreen> {
//   final _svc = ManageServicesService();

//   late Future<List<ProviderServiceItem>> _future;
//   String _filter = 'ALL'; // ALL | ACTIVE | INACTIVE

//   @override
//   void initState() {
//     super.initState();
//     _future = _svc.listAllByProvider(widget.providerId);
//   }

//   Future<void> _reload() async {
//     setState(() => _future = _svc.listAllByProvider(widget.providerId));
//     await _future;
//   }

//   String _catLabel(AppLocalizations t, String cat) {
//     switch (cat) {
//       case 'BARBERSHOP':
//         return t.cat_barbershop;
//       case 'DENTAL':
//         return t.cat_dental;
//       case 'CLINIC':
//         return t.cat_clinic;
//       case 'SPA':
//         return t.cat_spa;
//       case 'GYM':
//         return t.cat_gym;
//       case 'NAIL_SALON':
//         return t.cat_nail_salon;
//       case 'BEAUTY_CLINIC':
//         return t.cat_beauty_clinic;
//       case 'TATTOO_STUDIO':
//         return t.cat_tattoo_studio;
//       case 'MASSAGE_CENTER':
//         return t.cat_massage_center;
//       case 'PHYSIOTHERAPY_CLINIC':
//         return t.cat_physiotherapy_clinic;
//       case 'MAKEUP_STUDIO':
//         return t.cat_makeup_studio;
//       default:
//         return cat;
//     }
//   }

//   String _fmtDuration(Duration? d) {
//     if (d == null) return '';
//     final h = d.inHours;
//     final m = d.inMinutes % 60;
//     if (h > 0 && m > 0) return '${h}h ${m}m';
//     if (h > 0) return '${h}h';
//     return '${m}m';
//   }

//   void _onAdd() async {
//     final created = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (_) => ServiceEditorScreen(
//           providerId: widget.providerId,
//           existing: null,
//         ),
//       ),
//     );
//     if (created == true) _reload();
//   }

//   void _onEdit(ProviderServiceItem item) async {
//     final updated = await Navigator.of(context).push<bool>(
//       MaterialPageRoute(
//         builder: (_) => ServiceEditorScreen(
//           providerId: widget.providerId,
//           existing: item,
//         ),
//       ),
//     );
//     if (updated == true) _reload();
//   }

//   void _onToggleActive(ProviderServiceItem item, bool value) async {
//     try {
//       if (value) {
//         await _svc.activate(item.id);
//       } else {
//         await _svc.deactivate(item.id);
//       }
//       _reload();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Failed: $e')));
//     }
//   }

//   void _onDelete(ProviderServiceItem item) async {
//     final t = AppLocalizations.of(context)!;
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text('Delete service?'),
//         content: Text('This cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text(t.common_no),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Yes'),
//           ),
//         ],
//       ),
//     );
//     if (ok != true) return;
//     try {
//       await _svc.delete(item.id);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Deleted')));
//       _reload();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Failed: $e')));
//     }
//   }

//   Future<void> _onChangeImage(ProviderServiceItem item) async {
//     final controller = TextEditingController(text: item.logoUrl ?? '');
//     final url = await showDialog<String>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Service image URL'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(
//             labelText: 'Image URL (public)',
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           FilledButton(
//             onPressed: () => Navigator.pop(context, controller.text.trim()),
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//     if (url == null) return;
//     try {
//       await _svc.setImageUrl(item.id, url);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Image updated')),
//       );
//       _reload();
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Failed: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final t = AppLocalizations.of(context)!;
//     final locale = Localizations.localeOf(context).toLanguageTag();
//     final money =
//         NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0);

//     return Scaffold(
//       appBar: AppBar(title: Text(t.provider_tab_services)),
//       body: RefreshIndicator(
//         onRefresh: _reload,
//         child: FutureBuilder<List<ProviderServiceItem>>(
//           future: _future,
//           builder: (context, snap) {
//             if (snap.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
//             if (snap.hasError) {
//               return ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 children: [
//                   const SizedBox(height: 120),
//                   Center(child: Text('Failed: ${snap.error}')),
//                   const SizedBox(height: 8),
//                   Center(
//                     child: OutlinedButton(
//                       onPressed: _reload,
//                       child: Text(t.provider_retry),
//                     ),
//                   ),
//                 ],
//               );
//             }
//             final all = snap.data ?? const [];
//             final items = switch (_filter) {
//               'ACTIVE' => all.where((e) => e.isActive).toList(),
//               'INACTIVE' => all.where((e) => !e.isActive).toList(),
//               _ => all,
//             };

//             return ListView(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
//               children: [
//                 // Filter chips
//                 Wrap(
//                   spacing: 8,
//                   children: [
//                     ChoiceChip(
//                       selected: _filter == 'ALL',
//                       label: const Text('All'),
//                       onSelected: (_) => setState(() => _filter = 'ALL'),
//                     ),
//                     ChoiceChip(
//                       selected: _filter == 'ACTIVE',
//                       label: const Text('Active'),
//                       onSelected: (_) => setState(() => _filter = 'ACTIVE'),
//                     ),
//                     ChoiceChip(
//                       selected: _filter == 'INACTIVE',
//                       label: const Text('Inactive'),
//                       onSelected: (_) => setState(() => _filter = 'INACTIVE'),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),

//                 if (items.isEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 40),
//                     child: Center(
//                       child: Text('No services yet'),
//                     ),
//                   )
//                 else
//                   ...items.map((s) {
//                     final img = ApiService.normalizeMediaUrl(s.logoUrl);
//                     final priceText = (s.price == null || s.price == 0)
//                         ? 'Free'
//                         : money.format(s.price);
//                     final durText = _fmtDuration(s.duration);
//                     return Card(
//                       elevation: 0,
//                       child: ListTile(
//                         leading: ClipRRect(
//                           borderRadius: BorderRadius.circular(8),
//                           child: img == null
//                               ? Container(
//                                   width: 48,
//                                   height: 48,
//                                   color: const Color(0xFFF2F4F7),
//                                   child: const Icon(Icons.image_outlined),
//                                 )
//                               : Image.network(
//                                   img,
//                                   width: 48,
//                                   height: 48,
//                                   fit: BoxFit.cover,
//                                   errorBuilder: (_, __, ___) => Container(
//                                     width: 48,
//                                     height: 48,
//                                     color: const Color(0xFFF2F4F7),
//                                     child: const Icon(Icons.broken_image),
//                                   ),
//                                 ),
//                         ),
//                         title: Text(
//                           s.name,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(fontWeight: FontWeight.w700),
//                         ),
//                         subtitle: Wrap(
//                           spacing: 8,
//                           crossAxisAlignment: WrapCrossAlignment.center,
//                           children: [
//                             if (s.category.isNotEmpty)
//                               Chip(
//                                 label: Text(_catLabel(t, s.category)),
//                                 padding: EdgeInsets.zero,
//                                 visualDensity: VisualDensity.compact,
//                               ),
//                             if (durText.isNotEmpty)
//                               Chip(
//                                 label: Text(durText),
//                                 padding: EdgeInsets.zero,
//                                 visualDensity: VisualDensity.compact,
//                               ),
//                             Chip(
//                               label: Text(priceText),
//                               padding: EdgeInsets.zero,
//                               visualDensity: VisualDensity.compact,
//                             ),
//                           ],
//                         ),
//                         trailing: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Switch(
//                               value: s.isActive,
//                               onChanged: (v) => _onToggleActive(s, v),
//                             ),
//                             PopupMenuButton<String>(
//                               onSelected: (v) {
//                                 switch (v) {
//                                   case 'edit':
//                                     _onEdit(s);
//                                     break;
//                                   case 'image':
//                                     _onChangeImage(s);
//                                     break;
//                                   case 'delete':
//                                     _onDelete(s);
//                                     break;
//                                 }
//                               },
//                               itemBuilder: (_) => [
//                                 const PopupMenuItem(
//                                   value: 'edit',
//                                   child: ListTile(
//                                     leading: Icon(Icons.edit_outlined),
//                                     title: Text('Edit'),
//                                   ),
//                                 ),
//                                 const PopupMenuItem(
//                                   value: 'image',
//                                   child: ListTile(
//                                     leading: Icon(Icons.image_outlined),
//                                     title: Text('Change image'),
//                                   ),
//                                 ),
//                                 const PopupMenuItem(
//                                   value: 'delete',
//                                   child: ListTile(
//                                     leading: Icon(Icons.delete_outline),
//                                     title: Text('Delete'),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                         onTap: () => _onEdit(s),
//                       ),
//                     );
//                   }),
//               ],
//             );
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _onAdd,
//         icon: const Icon(Icons.add),
//         label: const Text('Add service'),
//       ),
//     );
//   }
// }
