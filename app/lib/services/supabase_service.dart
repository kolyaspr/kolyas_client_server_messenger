import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';


import '../models/message.dart';
import '../models/reaction.dart';
import '../models/user_model.dart';
import '../supabase_options.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser =>
      _client.auth.currentSession?.user ?? _client.auth.currentUser;

  Future<AuthResponse> signUp(String email, String password) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
  await _client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: kIsWeb
        ? 'http://localhost:3000'
        : SupabaseOptions.googleRedirectUri,
  );
}

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Stream<User?> onAuthStateChange() {
    return _client.auth.onAuthStateChange.map(
      (event) => event.session?.user ?? _client.auth.currentUser,
    );
  }

  Future<void> upsertUser(String id, String email) async {
    await _client.from('users').upsert({
      'id': id,
      'email': email,
    });
  }

  Future<List<UserModel>> getUsers({
    required String currentUserId,
  }) async {
    final response = await _client
        .from('users')
        .select()
        .neq('id', currentUserId)
        .order('email');

    return (response as List)
        .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> getMessages(String chatRoomId) async {
    final response = await _client
        .from('messages')
        .select('*, message_reactions(*)')
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => Message.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendTextMessage({
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String chatRoomId,
    required String text,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'sender_id': senderId,
          'sender_email': senderEmail,
          'receiver_id': receiverId,
          'chat_room_id': chatRoomId,
          'message': text,
          'message_type': 'text',
        })
        .select('*, message_reactions(*)')
        .single();

    return Message.fromJson(response);
  }

  Future<Message> sendFileMessage({
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String chatRoomId,
    required String fileUrl,
    required String fileName,
    required MessageType messageType,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'sender_id': senderId,
          'sender_email': senderEmail,
          'receiver_id': receiverId,
          'chat_room_id': chatRoomId,
          'message': '',
          'message_type': messageType.name,
          'file_url': fileUrl,
          'file_name': fileName,
        })
        .select('*, message_reactions(*)')
        .single();

    return Message.fromJson(response);
  }

  Future<Message> sendAudioMessage({
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String chatRoomId,
    required String audioUrl,
    required int audioDuration,
  }) async {
    final response = await _client
        .from('messages')
        .insert({
          'sender_id': senderId,
          'sender_email': senderEmail,
          'receiver_id': receiverId,
          'chat_room_id': chatRoomId,
          'message': '',
          'message_type': 'audio',
          'audio_url': audioUrl,
          'audio_duration': audioDuration,
        })
        .select('*, message_reactions(*)')
        .single();

    return Message.fromJson(response);
  }

  Future<bool> deleteMessage(String messageId) async {
  final deleted = await _client
      .from('messages')
      .delete()
      .eq('id', messageId)
      .select('id');

  debugPrint('Удалено строк: ${deleted.length}');
  return deleted.isNotEmpty;
}
  Future<void> deleteMessages(List<String> messageIds) async {
  await _client
      .from('messages')
      .delete()
      .inFilter('id', messageIds);
}

Future<void> deleteMessageWithFile(
  String messageId, {
  String? fileUrl,
  String? audioUrl,
}) async {
  Future<void> removeFromStorage(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      final bucketIndex = segments.indexWhere(
        (s) => s == 'chat-files' || s == 'chat-audio',
      );

      if (bucketIndex == -1 || bucketIndex >= segments.length - 1) return;

      final bucket = segments[bucketIndex];
      final filePath = segments.sublist(bucketIndex + 1).join('/');

      await _client.storage.from(bucket).remove([filePath]);
      final deleted = await deleteMessage(messageId);
if (!deleted) {
  throw Exception('Сообщение не удалено из БД');
}
    } catch (_) {
      // Если файл не удалился, всё равно удаляем сообщение из БД
    }
  }

  await removeFromStorage(fileUrl);
  await removeFromStorage(audioUrl);
  await deleteMessage(messageId);
}

  Future<String> uploadFile({
    required File file,
    required String bucket,
    required String userId,
  }) async {
    final ext = p.extension(file.path);
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}$ext';

    await _client.storage.from(bucket).upload(
          fileName,
          file,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(fileName);
  }

  Future<void> upsertReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final existing = await _client
        .from('message_reactions')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('message_reactions')
          .update({'reaction': emoji})
          .eq('message_id', messageId)
          .eq('user_id', userId);
    } else {
      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'reaction': emoji,
      });
    }
  }

  Future<void> deleteReaction({
    required String messageId,
    required String userId,
  }) async {
    await _client
        .from('message_reactions')
        .delete()
        .eq('message_id', messageId)
        .eq('user_id', userId);
  }

  RealtimeChannel subscribeToMessages(
    String chatRoomId,
    void Function(Message) onMessage,
  ) {
    return _client
        .channel('messages:$chatRoomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_room_id',
            value: chatRoomId,
          ),
          callback: (payload) {
            try {
              final msg = Message.fromJson(payload.newRecord);
              onMessage(msg);
            } catch (_) {}
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToReactions(
    void Function() onReactionChange,
  ) {
    return _client
        .channel('reactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_reactions',
          callback: (_) => onReactionChange(),
        )
        .subscribe();
  }
}