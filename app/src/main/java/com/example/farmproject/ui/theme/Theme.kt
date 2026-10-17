package com.example.farmproject.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

private val DarkColorScheme = darkColorScheme(
    primary = LeafGreenSecondary,
    onPrimary = Color.White,
    primaryContainer = ForestGreenPrimary,
    onPrimaryContainer = MintGreenContainer,
    secondary = TurquoiseMedium,
    onSecondary = Color.White,
    secondaryContainer = TurquoiseDark,
    onSecondaryContainer = TurquoiseCardBackground,
    tertiary = AmberWarning,
    onTertiary = Color.Black,
    background = Color(0xFF121212),
    surface = Color(0xFF1E1E1E),
    surfaceVariant = Color(0xFF2C2C2C),
    onSurfaceVariant = WarmClaySurface,
    error = WarmCoralError,
    errorContainer = CrimsonRed
)

private val LightColorScheme = lightColorScheme(
    primary = ForestGreenPrimary,
    onPrimary = Color.White,
    primaryContainer = MintGreenContainer,
    onPrimaryContainer = ForestGreenPrimary,
    secondary = LeafGreenSecondary,
    onSecondary = Color.White,
    secondaryContainer = TurquoiseCardBackground,
    onSecondaryContainer = TurquoiseDark,
    tertiary = HarvestGold,
    onTertiary = Color.White,
    tertiaryContainer = CreamYellowContainer,
    onTertiaryContainer = HarvestGold,
    background = SoftEarthBackground,
    onBackground = Color(0xFF212121),
    surface = Color.White,
    onSurface = Color(0xFF212121),
    surfaceVariant = WarmClaySurface,
    onSurfaceVariant = EarthBrown,
    error = CrimsonRed,
    errorContainer = LightRedContainer,
    onError = Color.White
)

@Composable
fun FarmProjectTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }

        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
