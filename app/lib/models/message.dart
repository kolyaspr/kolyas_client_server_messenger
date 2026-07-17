import 'reaction.dart';

/// Типы сообщений в чате
enum MessageType { text, image, audio, file }

/// Модель сообщения с поддержкой текста, файлов и аудио
class Message {
  final String id;
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final String chatRoomId;
  final DateTime createdAt;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final String? audioUrl;
  final int? audioDuration;
  final List<Reaction> reactions;

  Message({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.chatRoomId,
    required this.createdAt,
    this.messageType = MessageType.text,
    this.fileUrl,
    this.fileName,
    this.audioUrl,
    this.audioDuration,
    this.reactions = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final typeStr = json['message_type'] as String? ?? 'text';
    final type = MessageType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => MessageType.text,
    );

    final rawReactions = json['message_reactions'] as List<dynamic>? ?? [];
    final reactions =
        rawReactions.map((r) => Reaction.fromJson(r as Map<String, dynamic>)).toList();

    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      senderEmail: json['sender_email'] as String,
      receiverId: json['receiver_id'] as String,
      message: json['message'] as String? ?? '',
      chatRoomId: json['chat_room_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      messageType: type,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      audioUrl: json['audio_url'] as String?,
      audioDuration: json['audio_duration'] as int?,
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() => {
        'sender_id': senderId,
        'sender_email': senderEmail,
        'receiver_id': receiverId,
        'message': message,
        'chat_room_id': chatRoomId,
        'message_type': messageType.name,
        if (fileUrl != null) 'file_url': fileUrl,
        if (fileName != null) 'file_name': fileName,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (audioDuration != null) 'audio_duration': audioDuration,
      };

  Message copyWith({List<Reaction>? reactions}) {
    return Message(
      id: id,
      senderId: senderId,
      senderEmail: senderEmail,
      receiverId: receiverId,
      message: message,
      chatRoomId: chatRoomId,
      createdAt: createdAt,
      messageType: messageType,
      fileUrl: fileUrl,
      fileName: fileName,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
      reactions: reactions ?? this.reactions,
    );
  }
}
