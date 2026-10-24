// =====================================================================
// ChatNavigation.kt
// Routes + one function that plugs the three chat screens into your
// existing NavHost.
//
// DEPENDENCIES
//   androidx.navigation:navigation-compose
//   androidx.lifecycle:lifecycle-runtime-compose  (2.7+)
//   androidx.compose.material3:material3          (1.2+)
//
// USAGE - inside your existing NavHost { ... }:
//
//   val repo = remember { ChatRepository(supabase) }
//   NavHost(navController, startDestination = "dashboard") {
//       // ...your other destinations...
//       chatGraph(navController, repo)
//   }
//
// Then open the chat list from any screen (e.g. a "Messages" button):
//   navController.navigate(ChatRoutes.LIST)
// =====================================================================
package com.example.farmproject.ui.chat

import android.net.Uri
import androidx.compose.runtime.remember
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavType
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.example.farmproject.data.repository.ChatRepository

object ChatRoutes {
    const val LIST = "chat_list"
    const val NEW = "chat_new"
    const val CHAT = "chat/{conversationId}?title={title}&group={group}"

    fun chat(conversationId: String, title: String, isGroup: Boolean): String =
        "chat/$conversationId?title=${Uri.encode(title)}&group=$isGroup"
}

fun NavGraphBuilder.chatGraph(navController: NavController, repo: ChatRepository) {

    // ---- Chat list -------------------------------------------------
    composable(ChatRoutes.LIST) {
        val vm: ChatListViewModel = viewModel(factory = ChatListViewModelFactory(repo))

        ChatListScreen(
            viewModel = vm,
            myId = repo.myId,
            onOpenChat = { c ->
                navController.navigate(
                    ChatRoutes.chat(c.conversationId, c.displayTitle, isGroup = c.type == "group")
                )
            },
            onNewChat = { navController.navigate(ChatRoutes.NEW) },
            onBack = { navController.popBackStack() },
        )
    }

    // ---- New chat (contact picker) ---------------------------------
    composable(ChatRoutes.NEW) { entry ->
        // Reuse the list screen's ViewModel so we don't open a second realtime connection.
        val listEntry = remember(entry) {
            try {
                navController.getBackStackEntry(ChatRoutes.LIST)
            } catch (_: Exception) {
                entry
            }
        }
        val listVm: ChatListViewModel = viewModel(
            viewModelStoreOwner = listEntry,
            factory = ChatListViewModelFactory(repo),
        )

        NewChatScreen(
            search = listVm::searchContacts,
            startChat = listVm::startChatWith,
            onBack = { navController.popBackStack() },
            onChatReady = { conversationId, title ->
                navController.navigate(ChatRoutes.chat(conversationId, title, isGroup = false)) {
                    // Back from the chat returns to the list, not the picker.
                    popUpTo(ChatRoutes.NEW) { inclusive = true }
                }
            },
        )
    }

    // ---- One conversation ------------------------------------------
    composable(
        route = ChatRoutes.CHAT,
        arguments = listOf(
            navArgument("conversationId") { type = NavType.StringType },
            navArgument("title") {
                type = NavType.StringType
                defaultValue = "Chat"
            },
            navArgument("group") {
                type = NavType.BoolType
                defaultValue = false
            },
        ),
    ) { entry ->
        val conversationId = entry.arguments?.getString("conversationId").orEmpty()
        val title = entry.arguments?.getString("title") ?: "Chat"
        val isGroup = entry.arguments?.getBoolean("group") ?: false

        val vm: ChatViewModel = viewModel(factory = ChatViewModelFactory(repo, conversationId))

        ChatScreen(
            viewModel = vm,
            title = title,
            isGroup = isGroup,
            onBack = { navController.popBackStack() },
        )
    }
}
