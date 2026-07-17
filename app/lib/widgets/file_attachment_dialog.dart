import 'package:flutter/material.dart';

/// Диалог выбора типа вложения (фото или файл)
class FileAttachmentDialog extends StatelessWidget {
  const FileAttachmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.image, color: Colors.white),
            ),
            title: const Text('Фото из галереи'),
            onTap: () => Navigator.of(context).pop('image'),
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.insert_drive_file, color: Colors.white),
            ),
            title: const Text('Файл из памяти'),
            onTap: () => Navigator.of(context).pop('file'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Показывает нижний лист выбора вложения.
/// Возвращает 'image', 'file' или null если отменено.
Future<String?> showAttachmentPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const FileAttachmentDialog(),
  );
}
