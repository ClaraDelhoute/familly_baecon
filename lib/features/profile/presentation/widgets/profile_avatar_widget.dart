import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:familly_baecon/core/providers/profile_image_provider.dart';

class ProfileAvatarWidget extends ConsumerStatefulWidget {
  final double size;
  final String initialName;

  const ProfileAvatarWidget({super.key, this.size = 90, this.initialName = 'R'});

  @override
  ConsumerState<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends ConsumerState<ProfileAvatarWidget> {
  final _picker = ImagePicker();

  Future<void> _onPickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final imagePath = ref.read(profileImagePathProvider);
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Copier l'image dans le répertoire de l'application
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${appDir.path}/$fileName';

      // Supprimer l'ancienne photo si elle existe
      final oldPath = ref.read(profileImagePathProvider);
      if (oldPath != null && oldPath.isNotEmpty) {
        final oldFile = File(oldPath);
        if (oldFile.existsSync()) {
          await oldFile.delete();
        }
      }

      // Copier la nouvelle image
      await File(pickedFile.path).copy(savedPath);

      // Mettre à jour le provider (met à jour toutes les pages)
      await ref.read(profileImagePathProvider.notifier).updateImage(savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _removeImage() async {
    final oldPath = ref.read(profileImagePathProvider);
    if (oldPath != null && oldPath.isNotEmpty) {
      final file = File(oldPath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    await ref.read(profileImagePathProvider.notifier).updateImage(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil supprimée')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = ref.watch(profileImagePathProvider);
    final size = widget.size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onPickImage,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              gradient: imagePath == null
                  ? LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600])
                  : null,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: imagePath == null
                  ? Center(
                      child: Text(
                        widget.initialName,
                        style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    )
                  : Image.file(File(imagePath), fit: BoxFit.cover, width: size, height: size),
            ),
          ),
          // Icône d'édition
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
