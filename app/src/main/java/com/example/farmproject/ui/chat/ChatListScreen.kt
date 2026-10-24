// =====================================================================
// ChatListScreen.kt
// "Messages" screen: every chat the user belongs to (direct chats and
// the farm group channel), newest first, with unread badges.
// =====================================================================
package com.example.farmproject.ui.chat

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Badge
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.farmproject.data.model.ConversationSummary

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatListScreen(
    viewModel: ChatListViewModel,
    myId: String,
    onOpenChat: (ConversationSummary) -> Unit,
    onNewChat: () -> Unit,
    onBack: (() -> Unit)? = null,
) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    // Catch anything missed while the app was in the background / offline.
    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) { viewModel.refresh() }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Messages") },
                navigationIcon = {
                    if (onBack != null) {
                        IconButton(onClick = onBack) {
                            Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                        }
                    }
                },
            )
        },
        floatingActionButton = {
            FloatingActionButton(onClick = onNewChat) {
                Icon(Icons.Default.Add, contentDescription = "New chat")
            }
        },
    ) { inner ->
        Column(
            Modifier
                .padding(inner)
                .fillMaxSize()
        ) {
            state.error?.let {
                ErrorBanner(
                    message = it,
                    onRetry = viewModel::refresh
                )
            }

            when {
                state.loading && state.conversations.isEmpty() -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }

                state.conversations.isEmpty() -> {
                    EmptyState(
                        title = "No conversations yet",
                        subtitle = "Tap + to message someone on your farm.",
                    )
                }

                else -> {
                    LazyColumn(Modifier.fillMaxSize()) {
                        items(
                            items = state.conversations,
                            key = { it.conversationId }
                        ) { c ->
                            ConversationRow(c, myId, onClick = { onOpenChat(c) })
                            HorizontalDivider(Modifier.padding(start = 76.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ConversationRow(c: ConversationSummary, myId: String, onClick: () -> Unit) {
    val hasUnread = c.unreadCount > 0

    val preview = when {
        c.lastMessageDeleted -> "Message deleted"
        c.lastMessageBody == null ->
            if (c.type == "group") "Say hello to your farm team" else "No messages yet"
        else -> (if (c.lastMessageSenderId == myId) "You: " else "") + c.lastMessageBody
    }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        InitialsAvatar(name = c.displayTitle)
        Spacer(Modifier.width(12.dp))

        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = c.displayTitle,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = if (hasUnread) FontWeight.Bold else FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    text = c.lastActivityAt.listLabel(),
                    style = MaterialTheme.typography.labelSmall,
                    color = if (hasUnread) MaterialTheme.colorScheme.primary
                    else MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = preview,
                    modifier = Modifier.weight(1f),
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (hasUnread) MaterialTheme.colorScheme.onSurface
                    else MaterialTheme.colorScheme.onSurfaceVariant,
                    fontWeight = if (hasUnread) FontWeight.Medium else FontWeight.Normal,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (hasUnread) {
                    Spacer(Modifier.width(8.dp))
                    Badge(containerColor = MaterialTheme.colorScheme.primary) {
                        Text(if (c.unreadCount > 99) "99+" else c.unreadCount.toString())
                    }
                }
            }
        }
    }
}
