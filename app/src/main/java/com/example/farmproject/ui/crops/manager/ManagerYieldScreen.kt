package com.example.farmproject.ui.crops.manager

import com.example.farmproject.ui.common.DatePickerField

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
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Notes
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Eco
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.Numbers
import androidx.compose.material.icons.filled.Scale
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.farmproject.data.model.CropPlantingDisplay
import com.example.farmproject.data.repository.CropHarvestDisplay
import java.time.LocalDate
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerYieldScreen(
    viewModel: YieldViewModel = viewModel(),
    onBackClick: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val saveState by viewModel.saveState.collectAsState()

    var showRecordDialog by remember { mutableStateOf(false) }
    var selectedGradeFilter by remember { mutableStateOf("All") }

    LaunchedEffect(Unit) {
        viewModel.loadYieldData()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                title = {
                    Column {
                        Text(
                            text = "Crop Yields & Harvests",
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Record and track crop harvest yields by section",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            when (val state = uiState) {
                is YieldUiState.Loading -> {
                    Box(
                        modifier = Modifier.fillMaxSize(),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }

                is YieldUiState.Error -> {
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text(
                            text = state.message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodyLarge
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = { viewModel.loadYieldData() }) {
                            Text("Retry")
                        }
                    }
                }

                is YieldUiState.Success -> {
                    val harvests = state.harvests
                    val activePlantings = state.activePlantings

                    val gradeFilters = listOf("All", "Grade A", "Grade B", "Export Grade", "Premium")

                    val filteredHarvests = when (selectedGradeFilter) {
                        "All" -> harvests
                        else -> harvests.filter {
                            it.harvest.qualityGrade?.contains(selectedGradeFilter, ignoreCase = true) == true
                        }
                    }

                    LazyColumn(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(MaterialTheme.colorScheme.background)
                            .padding(horizontal = 16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        item {
                            Spacer(modifier = Modifier.height(8.dp))

                            YieldSummaryCard(
                                totalHarvests = harvests.size,
                                totalQuantityStr = formatTotalHarvestedQuantity(harvests)
                            )
                        }

                        item {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Harvest Logs",
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.Bold
                                )

                                OutlinedButton(onClick = { showRecordDialog = true }) {
                                    Icon(
                                        imageVector = Icons.Default.Add,
                                        contentDescription = null,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Spacer(modifier = Modifier.size(4.dp))
                                    Text("Record Yield")
                                }
                            }
                        }

                        item {
                            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                items(gradeFilters) { grade ->
                                    FilterChip(
                                        selected = selectedGradeFilter == grade,
                                        onClick = { selectedGradeFilter = grade },
                                        label = { Text(grade) }
                                    )
                                }
                            }
                        }

                        if (filteredHarvests.isEmpty()) {
                            item {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 32.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Text(
                                        text = "No crop yield records found. Tap 'Record Yield' to add a log.",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = MaterialTheme.colorScheme.onSurfaceVariant
                                    )
                                }
                            }
                        } else {
                            items(filteredHarvests) { display ->
                                HarvestItemCard(display = display)
                            }
                        }

                        item {
                            Spacer(modifier = Modifier.height(16.dp))
                        }
                    }

                    if (showRecordDialog) {
                        RecordYieldDialog(
                            activePlantings = activePlantings,
                            saveState = saveState,
                            onDismiss = {
                                viewModel.resetSaveState()
                                showRecordDialog = false
                            },
                            onRecord = { plantingId, divisionId, harvestDate, qty, unit, grade, notes ->
                                viewModel.recordYield(
                                    plantingId = plantingId,
                                    divisionId = divisionId,
                                    harvestDate = harvestDate,
                                    quantityHarvested = qty,
                                    quantityUnit = unit,
                                    qualityGrade = grade,
                                    notes = notes
                                )
                            }
                        )
                    }
                }
            }
        }
    }
}

private fun formatTotalHarvestedQuantity(harvests: List<CropHarvestDisplay>): String {
    if (harvests.isEmpty()) return "0 units"
    val totalQty = harvests.sumOf { it.harvest.quantityHarvested }
    val primaryUnit = harvests.firstOrNull()?.harvest?.quantityUnit ?: "kg"
    return String.format(Locale.US, "%,.1f %s", totalQty, primaryUnit)
}

@Composable
private fun YieldSummaryCard(
    totalHarvests: Int,
    totalQuantityStr: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(18.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .background(
                        color = MaterialTheme.colorScheme.primaryContainer,
                        shape = RoundedCornerShape(14.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Scale,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
            }

            Spacer(modifier = Modifier.size(16.dp))

            Column {
                Text(
                    text = totalQuantityStr,
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    text = "$totalHarvests crop harvest log(s) recorded",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
        }
    }
}

@Composable
private fun HarvestItemCard(
    display: CropHarvestDisplay
) {
    val harvest = display.harvest

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .background(
                            color = MaterialTheme.colorScheme.primaryContainer,
                            shape = RoundedCornerShape(12.dp)
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Eco,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                Spacer(modifier = Modifier.size(12.dp))

                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = display.cropName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = display.divisionName,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                Text(
                    text = "${harvest.quantityHarvested} ${harvest.quantityUnit}",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.CalendarMonth,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = harvest.harvestDate,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                if (!harvest.qualityGrade.isNullOrBlank()) {
                    Box(
                        modifier = Modifier
                            .background(
                                color = MaterialTheme.colorScheme.primaryContainer,
                                shape = RoundedCornerShape(20.dp)
                            )
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = harvest.qualityGrade,
                            style = MaterialTheme.typography.labelSmall,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            if (!harvest.notes.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Notes,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = harvest.notes,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun RecordYieldDialog(
    activePlantings: List<CropPlantingDisplay>,
    saveState: YieldSaveState,
    onDismiss: () -> Unit,
    onRecord: (
        plantingId: String,
        divisionId: String,
        harvestDate: String,
        qty: Double,
        unit: String,
        grade: String?,
        notes: String?
    ) -> Unit
) {
    var selectedPlanting by remember { mutableStateOf(activePlantings.firstOrNull()) }
    var quantityText by remember { mutableStateOf("") }
    var unitText by remember { mutableStateOf("kg") }
    var gradeText by remember { mutableStateOf("Grade A") }
    var dateText by remember {
        val today = try { LocalDate.now().toString() } catch (_: Exception) { "2026-03-30" }
        mutableStateOf(today)
    }
    var notesText by remember { mutableStateOf("") }
    var errorMsg by remember { mutableStateOf<String?>(null) }

    var plantingExpanded by remember { mutableStateOf(false) }
    var unitExpanded by remember { mutableStateOf(false) }
    var gradeExpanded by remember { mutableStateOf(false) }

    val validUnits = listOf("kg", "g", "ton", "tonnes", "bags", "crates", "boxes", "pieces")
    val validGrades = listOf("Grade A", "Grade B", "Grade C", "Premium", "Export Grade")

    val isSaving = saveState is YieldSaveState.Saving

    LaunchedEffect(saveState) {
        if (saveState is YieldSaveState.Saved) {
            onDismiss()
        }
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "Record Crop Yield / Harvest",
                fontWeight = FontWeight.Bold
            )
        },
        text = {
            if (activePlantings.isEmpty()) {
                Text(
                    text = "No active planted crops found. Please add a crop planting first.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else {
                Column(
                    modifier = Modifier.verticalScroll(rememberScrollState()),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    // SELECT PLANTED CROP / SECTION
                    ExposedDropdownMenuBox(
                        expanded = plantingExpanded,
                        onExpandedChange = { plantingExpanded = !plantingExpanded }
                    ) {
                        OutlinedTextField(
                            value = selectedPlanting?.let { "${it.cropName} - ${it.divisionName}" } ?: "",
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Planted Crop / Section *") },
                            leadingIcon = { Icon(imageVector = Icons.Default.Eco, contentDescription = null) },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = plantingExpanded) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )

                        ExposedDropdownMenu(
                            expanded = plantingExpanded,
                            onDismissRequest = { plantingExpanded = false }
                        ) {
                            activePlantings.forEach { plantingDisplay ->
                                DropdownMenuItem(
                                    text = { Text("${plantingDisplay.cropName} (${plantingDisplay.divisionName})") },
                                    onClick = {
                                        selectedPlanting = plantingDisplay
                                        plantingExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    // QUANTITY HARVESTED & UNIT
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedTextField(
                            value = quantityText,
                            onValueChange = { if (it.all { c -> c.isDigit() || c == '.' }) quantityText = it },
                            modifier = Modifier.weight(1f),
                            label = { Text("Quantity *") },
                            placeholder = { Text("500") },
                            leadingIcon = { Icon(imageVector = Icons.Default.Numbers, contentDescription = null) },
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            singleLine = true
                        )

                        ExposedDropdownMenuBox(
                            expanded = unitExpanded,
                            onExpandedChange = { unitExpanded = !unitExpanded },
                            modifier = Modifier.weight(1f)
                        ) {
                            OutlinedTextField(
                                value = unitText,
                                onValueChange = {},
                                readOnly = true,
                                label = { Text("Unit *") },
                                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = unitExpanded) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .menuAnchor()
                            )

                            ExposedDropdownMenu(
                                expanded = unitExpanded,
                                onDismissRequest = { unitExpanded = false }
                            ) {
                                validUnits.forEach { uItem ->
                                    DropdownMenuItem(
                                        text = { Text(uItem) },
                                        onClick = {
                                            unitText = uItem
                                            unitExpanded = false
                                        }
                                    )
                                }
                            }
                        }
                    }

                    // QUALITY GRADE DROPDOWN
                    ExposedDropdownMenuBox(
                        expanded = gradeExpanded,
                        onExpandedChange = { gradeExpanded = !gradeExpanded }
                    ) {
                        OutlinedTextField(
                            value = gradeText,
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Quality Grade") },
                            leadingIcon = { Icon(imageVector = Icons.Default.Verified, contentDescription = null) },
                            trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = gradeExpanded) },
                            modifier = Modifier
                                .fillMaxWidth()
                                .menuAnchor()
                        )

                        ExposedDropdownMenu(
                            expanded = gradeExpanded,
                            onDismissRequest = { gradeExpanded = false }
                        ) {
                            validGrades.forEach { gItem ->
                                DropdownMenuItem(
                                    text = { Text(gItem) },
                                    onClick = {
                                        gradeText = gItem
                                        gradeExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    // HARVEST DATE
                    DatePickerField(
                        value = dateText,
                        onValueChange = { dateText = it },
                        label = "Harvest Date *",
                        modifier = Modifier.fillMaxWidth()
                    )

                    // NOTES
                    OutlinedTextField(
                        value = notesText,
                        onValueChange = { notesText = it },
                        label = { Text("Notes / Observations") },
                        placeholder = { Text("e.g. Excellent moisture and grain size") },
                        modifier = Modifier.fillMaxWidth()
                    )

                    if (saveState is YieldSaveState.Error) {
                        Text(
                            text = (saveState as YieldSaveState.Error).message,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }

                    errorMsg?.let {
                        Text(
                            text = it,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            }
        },
        confirmButton = {
            if (activePlantings.isNotEmpty()) {
                Button(
                    onClick = {
                        if (isSaving) return@Button

                        val pDisplay = selectedPlanting
                        val qty = quantityText.toDoubleOrNull()
                        val today = try { LocalDate.now() } catch (_: Exception) { null }
                        val dParsed = if (dateText.isNotBlank()) try { LocalDate.parse(dateText.trim()) } catch (_: Exception) { null } else null

                        when {
                            pDisplay == null -> errorMsg = "Select a planted crop."
                            qty == null || qty <= 0.0 -> errorMsg = "Enter a valid harvested quantity."
                            dParsed != null && today != null && dParsed.isBefore(today) -> errorMsg = "Harvest date cannot be in the past."
                            else -> {
                                val pId = pDisplay.planting.plantingId
                                val dId = pDisplay.planting.divisionId
                                if (pId != null && dId != null) {
                                    onRecord(
                                        pId,
                                        dId,
                                        dateText.trim(),
                                        qty,
                                        unitText.trim(),
                                        gradeText.trim().ifBlank { null },
                                        notesText.trim().ifBlank { null }
                                    )
                                } else {
                                    errorMsg = "Planting record is missing ID."
                                }
                            }
                        }
                    },
                    enabled = !isSaving
                ) {
                    if (isSaving) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = Color.White,
                            strokeWidth = 2.dp
                        )
                    } else {
                        Text("Save Yield")
                    }
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
