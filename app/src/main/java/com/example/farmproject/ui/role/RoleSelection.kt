package com.example.farmproject.ui.role

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp


@Composable
fun RoleSelectionScreen(
    onManagerSelected: () -> Unit,
    onSupervisorSelected: () -> Unit,
    onWorkerSelected: () -> Unit
) {

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                MaterialTheme.colorScheme.background
            )
    ) {

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(
                    horizontal = 24.dp,
                    vertical = 40.dp
                ),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {

            // Application name
            Text(
                text = "MyFarm",
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(
                modifier = Modifier.height(8.dp)
            )

            Text(
                text = "Smart Farm Management",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onBackground,
                textAlign = TextAlign.Center
            )

            Spacer(
                modifier = Modifier.height(36.dp)
            )

            Text(
                text = "Welcome",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )

            Spacer(
                modifier = Modifier.height(8.dp)
            )

            Text(
                text = "Select your role to continue",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )

            Spacer(
                modifier = Modifier.height(28.dp)
            )

            // Manager
            RoleCard(
                title = "Manager",
                description = "Manage farms, workers, resources and operations",
                onClick = onManagerSelected
            )

            Spacer(
                modifier = Modifier.height(16.dp)
            )

            // Supervisor
            RoleCard(
                title = "Supervisor",
                description = "Supervise farm activities, crops and workers",
                onClick = onSupervisorSelected
            )

            Spacer(
                modifier = Modifier.height(16.dp)
            )

            // Worker
            RoleCard(
                title = "Worker",
                description = "View assigned tasks and record farm activities",
                onClick = onWorkerSelected
            )
        }
    }
}


@Composable
private fun RoleCard(
    title: String,
    description: String,
    onClick: () -> Unit
) {

    Card(
        modifier = Modifier
            .fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(
            defaultElevation = 4.dp
        )
    ) {

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp)
        ) {

            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )

            Spacer(
                modifier = Modifier.height(6.dp)
            )

            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(
                modifier = Modifier.height(14.dp)
            )

            Button(
                onClick = onClick,
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.primary
                )
            ) {
                Text(
                    text = "Continue"
                )
            }
        }
    }
}