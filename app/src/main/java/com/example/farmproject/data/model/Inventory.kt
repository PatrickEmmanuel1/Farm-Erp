package com.example.farmproject.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.util.UUID

enum class InventoryCategory(val displayName: String) {
    FERTILIZER("Fertilizer"),
    HERBICIDE("Herbicide"),
    PESTICIDE("Pesticide"),
    FUNGICIDE("Fungicide"),
    INSECTICIDE("Insecticide"),
    WATER("Water")
}

@Serializable
data class StockIssuance(
    @SerialName("issuance_id") val issuanceId: String? = null,
    @SerialName("item_id") val itemId: String? = null,
    val category: String? = null,
    @SerialName("item_name") val itemName: String? = null,
    @SerialName("quantity_issued") val quantityIssued: Double? = null,
    val unit: String? = null,
    @SerialName("issued_to") val issuedTo: String? = null,
    @SerialName("issue_date") val issueDate: String? = null,
    val notes: String? = null,
    @SerialName("farm_id") val farmId: String? = null
) {
    val safeIssuanceId: String get() = issuanceId.orEmpty().ifBlank { UUID.randomUUID().toString() }
    val safeItemId: String get() = itemId.orEmpty()
    val safeCategory: String get() = category.orEmpty()
    val safeItemName: String get() = itemName.orEmpty().ifBlank { "Stock Item" }
    val safeQuantityIssued: Double get() = quantityIssued ?: 0.0
    val safeUnit: String get() = unit.orEmpty().ifBlank { "litres" }
    val safeIssuedTo: String get() = issuedTo.orEmpty().ifBlank { "General Field" }
    val safeIssueDate: String get() = issueDate.orEmpty().ifBlank { "2026-03-30" }
}

data class InventoryItem(
    val id: String,
    val category: InventoryCategory,
    val name: String,
    /** fertilizer_type or active_ingredient; null for Water. */
    val subtype: String?,
    val quantity: Double,
    val unit: String,
    val reorderLevel: Double?,
    val description: String?
) {
    val isLowStock: Boolean
        get() = reorderLevel != null && quantity <= reorderLevel
}

fun Fertilizer.toInventoryItem() = InventoryItem(
    id = requireNotNull(fertilizerId) { "Fertilizer row has no id" },
    category = InventoryCategory.FERTILIZER,
    name = name,
    subtype = fertilizerType,
    quantity = quantity,
    unit = unit,
    reorderLevel = reorderLevel,
    description = description
)

fun Pesticide.toInventoryItem() = InventoryItem(
    id = requireNotNull(pesticideId) { "Pesticide row has no id" },
    category = InventoryCategory.PESTICIDE,
    name = name,
    subtype = activeIngredient,
    quantity = quantity,
    unit = unit,
    reorderLevel = reorderLevel,
    description = description
)

fun Fungicide.toInventoryItem() = InventoryItem(
    id = requireNotNull(fungicideId) { "Fungicide row has no id" },
    category = InventoryCategory.FUNGICIDE,
    name = name,
    subtype = activeIngredient,
    quantity = quantity,
    unit = unit,
    reorderLevel = reorderLevel,
    description = description
)

fun Insecticide.toInventoryItem() = InventoryItem(
    id = requireNotNull(insecticideId) { "Insecticide row has no id" },
    category = InventoryCategory.INSECTICIDE,
    name = name,
    subtype = activeIngredient,
    quantity = quantity,
    unit = unit,
    reorderLevel = reorderLevel,
    description = description
)

fun Herbicide.toInventoryItem() = InventoryItem(
    id = requireNotNull(herbicideId) { "Herbicide row has no id" },
    category = InventoryCategory.HERBICIDE,
    name = name,
    subtype = activeIngredient,
    quantity = quantity,
    unit = unit,
    reorderLevel = reorderLevel,
    description = description
)

fun Water.toInventoryItem() = InventoryItem(
    id = requireNotNull(waterId) { "Water row has no id" },
    category = InventoryCategory.WATER,
    name = sourceName,
    subtype = null,
    quantity = availableQuantity,
    unit = unit,
    reorderLevel = reorderLevel,
    description = description
)
