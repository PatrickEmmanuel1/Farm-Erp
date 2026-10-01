package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** One row of public.supervisor_details (also used as the upsert payload). */
@Serializable
data class SupervisorDetailsRow(
    @SerialName("supervisor_profile_id") val supervisorProfileId: String,
    val salary: Double,
    val age: Int,
    val residence: String,
    @SerialName("date_employed") val dateEmployed: String, // ISO "yyyy-MM-dd"
    val gender: String                                       // "Male" | "Female" | "Other"
)

/** What the manager types into the "Add details" form. */
data class SupervisorDetailsInput(
    val salary: Double,
    val age: Int,
    val residence: String,
    val dateEmployed: String,
    val gender: String
)
