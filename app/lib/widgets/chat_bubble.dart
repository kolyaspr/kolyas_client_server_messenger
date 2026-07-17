import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/message.dart';
import '../models/reaction.dart';
import '../views/image_viewer.dart';
import 'audio_player_widget.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final void Function(String emoji) onReact;
  final void Function() onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.onReact,
    required this.onDelete,
  });

  static const _emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141B2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Выберите реакцию',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _emojis.map((e) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReact(e);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          e,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF141B2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: const Text('Удалить сообщение?'),
        content: const Text('Сообщение будет удалено из текущего чата.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownGradient = const LinearGradient(
      colors: [Color(0xFF8B7CFF), Color(0xFF6E6BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final otherColor = const Color(0xFF192238);
    final textColor = isOwn ? Colors.white : const Color(0xFFF3F5FF);

    return GestureDetector(
      onTap: () => _showReactionPicker(context),
      onLongPress: () => _showDeleteDialog(context),
      child: Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isOwn ? ownGradient : null,
                  color: isOwn ? null : otherColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isOwn ? 20 : 6),
                    bottomRight: Radius.circular(isOwn ? 6 : 20),
                  ),
                  border: Border.all(
                    color: isOwn
                        ? Colors.white.withOpacity(0.06)
                        : Colors.white.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOwn)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          message.senderEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8B7CFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    _buildContent(context, textColor),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isOwn
                              ? Colors.white.withOpacity(0.72)
                              : const Color(0xFF8E97B6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildReactions(message.reactions),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color textColor) {
    switch (message.messageType) {
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.audio:
        return AudioPlayerWidget(
          audioUrl: message.audioUrl ?? '',
          durationSeconds: message.audioDuration,
          isOwnMessage: isOwn,
        );
      case MessageType.file:
        return _buildFileContent(context, textColor);
      case MessageType.text:
        return Text(
          message.message,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }

  Widget _buildImageContent(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(imageUrl: message.fileUrl ?? ''),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Image.network(
              message.fileUrl ?? '',
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Icon(Icons.broken_image_rounded, size: 60),
                    ),
                  ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.38),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Открыть',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(BuildContext context, Color textColor) {
    return GestureDetector(
      onTap: () => _downloadFile(context),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isOwn
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isOwn
                    ? Colors.white.withOpacity(0.14)
                    : const Color(0xFF8B7CFF).withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.insert_drive_file_rounded,
                color: isOwn ? Colors.white : const Color(0xFF8B7CFF),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'Файл',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Нажмите, чтобы открыть',
                    style: TextStyle(
                      color: isOwn
                          ? Colors.white.withOpacity(0.74)
                          : const Color(0xFFB6BED8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download_rounded,
              color: isOwn ? Colors.white : const Color(0xFF8B7CFF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    final url = message.fileUrl;
    if (url == null || url.isEmpty) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 10),
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Скачивание...'),
            ],
          ),
        ),
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception('Ошибка загрузки');

      final dir = await getTemporaryDirectory();
      final fileName =
          message.fileName ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: fileName,
      );
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Widget _buildReactions(List<Reaction> reactions) {
    final Map<String, int> counts = {};
    for (final r in reactions) {
      counts[r.reaction] = (counts[r.reaction] ?? 0) + 1;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: counts.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF141B2D),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Text(
            '${e.key} ${e.value}',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}