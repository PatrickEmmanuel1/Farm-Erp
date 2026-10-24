import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/chat.dart';
import '../model/model_parsing.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  String get myId => _client.auth.currentUser?.id ?? '';

  Future<List<ChatConversation>> conversations() async {
    final rows = await _client.rpc('my_conversations');
    final conversations = List<JsonRow>.from(rows)
        .map(ChatConversation.fromJson)
        .where((conversation) => conversation.id.isNotEmpty)
        .toList()
      ..sort(
        (a, b) =>
            DateTime.tryParse(b.lastActivityAt)?.compareTo(
                DateTime.tryParse(a.lastActivityAt) ??
                    DateTime.fromMillisecondsSinceEpoch(0)) ??
            0,
      );
    return conversations;
  }

  Future<List<ChatContact>> searchContacts(String query) async {
    final rows = await _client.rpc(
      'search_message_contacts',
      params: {'p_query': query.trim()},
    );
    return List<JsonRow>.from(rows)
        .map(ChatContact.fromJson)
        .where((contact) => contact.accountId.isNotEmpty)
        .toList();
  }

  Future<String> openDirectChat(String otherAccountId) async {
    final result = await _client.rpc(
      'get_or_create_direct_conversation',
      params: {'other_id': otherAccountId},
    );
    final conversationId = result?.toString() ?? '';
    if (conversationId.isEmpty) {
      throw const FormatException(
        'The chat service did not return a conversation ID.',
      );
    }
    return conversationId;
  }

  Future<List<ChatPerson>> people(String conversationId) async {
    final rows = await _client.rpc(
      'get_conversation_people',
      params: {'p_conversation_id': conversationId},
    );
    return List<JsonRow>.from(rows).map(ChatPerson.fromJson).toList();
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) => _client
      .from('message')
      .stream(primaryKey: ['message_id'])
      .eq('conversation_id', conversationId)
      .order('created_at')
      .map(
        (rows) => rows.map(ChatMessage.fromJson).toList()
          ..sort(
            (a, b) =>
                DateTime.tryParse(a.createdAt)?.compareTo(
                    DateTime.tryParse(b.createdAt) ??
                        DateTime.fromMillisecondsSinceEpoch(0)) ??
                0,
          ),
      );

  Future<void> send(String conversationId, String body) async {
    final cleanBody = body.trim();
    if (cleanBody.isEmpty) return;
    final senderId = myId;
    if (senderId.isEmpty) {
      throw StateError('Sign in again to send a message.');
    }
    await _client.from('message').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': cleanBody,
      'client_message_id': _uuid.v4(),
    });
  }

  Future<void> markRead(String conversationId) async {
    await _client.rpc(
      'mark_conversation_read',
      params: {'p_conversation_id': conversationId},
    );
  }
}
