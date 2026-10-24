// =====================================================================
// ChatViewModelFactories.kt
// Plain ViewModelProvider factories. Skip this file if your project
// already uses Hilt or Koin to provide ViewModels.
//
// Usage in a screen:
//   val repo = ChatRepository(supabase)
//   val listVm: ChatListViewModel = viewModel(factory = ChatListViewModelFactory(repo))
//   val chatVm: ChatViewModel = viewModel(factory = ChatViewModelFactory(repo, conversationId))
// =====================================================================
package com.example.farmproject.ui.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.example.farmproject.data.repository.ChatRepository

class ChatListViewModelFactory(
    private val repo: ChatRepository,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T =
        ChatListViewModel(repo) as T
}

class ChatViewModelFactory(
    private val repo: ChatRepository,
    private val conversationId: String,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T =
        ChatViewModel(repo, conversationId) as T
}
