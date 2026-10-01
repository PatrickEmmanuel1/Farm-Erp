package com.example.farmproject.ui.divisions.manager

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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.GridOn
import androidx.compose.material.icons.filled.Landscape
import androidx.compose.material.icons.filled.Science
import androidx.compose.material.icons.filled.SquareFoot
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerAddDivisionScreen(
    viewModel: DivisionsViewModel = viewModel(),
    onBackClick: () -> Unit = {}
) {
    val saveState by viewModel.saveState.collectAsState()

    var name by remember { mutableStateOf("") }
    var sizeText by remember { mutableStateOf("") }
    var units by remember { mutableStateOf("Acres") }
    var soilPhText by remember { mutableStateOf("") }
    var soilHealth by remember { mutableStateOf("") }

    LaunchedEffect(saveState) {
        if (saveState is DivisionSaveState.Saved) {
            viewModel.resetSaveState()
            onBackClick()
        }
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
                            text = "Create Division",
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Partition a section of your farm",
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
            if (saveState is DivisionSaveState.Error) {
                Text(
                    text = (saveState as DivisionSaveState.Error).message,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(horizontal = 4.dp)
                )
            }

            // Division Name
            OutlinedTextField(
                value = name,
                onValueChange = {
                    name = it
                    viewModel.resetSaveState()
                },
                label = { Text("Division Name *") },
                placeholder = { Text("e.g. Division A / North Field") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.GridOn,
                        contentDescription = null
                    )
                },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            // Size
            OutlinedTextField(
                value = sizeText,
                onValueChange = {
                    if (it.isEmpty() || it.all { char -> char.isDigit() || char == '.' }) {
                        sizeText = it
                        viewModel.resetSaveState()
                    }
                },
                label = { Text("Partition Size *") },
                placeholder = { Text("e.g. 25") },
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

                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    FilterChip(
                        selected = units == "Acres",
                        onClick = {
                            units = "Acres"
                            viewModel.resetSaveState()
                        },
                        label = { Text("Acres") },
                        leadingIcon = if (units == "Acres") {
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
                        selected = units == "Hectares",
                        onClick = {
                            units = "Hectares"
                            viewModel.resetSaveState()
                        },
                        label = { Text("Hectares") },
                        leadingIcon = if (units == "Hectares") {
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

            // Soil pH (Optional)
            OutlinedTextField(
                value = soilPhText,
                onValueChange = {
                    if (it.isEmpty() || it.all { char -> char.isDigit() || char == '.' }) {
                        soilPhText = it
                        viewModel.resetSaveState()
                    }
                },
                label = { Text("Soil pH (Optional)") },
                placeholder = { Text("e.g. 6.5") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Science,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                shape = RoundedCornerShape(12.dp)
            )

            // Soil Health (Optional)
            OutlinedTextField(
                value = soilHealth,
                onValueChange = {
                    soilHealth = it
                    viewModel.resetSaveState()
                },
                label = { Text("Soil Health / Condition (Optional)") },
                placeholder = { Text("e.g. Good / High Nitrogen") },
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

            Spacer(modifier = Modifier.height(12.dp))

            // Submit Button
            Button(
                onClick = {
                    viewModel.addDivision(
                        name = name,
                        sizeText = sizeText,
                        units = units,
                        soilPhText = soilPhText,
                        soilHealth = soilHealth
                    )
                },
                enabled = saveState !is DivisionSaveState.Saving,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF1565C0)
                )
            ) {
                if (saveState is DivisionSaveState.Saving) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = Color.White,
                        strokeWidth = 2.5.dp
                    )
                } else {
                    Text(
                        text = "Save Division",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
