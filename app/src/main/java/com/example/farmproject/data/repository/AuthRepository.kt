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
import kotlinx.serialization.json.buildJsonObject
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

    suspend fun get_my_account(): AccountSignUpResult? {
        return try {
            client.postgrest.rpc("get_my_account").decodeSingleOrNull<AccountSignUpResult>()
        } catch (_: Exception) {
            null
        }
    }

    suspend fun get_my_role(): String? {
        return try {
            client.postgrest.rpc("get_my_role").decodeSingleOrNull<String>()
        } catch (_: Exception) {
            null
        }
    }

    suspend fun current_user_role(): String? {
        return try {
            client.postgrest.rpc("current_user_role").decodeSingleOrNull<String>()
        } catch (_: Exception) {
            null
        }
    }

    suspend fun has_farm_access(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "has_farm_access",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    suspend fun is_farm_manager(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "is_farm_manager",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    suspend fun is_farm_supervisor(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "is_farm_supervisor",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    suspend fun is_farm_worker(farmId: String): Boolean {
        return try {
            client.postgrest.rpc(
                function = "is_farm_worker",
                parameters = buildJsonObject { put("p_farm_id", farmId) }
            ).decodeAs<Boolean>()
        } catch (_: Exception) {
            false
        }
    }

    suspend fun create_account(fullName: String, email: String, phoneNumber: String?, role: String = "Manager") {
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

            val isEmailNotConfirmed = authErrorMsg?.contains("email_not_confirmed", ignoreCase = true) == true

            if (!authSuccess) {
                if (isEmailNotConfirmed) {
                    return Result.failure(Exception("Email not confirmed for '$trimmedEmail'. Accounts created before disabling 'Confirm Email' must be manually confirmed in Supabase Dashboard -> Authentication -> Users (click '...' -> Confirm user), or run: UPDATE auth.users SET email_confirmed_at = now() WHERE email = '$trimmedEmail';"))
                }
                val msg = authErrorMsg ?: "Invalid credentials. Please check your email and password or sign up."
                return Result.failure(Exception(msg))
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

            val userRole = when {
                expectedRole.equals("Supervisor", ignoreCase = true) -> "Supervisor"
                expectedRole.equals("Worker", ignoreCase = true) -> "Worker"
                else -> dbAccount?.role ?: expectedRole ?: "Manager"
            }

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
            CurrentSession.updateSession(
                userId = account.accountId,
                fullName = account.fullName.ifBlank { fallbackName },
                email = account.email,
                phoneNumber = account.phoneNumber,
                userRole = userRole,
                farmId = farm?.farmId ?: ""
            )
            Result.success(account.copy(role = userRole))
        } catch (e: Exception) {
            Result.failure(Exception(e.message ?: "Login failed. Please check your credentials."))
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

            val isEmailNotConfirmed = signUpError?.contains("email_not_confirmed", ignoreCase = true) == true

            // If neither signUp nor signIn established an auth session or returned user ID
            if (client.auth.currentSessionOrNull() == null && authUserId == null) {
                if (isEmailNotConfirmed) {
                    return Result.failure(Exception("Email not confirmed for '$trimmedEmail'. Please confirm user in Supabase Dashboard -> Authentication -> Users, or run: UPDATE auth.users SET email_confirmed_at = now() WHERE email = '$trimmedEmail';"))
                }
                val msg = signUpError ?: "Sign up failed. Please check your details and try again."
                return Result.failure(Exception(msg))
            }

            val currentAuthId = authUserId ?: client.auth.currentUserOrNull()?.id ?: UUID.randomUUID().toString()

            // 2. Insert row directly into public.account table or call create_account RPC
            var insertedAccount: AccountSignUpResult? = null
            try {
                create_account(fullName = fullName, email = trimmedEmail, phoneNumber = phoneNumber, role = "Manager")
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
            var account = get_my_account()

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
            val resolvedRole = account.role ?: roleFromMeta ?: "Manager"

            if (resolvedRole.equals("Manager", ignoreCase = true)) {
                ensureManagerAccount(user.id, resolvedName, userEmail, resolvedPhone)
            }

            val farm = FarmRepository(client).getFarmForUser(account.accountId.ifBlank { user.id })

            CurrentSession.updateSession(
                userId = account.accountId.ifBlank { user.id },
                fullName = resolvedName,
                email = userEmail,
                phoneNumber = resolvedPhone,
                userRole = resolvedRole,
                farmId = farm?.farmId ?: ""
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
