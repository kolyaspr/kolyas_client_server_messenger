/// Модель реакции (emoji) на сообщение
class Reaction {
  final String id;
  final String messageId;
  final String userId;
  final String reaction;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.reaction,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      reaction: json['reaction'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'message_id': messageId,
        'user_id': userId,
        'reaction': reaction,
      };
}
