import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

/// Полноэкранный просмотр изображения с зумом и сохранением в галерею
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({super.key, required this.imageUrl});

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      // На Android 13+ разрешение не требуется для Gal,
      // на более старых — запрашиваем
      final status = await Permission.storage.status;
      if (status.isDenied) {
        await Permission.storage.request();
      }

      // Скачиваем файл во временную папку
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) throw Exception('Ошибка загрузки');

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);

      // Сохраняем в галерею
      await Gal.putImage(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение сохранено в галерею')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Сохранить в галерею',
            onPressed: () => _saveToGallery(context),
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 4,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 72),
        ),
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
