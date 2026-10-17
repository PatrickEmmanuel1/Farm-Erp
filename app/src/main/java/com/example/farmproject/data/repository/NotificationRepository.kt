package com.example.farmproject.data.repository

import com.example.farmproject.data.model.AppNotification
import com.example.farmproject.data.remote.SupabaseClientProvider
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.query.Order
import io.github.jan.supabase.realtime.PostgresAction
import io.github.jan.supabase.realtime.RealtimeChannel
import io.github.jan.supabase.realtime.channel
import io.github.jan.supabase.realtime.postgresChangeFlow
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch

class NotificationRepository(
    private val supabase: SupabaseClient = SupabaseClientProvider.client
) {

    suspend fun fetch(): List<AppNotification> = try {
        supabase.from("notification")
            .select {
                order("created_at", Order.DESCENDING)
                limit(50)
            }
            .decodeList()
    } catch (_: Exception) {
        emptyList()
    }

    suspend fun markRead(id: String) {
        try {
            supabase.from("notification").update({ set("is_read", true) }) {
                filter { eq("notification_id", id) }
            }
        } catch (_: Exception) {}
    }

    suspend fun markAllRead() {
        try {
            supabase.from("notification").update({ set("is_read", true) }) {
                filter { eq("is_read", false) }
            }
        } catch (_: Exception) {}
    }

    fun inserts(scope: CoroutineScope, onNew: () -> Unit): RealtimeChannel? {
        return try {
            val channel = supabase.channel("notifications")
            val flow: Flow<PostgresAction.Insert> = channel.postgresChangeFlow<PostgresAction.Insert>(schema = "public") {
                table = "notification"
            }
            flow.onEach { _ -> onNew() }.launchIn(scope)
            scope.launch {
                try {
                    channel.subscribe()
                } catch (_: Exception) {}
            }
            channel
        } catch (_: Exception) {
            null
        }
    }
}
