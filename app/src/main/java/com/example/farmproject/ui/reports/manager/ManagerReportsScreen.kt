package com.example.farmproject.ui.reports.manager

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.PrecisionManufacturing
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.Warehouse
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.farmproject.R
import com.example.farmproject.data.model.ReportCategoryStatus
import com.example.farmproject.data.model.lastGeneratedLabel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerReportsScreen(
    uiState: ReportsUiState = ReportsUiState(),
    onBackClick: () -> Unit = {},
    onGenerateReportClick: () -> Unit = {},
    onReportClick: (String) -> Unit = {},
) {
    val categories = uiState.categories.ifEmpty {
        defaultReportCategories()
    }

    val softCreamBg = Color(0xFFF7F6F0)

    Scaffold(
        containerColor = softCreamBg
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 20.dp)
        ) {
            Spacer(modifier = Modifier.height(12.dp))

            // Custom Top Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back",
                            tint = Color(0xFF1A1D1A)
                        )
                    }

                    Spacer(modifier = Modifier.width(4.dp))

                    Column {
                        Text(
                            text = "Reports",
                            fontSize = 28.sp,
                            fontWeight = FontWeight.ExtraBold,
                            color = Color(0xFF1A1D1A)
                        )
                        Text(
                            text = "View farm reports and summaries",
                            fontSize = 13.sp,
                            color = Color(0xFF6E7068)
                        )
                    }
                }

                IconButton(onClick = {}) {
                    Icon(
                        imageVector = Icons.Default.MoreVert,
                        contentDescription = "More options",
                        tint = Color(0xFF1A1D1A)
                    )
                }
            }

            Spacer(modifier = Modifier.height(18.dp))

            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                item {
                    ReportsSummaryCard(totalCategories = categories.size)
                }

                item {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Report Categories",
                            fontSize = 22.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF1A1D1A)
                        )

                        OutlinedButton(
                            onClick = onGenerateReportClick,
                            shape = RoundedCornerShape(20.dp),
                            border = BorderStroke(1.5.dp, Color(0xFF1B5E20)),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFF1B5E20))
                        ) {
                            Icon(
                                imageVector = Icons.Default.BarChart,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp),
                                tint = Color(0xFF1B5E20)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Generate",
                                fontSize = 14.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }

                items(categories) { category ->
                    ReportCategoryCard(
                        category = category,
                        onClick = { onReportClick(category.code) }
                    )
                }

                item {
                    Spacer(modifier = Modifier.height(24.dp))
                }
            }
        }
    }
}

@Composable
private fun ReportsSummaryCard(totalCategories: Int) {
    val gradientBrush = Brush.verticalGradient(
        colors = listOf(
            Color(0xFF277A3C),
            Color(0xFF1B5E20)
        )
    )

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(gradientBrush)
                .padding(20.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .background(
                            color = Color.White.copy(alpha = 0.20f),
                            shape = RoundedCornerShape(16.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.BarChart,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(30.dp)
                    )
                }

                Spacer(modifier = Modifier.width(16.dp))

                Column {
                    Text(
                        text = totalCategories.toString(),
                        fontSize = 32.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )

                    Text(
                        text = "Report categories available",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color.White.copy(alpha = 0.9f)
                    )
                }
            }
        }
    }
}

@Composable
private fun ReportCategoryCard(
    category: ReportCategoryStatus,
    onClick: () -> Unit
) {
    val reportIconRes = when (category.code.lowercase()) {
        "inventory" -> R.drawable.ic_cat_fertilizer
        "machinery" -> R.drawable.ic_cat_machinery
        "workforce" -> R.drawable.ic_cat_reports
        "storage" -> R.drawable.ic_cat_storage
        else -> R.drawable.ic_cat_yield
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(18.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Image(
                painter = painterResource(id = reportIconRes),
                contentDescription = category.name,
                modifier = Modifier.size(48.dp)
            )

            Spacer(modifier = Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = category.name,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF1A1D1A)
                )

                Text(
                    text = category.description,
                    fontSize = 13.sp,
                    color = Color(0xFF6E7068)
                )

                Spacer(modifier = Modifier.height(6.dp))

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.CalendarMonth,
                        contentDescription = null,
                        modifier = Modifier.size(15.dp),
                        tint = Color(0xFF2E7D32)
                    )

                    Spacer(modifier = Modifier.width(4.dp))

                    Text(
                        text = category.lastGeneratedLabel(),
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFF1A1D1A)
                    )
                }
            }

            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null,
                tint = Color(0xFF9E9E9E),
                modifier = Modifier.size(20.dp)
            )
        }
    }
}

private fun defaultReportCategories(): List<ReportCategoryStatus> = listOf(
    ReportCategoryStatus(
        farmId = "",
        categoryId = "cat-crop-yield",
        code = "crop_yield",
        name = "Crop Yield Report",
        description = "Planting, growth stage and harvest summaries",
        lastReportId = "rep-crop-yield",
        lastGeneratedAt = "2026-10-15T10:00:00Z"
    ),
    ReportCategoryStatus(
        farmId = "",
        categoryId = "cat-inventory",
        code = "inventory",
        name = "Inventory Report",
        description = "Stock levels, usage and reorder alerts",
        lastReportId = "rep-inventory",
        lastGeneratedAt = "2026-10-15T14:30:00Z"
    ),
    ReportCategoryStatus(
        farmId = "",
        categoryId = "cat-machinery",
        code = "machinery",
        name = "Machinery Report",
        description = "Equipment usage, condition and maintenance",
        lastReportId = "rep-machinery",
        lastGeneratedAt = "2026-10-15T09:15:00Z"
    ),
    ReportCategoryStatus(
        farmId = "",
        categoryId = "cat-workforce",
        code = "workforce",
        name = "Workforce Report",
        description = "Attendance and task completion by employee",
        lastReportId = "rep-workforce",
        lastGeneratedAt = "2026-10-15T16:45:00Z"
    ),
    ReportCategoryStatus(
        farmId = "",
        categoryId = "cat-storage",
        code = "storage",
        name = "Storage Report",
        description = "Stored produce, capacity and condition",
        lastReportId = "rep-storage",
        lastGeneratedAt = "2026-10-15T11:20:00Z"
    )
)
