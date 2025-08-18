import 'package:flutter/material.dart';
import '../services/favorites_service.dart';

class FavoriteToggleButton extends StatefulWidget {
  final String providerId;
  final bool? initialIsFavorite; // optional if you already know on screen open
  final VoidCallback? onChanged;

  const FavoriteToggleButton({
    super.key,
    required this.providerId,
    this.initialIsFavorite,
    this.onChanged,
  });

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
        setState(() => _isFav = false);
      } else {
        await _favSvc.addFavorite(widget.providerId);
        setState(() => _isFav = true);
      }
      widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = _isFav ?? false;

    return FilledButton.icon(
      onPressed: _busy ? null : _toggle,
      style: FilledButton.styleFrom(
        backgroundColor: fav ? Colors.pink.shade500 : Colors.grey.shade200,
        foregroundColor: fav ? Colors.white : Colors.black87,
      ),
      icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
      label: Text(fav ? 'Favorited' : 'Favorite'),
    );
  }
}
