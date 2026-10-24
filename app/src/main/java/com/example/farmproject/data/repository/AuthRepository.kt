package com.example.farmproject.data.repository

import com.example.farmproject.data.remote.SupabaseClientProvider
import com.example.farmproject.data.session.CurrentSession
import io.github.jan.supabase.SupabaseClient
import io.github.jan.supabase.auth.*
import io.github.jan.supabase.auth.status.SessionStatus
import io.github.jan.supabase.auth.providers.builtin.Email
import io.github.jan.supabase.postgrest.from
import io.github.jan.supabase.postgrest.postgrest
import kotlinx.coroutines.flow.StateFlow
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import java.util.UUID

@Serializable
internal data class AccountSignUpInsert(
    @SerialName("account_id") val accountId: String? = null,
    @SerialName("full_name") val fullName: String,
    val email: String,
    @SerialName("phone_number") val phoneNumber: String? = null
)

@Serializable
data class AccountSignUpResult(
    @SerialName("account_id") val accountId: String,
    @SerialName("full_name") val fullName: String,
    val email: String,
    @SerialName("phone_number") val phoneNumber: String? = null,
    val role: String? = null
)

@Serializable
internal data class RoleLookup(
    @SerialName("role_id") val roleId: String,
    @SerialName("role_name") val roleName: String
)

class AuthRepository(
    private val client: SupabaseClient = SupabaseClientProvider.client
) {

    /**
     * Exposes Supabase Auth session status StateFlow (Authenticated / NotAuthenticated).
     */
    val sessionStatus: StateFlow<SessionStatus> = client.auth.sessionStatus

    suspend fun ensureManagerAccount(userId: String, fullName: String, email: String, phoneNumber: String?) {
        val managerRoleId = try {
            client.from("role")
                .select {
                    filter {
                        ilike("role_name", "Manager")
                    }
                }
                .decodeList<RoleLookup>()
                .firstOrNull()?.roleId
        } catch (_: Exception) {
            null
        }

        try {
            client.from("account").upsert(
                buildJsonObject {
                    put("account_id", userId)
                    if (managerRoleId != null) put("role_id", managerRoleId)
                    put("full_name", fullName)
                    put("email", email)
                    if (phoneNumber != null) put("phone_number", phoneNumber)
                }
            )
        } catch (_: Exception) {}

        try {
            client.from("manager_profile").upsert(
                buildJsonObject {
                    put("manager_profile_id", UUID.randomUUID().toString())
                    put("account_id", userId)
                }
            )
        } catch (_: Exception) {}
    }

    // -------------------------------------------------------------------
    // Exact Supabase Database RPC Functions
    // -------------------------------------------------------------------


    suspend fun getMyAccount(): AccountSignUpResult? {
        return try {
            client.postgrest.rpc("get_my_account").decodeSingleOrNull<AccountSignUpResult>()
        } catch (_: Exception) {
            null
        }
    }

    @Suppress( "unused")
    suspend fun getMyRole(): String? {
        return try {
            client.postgrest.rpc("get_my_role").decodeSingleOrNull<String>()
        } catch (_: Exception) {
            null
        }
    }

    @Suppress( "unused")
    suspend fun currentUserRole(): String? {
        return try {
            client.postgrest.rpc("current_user_role").decodeSingleOrNull<String>()
        } catch (_: Exception) {
            null
        }
    }

    @Suppress( "unused")
    suspend fun hasFarmAccess(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "has_farm_access",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    @Suppress( "unused")
    suspend fun isFarmManager(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "is_farm_manager",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    @Suppress( "unused")
    suspend fun isFarmSupervisor(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "is_farm_supervisor",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    @Suppress( "unused")
    suspend fun isFarmWorker(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "is_farm_worker",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    suspend fun createAccount(fullName: String, email: String, phoneNumber: String?, role: String = "Manager") {
        try {
            client.postgrest.rpc(
                function = "create_account",
                parameters = buildJsonObject {
                    put("p_full_name", fullName)
                    put("p_email", email)
                    if (phoneNumber != null) put("p_phone_number", phoneNumber)
                    put("p_role", role)
                }
            )
        } catch (_: Exception) {}
    }

    // -------------------------------------------------------------------
    // Authentication Operations
    // -------------------------------------------------------------------

    private fun sanitizeAuthErrorMessage(rawError: String?, isSignUp: Boolean = false): String {
        if (rawError.isNullOrBlank()) {
            return if (isSignUp) "Sign up failed. Please check your details and try again."
                   else "Invalid credentials. Please check your email and password."
        }

        val lower = rawError.lowercase()

        return when {
            lower.contains("email_not_confirmed") ->
                "Email not confirmed. Please check your inbox or confirm user in Supabase Dashboard."
            lower.contains("invalid_credentials") || lower.contains("invalid login credentials") || lower.contains("invalid_grant") ->
                "Invalid email or password. Please check your credentials and try again."
            lower.contains("user_not_found") ->
                "No account found for this email. Please sign up first."
            lower.contains("user_already_exists") || lower.contains("already registered") ->
                "An account with this email already exists. Please sign in instead."
            lower.contains("password") && lower.contains("should be at least") ->
                "Password must be at least 6 characters long."
            else -> {
                val cleanLine = rawError.lines().firstOrNull { line ->
                    !line.contains("URL:", ignoreCase = true) &&
                    !line.contains("Headers:", ignoreCase = true) &&
                    !line.contains("Http Method:", ignoreCase = true)
                }?.trim()

                if (!cleanLine.isNullOrBlank() && cleanLine.length < 100) {
                    cleanLine
                } else if (isSignUp) {
                    "Sign up failed. Please check your details and try again."
                } else {
                    "Invalid email or password. Please check your credentials and try again."
                }
            }
        }
    }

    suspend fun loginUser(
        email: String,
        password: String,
        expectedRole: String? = null
    ): Result<AccountSignUpResult> {
        val trimmedEmail = email.trim()

        return try {
            client.auth.awaitInitialization()

            // 1. Attempt Supabase Auth Sign In (GoTrue)
            var authErrorMsg: String? = null
            var authSuccess = false
            try {
                client.auth.signInWith(Email) {
                    this.email = trimmedEmail
                    this.password = password
                }
                authSuccess = true
            } catch (e: Exception) {
                authErrorMsg = e.message
            }

            if (!authSuccess) {
                val cleanMessage = sanitizeAuthErrorMessage(authErrorMsg, isSignUp = false)
                return Result.failure(Exception(cleanMessage))
            }

            // 2. Query public.account table
            val accounts = try {
                client.from("account")
                    .select {
                        filter {
                            eq("email", trimmedEmail)
                        }
                    }
                    .decodeList<AccountSignUpResult>()
            } catch (_: Exception) {
                emptyList()
            }

            // 3. Resolve logged-in user profile details
            val authUser = client.auth.currentUserOrNull()
            val metaName = authUser?.userMetadata?.get("full_name")?.jsonPrimitive?.content
            val fallbackName = metaName ?: trimmedEmail.substringBefore("@").replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }

            val dbAccount = accounts.firstOrNull()
            val metaRole = authUser?.userMetadata?.get("role")?.jsonPrimitive?.contentOrNull

            val currentAccountId = dbAccount?.accountId ?: authUser?.id.orEmpty()

            val supervisorFarmId = if (currentAccountId.isNotBlank()) {
                try {
                    val rows = client.from("supervisor_profile").select { filter { eq("account_id", currentAccountId) } }.decodeList<JsonObject>()
                    rows.firstOrNull()?.get("farm_id")?.jsonPrimitive?.contentOrNull
                } catch (_: Exception) { null }
            } else null

            val workerFarmId = if (currentAccountId.isNotBlank() && supervisorFarmId == null) {
                try {
                    val rows = client.from("worker_profile").select { filter { eq("account_id", currentAccountId) } }.decodeList<JsonObject>()
                    rows.firstOrNull()?.get("farm_id")?.jsonPrimitive?.contentOrNull
                } catch (_: Exception) { null }
            } else null

            val isSupervisorProfile = supervisorFarmId != null
            val isWorkerProfile = workerFarmId != null

            val detectedRole = when {
                isSupervisorProfile -> "Supervisor"
                isWorkerProfile -> "Worker"
                !dbAccount?.role.isNullOrBlank() -> dbAccount.role
                !metaRole.isNullOrBlank() -> metaRole
                else -> "Manager"
            }

            val userRole = expectedRole ?: detectedRole

            val account = dbAccount ?: AccountSignUpResult(
                accountId = authUser?.id ?: UUID.randomUUID().toString(),
                fullName = fallbackName,
                email = authUser?.email ?: trimmedEmail,
                phoneNumber = null,
                role = userRole
            )

            // Force update role in account table if signing in from Supervisor/Worker portal
            try {
                if (expectedRole.equals("Supervisor", ignoreCase = true) || expectedRole.equals("Worker", ignoreCase = true)) {
                    client.from("account")
                        .update(buildJsonObject { put("role", expectedRole) }) {
                            filter {
                                eq("email", trimmedEmail)
                            }
                        }
                }
            } catch (_: Exception) {}

            if (userRole.equals("Manager", ignoreCase = true)) {
                ensureManagerAccount(account.accountId, account.fullName.ifBlank { fallbackName }, account.email, account.phoneNumber)
            }

            val farm = FarmRepository(client).getFarmForUser(account.accountId)
            val resolvedFarmId = supervisorFarmId ?: workerFarmId ?: farm?.farmId ?: ""

            CurrentSession.updateSession(
                userId = account.accountId,
                fullName = account.fullName.ifBlank { fallbackName },
                email = account.email,
                phoneNumber = account.phoneNumber,
                userRole = userRole,
                farmId = resolvedFarmId
            )
            Result.success(account.copy(role = userRole))
        } catch (e: Exception) {
            Result.failure(Exception(sanitizeAuthErrorMessage(e.message, isSignUp = false)))
        }
    }

    suspend fun signUpManager(
        fullName: String,
        email: String,
        phoneNumber: String?,
        password: String
    ): Result<AccountSignUpResult> {
        val trimmedEmail = email.trim()

        return try {
            client.auth.awaitInitialization()

            // 1. Register with Supabase Auth (GoTrue) storing full_name in user metadata
            var authUserId: String? = null
            var signUpError: String? = null
            try {
                client.auth.signUpWith(Email) {
                    this.email = trimmedEmail
                    this.password = password
                    data = buildJsonObject {
                        put("full_name", fullName)
                        if (phoneNumber != null) put("phone_number", phoneNumber)
                        put("role", "Manager")
                    }
                }
                authUserId = client.auth.currentUserOrNull()?.id
            } catch (e: Exception) {
                signUpError = e.message
            }

            // Attempt signInWith to establish active session if signUp didn't automatically issue token
            if (client.auth.currentSessionOrNull() == null) {
                try {
                    client.auth.signInWith(Email) {
                        this.email = trimmedEmail
                        this.password = password
                    }
                    authUserId = client.auth.currentUserOrNull()?.id
                } catch (e: Exception) {
                    if (signUpError == null) {
                        signUpError = e.message
                    }
                }
            }

            // If neither signUp nor signIn established an auth session or returned user ID
            if (client.auth.currentSessionOrNull() == null && authUserId == null) {
                val cleanMessage = sanitizeAuthErrorMessage(signUpError, isSignUp = true)
                return Result.failure(Exception(cleanMessage))
            }

            val currentAuthId = authUserId ?: client.auth.currentUserOrNull()?.id ?: UUID.randomUUID().toString()

            // 2. Insert row directly into public.account table or call create_account RPC
            var insertedAccount: AccountSignUpResult? = null
            try {
                createAccount(fullName = fullName, email = trimmedEmail, phoneNumber = phoneNumber, role = "Manager")
            } catch (_: Exception) {
                try {
                    insertedAccount = client.from("account")
                        .insert(
                            AccountSignUpInsert(
                                accountId = currentAuthId,
                                fullName = fullName,
                                email = trimmedEmail,
                                phoneNumber = phoneNumber
                            )
                        ) {
                            select()
                        }
                        .decodeSingle<AccountSignUpResult>()
                } catch (_: Exception) {
                    try {
                        insertedAccount = client.from("account")
                            .select {
                                filter {
                                    eq("email", trimmedEmail)
                                }
                            }
                            .decodeSingleOrNull<AccountSignUpResult>()
                    } catch (_: Exception) {}
                }
            }

            val result = insertedAccount ?: AccountSignUpResult(
                accountId = currentAuthId,
                fullName = fullName,
                email = trimmedEmail,
                phoneNumber = phoneNumber,
                role = "Manager"
            )

            ensureManagerAccount(currentAuthId, fullName, trimmedEmail, phoneNumber)

            CurrentSession.updateSession(
                userId = result.accountId,
                fullName = result.fullName,
                email = result.email,
                phoneNumber = result.phoneNumber,
                userRole = "Manager",
                farmId = ""
            )

            Result.success(result)
        } catch (e: Exception) {
            Result.failure(Exception(e.message ?: "Sign up failed. Please try again."))
        }
    }

    /**
     * Requirement 1: Restores active session on app launch and populates
     * CurrentSession with full profile details (fullName, phoneNumber, userRole)
     * fetched from get_my_account RPC or account table in Supabase.
     */
    suspend fun restoreSession(): Boolean {
        return try {
            client.auth.awaitInitialization()
            val user = client.auth.currentUserOrNull() ?: return false
            val userEmail = user.email ?: return false

            // Fetch full account profile details from Supabase database
            var account = getMyAccount()

            if (account == null) {
                account = try {
                    client.from("account")
                        .select {
                            filter {
                                eq("email", userEmail)
                            }
                        }
                        .decodeSingleOrNull<AccountSignUpResult>()
                } catch (_: Exception) {
                    null
                }
            }

            // If account doesn't exist in Supabase database (e.g. user was deleted from Supabase Dashboard)
            if (account == null) {
                try {
                    logout()
                } catch (_: Exception) {
                    CurrentSession.clear()
                }
                return false
            }

            val metadata = user.userMetadata
            val fullNameFromMeta = metadata?.get("full_name")?.jsonPrimitive?.content
            val phoneFromMeta = metadata?.get("phone_number")?.jsonPrimitive?.content
            val roleFromMeta = metadata?.get("role")?.jsonPrimitive?.content

            val defaultName = userEmail.substringBefore("@").replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }
            val resolvedName = account.fullName.ifBlank { fullNameFromMeta ?: defaultName }
            val resolvedPhone = account.phoneNumber ?: phoneFromMeta
            val currentAccId = account.accountId.ifBlank { user.id }

            val supervisorFarmId = try {
                val rows = client.from("supervisor_profile").select { filter { eq("account_id", currentAccId) } }.decodeList<JsonObject>()
                rows.firstOrNull()?.get("farm_id")?.jsonPrimitive?.contentOrNull
            } catch (_: Exception) { null }

            val workerFarmId = if (supervisorFarmId == null) {
                try {
                    val rows = client.from("worker_profile").select { filter { eq("account_id", currentAccId) } }.decodeList<JsonObject>()
                    rows.firstOrNull()?.get("farm_id")?.jsonPrimitive?.contentOrNull
                } catch (_: Exception) { null }
            } else null

            val isSupervisorProfile = supervisorFarmId != null || account.role.equals("Supervisor", ignoreCase = true) || roleFromMeta.equals("Supervisor", ignoreCase = true)
            val isWorkerProfile = workerFarmId != null || account.role.equals("Worker", ignoreCase = true) || roleFromMeta.equals("Worker", ignoreCase = true)

            val detectedRole = when {
                isSupervisorProfile -> "Supervisor"
                isWorkerProfile -> "Worker"
                !account.role.isNullOrBlank() -> account.role
                !roleFromMeta.isNullOrBlank() -> roleFromMeta
                else -> "Manager"
            }

            val resolvedRole = detectedRole

            if (resolvedRole.equals("Manager", ignoreCase = true)) {
                ensureManagerAccount(user.id, resolvedName, userEmail, resolvedPhone)
            }

            val farm = FarmRepository(client).getFarmForUser(currentAccId)
            val resolvedFarmId = supervisorFarmId ?: workerFarmId ?: farm?.farmId ?: ""

            CurrentSession.updateSession(
                userId = currentAccId,
                fullName = resolvedName,
                email = userEmail,
                phoneNumber = resolvedPhone,
                userRole = resolvedRole,
                farmId = resolvedFarmId
            )

            true
        } catch (_: Exception) {
            try {
                logout()
            } catch (_: Exception) {
                CurrentSession.clear()
            }
            false
        }
    }

    suspend fun logout() {
        CurrentSession.clearSession(client)
    }

    suspend fun updateUserProfile(
        userId: String,
        fullName: String,
        phoneNumber: String?
    ): Result<Unit> {
        return try {
            if (userId.isNotBlank()) {
                val updateJsonObject = buildJsonObject {
                    put("full_name", fullName.trim())
                    if (phoneNumber != null) put("phone_number", phoneNumber.trim())
                }
                client.from("account")
                    .update(updateJsonObject) {
                        filter { eq("account_id", userId) }
                    }
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
