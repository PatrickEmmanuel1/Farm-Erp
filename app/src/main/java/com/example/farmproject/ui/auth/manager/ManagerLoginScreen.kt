package com.example.farmproject.ui.auth.manager

import androidx.compose.foundation.background
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.farmproject.ui.auth.LoginUiState
import com.example.farmproject.ui.auth.LoginViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManagerLoginScreen(
    viewModel: LoginViewModel = viewModel(),
    onLoginSuccess: () -> Unit,
    onSignUpClick: () -> Unit = {}
) {
    val uiState by viewModel.uiState.collectAsState()

    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var passwordVisible by remember { mutableStateOf(false) }

    var emailError by remember { mutableStateOf(false) }
    var passwordError by remember { mutableStateOf(false) }

    LaunchedEffect(uiState) {
        if (uiState is LoginUiState.Success) {
            onLoginSuccess()
        }
    }

    val deepGreenBackground = Color(0xFF1B5E20)
    val turquoiseCardBg = Color(0xFFE0F2F1)
    val turquoiseTextDark = Color(0xFF004D40)
    val primaryGreenButton = Color(0xFF2E7D32)

    val fieldColors = OutlinedTextFieldDefaults.colors(
        focusedBorderColor = turquoiseTextDark,
        unfocusedBorderColor = Color(0xFF80CBC4),
        focusedLabelColor = turquoiseTextDark,
        cursorColor = turquoiseTextDark,
        focusedTextColor = turquoiseTextDark,
        unfocusedTextColor = turquoiseTextDark
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(deepGreenBackground)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Farm ERP",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = "Smart Agricultural Management System",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.White.copy(alpha = 0.9f),
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(28.dp))

            // TURQUOISE LOGIN CARD
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = turquoiseCardBg
                ),
                elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
            ) {
                Column(
                    modifier = Modifier.padding(24.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Welcome Back",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Bold,
                        color = turquoiseTextDark
                    )

                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = "Sign in to manage your farm operations",
                        fontSize = 13.sp,
                        color = turquoiseTextDark.copy(alpha = 0.8f),
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(24.dp))

                    // Email
                    OutlinedTextField(
                        value = email,
                        onValueChange = {
                            email = it
                            emailError = false
                        },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Email") },
                        placeholder = { Text("Enter your email") },
                        singleLine = true,
                        isError = emailError,
                        supportingText = {
                            if (emailError) {
                                Text("Please enter your email", color = MaterialTheme.colorScheme.error)
                            }
                        },
                        colors = fieldColors,
                        shape = RoundedCornerShape(12.dp)
                    )

                    Spacer(modifier = Modifier.height(14.dp))

                    // Password
                    OutlinedTextField(
                        value = password,
                        onValueChange = {
                            password = it
                            passwordError = false
                        },
                        modifier = Modifier.fillMaxWidth(),
                        label = { Text("Password") },
                        placeholder = { Text("Enter your password") },
                        singleLine = true,
                        isError = passwordError,
                        supportingText = {
                            if (passwordError) {
                                Text("Please enter your password", color = MaterialTheme.colorScheme.error)
                            }
                        },
                        visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                        trailingIcon = {
                            TextButton(onClick = { passwordVisible = !passwordVisible }) {
                                Text(
                                    text = if (passwordVisible) "Hide" else "Show",
                                    color = turquoiseTextDark,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        },
                        colors = fieldColors,
                        shape = RoundedCornerShape(12.dp)
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Forgot password
                    Box(modifier = Modifier.fillMaxWidth()) {
                        TextButton(
                            onClick = {
                                // Password recovery
                            },
                            modifier = Modifier.align(Alignment.CenterEnd)
                        ) {
                            Text(
                                text = "Forgot password?",
                                color = turquoiseTextDark,
                                fontSize = 13.sp
                            )
                        }
                    }

                    if (uiState is LoginUiState.Error) {
                        val errorMsg = (uiState as LoginUiState.Error).message
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = errorMsg,
                            color = MaterialTheme.colorScheme.error,
                            style = MaterialTheme.typography.bodySmall,
                            textAlign = TextAlign.Center
                        )
                        if (errorMsg.contains("Confirm", ignoreCase = true)) {
                            Spacer(modifier = Modifier.height(6.dp))
                            TextButton(onClick = onSignUpClick) {
                                Text(
                                    text = "Create New Account",
                                    fontWeight = FontWeight.Bold,
                                    color = turquoiseTextDark
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Login button
                    Button(
                        onClick = {
                            emailError = email.isBlank()
                            passwordError = password.isBlank()

                            if (!emailError && !passwordError) {
                                viewModel.login(email, password)
                            }
                        },
                        enabled = uiState !is LoginUiState.Loading,
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(52.dp),
                        shape = RoundedCornerShape(12.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = primaryGreenButton
                        )
                    ) {
                        if (uiState is LoginUiState.Loading) {
                            CircularProgressIndicator(
                                color = Color.White,
                                modifier = Modifier.size(24.dp)
                            )
                        } else {
                            Text(
                                text = "Sign In",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = Color.White
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(
                            text = "Don't have an account? ",
                            fontSize = 14.sp,
                            color = turquoiseTextDark
                        )
                        TextButton(onClick = onSignUpClick) {
                            Text(
                                text = "Sign Up",
                                fontWeight = FontWeight.Bold,
                                color = turquoiseTextDark,
                                fontSize = 14.sp
                            )
                        }
                    }
                }
            }
        }
    }
}
