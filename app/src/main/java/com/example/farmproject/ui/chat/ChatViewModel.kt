// =====================================================================
// ChatViewModel.kt
// Drives one conversation screen: history, paging, optimistic sending
// with retry, live incoming messages, and read tracking.
// =====================================================================
package com.example.farmproject.ui.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.ChatMessage
import com.example.farmproject.data.repository.ChatRepository
import com.example.farmproject.data.model.Person
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.UUID
import kotlin.time.Instant

enum class SendStatus { SENDING, SENT, FAILED }

/** A message as the UI sees it (real rows and not-yet-confirmed ones). */
data class UiMessage(
    val clientId: String,          // stable list key (client_message_id, or message_id for old rows)
    val serverId: String?,         // null until the server confirms
    val senderId: String?,
    val body: String,
    val createdAt: Instant?,       // null while pending
    val isDeleted: Boolean,
    val status: SendStatus,
)

data class ChatState(
    val loading: Boolean = true,
    val messages: List<UiMessage> = emptyList(),      // oldest -> newest
    val people: Map<String, Person> = emptyMap(),     // account_id -> person (for names)
    val canLoadOlder: Boolean = true,
    val error: String? = null,
)

class ChatViewModel(
    private val repo: ChatRepository,
    private val conversationId: String,
) : ViewModel() {

    private val _state = MutableStateFlow(ChatState())
    val state: StateFlow<ChatState> = _state.asStateFlow()

    val myId: String get() = repo.myId

    init {
        viewModelScope.launch { loadInitial() }
        listenForMessages()
    }

    // ---- loading ---------------------------------------------------
    private suspend fun loadInitial() {
        runCatching {
            val people = repo.people(conversationId).associateBy { it.accountId }
            val page = repo.messages(conversationId)
            people to page
        }.onSuccess { (people, page) ->
            _state.update {
                it.copy(
                    loading = false,
                    people = people,
                    messages = merge(it.messages, page.map(::toUi)),
                    canLoadOlder = page.size >= PAGE_SIZE,
                    error = null,
                )
            }
            runCatching { repo.markRead(conversationId) }
        }.onFailure { e ->
            _state.update { it.copy(loading = false, error = e.message) }
        }
    }

    /** Call when the user scrolls to the top. */
    fun loadOlder() {
        val oldest = _state.value.messages.firstOrNull { it.createdAt != null }?.createdAt ?: return
        viewModelScope.launch {
            runCatching { repo.messages(conversationId, before = oldest) }
                .onSuccess { page ->
                    _state.update {
                        it.copy(
                            messages = merge(it.messages, page.map(::toUi)),
                            canLoadOlder = page.size >= PAGE_SIZE,
                        )
                    }
                }
        }
    }

    /** Re-fetch the latest page (call from ON_RESUME / after reconnecting). */
    fun refresh() {
        viewModelScope.launch { loadInitial() }
    }

    // ---- sending ---------------------------------------------------
    fun send(text: String) {
        val body = text.trim()
        if (body.isEmpty()) return
        val clientId = UUID.randomUUID().toString()

        // optimistic bubble
        val pending = UiMessage(clientId, null, myId, body, null, false, SendStatus.SENDING)
        _state.update { it.copy(messages = merge(it.messages, listOf(pending))) }
        attemptSend(pending)
    }

    fun retry(clientId: String) {
        val failed = _state.value.messages
            .firstOrNull { it.clientId == clientId && it.status == SendStatus.FAILED } ?: return
        setStatus(clientId, SendStatus.SENDING)
        attemptSend(failed)
    }

    private fun attemptSend(m: UiMessage) {
        viewModelScope.launch {
            runCatching { repo.send(conversationId, m.body, m.clientId) }
                .onFailure { setStatus(m.clientId, SendStatus.FAILED) }
            // On success, the realtime INSERT event swaps the pending bubble for the real row.
        }
    }

    fun delete(message: UiMessage) {
        val id = message.serverId ?: return
        viewModelScope.launch { runCatching { repo.deleteMessage(id) } }
        // optimistic: show as deleted immediately
        _state.update { s ->
            s.copy(messages = s.messages.map {
                if (it.clientId == message.clientId) it.copy(isDeleted = true) else it
            })
        }
    }

    // ---- realtime --------------------------------------------------
    private fun listenForMessages() {
        viewModelScope.launch {
            val (channel, inserts) = repo.messageInserts(conversationId)
            try {
                channel.subscribe(blockUntilSubscribed = true)
                inserts.collect { msg ->
                    _state.update { it.copy(messages = merge(it.messages, listOf(toUi(msg)))) }

                    // sender we haven't loaded yet (e.g. a new member)? fetch names once
                    if (msg.senderId != null && msg.senderId !in _state.value.people) {
                        runCatching { repo.people(conversationId) }.onSuccess { list ->
                            _state.update { it.copy(people = list.associateBy { p -> p.accountId }) }
                        }
                    }
                    if (msg.senderId != myId) runCatching { repo.markRead(conversationId) }
                }
            } finally {
                withContext(NonCancellable) { repo.closeChannel(channel) }
            }
        }
    }

    // ---- helpers ---------------------------------------------------
    private fun toUi(m: ChatMessage) = UiMessage(
        clientId = m.clientMessageId ?: m.messageId,
        serverId = m.messageId,
        senderId = m.senderId,
        body = m.body,
        createdAt = m.createdAt,
        isDeleted = m.isDeleted,
        status = SendStatus.SENT,
    )

    private fun setStatus(clientId: String, status: SendStatus) {
        _state.update { s ->
            s.copy(messages = s.messages.map {
                if (it.clientId == clientId) it.copy(status = status) else it
            })
        }
    }

    /** Upsert by clientId (replaces a pending bubble with its confirmed row), sorted oldest -> newest. */
    private fun merge(current: List<UiMessage>, incoming: List<UiMessage>): List<UiMessage> {
        val map = LinkedHashMap<String, UiMessage>()
        current.forEach { map[it.clientId] = it }
        incoming.forEach { map[it.clientId] = it }
        return map.values.sortedBy { it.createdAt ?: Instant.DISTANT_FUTURE }
    }

    companion object {
        private const val PAGE_SIZE = 50
    }
}
