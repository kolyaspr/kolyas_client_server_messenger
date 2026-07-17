import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/file_attachment_dialog.dart';
import 'login_view.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();

    if (vm.selectedUser != null) {
      return _ChatScreen(vm: vm);
    }

    return _UsersScreen(vm: vm);
  }
}

class _UsersScreen extends StatelessWidget {
  final ChatViewModel vm;
  const _UsersScreen({required this.vm});

  static const _primary = Color(0xFF8B7CFF);
  static const _accent = Color(0xFF63E6FF);

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1020),
              Color(0xFF111A31),
              Color(0xFF171F37),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [_primary, _accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.forum_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kolyas Messenger',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Выберите собеседника и начните чат',
                            style: TextStyle(
                              color: Color(0xFFB6BED8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Выйти',
                      onPressed: () async {
                        await authVm.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginView()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141B2D).withOpacity(0.88),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: vm.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : vm.users.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Пока нет других пользователей для чата',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFB6BED8),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(14),
                              itemCount: vm.users.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, i) {
                                final user = vm.users[i];
                                return _UserCard(
                                  email: user.email,
                                  onTap: () => vm.openChat(user),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String email;
  final VoidCallback onTap;

  const _UserCard({
    required this.email,
    required this.onTap,
  });

  Color _avatarColor(String email) {
    final colors = [
      const Color(0xFF8B7CFF),
      const Color(0xFF63E6FF),
      const Color(0xFFFF7AD9),
      const Color(0xFFFFA94D),
      const Color(0xFF66D9A6),
    ];
    return colors[email.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColor(email);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2238),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor.withOpacity(0.22),
                  border: Border.all(color: avatarColor.withOpacity(0.35)),
                ),
                child: Center(
                  child: Text(
                    email[0].toUpperCase(),
                    style: TextStyle(
                      color: avatarColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Доступен для общения',
                      style: TextStyle(
                        color: Color(0xFFB6BED8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B7CFF).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF8B7CFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatScreen extends StatefulWidget {
  final ChatViewModel vm;
  const _ChatScreen({required this.vm});

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  double _swipeOffset = 0;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final ok = await widget.vm.sendTextMessage(text);
    if (ok) {
      _textController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _pickAttachment() async {
    final choice = await showAttachmentPicker(context);
    if (choice == null || !mounted) return;

    if (choice == 'image') {
      await widget.vm.sendImageMessage();
    } else {
      await widget.vm.sendFileMessage();
    }

    _scrollToBottom();
  }

  void _showError(String? msg) {
    if (msg == null || msg.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
    widget.vm.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final peerEmail = vm.selectedUser?.email ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.errorMessage != null) {
        _showError(vm.errorMessage);
      }
    });

    _scrollToBottom();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A1020),
              Color(0xFF10172B),
              Color(0xFF161C31),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141B2D).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<ChatViewModel>().closeChat();
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B7CFF).withOpacity(0.18),
                      ),
                      child: Center(
                        child: Text(
                          peerEmail.isEmpty ? '?' : peerEmail[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF8B7CFF),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peerEmail,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Чат активен',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB6BED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF66D9A6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Expanded(child: _buildMessageList(vm)),
              if (vm.isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                ),
              _buildInputBar(vm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ChatViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.messages.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141B2D).withOpacity(0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: const Text(
            'Напишите первое сообщение',
            style: TextStyle(
              color: Color(0xFFB6BED8),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      itemCount: vm.messages.length,
      itemBuilder: (ctx, i) {
        final msg = vm.messages[i];
        final isOwn = msg.senderId == vm.currentUserId;
        return ChatBubble(
          message: msg,
          isOwn: isOwn,
          onReact: (emoji) => vm.addReaction(msg.id, emoji),
          onDelete: () => vm.deleteMessage(
            msg.id,
            fileUrl: msg.fileUrl,
            audioUrl: msg.audioUrl,
          ),
        );
      },
    );
  }

  Widget _buildInputBar(ChatViewModel vm) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141B2D).withOpacity(0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: vm.isRecording ? _buildRecordingBar(vm) : _buildNormalBar(vm),
      ),
    );
  }

  Widget _buildNormalBar(ChatViewModel vm) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF8B7CFF).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            icon: const Icon(Icons.attach_file_rounded, size: 20),
            onPressed: vm.isSending ? null : _pickAttachment,
            tooltip: 'Прикрепить файл',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _textController,
            minLines: 1,
            maxLines: 4,
            style: const TextStyle(fontSize: 15),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Сообщение...',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            onSubmitted: (_) => _sendText(),
          ),
        ),
        const SizedBox(width: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _textController,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            return GestureDetector(
              onTap: hasText ? _sendText : null,
              onLongPressStart: hasText
                  ? null
                  : (_) async {
                      setState(() => _swipeOffset = 0);
                      await widget.vm.startRecording();
                    },
              onLongPressMoveUpdate: hasText
                  ? null
                  : (details) {
                      setState(() => _swipeOffset = details.offsetFromOrigin.dx);
                      if (_swipeOffset < -60) widget.vm.cancelRecording();
                    },
              onLongPressEnd: hasText
                  ? null
                  : (_) async {
                      if (widget.vm.isRecording) {
                        await widget.vm.stopRecordingAndSend();
                        _scrollToBottom();
                      }
                    },
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B7CFF), Color(0xFF63E6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B7CFF).withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  hasText ? Icons.send_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecordingBar(ChatViewModel vm) {
    return Row(
      children: [
        const Icon(Icons.mic_rounded, color: Colors.redAccent),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Запись... свайп влево для отмены',
            style: TextStyle(
              color: Color(0xFFB6BED8),
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: () => vm.cancelRecording(),
          child: const Text('Отмена'),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () async {
            await vm.stopRecordingAndSend();
            _scrollToBottom();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B7CFF), Color(0xFF63E6FF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}