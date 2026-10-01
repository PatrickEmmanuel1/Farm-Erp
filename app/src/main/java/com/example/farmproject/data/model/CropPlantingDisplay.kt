package com.example.farmproject.data.model

import kotlinx.serialization.Serializable

@Serializable
data class CropPlantingDisplay(
    val planting: CropPlanting,
    val cropName: String,
    val divisionName: String
)