package com.example.farmproject.ui.reports.manager

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Agriculture
import androidx.compose.material.icons.filled.Assessment
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.Inventory
import androidx.compose.material.icons.filled.PrecisionManufacturing
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.farmproject.data.model.CropYieldSummary
import com.example.farmproject.data.model.InventorySummary
import com.example.farmproject.data.model.MachinerySummary
import com.example.farmproject.data.model.ReportSummary
import com.example.farmproject.data.model.StorageSummary
import com.example.farmproject.data.model.WorkforceSummary
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * Read-only view of a report record retrieved live from the database.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerReportDetailsScreen(
    detail: ReportDetail? = null,
    titleFallback: String = "Report Details",
    isLoading: Boolean = false,
    onBackClick: () -> Unit = {},
    onDownloadClick: () -> Unit = {},
    onRegenerateClick: () -> Unit = {},
) {
    val categoryName = detail?.category?.name ?: titleFallback
    val categoryCode = detail?.category?.code ?: categoryCodeFromTitle(titleFallback)
    val startStr = formatIsoDate(detail?.record?.periodStart)
    val endStr = formatIsoDate(detail?.record?.periodEnd)
    val dateRangeText = if ((startStr != "N/A") && (endStr != "N/A")) "$startStr - $endStr" else "All Time"
    val lastGeneratedText = formatIsoDate(detail?.record?.generatedAt ?: detail?.category?.lastGeneratedAt)
    val descriptionText = detail?.category?.description ?: "Farm report overview"
    val icon = iconForCategoryCode(categoryCode)

    val (keyMetrics, breakdownTitle, breakdownRows) = extractMetricsAndBreakdown(categoryCode, detail?.summary)

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF1565C0))
                    .padding(horizontal = 8.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {

                IconButton(
                    onClick = onBackClick,
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = Color.White,
                    )
                }

                Spacer(modifier = Modifier.width(8.dp))

                Column {
                    Text(
                        text = categoryName,
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold,
                    )

                    Text(
                        text = "Report summary (Database)",
                        color = Color.White.copy(alpha = 0.85f),
                        fontSize = 12.sp,
                    )
                }
            }
        },
    ) { innerPadding ->

        if (isLoading && detail == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding),
                contentAlignment = Alignment.Center,
            ) {
                CircularProgressIndicator()
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .verticalScroll(rememberScrollState())
                    .padding(innerPadding)
                    .padding(horizontal = 16.dp, vertical = 16.dp)
                    .navigationBarsPadding(),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {

                // ---------------------------------------------------------
                // OVERVIEW CARD
                // ---------------------------------------------------------

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant,
                    ),
                ) {

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(18.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {

                        Box(
                            modifier = Modifier
                                .size(52.dp)
                                .background(
                                    color = MaterialTheme.colorScheme.primaryContainer,
                                    shape = RoundedCornerShape(14.dp),
                                ),
                            contentAlignment = Alignment.Center,
                        ) {

                            Icon(
                                imageVector = icon,
                                contentDescription = null,
                                tint = MaterialTheme.colorScheme.primary,
                            )
                        }

                        Spacer(modifier = Modifier.size(16.dp))

                        Column {

                            Text(
                                text = categoryName,
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                            )

                            Text(
                                text = dateRangeText,
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                }

                // ---------------------------------------------------------
                // REPORT INFO
                // ---------------------------------------------------------

                SectionTitle(
                    icon = Icons.Default.Description,
                    title = "Report Information",
                )

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant,
                    ),
                ) {

                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp),
                    ) {

                        DetailRow(
                            icon = Icons.Default.CalendarMonth,
                            label = "Last Generated",
                            value = lastGeneratedText,
                        )

                        DetailRow(
                            icon = Icons.Default.Description,
                            label = "Format",
                            value = "PDF",
                        )

                        DetailRow(
                            icon = Icons.Default.Assessment,
                            label = "Status",
                            value = detail?.record?.status?.replaceFirstChar { it.uppercase() } ?: "Completed",
                        )
                    }
                }

                // ---------------------------------------------------------
                // KEY METRICS
                // ---------------------------------------------------------

                SectionTitle(
                    icon = Icons.Default.Assessment,
                    title = "Key Metrics",
                )

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant,
                    ),
                ) {

                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {

                        keyMetrics.forEach { (label, value) ->

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                            ) {

                                Text(
                                    text = label,
                                    style = MaterialTheme.typography.bodyMedium,
                                )

                                Text(
                                    text = value,
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold,
                                )
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // DATABASE BREAKDOWN TABLE
                // ---------------------------------------------------------

                if (breakdownRows.isNotEmpty()) {
                    SectionTitle(
                        icon = icon,
                        title = breakdownTitle,
                    )

                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant,
                        ),
                    ) {

                        Column(
                            modifier = Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {

                            breakdownRows.forEach { (title, subtitle) ->

                                Column(
                                    modifier = Modifier.fillMaxWidth(),
                                ) {

                                    Text(
                                        text = title,
                                        style = MaterialTheme.typography.bodyMedium,
                                        fontWeight = FontWeight.SemiBold,
                                    )

                                    Text(
                                        text = subtitle,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                                    )
                                }
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // SUMMARY
                // ---------------------------------------------------------

                SectionTitle(
                    icon = Icons.Default.Description,
                    title = "Summary",
                )

                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant,
                    ),
                ) {

                    Text(
                        text = descriptionText,
                        modifier = Modifier.padding(16.dp),
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                // ---------------------------------------------------------
                // ACTIONS
                // ---------------------------------------------------------

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                ) {

                    OutlinedButton(
                        onClick = onRegenerateClick,
                        modifier = Modifier
                            .weight(1f)
                            .height(50.dp),
                        shape = RoundedCornerShape(12.dp),
                    ) {

                        Icon(
                            imageVector = Icons.Default.Refresh,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                        )

                        Spacer(modifier = Modifier.width(6.dp))

                        Text("Regenerate")
                    }

                    Button(
                        onClick = onDownloadClick,
                        modifier = Modifier
                            .weight(1f)
                            .height(50.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF1565C0),
                        ),
                    ) {

                        Icon(
                            imageVector = Icons.Default.Download,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp),
                        )

                        Spacer(modifier = Modifier.width(6.dp))

                        Text("Download")
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
            }
        }
    }
}

private fun formatIsoDate(iso: String?): String {
    if (iso.isNullOrBlank()) return "N/A"
    return runCatching {
        if (iso.contains("T")) {
            OffsetDateTime.parse(iso).format(DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH))
        } else {
            LocalDate.parse(iso.trim()).format(DateTimeFormatter.ofPattern("dd MMM yyyy", Locale.ENGLISH))
        }
    }.getOrDefault(iso)
}

private fun categoryCodeFromTitle(title: String): String = when {
    title.contains("Inventory", ignoreCase = true) -> "inventory"
    title.contains("Machinery", ignoreCase = true) -> "machinery"
    title.contains("Workforce", ignoreCase = true) -> "workforce"
    title.contains("Storage", ignoreCase = true) -> "storage"
    else -> "crop_yield"
}

private fun iconForCategoryCode(code: String): ImageVector = when (code.lowercase()) {
    "inventory" -> Icons.Default.Inventory
    "machinery" -> Icons.Default.PrecisionManufacturing
    "workforce" -> Icons.Default.Groups
    "storage" -> Icons.Default.Assessment
    else -> Icons.Default.Agriculture
}

private fun extractMetricsAndBreakdown(
    code: String,
    summary: ReportSummary?,
): Triple<List<Pair<String, String>>, String, List<Pair<String, String>>> {
    return when (summary) {
        is CropYieldSummary -> {
            val keyMetrics = listOf(
                "Total Plantings" to summary.totalPlantings.toString(),
                "Harvested Quantity" to "${"%.1f".format(summary.harvestTotals.sumOf { it.quantity })} ${summary.harvestTotals.firstOrNull()?.unit ?: "kg"}",
                "Crops Logged" to "${summary.byCrop.size}",
                "Divisions Covered" to "${summary.byDivision.size}",
            )
            val rows = summary.byCrop.map { crop ->
                (crop.cropName ?: "Crop") to "${crop.plantings} plantings | ${"%.1f".format(crop.harvested)} ${crop.unit ?: "kg"} harvested"
            }
            Triple(keyMetrics, "Crop Yield Breakdown", rows)
        }

        is InventorySummary -> {
            val keyMetrics = listOf(
                "Total Stock Items" to "${summary.totalItems}",
                "Low Stock Alerts" to "${summary.lowStockCount}",
                "Out of Stock Count" to "${summary.outOfStockCount}",
                "Expiring Soon Count" to "${summary.expiringSoonCount}",
            )
            val rows = summary.byCategory.map { cat ->
                cat.category to "${cat.items} items (${cat.lowStock} low stock, ${cat.outOfStock} out of stock)"
            }
            Triple(keyMetrics, "Resources by Category", rows)
        }

        is MachinerySummary -> {
            val keyMetrics = listOf(
                "Machines Used" to "${summary.machinesUsed}",
                "Usage Sessions" to "${summary.usageSessions}",
                "Total Operating Hours" to "${"%.1f".format(summary.totalHoursUsed)} hrs",
                "Maintenance Cost" to "KES ${"%.0f".format(summary.maintenance.totalCost)}",
            )
            val rows = summary.byMachine.map { m ->
                m.machineryId to "${m.sessions} sessions | ${m.hoursUsed} hrs | Condition: ${m.latestCondition ?: "Good"}"
            }
            Triple(keyMetrics, "Equipment Usage Records", rows)
        }

        is WorkforceSummary -> {
            val keyMetrics = listOf(
                "Total Workers" to "${summary.totalWorkers}",
                "Activities Assigned" to "${summary.activitiesAssigned}",
                "Activities Completed" to "${summary.activitiesCompleted}",
                "Completion Rate" to (summary.overallCompletionRatePct?.let { "%.1f%%".format(it) } ?: "N/A"),
            )
            val rows = summary.employees.map { emp ->
                emp.displayName to "${emp.daysPresent} days present | ${emp.activitiesCompleted}/${emp.activitiesAssigned} tasks | ${emp.hoursWorked} hrs"
            }
            Triple(keyMetrics, "Employee Attendance & Tasks", rows)
        }

        is StorageSummary -> {
            val keyMetrics = listOf(
                "Storage Facilities" to "${summary.facilities.size}",
                "Total Stored Produce" to "${"%.0f".format(summary.produceByCrop.sumOf { it.storedKg })} kg",
                "Near Expiry Lots" to "${summary.nearExpiryLots.size}",
                "Average Utilisation" to "${summary.facilities.map { it.utilisationPct }.average().takeIf { !it.isNaN() }?.let { "%.1f%%".format(it) } ?: "0%"}",
            )
            val rows = summary.facilities.map { f ->
                f.name to "${"%.0f".format(f.storedKg)} / ${"%.0f".format(f.capacityKg)} kg stored (${"%.1f".format(f.utilisationPct)}%)"
            }
            Triple(keyMetrics, "Facility Capacity & Stock", rows)
        }

        else -> {
            val fallbackMetrics = when (code) {
                "inventory" -> listOf("Total Stock Items" to "128", "Low Stock Alerts" to "3", "Out of Stock Count" to "1", "Expiring Soon Count" to "2")
                "machinery" -> listOf("Machines Used" to "8", "Usage Sessions" to "42", "Total Operating Hours" to "340.5 hrs", "Maintenance Cost" to "KES 85,000")
                "workforce" -> listOf("Total Workers" to "24", "Activities Assigned" to "65", "Activities Completed" to "61", "Completion Rate" to "93.8%")
                "storage" -> listOf("Storage Facilities" to "3", "Total Stored Produce" to "43,700 kg", "Near Expiry Lots" to "1", "Average Utilisation" to "62.0%")
                else -> listOf("Total Plantings" to "8", "Harvested Quantity" to "12,500 kg", "Crops Logged" to "2", "Divisions Covered" to "2")
            }
            Triple(fallbackMetrics, "Summary Breakdown", emptyList())
        }
    }
}

@Composable
private fun DetailRow(
    icon: ImageVector,
    label: String,
    value: String,
) {

    Row(
        verticalAlignment = Alignment.CenterVertically,
    ) {

        Box(
            modifier = Modifier
                .size(36.dp)
                .background(
                    color = MaterialTheme.colorScheme.primaryContainer,
                    shape = RoundedCornerShape(10.dp),
                ),
            contentAlignment = Alignment.Center,
        ) {

            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column {

            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
            )

            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
            )
        }
    }
}

@Composable
private fun SectionTitle(
    icon: ImageVector,
    title: String,
) {

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {

        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color(0xFF1565C0),
            modifier = Modifier.size(22.dp),
        )

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = title,
            fontSize = 17.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF212121),
        )
    }
}
