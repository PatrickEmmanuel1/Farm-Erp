@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.farmproject.ui.employees.manager

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SelectableDates
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.example.farmproject.data.model.SupervisorDetailsInput
import com.example.farmproject.data.model.SupervisorDetailsRow
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

private val GENDER_OPTIONS = listOf("Male", "Female", "Other")
private const val DAY_MS = 24L * 60 * 60 * 1000

@Composable
internal fun EmploymentDetailsDialog(
    initial: SupervisorDetailsRow?,
    isSaving: Boolean,
    saveError: String?,
    onDismiss: () -> Unit,
    onSave: (SupervisorDetailsInput) -> Unit
) {
    var salary by remember { mutableStateOf(initial?.salary?.let { formatPlain(it) } ?: "") }
    var age by remember { mutableStateOf(initial?.age?.toString() ?: "") }
    var residence by remember { mutableStateOf(initial?.residence ?: "") }
    var dateEmployed by remember { mutableStateOf(initial?.dateEmployed) }
    var gender by remember { mutableStateOf(initial?.gender) }
    var localError by remember { mutableStateOf<String?>(null) }
    var showDatePicker by remember { mutableStateOf(false) }

    AlertDialog(
        onDismissRequest = { if (!isSaving) onDismiss() },
        title = { Text(if (initial == null) "Add Details" else "Edit Details") },
        text = {
            Column(
                modifier = Modifier.verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                OutlinedTextField(
                    value = salary,
                    onValueChange = { salary = it },
                    label = { Text("Salary (KES)") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = age,
                    onValueChange = { age = it.filter(Char::isDigit).take(3) },
                    label = { Text("Age") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth()
                )
                OutlinedTextField(
                    value = residence,
                    onValueChange = { residence = it },
                    label = { Text("Residence") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                OutlinedButton(
                    onClick = { showDatePicker = true },
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Icon(
                        imageVector = Icons.Default.CalendarMonth,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.size(8.dp))
                    Text(dateEmployed ?: "Select date employed")
                }

                Text("Gender", style = MaterialTheme.typography.labelMedium)
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    GENDER_OPTIONS.forEach { option ->
                        FilterChip(
                            selected = gender == option,
                            onClick = { gender = option },
                            label = { Text(option) }
                        )
                    }
                }

                (localError ?: saveError)?.let { message ->
                    Text(
                        text = message,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            }
        },
        confirmButton = {
            Button(
                enabled = !isSaving,
                onClick = {
                    val salaryValue = salary.trim().toDoubleOrNull()
                    val ageValue = age.trim().toIntOrNull()
                    val dateValue = dateEmployed
                    val genderValue = gender

                    when {
                        salaryValue == null || salaryValue < 0 ->
                            localError = "Enter a valid salary."
                        ageValue == null || ageValue !in 16..100 ->
                            localError = "Enter an age between 16 and 100."
                        residence.isBlank() ->
                            localError = "Enter the residence."
                        dateValue == null ->
                            localError = "Select the date employed."
                        genderValue == null ->
                            localError = "Select a gender."
                        else -> {
                            localError = null
                            onSave(
                                SupervisorDetailsInput(
                                    salary = salaryValue,
                                    age = ageValue,
                                    residence = residence.trim(),
                                    dateEmployed = dateValue,
                                    gender = genderValue
                                )
                            )
                        }
                    }
                }
            ) {
                if (isSaving) {
                    CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp)
                } else {
                    Text("Save")
                }
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss, enabled = !isSaving) { Text("Cancel") }
        }
    )

    if (showDatePicker) {
        val pickerState = rememberDatePickerState(
            initialSelectedDateMillis = isoToUtcMillis(dateEmployed),
            selectableDates = object : SelectableDates {
                // No future hire dates. The picker reports UTC midnight, and in Kenya (UTC+3)
                // the local "today" can already be the next UTC day, so allow one day of slack.
                override fun isSelectableDate(utcTimeMillis: Long): Boolean =
                    utcTimeMillis <= System.currentTimeMillis() + DAY_MS
            }
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        pickerState.selectedDateMillis?.let { dateEmployed = utcMillisToIso(it) }
                        showDatePicker = false
                    }
                ) { Text("OK") }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) { Text("Cancel") }
            }
        ) {
            DatePicker(state = pickerState)
        }
    }
}

private fun isoFormat() = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
    timeZone = TimeZone.getTimeZone("UTC")
}

private fun utcMillisToIso(millis: Long): String = isoFormat().format(Date(millis))

private fun isoToUtcMillis(iso: String?): Long? =
    iso?.let { runCatching { isoFormat().parse(it)?.time }.getOrNull() }

internal fun formatSalary(value: Double): String {
    val formatter = NumberFormat.getNumberInstance(Locale.US).apply {
        minimumFractionDigits = 2
        maximumFractionDigits = 2
    }
    return "KES ${formatter.format(value)}"
}

private fun formatPlain(value: Double): String =
    if (value % 1.0 == 0.0) value.toLong().toString() else value.toString()
