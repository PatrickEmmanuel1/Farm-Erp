package com.example.farmproject.ui.storage.manager

import com.example.farmproject.ui.common.DatePickerField

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
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
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Notes
import androidx.compose.material.icons.filled.Numbers
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.Straighten
import androidx.compose.material.icons.filled.Warehouse
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerAddStorageScreen(
    viewModel: StorageViewModel = viewModel(),
    onBackClick: () -> Unit = {},
    onSaveSuccess: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()
    val facilityNames = (uiState as? StorageUiState.Success)?.facilities?.map { it.name } ?: emptyList()

    var cropName by remember { mutableStateOf("") }
    var quantity by remember { mutableStateOf("") }
    var unit by remember { mutableStateOf("kg") }
    var location by remember { mutableStateOf("") }
    var dateStored by remember { mutableStateOf("") }
    var condition by remember { mutableStateOf("Good") }
    var notes by remember { mutableStateOf("") }

    var unitExpanded by remember { mutableStateOf(false) }
    var locationExpanded by remember { mutableStateOf(false) }
    var conditionExpanded by remember { mutableStateOf(false) }

    val units = listOf(
        "kg",
        "g",
        "litres",
        "bags",
        "crates",
        "units"
    )

    val defaultLocations = listOf(
        "Main Store",
        "Warehouse 1",
        "Cold Store A",
        "Silo 1"
    )

    val locations = (facilityNames + defaultLocations).distinct()

    val conditions = listOf(
        "Good",
        "Fair",
        "Spoiled"
    )

    val fieldColors = OutlinedTextFieldDefaults.colors(
        focusedBorderColor = Color(0xFF1565C0),
        unfocusedBorderColor = Color(0xFFBDBDBD),
        focusedLabelColor = Color(0xFF1565C0),
        cursorColor = Color(0xFF1565C0)
    )

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color(0xFF1565C0))
                    .padding(horizontal = 8.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {

                IconButton(
                    onClick = onBackClick
                ) {
                    Icon(
                        imageVector = Icons.Default.ArrowBack,
                        contentDescription = "Back",
                        tint = Color.White
                    )
                }

                Spacer(modifier = Modifier.width(8.dp))

                Column {
                    Text(
                        text = "Add Stored Produce",
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "Record newly stored produce",
                        color = Color.White.copy(alpha = 0.85f),
                        fontSize = 12.sp
                    )
                }
            }
        }
    ) { innerPadding ->

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp, vertical = 16.dp)
                .navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {

            // ---------------------------------------------------------
            // BASIC INFORMATION
            // ---------------------------------------------------------

            SectionTitle(
                icon = Icons.Default.Warehouse,
                title = "Basic Information"
            )

            OutlinedTextField(
                value = cropName,
                onValueChange = { cropName = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Crop / Produce Name") },
                placeholder = { Text("e.g. Maize") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Warehouse,
                        contentDescription = null
                    )
                },
                singleLine = true,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            // ---------------------------------------------------------
            // STORAGE DETAILS
            // ---------------------------------------------------------

            SectionTitle(
                icon = Icons.Default.Numbers,
                title = "Storage Details"
            )

            OutlinedTextField(
                value = quantity,
                onValueChange = { input ->
                    if (input.all { it.isDigit() || it == '.' || it == ',' }) {
                        quantity = input
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Quantity") },
                placeholder = { Text("e.g. 1200") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Numbers,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal
                ),
                singleLine = true,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            ExposedDropdownMenuBox(
                expanded = unitExpanded,
                onExpandedChange = {
                    unitExpanded = !unitExpanded
                }
            ) {

                OutlinedTextField(
                    value = unit,
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    label = { Text("Unit") },
                    placeholder = { Text("Select unit") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Straighten,
                            contentDescription = null
                        )
                    },
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(
                            expanded = unitExpanded
                        )
                    },
                    colors = fieldColors,
                    shape = RoundedCornerShape(12.dp)
                )

                ExposedDropdownMenu(
                    expanded = unitExpanded,
                    onDismissRequest = {
                        unitExpanded = false
                    }
                ) {

                    units.forEach { item ->

                        DropdownMenuItem(
                            text = {
                                Text(item)
                            },
                            onClick = {
                                unit = item
                                unitExpanded = false
                            }
                        )
                    }
                }
            }

            ExposedDropdownMenuBox(
                expanded = locationExpanded,
                onExpandedChange = {
                    locationExpanded = !locationExpanded
                }
            ) {

                OutlinedTextField(
                    value = location,
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    label = { Text("Storage Location") },
                    placeholder = { Text("Select location") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = null
                        )
                    },
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(
                            expanded = locationExpanded
                        )
                    },
                    colors = fieldColors,
                    shape = RoundedCornerShape(12.dp)
                )

                ExposedDropdownMenu(
                    expanded = locationExpanded,
                    onDismissRequest = {
                        locationExpanded = false
                    }
                ) {

                    locations.forEach { item ->

                        DropdownMenuItem(
                            text = {
                                Text(item)
                            },
                            onClick = {
                                location = item
                                locationExpanded = false
                            }
                        )
                    }
                }
            }

            DatePickerField(
                value = dateStored,
                onValueChange = { dateStored = it },
                modifier = Modifier.fillMaxWidth(),
                label = "Date Stored",
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            // ---------------------------------------------------------
            // CONDITION
            // ---------------------------------------------------------

            SectionTitle(
                icon = Icons.Default.CheckCircle,
                title = "Condition"
            )

            ExposedDropdownMenuBox(
                expanded = conditionExpanded,
                onExpandedChange = {
                    conditionExpanded = !conditionExpanded
                }
            ) {

                OutlinedTextField(
                    value = condition,
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .fillMaxWidth()
                        .menuAnchor(),
                    label = { Text("Current Condition") },
                    placeholder = { Text("Select condition") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null
                        )
                    },
                    trailingIcon = {
                        ExposedDropdownMenuDefaults.TrailingIcon(
                            expanded = conditionExpanded
                        )
                    },
                    colors = fieldColors,
                    shape = RoundedCornerShape(12.dp)
                )

                ExposedDropdownMenu(
                    expanded = conditionExpanded,
                    onDismissRequest = {
                        conditionExpanded = false
                    }
                ) {

                    conditions.forEach { item ->

                        DropdownMenuItem(
                            text = {
                                Text(item)
                            },
                            onClick = {
                                condition = item
                                conditionExpanded = false
                            }
                        )
                    }
                }
            }

            // ---------------------------------------------------------
            // NOTES
            // ---------------------------------------------------------

            SectionTitle(
                icon = Icons.Default.Notes,
                title = "Additional Information"
            )

            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp),
                label = { Text("Notes") },
                placeholder = {
                    Text("Enter any additional information...")
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Notes,
                        contentDescription = null
                    )
                },
                maxLines = 5,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            Spacer(modifier = Modifier.height(4.dp))

            // ---------------------------------------------------------
            // SAVE BUTTON
            // ---------------------------------------------------------

            Button(
                onClick = {
                    val qty = quantity.toDoubleOrNull() ?: 0.0
                    if (cropName.isNotBlank() && qty > 0) {
                        viewModel.addProduce(
                            cropName = cropName,
                            quantity = qty,
                            unit = unit.ifBlank { "kg" },
                            location = location.ifBlank { "Main Store" },
                            dateStored = dateStored,
                            condition = condition.ifBlank { "Good" },
                            onSuccess = { onSaveSuccess() },
                            onError = { /* handled */ }
                        )
                    }
                },
                enabled = cropName.isNotBlank() && (quantity.toDoubleOrNull() ?: 0.0) > 0,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF1565C0)
                )
            ) {

                Icon(
                    imageVector = Icons.Default.Save,
                    contentDescription = null
                )

                Spacer(modifier = Modifier.width(8.dp))

                Text(
                    text = "Save Produce",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun SectionTitle(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String
) {

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {

        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color(0xFF1565C0),
            modifier = Modifier.size(22.dp)
        )

        Spacer(modifier = Modifier.width(8.dp))

        Text(
            text = title,
            fontSize = 17.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF212121)
        )
    }
}