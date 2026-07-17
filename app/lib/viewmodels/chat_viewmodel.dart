import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../supabase_options.dart';
import '../utils/audio_recorder.dart';

class ChatViewModel extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  final AudioRecorderHelper _recorder = AudioRecorderHelper();
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> _messages = [];
  List<UserModel> _users = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isRecording = false;
  String? _errorMessage;

  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _reactionsChannel;

  UserModel? _selectedUser;
  String? _chatRoomId;

  String? _myUserId;
  String? _myEmail;

  List<Message> get messages => _messages;
  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isRecording => _isRecording;
  String? get errorMessage => _errorMessage;
  UserModel? get selectedUser => _selectedUser;
  String? get currentUserId => _myUserId;

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _ensureCurrentUser() async {
    if (_myUserId != null && _myEmail != null) return true;

    for (int i = 0; i < 20; i++) {
      final user = _service.currentUser;
      if (user != null) {
        _myUserId = user.id;
        _myEmail = user.email ?? '';
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }

    _setError('Сессия не готова. Выйдите и войдите заново.');
    return false;
  }

  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      notifyListeners();

      final ok = await _ensureCurrentUser();
      if (!ok) {
        _users = [];
        return;
      }

      _users = await _service.getUsers(currentUserId: _myUserId!);
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openChat(UserModel user) async {
    final ok = await _ensureCurrentUser();
    if (!ok) return;

    _selectedUser = user;
    final ids = [_myUserId!, user.id]..sort();
    _chatRoomId = '${ids[0]}_${ids[1]}';

    _messages = [];
    notifyListeners();

    await _loadMessages();
    _subscribeRealtime();
  }

  Future<void> _loadMessages() async {
    if (_chatRoomId == null) return;

    try {
      _isLoading = true;
      notifyListeners();
      _messages = await _service.getMessages(_chatRoomId!);
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeRealtime() {
    _messagesChannel?.unsubscribe();
    _reactionsChannel?.unsubscribe();

    if (_chatRoomId == null) return;

    _messagesChannel = _service.subscribeToMessages(_chatRoomId!, (msg) {
      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.add(msg);
        notifyListeners();
      }
    });

    _reactionsChannel = _service.subscribeToReactions(() async {
      if (_chatRoomId != null) {
        _messages = await _service.getMessages(_chatRoomId!);
        notifyListeners();
      }
    });
  }

  void closeChat() {
    _messagesChannel?.unsubscribe();
    _reactionsChannel?.unsubscribe();
    _selectedUser = null;
    _chatRoomId = null;
    _messages = [];
    notifyListeners();
  }

  Future<bool> sendTextMessage(String text) async {
    if (text.trim().isEmpty || _chatRoomId == null || _selectedUser == null) {
      return false;
    }

    final ok = await _ensureCurrentUser();
    if (!ok) return false;

    try {
      _isSending = true;
      notifyListeners();

      final msg = await _service.sendTextMessage(
        senderId: _myUserId!,
        senderEmail: _myEmail ?? '',
        receiverId: _selectedUser!.id,
        chatRoomId: _chatRoomId!,
        text: text.trim(),
      );

      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.add(msg);
      }

      _messages = await _service.getMessages(_chatRoomId!);
      return true;
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendImageMessage() async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (xFile == null) return;

      await _uploadAndSendFile(
        file: File(xFile.path),
        fileName: xFile.name,
        messageType: MessageType.image,
      );
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    }
  }

  Future<void> sendFileMessage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return;

      final picked = result.files.single;
      await _uploadAndSendFile(
        file: File(picked.path!),
        fileName: picked.name,
        messageType: MessageType.file,
      );
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    }
  }

  Future<void> _uploadAndSendFile({
    required File file,
    required String fileName,
    required MessageType messageType,
  }) async {
    if (_chatRoomId == null || _selectedUser == null) return;

    final ok = await _ensureCurrentUser();
    if (!ok) return;

    try {
      _isSending = true;
      notifyListeners();

      final url = await _service.uploadFile(
        file: file,
        bucket: SupabaseOptions.filesBucket,
        userId: _myUserId!,
      );

      final msg = await _service.sendFileMessage(
        senderId: _myUserId!,
        senderEmail: _myEmail ?? '',
        receiverId: _selectedUser!.id,
        chatRoomId: _chatRoomId!,
        fileUrl: url,
        fileName: fileName,
        messageType: messageType,
      );

      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.add(msg);
      }

      _messages = await _service.getMessages(_chatRoomId!);
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    try {
      await _recorder.startRecording();
      _isRecording = true;
      notifyListeners();
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    }
  }

  Future<void> stopRecordingAndSend() async {
    if (!_isRecording || _chatRoomId == null || _selectedUser == null) return;

    final ok = await _ensureCurrentUser();
    if (!ok) return;

    try {
      _isRecording = false;
      notifyListeners();

      final result = await _recorder.stopRecording();
      if (result == null) return;

      _isSending = true;
      notifyListeners();

      final file = File(result.path);
      final url = await _service.uploadFile(
        file: file,
        bucket: SupabaseOptions.audioBucket,
        userId: _myUserId!,
      );

      final msg = await _service.sendAudioMessage(
        senderId: _myUserId!,
        senderEmail: _myEmail ?? '',
        receiverId: _selectedUser!.id,
        chatRoomId: _chatRoomId!,
        audioUrl: url,
        audioDuration: result.duration,
      );

      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.add(msg);
      }

      _messages = await _service.getMessages(_chatRoomId!);
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> cancelRecording() async {
    await _recorder.cancelRecording();
    _isRecording = false;
    notifyListeners();
  }

  Future<bool> deleteMessage(
  String messageId, {
  String? fileUrl,
  String? audioUrl,
}) async {
  try {
    bool deleted;

    if ((fileUrl != null && fileUrl.isNotEmpty) ||
        (audioUrl != null && audioUrl.isNotEmpty)) {
      await _service.deleteMessageWithFile(
        messageId,
        fileUrl: fileUrl,
        audioUrl: audioUrl,
      );
      deleted = true;
    } else {
      deleted = await _service.deleteMessage(messageId);
    }

    if (!deleted) {
      _setError('Сообщение не удалилось из БД');
      return false;
    }

    _messages = _messages.where((m) => m.id != messageId).toList();
    notifyListeners();
    return true;
  } catch (e) {
    _setError('Ошибка удаления: $e');
    return false;
  }
}

  Future<void> addReaction(String messageId, String emoji) async {
    final ok = await _ensureCurrentUser();
    if (!ok) return;

    try {
      await _service.upsertReaction(
        messageId: messageId,
        emoji: emoji,
        userId: _myUserId!,
      );
      if (_chatRoomId != null) {
        _messages = await _service.getMessages(_chatRoomId!);
        notifyListeners();
      }
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    }
  }

  Future<void> removeReaction(String messageId) async {
    final ok = await _ensureCurrentUser();
    if (!ok) return;

    try {
      await _service.deleteReaction(
        messageId: messageId,
        userId: _myUserId!,
      );
      if (_chatRoomId != null) {
        _messages = await _service.getMessages(_chatRoomId!);
        notifyListeners();
      }
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('network') || raw.contains('SocketException')) {
      return 'Нет подключения к интернету';
    }
    if (raw.contains('permission') || raw.contains('Permission')) {
      return 'Нет разрешения на доступ к файлу или микрофону';
    }
    if (raw.contains('storage')) {
      return 'Ошибка загрузки файла. Проверьте настройки Storage';
    }
    return 'Ошибка: $raw';
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _reactionsChannel?.unsubscribe();
    _recorder.cancelRecording();
    super.dispose();
  }
}