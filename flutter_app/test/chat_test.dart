import 'package:farm_flutter/data/model/chat.dart';
import 'package:farm_flutter/data/model/farm_user.dart';
import 'package:farm_flutter/data/repository/chat_repository.dart';
import 'package:farm_flutter/ui/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('opens a conversation and sends a message', (tester) async {
    final repository = _FakeChatRepository(
      conversationRows: const [
        ChatConversation(
          id: 'conversation-id',
          type: 'group',
          title: 'Farm Team',
          lastActivityAt: '2026-10-24T10:00:00Z',
        ),
      ],
      messages: const [
        ChatMessage(
          id: 'message-id',
          conversationId: 'conversation-id',
          senderId: 'other-account',
          body: 'Morning team',
          createdAt: '2026-10-24T10:00:00Z',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MessagesScreen(
          user: _user,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Farm Team'), findsOneWidget);

    await tester.tap(find.text('Farm Team'));
    await tester.pumpAndSettle();
    expect(find.text('Morning team'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Harvest starts at noon');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(repository.sentConversationId, 'conversation-id');
    expect(repository.sentBody, 'Harvest starts at noon');
  });

  testWidgets('starts a direct chat from the contact picker', (tester) async {
    final repository = _FakeChatRepository(
      contacts: const [
        ChatContact(accountId: 'contact-id', fullName: 'Alex Farm'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MessagesScreen(
          user: _user,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('New chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex Farm'));
    await tester.pumpAndSettle();

    expect(repository.openedAccountId, 'contact-id');
    expect(find.text('Alex Farm'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'See you tomorrow');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(repository.sentConversationId, 'new-conversation-id');
    expect(repository.sentBody, 'See you tomorrow');
  });
}

const _user = FarmUser(
  id: 'current-account',
  fullName: 'Farm Manager',
  email: 'manager@example.com',
  role: 'Manager',
);

class _FakeChatRepository extends ChatRepository {
  _FakeChatRepository({
    this.conversationRows = const [],
    this.contacts = const [],
    this.messages = const [],
  }) : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final List<ChatConversation> conversationRows;
  final List<ChatContact> contacts;
  final List<ChatMessage> messages;
  String? openedAccountId;
  String? sentConversationId;
  String? sentBody;

  @override
  String get myId => 'current-account';

  @override
  Future<List<ChatConversation>> conversations() async => conversationRows;

  @override
  Future<List<ChatContact>> searchContacts(String query) async => contacts;

  @override
  Future<String> openDirectChat(String otherAccountId) async {
    openedAccountId = otherAccountId;
    return 'new-conversation-id';
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      Stream.value(messages);

  @override
  Future<List<ChatPerson>> people(String conversationId) async => const [];

  @override
  Future<void> markRead(String conversationId) async {}

  @override
  Future<void> send(String conversationId, String body) async {
    sentConversationId = conversationId;
    sentBody = body;
  }
}
