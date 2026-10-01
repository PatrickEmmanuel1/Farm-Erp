package com.example.farmproject.data.remote

import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.Auth
import io.github.jan.supabase.createSupabaseClient
import io.github.jan.supabase.functions.Functions
import io.github.jan.supabase.postgrest.Postgrest
import io.github.jan.supabase.storage.Storage

object SupabaseClientProvider {

    private const val SUPABASE_URL = "https://grlxcuutqwunnruipbzg.supabase.co"
    private const val SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdybHhjdXV0cXd1bm5ydWlwYnpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxNjIzNTcsImV4cCI6MjEwMzczODM1N30.e43rmKwPy1cgXYimIxGfglplSCpSZdQlXZqXL4OhMSI"

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
