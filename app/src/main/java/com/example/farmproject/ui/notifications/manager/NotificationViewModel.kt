package com.example.farmproject.ui.notifications.manager

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.farmproject.data.model.AppNotification
import com.example.farmproject.data.repository.NotificationRepository
import io.github.jan.supabase.realtime.RealtimeChannel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class NotificationViewModel(
    private val repo: NotificationRepository = NotificationRepository()
) : ViewModel() {

    private val _items = MutableStateFlow<List<AppNotification>>(emptyList())
    val items = _items.asStateFlow()
    val unreadCount = items.map { list -> list.count { !it.isRead } }
        .stateIn(viewModelScope, SharingStarted.Eagerly, 0)

    private var channel: RealtimeChannel? = null

    init {
        refresh()
        try {
            channel = repo.inserts(viewModelScope) { refresh() }
        } catch (_: Exception) {}
    }

    fun refresh() = viewModelScope.launch {
        runCatching { repo.fetch() }.onSuccess { _items.value = it }
    }

    fun markRead(id: String) = viewModelScope.launch {
        repo.markRead(id)
        _items.update { l -> l.map { if (it.id == id) it.copy(isRead = true) else it } }
    }

    fun markAllRead() = viewModelScope.launch {
        repo.markAllRead()
        _items.update { l -> l.map { it.copy(isRead = true) } }
    }

    override fun onCleared() {
        super.onCleared()
        viewModelScope.launch {
            try {
                channel?.unsubscribe()
            } catch (_: Exception) {}
        }
    }
}
