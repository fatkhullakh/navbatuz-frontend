// lib/widgets/change_avatar_tile.dart
import 'package:flutter/material.dart';
import '../services/upload_service.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class ChangeAvatarTile extends StatefulWidget {
  final String userId; // current user id
  final String? currentUrl;
  const ChangeAvatarTile({super.key, required this.userId, this.currentUrl});
  @override
  State<ChangeAvatarTile> createState() => _ChangeAvatarTileState();
}

class _ChangeAvatarTileState extends State<ChangeAvatarTile> {
  final _uploader = UploadService();
  final _dio = ApiService.client;
  bool _busy = false;

  Future<void> _run(bool camera) async {
    setState(() => _busy = true);
    try {
      final res = await _uploader.pickAndUpload(
        scope: UploadScope.user,
        ownerId: widget.userId,
        useCamera: camera,
      );
      if (res == null) return;
      await _dio.put('/users/me/avatar', data: {'url': res.url});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avatar updated')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: !_busy,
      leading: CircleAvatar(
        backgroundImage:
            (widget.currentUrl != null && widget.currentUrl!.isNotEmpty)
                ? NetworkImage(widget.currentUrl!)
                : null,
        child: (widget.currentUrl == null || widget.currentUrl!.isEmpty)
            ? const Icon(Icons.person_outline)
            : null,
      ),
      title: const Text('Change avatar'),
      subtitle: const Text('Update your profile picture'),
      trailing: PopupMenuButton(
        icon: const Icon(Icons.edit_outlined),
        onSelected: (v) => _run(v == 'camera'),
        itemBuilder: (_) => [
          const PopupMenuItem(
              value: 'gallery', child: Text('Pick from gallery')),
          const PopupMenuItem(value: 'camera', child: Text('Take a photo')),
        ],
      ),
    );
  }
}
