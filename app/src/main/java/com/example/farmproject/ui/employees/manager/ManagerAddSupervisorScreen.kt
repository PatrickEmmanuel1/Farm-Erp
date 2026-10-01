package com.example.farmproject.ui.employees.manager

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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Phone
import androidx.compose.material.icons.filled.Save
import androidx.compose.material.icons.filled.SupervisorAccount
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel

// Must match MIN_PASSWORD_LENGTH in EmployeeRepository and the create-supervisor Edge Function.
private const val MIN_PASSWORD_LENGTH = 8

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerAddSupervisorScreen(
    viewModel: EmployeesViewModel = viewModel(),
    onBackClick: () -> Unit = {},
    // Defaults to saving through this screen's own ViewModel. Only override it if you
    // really need to intercept the save, and then make sure it calls the SAME ViewModel
    // instance, otherwise the saving/error/saved state below will never update.
    onSaveClick: (
        fullName: String,
        email: String,
        phoneNumber: String?,
        employeeNumber: String?,
        password: String
    ) -> Unit = { name, mail, phone, empNum, pass ->
        viewModel.addSupervisor(name, mail, phone, empNum, pass)
    }
) {
    val saveState by viewModel.saveState.collectAsStateWithLifecycle()
    val isSaving = saveState is EmployeeSaveState.Saving
    val serverError = (saveState as? EmployeeSaveState.Error)?.message

    // Clear anything left over from a previous attempt when the screen opens.
    LaunchedEffect(Unit) {
        viewModel.resetSaveState()
    }

    LaunchedEffect(saveState) {
        if (saveState is EmployeeSaveState.Saved) {
            viewModel.resetSaveState()
            onBackClick()
        }
    }

    var fullName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var employeeNumber by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }

    var fullNameError by remember { mutableStateOf<String?>(null) }
    var emailError by remember { mutableStateOf<String?>(null) }
    var passwordError by remember { mutableStateOf<String?>(null) }

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
                IconButton(onClick = onBackClick, enabled = !isSaving) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = Color.White
                    )
                }

                Spacer(modifier = Modifier.width(8.dp))

                Column {
                    Text(
                        text = "Add Supervisor",
                        color = Color.White,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.Bold
                    )

                    Text(
                        text = "Register a new supervisor",
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
            SectionTitle(
                icon = Icons.Default.SupervisorAccount,
                title = "Basic Information"
            )

            OutlinedTextField(
                value = fullName,
                onValueChange = {
                    fullName = it
                    fullNameError = null
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Full Name *") },
                placeholder = { Text("e.g. John Mwangi") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = null
                    )
                },
                isError = fullNameError != null,
                supportingText = fullNameError?.let { { Text(it) } },
                singleLine = true,
                enabled = !isSaving,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = email,
                onValueChange = {
                    email = it
                    emailError = null
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Email *") },
                placeholder = { Text("e.g. john.mwangi@example.com") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Email,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                isError = emailError != null,
                supportingText = emailError?.let { { Text(it) } },
                singleLine = true,
                enabled = !isSaving,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            // Temporary Password
            OutlinedTextField(
                value = password,
                onValueChange = {
                    password = it
                    passwordError = null
                },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Temporary Password *") },
                placeholder = { Text("At least $MIN_PASSWORD_LENGTH characters") },
                supportingText = {
                    if (passwordError != null) {
                        Text(passwordError!!)
                    } else {
                        Text("The supervisor will use this password to sign in.")
                    }
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = null
                    )
                },
                trailingIcon = {
                    TextButton(onClick = { passwordVisible = !passwordVisible }) {
                        Text(if (passwordVisible) "Hide" else "Show")
                    }
                },
                visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                isError = passwordError != null,
                singleLine = true,
                enabled = !isSaving,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            SectionTitle(
                icon = Icons.Default.Badge,
                title = "Employment Details"
            )

            OutlinedTextField(
                value = phone,
                onValueChange = { phone = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Phone Number") },
                placeholder = { Text("e.g. +254 712 345 678") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Phone,
                        contentDescription = null
                    )
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                singleLine = true,
                enabled = !isSaving,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            OutlinedTextField(
                value = employeeNumber,
                onValueChange = { employeeNumber = it },
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Employee Number (optional)") },
                placeholder = { Text("e.g. SUP-014") },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Badge,
                        contentDescription = null
                    )
                },
                singleLine = true,
                enabled = !isSaving,
                colors = fieldColors,
                shape = RoundedCornerShape(12.dp)
            )

            // Server-side failures (duplicate email, staff limit, no farm, network...)
            if (serverError != null) {
                Text(
                    text = serverError,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodyMedium
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            Button(
                onClick = {
                    var isValid = true
                    if (fullName.isBlank()) {
                        fullNameError = "Please enter full name"
                        isValid = false
                    }
                    if (email.isBlank()) {
                        emailError = "Please enter email"
                        isValid = false
                    } else if (!android.util.Patterns.EMAIL_ADDRESS.matcher(email.trim()).matches()) {
                        emailError = "Enter a valid email address"
                        isValid = false
                    }
                    if (password.isBlank()) {
                        passwordError = "Please enter temporary password"
                        isValid = false
                    } else if (password.length < MIN_PASSWORD_LENGTH) {
                        passwordError = "Password must be at least $MIN_PASSWORD_LENGTH characters"
                        isValid = false
                    }

                    if (isValid) {
                        onSaveClick(
                            fullName.trim(),
                            email.trim(),
                            phone.trim().ifBlank { null },
                            employeeNumber.trim().ifBlank { null },
                            password
                        )
                    }
                },
                enabled = !isSaving,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(54.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF1565C0)
                )
            ) {
                if (isSaving) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(22.dp),
                        strokeWidth = 2.dp,
                        color = Color.White
                    )
                } else {
                    Icon(
                        imageVector = Icons.Default.Save,
                        contentDescription = null
                    )

                    Spacer(modifier = Modifier.width(8.dp))

                    Text(
                        text = "Save Supervisor",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun SectionTitle(
    icon: ImageVector,
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