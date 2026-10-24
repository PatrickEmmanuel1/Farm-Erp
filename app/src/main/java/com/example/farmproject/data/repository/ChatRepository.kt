// =====================================================================
// ChatRepository.kt
// Every Supabase call the chat feature makes: RPCs, queries, inserts,
// and the realtime subscription.
// =====================================================================
package com.example.farmproject.data.repository

import com.example.farmproject.data.model.ChatMessage
import com.example.farmproject.data.model.Contact
import com.example.farmproject.data.model.ConversationSummary
import com.example.farmproject.data.model.Person
import com.example.farmproject.data.remote.SupabaseClientProvider
import com.example.farmproject.data.session.CurrentSession
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.auth
import io.github.jan.supabase.exceptions.RestException
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.postgrest.query.filter.FilterOperator
import io.github.jan.supabase.postgrest.rpc
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.RealtimeChannel
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.decodeRecord
import io.github.jan.supabase.realtime.postgresChangeFlow
import io.github.jan.supabase.realtime.realtime
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import java.util.UUID
import kotlin.time.Instant

// Only the columns the database lets clients insert.
@Serializable
private data class NewMessage(
    @SerialName("conversation_id") val conversationId: String,
    @SerialName("sender_id") val senderId: String,
    val body: String,
    @SerialName("client_message_id") val clientMessageId: String,
)

// RPC parameter names must match the SQL argument names exactly.
@Serializable private data class SearchParams(@SerialName("p_query") val query: String)
@Serializable private data class OpenDirectParams(@SerialName("other_id") val otherId: String)
@Serializable private data class ConversationParam(@SerialName("p_conversation_id") val id: String)

class ChatRepository(private val supabase: SupabaseClient = SupabaseClientProvider.client) {

    val myId: String
        get() = CurrentSession.userId ?: supabase.auth.currentUserOrNull()?.id ?: ""

    // ---- chat list -------------------------------------------------
    suspend fun conversations(): List<ConversationSummary> =
        try {
            val list = supabase.postgrest.rpc("my_conversations").decodeList<ConversationSummary>()
            deduplicateConversations(list)
        } catch (_: Exception) {
            getConversationsFallback()
        }

    private fun deduplicateConversations(list: List<ConversationSummary>): List<ConversationSummary> {
        val directChats = list.filter { it.type == "direct" && !it.otherAccountId.isNullOrBlank() }
            .groupBy { it.otherAccountId }
            .mapValues { (_, convs) ->
                convs.maxByOrNull { (if (it.lastMessageBody != null) 1000000000000000L else 0L) + it.lastActivityAt.toEpochMilliseconds() }!!
            }
            .values.toList()

        val groupChats = list.filter { it.type == "group" }
            .groupBy { it.title ?: "Farm Team" }
            .mapValues { (_, convs) ->
                convs.maxByOrNull { (if (it.lastMessageBody != null) 1000000000000000L else 0L) + it.lastActivityAt.toEpochMilliseconds() }!!
            }
            .values.toList()

        return (directChats + groupChats).distinctBy { it.conversationId }
            .sortedByDescending { it.lastActivityAt }
    }

    private suspend fun getConversationsFallback(): List<ConversationSummary> {
        val currentAccountId = myId
        if (currentAccountId.isBlank()) return emptyList()

        try {
            val myParticipants = supabase.from("conversation_participant")
                .select { filter { eq("account_id", currentAccountId) } }
                .decodeList<JsonObject>()

            val myConvIds = myParticipants.mapNotNull { it["conversation_id"]?.jsonPrimitive?.contentOrNull }.distinct()
            if (myConvIds.isEmpty()) return emptyList()

            val conversations = supabase.from("conversation")
                .select { filter { isIn("conversation_id", myConvIds) } }
                .decodeList<JsonObject>()

            val resultList = mutableListOf<ConversationSummary>()

            for (conv in conversations) {
                val convId = conv["conversation_id"]?.jsonPrimitive?.contentOrNull ?: continue
                val type = conv["type"]?.jsonPrimitive?.contentOrNull ?: "direct"
                val title = conv["title"]?.jsonPrimitive?.contentOrNull ?: if (type == "group") "Farm Team" else null

                // Find other participant for direct chat
                var otherId: String? = null
                var otherName: String? = null

                if (type == "direct") {
                    val otherPart = supabase.from("conversation_participant")
                        .select {
                            filter {
                                eq("conversation_id", convId)
                                neq("account_id", currentAccountId)
                            }
                        }
                        .decodeList<JsonObject>()
                        .firstOrNull()

                    otherId = otherPart?.get("account_id")?.jsonPrimitive?.contentOrNull
                    if (!otherId.isNullOrBlank()) {
                        val otherAccount = supabase.from("account")
                            .select { filter { eq("account_id", otherId) } }
                            .decodeList<JsonObject>()
                            .firstOrNull()
                        otherName = otherAccount?.get("full_name")?.jsonPrimitive?.contentOrNull ?: "Team Member"
                    }
                }

                // Fetch latest message
                val lastMsgs = supabase.from("message")
                    .select {
                        filter { eq("conversation_id", convId) }
                        order("created_at", Order.DESCENDING)
                        limit(1)
                    }
                    .decodeList<JsonObject>()

                val lastMsg = lastMsgs.firstOrNull()
                val lastBody = lastMsg?.get("body")?.jsonPrimitive?.contentOrNull
                val lastSenderId = lastMsg?.get("sender_id")?.jsonPrimitive?.contentOrNull
                val lastTimeStr = lastMsg?.get("created_at")?.jsonPrimitive?.contentOrNull
                val lastInstant = if (!lastTimeStr.isNullOrBlank()) {
                    try { Instant.parse(lastTimeStr) } catch (_: Exception) { null }
                } else null

                resultList.add(
                    ConversationSummary(
                        conversationId = convId,
                        type = type,
                        farmId = CurrentSession.farmId,
                        title = title,
                        otherAccountId = otherId,
                        otherName = otherName,
                        lastMessageBody = lastBody,
                        lastMessageSenderId = lastSenderId,
                        lastActivityAt = lastInstant ?: Instant.fromEpochMilliseconds(0)
                    )
                )
            }

            return deduplicateConversations(resultList)
        } catch (_: Exception) {
            return emptyList()
        }
    }

    // ---- starting a chat -------------------------------------------
    suspend fun searchContacts(query: String = ""): List<Contact> =
        try {
            supabase.postgrest.rpc("search_message_contacts", SearchParams(query)).decodeList()
        } catch (_: Exception) {
            getContactsFallback(query)
        }

    private suspend fun getContactsFallback(query: String): List<Contact> {
        val farmId = CurrentSession.farmId
        val currentAccountId = myId

        val contactsList = mutableListOf<Contact>()
        val employeeRepository = EmployeeRepository(supabase)

        // 1. Fetch supervisors
        try {
            val supervisors = employeeRepository.getSupervisorsForFarm(farmId)
            supervisors.forEach { sup ->
                val accId = sup.accountId
                if (!accId.isNullOrBlank() && accId != currentAccountId) {
                    contactsList.add(Contact(accountId = accId, fullName = sup.fullName + " (Supervisor)"))
                }
            }
        } catch (_: Exception) {}

        // 2. Fetch workers
        try {
            val workers = employeeRepository.getWorkersForFarm(farmId)
            workers.forEach { wrk ->
                val accId = wrk.accountId
                if (!accId.isNullOrBlank() && accId != currentAccountId) {
                    contactsList.add(Contact(accountId = accId, fullName = wrk.fullName + " (Worker)"))
                }
            }
        } catch (_: Exception) {}

        // 3. Fetch farm manager account if current user is not the manager
        try {
            if (farmId.isNotBlank()) {
                val farms = supabase.from("farm")
                    .select { filter { eq("farm_id", farmId) } }
                    .decodeList<JsonObject>()

                val managerAccountId = farms.firstOrNull()?.get("account_id")?.jsonPrimitive?.contentOrNull
                if (!managerAccountId.isNullOrBlank() && managerAccountId != currentAccountId) {
                    val managerAccounts = supabase.from("account")
                        .select { filter { eq("account_id", managerAccountId) } }
                        .decodeList<JsonObject>()

                    val managerName = managerAccounts.firstOrNull()?.get("full_name")?.jsonPrimitive?.contentOrNull ?: "Farm Manager"
                    contactsList.add(0, Contact(accountId = managerAccountId, fullName = managerName + " (Manager)"))
                }
            }
        } catch (_: Exception) {}

        // Filter by query if query is not blank
        val trimmedQuery = query.trim()
        val filtered = if (trimmedQuery.isBlank()) {
            contactsList
        } else {
            contactsList.filter {
                it.fullName.contains(trimmedQuery, ignoreCase = true)
            }
        }

        return filtered.distinctBy { it.accountId }
    }

    /** Returns the conversation id (existing or newly created). */
    suspend fun openDirectChat(otherAccountId: String): String =
        try {
            supabase.postgrest
                .rpc("get_or_create_direct_conversation", OpenDirectParams(otherAccountId))
                .decodeAs<String>()
        } catch (_: Exception) {
            openDirectChatFallback(otherAccountId)
        }

    private suspend fun openDirectChatFallback(otherAccountId: String): String {
        val currentAccountId = myId
        val farmId = CurrentSession.farmId

        // 1. Find existing direct conversation between currentAccountId and otherAccountId
        try {
            val myParticipants = supabase.from("conversation_participant")
                .select { filter { eq("account_id", currentAccountId) } }
                .decodeList<JsonObject>()

            val myConvIds = myParticipants.mapNotNull { it["conversation_id"]?.jsonPrimitive?.contentOrNull }.distinct()

            if (myConvIds.isNotEmpty()) {
                val directConvs = supabase.from("conversation")
                    .select {
                        filter {
                            isIn("conversation_id", myConvIds)
                            eq("type", "direct")
                        }
                    }
                    .decodeList<JsonObject>()

                val directConvIds = directConvs.mapNotNull { it["conversation_id"]?.jsonPrimitive?.contentOrNull }

                if (directConvIds.isNotEmpty()) {
                    val otherParticipants = supabase.from("conversation_participant")
                        .select {
                            filter {
                                eq("account_id", otherAccountId)
                                isIn("conversation_id", directConvIds)
                            }
                        }
                        .decodeList<JsonObject>()

                    val existingConvId = otherParticipants.firstOrNull()?.get("conversation_id")?.jsonPrimitive?.contentOrNull
                    if (!existingConvId.isNullOrBlank()) {
                        return existingConvId
                    }
                }
            }
        } catch (_: Exception) {}

        // 2. Create new direct conversation row in conversation table
        val newConvId = UUID.randomUUID().toString()
        try {
            supabase.from("conversation").insert(
                buildJsonObject {
                    put("conversation_id", newConvId)
                    put("type", "direct")
                    put("farm_id", farmId)
                }
            )

            // Insert participants
            supabase.from("conversation_participant").insert(
                listOf(
                    buildJsonObject {
                        put("conversation_id", newConvId)
                        put("account_id", currentAccountId)
                    },
                    buildJsonObject {
                        put("conversation_id", newConvId)
                        put("account_id", otherAccountId)
                    }
                )
            )
        } catch (_: Exception) {}

        return newConvId
    }

    // ---- inside a chat ---------------------------------------------
    suspend fun people(conversationId: String): List<Person> =
        try {
            supabase.postgrest.rpc("get_conversation_people", ConversationParam(conversationId)).decodeList()
        } catch (_: Exception) {
            getPeopleFallback(conversationId)
        }

    private suspend fun getPeopleFallback(conversationId: String): List<Person> {
        try {
            val participants = supabase.from("conversation_participant")
                .select { filter { eq("conversation_id", conversationId) } }
                .decodeList<JsonObject>()

            val accountIds = participants.mapNotNull { it["account_id"]?.jsonPrimitive?.contentOrNull }
            if (accountIds.isEmpty()) return emptyList()

            val accounts = supabase.from("account")
                .select { filter { isIn("account_id", accountIds) } }
                .decodeList<JsonObject>()

            return accounts.map { acc ->
                val accId = acc["account_id"]?.jsonPrimitive?.contentOrNull ?: ""
                val name = acc["full_name"]?.jsonPrimitive?.contentOrNull ?: "Team Member"
                Person(accountId = accId, fullName = name)
            }
        } catch (_: Exception) {
            return emptyList()
        }
    }

    /** Newest first. Pass [before] (created_at of the oldest loaded message) to page back. */
    suspend fun messages(
        conversationId: String,
        before: Instant? = null,
        limit: Int = 50,
    ): List<ChatMessage> =
        supabase.from("message").select {
            filter {
                eq("conversation_id", conversationId)
                if (before != null) lt("created_at", before.toString())
            }
            order("created_at", Order.DESCENDING)
            limit(limit.toLong())
        }.decodeList()

    /**
     * Safe to retry: client_message_id is unique in the database, so a retry
     * of a message that already arrived is treated as success.
     */
    suspend fun send(conversationId: String, body: String, clientMessageId: String) {
        try {
            supabase.from("message").insert(
                NewMessage(conversationId, myId, body.trim(), clientMessageId)
            )
        } catch (e: RestException) {
            if (e.message.orEmpty().contains("duplicate key")) return
            throw e
        }
    }

    suspend fun deleteMessage(messageId: String) {
        supabase.from("message").update({ set("is_deleted", true) }) {
            filter { eq("message_id", messageId) }
        }
    }

    suspend fun markRead(conversationId: String) {
        try {
            supabase.postgrest.rpc("mark_conversation_read", ConversationParam(conversationId))
        } catch (_: Exception) {}
    }

    // ---- realtime --------------------------------------------------
    fun messageInserts(conversationId: String?): Pair<RealtimeChannel, Flow<ChatMessage>> {
        val topic = "message-" + (conversationId ?: "all-${UUID.randomUUID()}")
        val channel = supabase.channel(topic)
        val flow = channel
            .postgresChangeFlow<PostgresAction.Insert>(schema = "public") {
                table = "message"
                if (conversationId != null) {
                    filter("conversation_id", FilterOperator.EQ, conversationId)
                }
            }
            .map { it.decodeRecord<ChatMessage>() }
        return channel to flow
    }

    suspend fun closeChannel(channel: RealtimeChannel) {
        try {
            channel.unsubscribe()
            supabase.realtime.removeChannel(channel)
        } catch (_: Exception) {}
    }
}
