import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/model/chat.dart';
import '../../data/model/farm_user.dart';
import '../../data/repository/chat_repository.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({
    required this.user,
    required this.repository,
    super.key,
  });

  final FarmUser user;
  final ChatRepository repository;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<ChatConversation>> _conversations;

  @override
  void initState() {
    super.initState();
    _conversations = widget.repository.conversations();
  }

  Future<void> _refresh() async {
    final request = widget.repository.conversations();
    setState(() => _conversations = request);
    await request;
  }

  Future<void> _openNewChat() async {
    final contact = await Navigator.of(context).push<ChatContact>(
      MaterialPageRoute(
        builder: (_) => _NewChatScreen(repository: widget.repository),
      ),
    );
    if (!mounted || contact == null) return;

    try {
      final id = await widget.repository.openDirectChat(contact.accountId);
      if (!mounted) return;
      await _openConversation(
        ChatConversation(
          id: id,
          type: 'direct',
          lastActivityAt: DateTime.now().toIso8601String(),
          otherAccountId: contact.accountId,
          otherName: contact.fullName,
        ),
      );
      if (mounted) await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _openConversation(ChatConversation conversation) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ConversationScreen(
          conversation: conversation,
          repository: widget.repository,
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open chat: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChat,
        tooltip: 'New chat',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ChatConversation>>(
        future: _conversations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(
              message: 'Could not load conversations: ${snapshot.error}',
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversations = snapshot.data!;
          if (conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('No conversations yet.')),
                  Center(child: Text('Tap + to message someone on your farm.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final unread = conversation.unreadCount > 0;
                final preview = conversation.lastMessageDeleted
                    ? 'Message deleted'
                    : conversation.lastMessageBody ??
                        (conversation.type == 'group'
                            ? 'Say hello to your farm team'
                            : 'No messages yet');
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(_initials(conversation.displayTitle)),
                  ),
                  title: Text(
                    conversation.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    conversation.lastMessageSenderId == widget.repository.myId
                        ? 'You: $preview'
                        : preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: unread
                      ? CircleAvatar(
                          radius: 12,
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : '${conversation.unreadCount}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        )
                      : null,
                  onTap: () => _openConversation(conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewChatScreen extends StatefulWidget {
  const _NewChatScreen({required this.repository});

  final ChatRepository repository;

  @override
  State<_NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<_NewChatScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<ChatContact> _contacts = const [];
  Object? _error;
  bool _loading = true;
  bool _opening = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query, {bool debounce = false}) {
    _debounce?.cancel();
    final generation = ++_searchGeneration;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    _debounce = Timer(
        debounce ? const Duration(milliseconds: 300) : Duration.zero, () async {
      try {
        final contacts = await widget.repository.searchContacts(query);
        if (!mounted || generation != _searchGeneration) return;
        setState(() {
          _contacts = contacts;
          _loading = false;
        });
      } catch (error) {
        if (!mounted || generation != _searchGeneration) return;
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    });
  }

  Future<void> _selectContact(ChatContact contact) async {
    if (_opening) return;
    setState(() => _opening = true);
    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New chat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _search(query.trim(), debounce: true),
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear search',
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_error != null)
            _LoadError(
              message: 'Could not load contacts: $_error',
              onRetry: () => _search(_searchController.text),
            )
          else if (_loading && _contacts.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (!_loading && _contacts.isEmpty)
            const Expanded(child: Center(child: Text('No matching contacts.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return ListTile(
                    leading:
                        CircleAvatar(child: Text(_initials(contact.fullName))),
                    title: Text(contact.fullName),
                    trailing: _opening
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _opening ? null : () => _selectContact(contact),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ConversationScreen extends StatefulWidget {
  const _ConversationScreen({
    required this.conversation,
    required this.repository,
  });

  final ChatConversation conversation;
  final ChatRepository repository;

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late Stream<List<ChatMessage>> _messages;
  Map<String, String> _people = const {};
  bool _sending = false;
  Object? _peopleError;

  @override
  void initState() {
    super.initState();
    _messages = widget.repository.watchMessages(widget.conversation.id);
    _loadPeopleAndMarkRead();
  }

  Future<void> _loadPeopleAndMarkRead() async {
    try {
      final people = await widget.repository.people(widget.conversation.id);
      if (mounted) {
        setState(() {
          _people = {
            for (final person in people) person.accountId: person.fullName
          };
        });
      }
    } catch (error) {
      if (mounted) setState(() => _peopleError = error);
    }
    try {
      await widget.repository.markRead(widget.conversation.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark messages as read: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.repository.send(widget.conversation.id, body);
      _controller.clear();
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message could not be sent: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.conversation.type == 'group';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.displayTitle),
            if (isGroup)
              Text(
                'Everyone on your farm',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_peopleError != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Could not load participant names: $_peopleError'),
            ),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _LoadError(
                    message: 'Could not load messages: ${snapshot.error}',
                    onRetry: () => setState(() {
                      _messages = widget.repository
                          .watchMessages(widget.conversation.id);
                    }),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Send the first message.'),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine = message.senderId == widget.repository.myId;
                    final senderName =
                        _people[message.senderId] ?? 'Team Member';
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isGroup && !mine)
                              Text(
                                senderName,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            Text(
                              message.isDeleted
                                  ? 'Message deleted'
                                  : message.body,
                              style: message.isDeleted
                                  ? const TextStyle(fontStyle: FontStyle.italic)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    tooltip: 'Send message',
                    icon: _sending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

String _initials(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}
