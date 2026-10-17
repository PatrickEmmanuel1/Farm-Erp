package com.example.farmproject.ui.dashboard.manager

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.FormatListBulleted
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Inventory2
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.PrecisionManufacturing
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.Terrain
import androidx.compose.material.icons.filled.Warehouse
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.farmproject.data.session.CurrentSession

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerDashboardScreen(
    viewModel: DashboardViewModel = viewModel(),
    onCropsClick: () -> Unit = {},
    onInventoryClick: () -> Unit = {},
    onWorkersClick: () -> Unit = {},
    onMachineryClick: () -> Unit = {},
    onStorageClick: () -> Unit = {},
    onDivisionsClick: () -> Unit = {},
    onActivitiesClick: () -> Unit = {},
    onAddCropClick: () -> Unit = {},
    onLogActivityClick: () -> Unit = {},
    onAddWorkerClick: () -> Unit = {},
    onReportsClick: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val lifecycleOwner = LocalLifecycleOwner.current

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                viewModel.loadDashboardData()
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    val softCreamBg = Color(0xFFF7F6F0)

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(softCreamBg)
            .padding(horizontal = 20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        item {
            Spacer(modifier = Modifier.height(12.dp))

            val fullName = CurrentSession.fullName?.trim()
            val managerFirstName = fullName?.split(" ")?.firstOrNull { it.isNotBlank() } ?: "Edward"
            val managerInitial = managerFirstName.firstOrNull()?.toString()?.uppercase() ?: "E"

            DashboardHeader(
                firstName = managerFirstName,
                initial = managerInitial
            )
        }

        when (val state = uiState) {
            is DashboardUiState.Loading -> {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = Color(0xFF1B5E20))
                    }
                }
            }

            is DashboardUiState.Error -> {
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = state.message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadDashboardData() }) {
                            Text("Retry")
                        }
                    }
                }
            }

            is DashboardUiState.Success -> {
                item {
                    FarmOverviewHeroCard(
                        farmName = state.farmName,
                        totalFarmSize = state.totalFarmSize,
                        farmUnit = state.farmUnit,
                        totalDivisions = state.totalDivisions,
                        pendingActivities = state.pendingActivities,
                        onDivisionsClick = onDivisionsClick,
                        onActivitiesClick = onActivitiesClick
                    )
                }

                item {
                    QuickActionsSection(
                        onAddCropClick = onAddCropClick,
                        onLogActivityClick = onLogActivityClick,
                        onAddWorkerClick = onAddWorkerClick,
                        onReportsClick = onReportsClick
                    )
                }

                item {
                    FarmOperationsSection(
                        cropsCount = state.totalCrops,
                        workersCount = state.totalWorkers,
                        resourcesCount = state.totalInventory,
                        machineryCount = state.totalMachinery,
                        storageCount = state.totalStorage,
                        onCropsClick = onCropsClick,
                        onWorkersClick = onWorkersClick,
                        onInventoryClick = onInventoryClick,
                        onMachineryClick = onMachineryClick,
                        onStorageClick = onStorageClick
                    )
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(24.dp))
        }
    }
}

@Composable
private fun DashboardHeader(
    firstName: String,
    initial: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(
                text = "Welcome back,",
                fontSize = 15.sp,
                color = Color(0xFF6E7068),
                fontWeight = FontWeight.Normal
            )

            Text(
                text = firstName,
                fontSize = 30.sp,
                color = Color(0xFF1A1D1A),
                fontWeight = FontWeight.ExtraBold
            )
        }

        Box(
            modifier = Modifier
                .size(50.dp)
                .background(
                    color = Color(0xFFE8F5E9),
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = initial,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF1B5E20)
            )
        }
    }
}

@Composable
private fun FarmOverviewHeroCard(
    farmName: String,
    totalFarmSize: Double,
    farmUnit: String,
    totalDivisions: Int,
    pendingActivities: Int,
    onDivisionsClick: () -> Unit,
    onActivitiesClick: () -> Unit
) {
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
            Column {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Terrain,
                        contentDescription = null,
                        tint = Color(0xFFA5D6A7),
                        modifier = Modifier.size(18.dp)
                    )
                    Text(
                        text = farmName.lowercase(),
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFFA5D6A7)
                    )
                }

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = "Farm Overview",
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                Spacer(modifier = Modifier.height(18.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    val sizeFormatted = if (totalFarmSize % 1.0 == 0.0) totalFarmSize.toInt().toString() else "%.1f".format(totalFarmSize)

                    OverviewStatBox(
                        modifier = Modifier.weight(1f),
                        value = sizeFormatted,
                        label = farmUnit,
                        onClick = {}
                    )

                    OverviewStatBox(
                        modifier = Modifier.weight(1f),
                        value = totalDivisions.toString(),
                        label = "Divisions",
                        onClick = onDivisionsClick
                    )

                    OverviewStatBox(
                        modifier = Modifier.weight(1f),
                        value = pendingActivities.toString(),
                        label = "Pending",
                        onClick = onActivitiesClick
                    )
                }
            }
        }
    }
}

@Composable
private fun OverviewStatBox(
    modifier: Modifier = Modifier,
    value: String,
    label: String,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .background(
                color = Color.White.copy(alpha = 0.18f),
                shape = RoundedCornerShape(14.dp)
            )
            .clickable { onClick() }
            .padding(vertical = 12.dp, horizontal = 10.dp)
    ) {
        Column {
            Text(
                text = value,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = label,
                fontSize = 12.sp,
                fontWeight = FontWeight.Medium,
                color = Color.White.copy(alpha = 0.9f)
            )
        }
    }
}

@Composable
private fun QuickActionsSection(
    onAddCropClick: () -> Unit,
    onLogActivityClick: () -> Unit,
    onAddWorkerClick: () -> Unit,
    onReportsClick: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            text = "Quick Actions",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF1A1D1A)
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            QuickActionButton(
                icon = Icons.Default.Add,
                label = "Add Crop",
                onClick = onAddCropClick
            )

            QuickActionButton(
                icon = Icons.AutoMirrored.Filled.FormatListBulleted,
                label = "Log Activity",
                onClick = onLogActivityClick
            )

            QuickActionButton(
                icon = Icons.Default.PersonAdd,
                label = "Add Worker",
                onClick = onAddWorkerClick
            )

            QuickActionButton(
                icon = Icons.Default.BarChart,
                label = "Reports",
                onClick = onReportsClick
            )
        }
    }
}

@Composable
private fun QuickActionButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable { onClick() }
    ) {
        Box(
            modifier = Modifier
                .size(60.dp)
                .background(
                    color = Color(0xFFE8F5E9),
                    shape = CircleShape
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = Color(0xFF1B5E20),
                modifier = Modifier.size(26.dp)
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = label,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            color = Color(0xFF2C312D)
        )
    }
}

@Composable
private fun FarmOperationsSection(
    cropsCount: Int,
    workersCount: Int,
    resourcesCount: Int,
    machineryCount: Int,
    storageCount: Int,
    onCropsClick: () -> Unit,
    onWorkersClick: () -> Unit,
    onInventoryClick: () -> Unit,
    onMachineryClick: () -> Unit,
    onStorageClick: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Text(
            text = "Farm Operations",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF1A1D1A)
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OperationGridCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Spa,
                iconBg = Color(0xFFE8F5E9),
                iconTint = Color(0xFF2E7D32),
                value = cropsCount.toString(),
                label = "Crops",
                onClick = onCropsClick
            )

            OperationGridCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Group,
                iconBg = Color(0xFFE3F2FD),
                iconTint = Color(0xFF1976D2),
                value = workersCount.toString(),
                label = "Workers",
                onClick = onWorkersClick
            )
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            OperationGridCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.Inventory2,
                iconBg = Color(0xFFFFF8E1),
                iconTint = Color(0xFFF57F17),
                value = resourcesCount.toString(),
                label = "Total Resources",
                onClick = onInventoryClick
            )

            OperationGridCard(
                modifier = Modifier.weight(1f),
                icon = Icons.Default.PrecisionManufacturing,
                iconBg = Color(0xFFFBE9E7),
                iconTint = Color(0xFFE64A19),
                value = machineryCount.toString(),
                label = "Total Machinery",
                onClick = onMachineryClick
            )
        }

        // Full Width Storage Card
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .clickable { onStorageClick() },
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color.White),
            elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(46.dp)
                        .background(
                            color = Color(0xFFEFEBE9),
                            shape = RoundedCornerShape(12.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Warehouse,
                        contentDescription = null,
                        tint = Color(0xFF5D4037),
                        modifier = Modifier.size(24.dp)
                    )
                }

                Spacer(modifier = Modifier.width(14.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text = storageCount.toString(),
                        fontSize = 22.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF1A1D1A)
                    )

                    Text(
                        text = "Storage Produce",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFF6E7068)
                    )
                }

                Icon(
                    imageVector = Icons.Default.ChevronRight,
                    contentDescription = null,
                    tint = Color(0xFF9E9E9E)
                )
            }
        }
    }
}

@Composable
private fun OperationGridCard(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    iconBg: Color,
    iconTint: Color,
    value: String,
    label: String,
    onClick: () -> Unit
) {
    Card(
        modifier = modifier.clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(38.dp)
                        .background(
                            color = iconBg,
                            shape = RoundedCornerShape(10.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = iconTint,
                        modifier = Modifier.size(22.dp)
                    )
                }

                Icon(
                    imageVector = Icons.Default.ChevronRight,
                    contentDescription = null,
                    tint = Color(0xFF9E9E9E),
                    modifier = Modifier.size(20.dp)
                )
            }

            Spacer(modifier = Modifier.height(14.dp))

            Text(
                text = value,
                fontSize = 24.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF1A1D1A)
            )

            Spacer(modifier = Modifier.height(2.dp))

            Text(
                text = label,
                fontSize = 13.sp,
                fontWeight = FontWeight.Medium,
                color = Color(0xFF6E7068)
            )
        }
    }
}
