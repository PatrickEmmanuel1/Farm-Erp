package com.example.farmproject.ui.farm

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Agriculture
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.SquareFoot
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
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

private val KENYA_COUNTIES = listOf(
    "Nairobi", "Nakuru", "Kiambu", "Uasin Gishu", "Trans Nzoia", "Machakos",
    "Meru", "Nyeri", "Kilifi", "Kisumu", "Kakamega", "Murang'a", "Kericho",
    "Bomet", "Bungoma", "Narok", "Laikipia", "Embu", "Kitui", "Makueni",
    "Nyandarua", "Nandi", "Homa Bay", "Migori", "Siaya", "Busia", "Kajiado"
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateFarmScreen(
    viewModel: CreateFarmViewModel = viewModel(),
    onFarmCreated: () -> Unit = {}
) {
    val saveState by viewModel.saveState.collectAsState()

    var farmName by remember { mutableStateOf("") }
    var selectedCounty by remember { mutableStateOf("") }
    var countyExpanded by remember { mutableStateOf(false) }
    var subCounty by remember { mutableStateOf("") }
    var sizeText by remember { mutableStateOf("") }
    var unit by remember { mutableStateOf("Acres") }

    LaunchedEffect(saveState) {
        if (saveState is CreateFarmState.Success) {
            onFarmCreated()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Setup Your Farm",
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Register your farm details to continue",
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                }
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .verticalScroll(rememberScrollState())
                .padding(innerPadding)
                .padding(horizontal = 20.dp, vertical = 16.dp)
                .navigationBarsPadding(),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Intro Banner
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Row(
                    modifier = Modifier.padding(18.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(52.dp)
                            .background(
                                color = MaterialTheme.colorScheme.primary,
                                shape = RoundedCornerShape(14.dp)
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.Agriculture,
                            contentDescription = null,
                            tint = Color.White
                        )
                    }

                    Spacer(modifier = Modifier.width(16.dp))

                    Column {
                        Text(
                            text = "Welcome to MyFarm",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )

                        Text(
                            text = "To manage crops, resources & workers, please create your farm profile first.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.85f)
                        )
                    }
                }
            }

            // Error Message
            if (saveState is CreateFarmState.Error) {
                Text(
                    text = (saveState as CreateFarmState.Error).message,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(horizontal = 4.dp)
                )
            }

            // Farm Name
            OutlinedTextField(
                value = farmName,
                onValueChange = {
                    farmName = it
                    viewModel.resetState()
                },
                label = { Text("Farm Name *") },
                placeholder = { Text("e.g. Green Valley Farm") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Landscape,
                        contentDescription = null
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            // County Dropdown
            Box(modifier = Modifier.fillMaxWidth()) {
                OutlinedTextField(
                    value = selectedCounty,
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("County *") },
                    placeholder = { Text("Select County") },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.LocationOn,
                            contentDescription = null
                        )
                    },
                    trailingIcon = {
                        Icon(
                            imageVector = Icons.Default.ArrowDropDown,
                            contentDescription = "Expand"
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                // Clickable overlay to expand dropdown
                Box(
                    modifier = Modifier
                        .matchParentSize()
                        .background(Color.Transparent)
                        .padding(4.dp)
                        .clickable { countyExpanded = true }
                )

                DropdownMenu(
                    expanded = countyExpanded,
                    onDismissRequest = { countyExpanded = false },
                    modifier = Modifier.fillMaxWidth(0.9f)
                ) {
                    KENYA_COUNTIES.forEach { countyName ->
                        DropdownMenuItem(
                            text = { Text(countyName) },
                            onClick = {
                                selectedCounty = countyName
                                countyExpanded = false
                                viewModel.resetState()
                            }
                        )
                    }
                }
            }

            // Sub-County
            OutlinedTextField(
                value = subCounty,
                onValueChange = {
                    subCounty = it
                    viewModel.resetState()
                },
                label = { Text("Sub-County (Optional)") },
                placeholder = { Text("e.g. Rongai / Limuru") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Map,
                        contentDescription = null
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            // Farm Size (1 to 10,000)
            OutlinedTextField(
                value = sizeText,
                onValueChange = {
                    if (it.isEmpty() || it.all { char -> char.isDigit() || char == '.' }) {
                        sizeText = it
                        viewModel.resetState()
                    }
                },
                label = { Text("Farm Size (1 - 10,000) *") },
                placeholder = { Text("e.g. 50") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.SquareFoot,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            // Units Selection (Acres or Hectares)
            Column {
                Text(
                    text = "Land Unit *",
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold
                )

                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    FilterChip(
                        selected = unit == "Acres",
                        onClick = {
                            unit = "Acres"
                            viewModel.resetState()
                        },
                        label = { Text("Acres") },
                        leadingIcon = if (unit == "Acres") {
                            {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        } else null
                    )

                    FilterChip(
                        selected = unit == "Hectares",
                        onClick = {
                            unit = "Hectares"
                            viewModel.resetState()
                        },
                        label = { Text("Hectares") },
                        leadingIcon = if (unit == "Hectares") {
                            {
                                Icon(
                                    imageVector = Icons.Default.Check,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        } else null
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Submit Button
            Button(
                onClick = {
                    viewModel.createFarm(
                        farmName = farmName,
                        county = selectedCounty,
                        subCounty = subCounty,
                        sizeText = sizeText,
                        unit = unit
                    )
                },
                enabled = saveState !is CreateFarmState.Saving,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF1565C0)
                )
            ) {
                if (saveState is CreateFarmState.Saving) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = Color.White,
                        strokeWidth = 2.5.dp
                    )
                } else {
                    Text(
                        text = "Create Farm & Continue",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
