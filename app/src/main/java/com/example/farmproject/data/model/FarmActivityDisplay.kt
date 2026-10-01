package com.example.farmproject.data.model

import kotlinx.serialization.Serializable

@Serializable
data class FarmActivityDisplay(
    val activity: FarmActivity,
    val activityTypeName: String,
    val divisionName: String?,
    val assignedToName: String?
) {
    val displayTitle: String
        get() {
            val titleText = activity.activityName?.trim()?.takeIf { it.isNotBlank() } ?: activityTypeName
            return if (divisionName != null) {
                "$titleText ($divisionName)"
            } else {
                titleText
            }
        }
}
