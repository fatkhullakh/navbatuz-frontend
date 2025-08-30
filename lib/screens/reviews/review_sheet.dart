// lib/screens/reviews/review_sheet.dart
import 'package:flutter/material.dart';
import '../../services/reviews/review_service.dart';

class ReviewSheet extends StatefulWidget {
  final String appointmentId;
  const ReviewSheet({super.key, required this.appointmentId});

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final _svc = ReviewService();
  int _rating = 5;
  final _text = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _svc.create(
        appointmentId: widget.appointmentId,
        rating: _rating,
        comment: _text.text.trim().isEmpty ? null : _text.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your review!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            const Text('Rate your visit',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: List.generate(5, (i) {
                final v = i + 1;
                return ChoiceChip(
                  label: Text('$v'),
                  selected: _rating == v,
                  onSelected: (_) => setState(() => _rating = v),
                );
              }),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _text,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share details (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit'),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
