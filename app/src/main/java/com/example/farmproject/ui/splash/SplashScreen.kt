package com.example.farmproject.ui.splash

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlin.time.Duration.Companion.milliseconds

@Composable
fun SplashScreen(
    onSplashFinished: () -> Unit
) {

    LaunchedEffect(Unit) {
        delay(2500.milliseconds)
        onSplashFinished()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.primary),
        contentAlignment = Alignment.Center
    ) {

        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {

            // Farm ERP Logo
            Box(
                modifier = Modifier
                    .size(120.dp)
                    .background(
                        color = MaterialTheme.colorScheme.surface,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {

                FarmLogo()
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text(
                text = "Farm ERP",
                style = MaterialTheme.typography.headlineLarge,
                color = MaterialTheme.colorScheme.onPrimary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Smart Farm Management",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onPrimary
            )

            Spacer(modifier = Modifier.height(40.dp))

            CircularProgressIndicator(
                modifier = Modifier.size(28.dp),
                color = MaterialTheme.colorScheme.onPrimary,
                strokeWidth = 3.dp
            )
        }
    }
}

@Composable
private fun FarmLogo() {

    val primaryColor = MaterialTheme.colorScheme.primary

    Canvas(
        modifier = Modifier.size(70.dp)
    ) {

        val width = size.width
        val height = size.height

        // Stem
        drawLine(
            color = primaryColor,
            start = Offset(
                width * 0.50f,
                height * 0.80f
            ),
            end = Offset(
                width * 0.50f,
                height * 0.42f
            ),
            strokeWidth = 5f,
            cap = StrokeCap.Round
        )

        // Left leaf
        val leftLeaf = Path().apply {
            moveTo(
                width * 0.50f,
                height * 0.55f
            )

            cubicTo(
                width * 0.20f,
                height * 0.55f,
                width * 0.15f,
                height * 0.25f,
                width * 0.42f,
                height * 0.28f
            )

            cubicTo(
                width * 0.55f,
                height * 0.30f,
                width * 0.55f,
                height * 0.45f,
                width * 0.50f,
                height * 0.55f
            )

            close()
        }

        drawPath(
            path = leftLeaf,
            color = primaryColor
        )

        // Right leaf
        val rightLeaf = Path().apply {
            moveTo(
                width * 0.50f,
                height * 0.55f
            )

            cubicTo(
                width * 0.80f,
                height * 0.55f,
                width * 0.85f,
                height * 0.25f,
                width * 0.58f,
                height * 0.28f
            )

            cubicTo(
                width * 0.45f,
                height * 0.30f,
                width * 0.45f,
                height * 0.45f,
                width * 0.50f,
                height * 0.55f
            )

            close()
        }

        drawPath(
            path = rightLeaf,
            color = primaryColor
        )

        // Ground
        drawLine(
            color = primaryColor,
            start = Offset(
                width * 0.25f,
                height * 0.82f
            ),
            end = Offset(
                width * 0.75f,
                height * 0.82f
            ),
            strokeWidth = 5f,
            cap = StrokeCap.Round
        )
    }
}

