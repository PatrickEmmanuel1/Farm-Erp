import 'model_parsing.dart';

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.type,
    required this.lastActivityAt,
    this.title,
    this.otherAccountId,
    this.otherName,
    this.lastMessageBody,
    this.lastMessageSenderId,
    this.lastMessageDeleted = false,
    this.unreadCount = 0,
  });

  final String id;
  final String type;
  final String? title;
  final String? otherAccountId;
  final String? otherName;
  final String? lastMessageBody;
  final String? lastMessageSenderId;
  final bool lastMessageDeleted;
  final String lastActivityAt;
  final int unreadCount;

  String get displayTitle =>
      type == 'direct' ? otherName ?? 'Chat' : title ?? 'Farm Team';

  factory ChatConversation.fromJson(JsonRow json) => ChatConversation(
        id: stringValue(json, 'conversation_id') ?? '',
        type: stringValue(json, 'type') ?? 'direct',
        title: stringValue(json, 'title'),
        otherAccountId: stringValue(json, 'other_account_id'),
        otherName: stringValue(json, 'other_name'),
        lastMessageBody: stringValue(json, 'last_message_body'),
        lastMessageSenderId: stringValue(json, 'last_message_sender_id'),
        lastMessageDeleted: boolValue(json, 'last_message_deleted'),
        lastActivityAt: stringValue(json, 'last_activity_at') ?? '',
        unreadCount: intValue(json, 'unread_count') ?? 0,
      );
}

class ChatContact {
  const ChatContact({
    required this.accountId,
    required this.fullName,
    this.roleId,
  });

  final String accountId;
  final String fullName;
  final String? roleId;

  factory ChatContact.fromJson(JsonRow json) => ChatContact(
        accountId: stringValue(json, 'account_id') ?? '',
        fullName: stringValue(json, 'full_name') ?? 'Team Member',
        roleId: stringValue(json, 'role_id'),
      );
}

class ChatPerson {
  const ChatPerson({
    required this.accountId,
    required this.fullName,
  });

  final String accountId;
  final String fullName;

  factory ChatPerson.fromJson(JsonRow json) => ChatPerson(
        accountId: stringValue(json, 'account_id') ?? '',
        fullName: stringValue(json, 'full_name') ?? 'Team Member',
      );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.createdAt,
    this.senderId,
    this.clientMessageId,
    this.isDeleted = false,
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String body;
  final String? clientMessageId;
  final bool isDeleted;
  final String createdAt;

  factory ChatMessage.fromJson(JsonRow json) => ChatMessage(
        id: stringValue(json, 'message_id') ?? '',
        conversationId: stringValue(json, 'conversation_id') ?? '',
        senderId: stringValue(json, 'sender_id'),
        body: stringValue(json, 'body') ?? '',
        clientMessageId: stringValue(json, 'client_message_id'),
        isDeleted: boolValue(json, 'is_deleted'),
        createdAt: stringValue(json, 'created_at') ?? '',
      );
}
