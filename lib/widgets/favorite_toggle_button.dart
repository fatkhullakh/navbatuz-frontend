import 'package:flutter/material.dart';
import '../services/customers/favorites_service.dart';

class FavoriteToggleButton extends StatefulWidget {
  const FavoriteToggleButton({
    super.key,
    required this.providerId,
    this.initialIsFavorite,
    this.onChanged,
    this.activeColor, // optional brand color
  });

  final String providerId;
  final bool? initialIsFavorite;
  final VoidCallback? onChanged;
  final Color? activeColor;

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton> {
  final _favSvc = FavoriteService();
  bool? _isFav;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIsFavorite != null) {
      _isFav = widget.initialIsFavorite;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final ids = await _favSvc.listFavoriteIds();
    if (!mounted) return;
    setState(() => _isFav = ids.contains(widget.providerId));
  }

  Future<void> _toggle() async {
    if (_isFav == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (_isFav!) {
        await _favSvc.removeFavorite(widget.providerId);
        _isFav = false;
      } else {
        await _favSvc.addFavorite(widget.providerId);
        _isFav = true;
      }
      if (mounted) setState(() {});
      widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = _isFav ?? false;
    final active = widget.activeColor ?? const Color(0xFF384959);

    return FilledButton.icon(
      onPressed: _busy ? null : _toggle,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: fav ? active : const Color(0xFFEFF3F7),
        foregroundColor: fav ? Colors.white : active,
      ),
      icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
      label: Text(fav ? 'Favorited' : 'Favorite'),
    );
  }
}
