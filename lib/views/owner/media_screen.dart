/// Media management screen for business owners.
///
/// Displays a grid of uploaded images with category labels,
/// supports uploading new images from camera or gallery,
/// full-screen viewing, and deletion with confirmation.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:alpaca_mobile/core/theme/app_colors.dart';
import 'package:alpaca_mobile/models/media_model.dart';
import 'package:alpaca_mobile/viewmodels/auth_view_model.dart';
import 'package:alpaca_mobile/viewmodels/media_view_model.dart';

/// Screen that allows business owners to manage their media gallery.
///
/// Features:
/// - Grid view of uploaded images with category labels
/// - FAB to upload new images (camera or gallery)
/// - Tap to view full screen
/// - Long press to delete with confirmation
/// - Upload progress indicator
class MediaScreen extends StatefulWidget {
  /// Creates a [MediaScreen].
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia();
    });
  }

  void _loadMedia() {
    final authVm = context.read<AuthViewModel>();
    final userId = authVm.currentUser?.id;
    if (userId != null) {
      context.read<MediaViewModel>().loadMedia(userId);
    }
  }

  Future<void> _showUploadDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Gambar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile == null || !mounted) return;

    // Langsung upload dengan category "gallery" tanpa dialog
    final userId = context.read<AuthViewModel>().currentUser?.id;
    if (userId == null) return;

    final mediaVm = context.read<MediaViewModel>();
    
    await mediaVm.uploadImage(
      imageFile: File(pickedFile.path),
      category: 'gallery',
      uploadedBy: userId,
    );
    
    // Wait a bit for backend to save, then reload
    await Future.delayed(const Duration(milliseconds: 500));
    await mediaVm.loadMedia(userId);
  }

  Future<void> _confirmDelete(MediaModel media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Gambar'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus gambar ini? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<MediaViewModel>().deleteMedia(media.id);
    }
  }

  void _viewFullScreen(MediaModel media) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullScreenImageView(media: media),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'gallery':
        return 'Galeri';
      case 'product':
        return 'Produk';
      case 'location':
        return 'Lokasi';
      case 'promotion':
        return 'Promosi';
      default:
        return 'Lainnya';
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'gallery':
        return AppColors.primary;
      case 'product':
        return AppColors.secondary;
      case 'location':
        return AppColors.info;
      case 'promotion':
        return AppColors.tertiary;
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaVm = context.watch<MediaViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          _buildHeader(mediaVm),
          Expanded(child: _buildBody(mediaVm)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: mediaVm.isUploading ? null : _showUploadDialog,
        backgroundColor: const Color(0xFF22C55E),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHeader(MediaViewModel mediaVm) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF86EFAC).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF86EFAC),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Kelola galeri foto',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF86EFAC),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (mediaVm.mediaList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${mediaVm.mediaList.length} gambar',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(MediaViewModel mediaVm) {
    // Upload progress indicator
    if (mediaVm.isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: mediaVm.uploadProgress > 0 ? mediaVm.uploadProgress : null,
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mengupload gambar...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            if (mediaVm.uploadProgress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${(mediaVm.uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (mediaVm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF22C55E),
        ),
      );
    }

    if (mediaVm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                mediaVm.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMedia,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (mediaVm.mediaList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  size: 64,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Belum ada media',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap tombol upload untuk menambahkan\ngambar pertama Anda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF22C55E),
      onRefresh: () async => _loadMedia(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: mediaVm.mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaVm.mediaList[index];
              return _MediaGridItem(
                media: media,
                categoryLabel: _categoryLabel(media.category),
                categoryColor: _categoryColor(media.category),
                onTap: () => _viewFullScreen(media),
                onLongPress: () => _confirmDelete(media),
              );
            },
          );
        },
      ),
    );
  }
}

/// A single grid item displaying a media image with category label.
class _MediaGridItem extends StatelessWidget {
  const _MediaGridItem({
    required this.media,
    required this.categoryLabel,
    required this.categoryColor,
    required this.onTap,
    required this.onLongPress,
  });

  final MediaModel media;
  final String categoryLabel;
  final Color categoryColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              media.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                    color: const Color(0xFF22C55E),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFF3F4F6),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoryLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: onLongPress,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: Colors.white,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen image viewer with hero animation support.
class _FullScreenImageView extends StatelessWidget {
  const _FullScreenImageView({required this.media});

  final MediaModel media;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          media.category,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            media.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
