package com.example.farmproject.data.remote

import com.example.farmproject.BuildConfig
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.realtime.Realtime
import io.github.jan.supabase.storage.Storage

object SupabaseClientProvider {

    private val SUPABASE_URL: String = BuildConfig.SUPABASE_URL
    private val SUPABASE_ANON_KEY: String = BuildConfig.SUPABASE_ANON_KEY

    val client: SupabaseClient = createSupabaseClient(
        supabaseUrl = SUPABASE_URL,
        supabaseKey = SUPABASE_ANON_KEY
    ) {
        install(Postgrest)
        install(Auth) {
            alwaysAutoRefresh = true
            autoLoadFromStorage = true
            autoSaveToStorage = true
        }
        install(Storage)
        install(Functions)
        install(Realtime)
    }

    /**
     * Isolated client used for background employee registration (Supervisors/Workers).
     * Disables session persistence so the active Manager's session is not overwritten or corrupted.
     */
    fun createIsolatedAuthClient(): SupabaseClient {
        return createSupabaseClient(
            supabaseUrl = SUPABASE_URL,
            supabaseKey = SUPABASE_ANON_KEY
        ) {
            install(Postgrest)
            install(Auth) {
                alwaysAutoRefresh = false
                autoLoadFromStorage = false
                autoSaveToStorage = false
            }
        }
    }
}
