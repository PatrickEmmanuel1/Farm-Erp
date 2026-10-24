// =====================================================================
// ChatModels.kt
// Data classes. Field names match the SQL columns / function outputs.
// Change the package to match your project (same package in all 5 files).
// =====================================================================
package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.time.Instant

/** One row of my_conversations() - a line on the chat list screen. */
@Serializable
data class ConversationSummary(
    @SerialName("conversation_id") val conversationId: String,
    val type: String,                                   // "direct" | "group"
    @SerialName("farm_id") val farmId: String? = null,
    val title: String? = null,
    @SerialName("other_account_id") val otherAccountId: String? = null,
    @SerialName("other_name") val otherName: String? = null,
    @SerialName("last_message_body") val lastMessageBody: String? = null,
    @SerialName("last_message_sender_id") val lastMessageSenderId: String? = null,
    @SerialName("last_message_deleted") val lastMessageDeleted: Boolean = false,
    @SerialName("last_activity_at") val lastActivityAt: Instant,
    @SerialName("unread_count") val unreadCount: Long = 0,
) {
    val displayTitle: String
        get() = if (type == "direct") otherName ?: "Chat" else title ?: "Farm Team"
}

/** A person you can start a chat with (search_message_contacts()). */
@Serializable
data class Contact(
    @SerialName("account_id") val accountId: String,
    @SerialName("full_name") val fullName: String,
    @SerialName("role_id") val roleId: String? = null,
)

/** A person shown inside a conversation, for names on message bubbles (get_conversation_people()). */
@Serializable
data class Person(
    @SerialName("account_id") val accountId: String,
    @SerialName("full_name") val fullName: String,
    @SerialName("role_id") val roleId: String? = null,
    @SerialName("is_active") val isActive: Boolean = true,
)

/** A message row exactly as stored in the database. */
@Serializable
data class ChatMessage(
    @SerialName("message_id") val messageId: String,
    @SerialName("conversation_id") val conversationId: String,
    @SerialName("sender_id") val senderId: String? = null,
    val body: String,
    @SerialName("client_message_id") val clientMessageId: String? = null,
    @SerialName("is_deleted") val isDeleted: Boolean = false,
    @SerialName("created_at") val createdAt: Instant,
)
