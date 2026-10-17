@file:Suppress("unused")
@file:OptIn(ExperimentalMaterial3Api::class)

package com.example.farmproject.ui.common

import androidx.compose.foundation.clickable
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.SelectableDates
import androidx.compose.material3.ShapeDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextFieldColors
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Shape
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * An OutlinedTextField for date input that opens a Material 3 DatePicker calendar dialog
 * when clicked or when the calendar icon is tapped.
 */
@Composable
fun DatePickerField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    placeholder: String? = "YYYY-MM-DD",
    leadingIcon: @Composable (() -> Unit)? = {
        Icon(
            imageVector = Icons.Default.CalendarMonth,
            contentDescription = null,
        )
    },
    isError: Boolean = false,
    supportingText: @Composable (() -> Unit)? = null,
    colors: TextFieldColors = OutlinedTextFieldDefaults.colors(),
    shape: Shape = ShapeDefaults.Small,
    allowFutureDates: Boolean = true,
    allowPastDates: Boolean = true,
    enabled: Boolean = true,
) {
    var showDialog by remember { mutableStateOf(value = false) }

    OutlinedTextField(
        value = value,
        onValueChange = { },
        readOnly = true,
        enabled = enabled,
        label = { Text(label) },
        placeholder = placeholder?.let { { Text(it) } },
        leadingIcon = leadingIcon,
        trailingIcon = {
            IconButton(
                onClick = { if (enabled) showDialog = true },
                enabled = enabled,
            ) {
                Icon(
                    imageVector = Icons.Default.CalendarMonth,
                    contentDescription = "Select $label",
                )
            }
        },
        isError = isError,
        supportingText = supportingText,
        colors = colors,
        shape = shape,
        singleLine = true,
        modifier = modifier.clickable(enabled = enabled) {
            showDialog = true
        },
    )

    if (showDialog) {
        AppDatePickerDialog(
            initialDateIso = value,
            allowFutureDates = allowFutureDates,
            allowPastDates = allowPastDates,
            onDateSelected = { selectedIso ->
                onValueChange(selectedIso)
                showDialog = false
            },
            onDismiss = { showDialog = false },
        )
    }
}

@Composable
fun AppDatePickerDialog(
    initialDateIso: String? = null,
    allowFutureDates: Boolean = true,
    allowPastDates: Boolean = true,
    onDateSelected: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    val initialMillis = isoToUtcMillis(initialDateIso)
    val pickerState = rememberDatePickerState(
        initialSelectedDateMillis = initialMillis,
        selectableDates = object : SelectableDates {
            override fun isSelectableDate(utcTimeMillis: Long): Boolean {
                val todayMs = System.currentTimeMillis()
                val oneDayMs = 24L * 60 * 60 * 1000
                if ((!allowFutureDates) && (utcTimeMillis > todayMs + oneDayMs)) return false
                return !((!allowPastDates) && (utcTimeMillis < todayMs - oneDayMs))
            }
        },
    )

    DatePickerDialog(
        onDismissRequest = onDismiss,
        confirmButton = {
            TextButton(
                onClick = {
                    pickerState.selectedDateMillis?.let { millis ->
                        onDateSelected(utcMillisToIso(millis))
                    }
                    onDismiss()
                },
            ) {
                Text("OK")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        },
    ) {
        DatePicker(state = pickerState)
    }
}

private fun isoFormat() = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
    timeZone = TimeZone.getTimeZone("UTC")
}

fun utcMillisToIso(millis: Long): String = isoFormat().format(Date(millis))

fun isoToUtcMillis(iso: String?): Long? =
    iso?.let { runCatching { isoFormat().parse(it.trim())?.time }.getOrNull() }
