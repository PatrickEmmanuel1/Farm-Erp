@file:Suppress("unused")

package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class FertilizerIssuance(
    @SerialName("fertilizer_issuance_id") val fertilizerIssuanceId: String? = null,
    @SerialName("fertilizer_id") val fertilizerId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("issued_by") val issuedBy: String,
    @SerialName("quantity_issued") val quantityIssued: Double,
    val unit: String,
    @SerialName("issuance_date") val issuanceDate: String,
    val notes: String? = null,
    val status: String = "Issued",
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("cancelled_by") val cancelledBy: String? = null,
    @SerialName("cancellation_reason") val cancellationReason: String? = null,
)

@Serializable
data class FungicideIssuance(
    @SerialName("fungicide_issuance_id") val fungicideIssuanceId: String? = null,
    @SerialName("fungicide_id") val fungicideId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("issued_by") val issuedBy: String,
    @SerialName("quantity_issued") val quantityIssued: Double,
    val unit: String,
    @SerialName("issuance_date") val issuanceDate: String,
    val notes: String? = null,
    val status: String = "Issued",
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("cancelled_by") val cancelledBy: String? = null,
    @SerialName("cancellation_reason") val cancellationReason: String? = null,
)

@Serializable
data class HerbicideIssuance(
    @SerialName("herbicide_issuance_id") val herbicideIssuanceId: String? = null,
    @SerialName("herbicide_id") val herbicideId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("issued_by") val issuedBy: String,
    @SerialName("quantity_issued") val quantityIssued: Double,
    val unit: String,
    @SerialName("issuance_date") val issuanceDate: String,
    val notes: String? = null,
    val status: String = "Issued",
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("cancelled_by") val cancelledBy: String? = null,
    @SerialName("cancellation_reason") val cancellationReason: String? = null,
)

@Serializable
data class InsecticideIssuance(
    @SerialName("insecticide_issuance_id") val insecticideIssuanceId: String? = null,
    @SerialName("insecticide_id") val insecticideId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("issued_by") val issuedBy: String,
    @SerialName("quantity_issued") val quantityIssued: Double,
    val unit: String,
    @SerialName("issuance_date") val issuanceDate: String,
    val notes: String? = null,
    val status: String = "Issued",
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("cancelled_by") val cancelledBy: String? = null,
    @SerialName("cancellation_reason") val cancellationReason: String? = null,
)

@Serializable
data class PesticideIssuance(
    @SerialName("pesticide_issuance_id") val pesticideIssuanceId: String? = null,
    @SerialName("pesticide_id") val pesticideId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("issued_by") val issuedBy: String,
    @SerialName("quantity_issued") val quantityIssued: Double,
    val unit: String,
    @SerialName("issuance_date") val issuanceDate: String,
    val notes: String? = null,
    val status: String = "Issued",
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("cancelled_by") val cancelledBy: String? = null,
    @SerialName("cancellation_reason") val cancellationReason: String? = null,
)

@Serializable
data class WaterIssuance(
    @SerialName("water_issuance_id") val waterIssuanceId: String? = null,
    @SerialName("water_id") val waterId: String,
    @SerialName("farm_id") val farmId: String,
    @SerialName("division_id") val divisionId: String? = null,
    @SerialName("issued_by") val issuedBy: String,
    @SerialName("quantity_issued") val quantityIssued: Double,
    val unit: String,
    @SerialName("issuance_date") val issuanceDate: String,
    val notes: String? = null,
    val status: String = "Issued",
    @SerialName("created_at") val createdAt: String? = null,
    @SerialName("cancelled_at") val cancelledAt: String? = null,
    @SerialName("cancelled_by") val cancelledBy: String? = null,
    @SerialName("cancellation_reason") val cancellationReason: String? = null,
)
