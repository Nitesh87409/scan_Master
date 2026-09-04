package com.scanner.poc.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Scanner app uses dark theme by default (camera screens look better dark)
private val ScannerColorScheme = darkColorScheme(
    primary = Color(0xFF00BCD4),        // Cyan — action buttons
    onPrimary = Color.Black,
    surface = Color(0xFF1A1A1A),        // Very dark surface
    onSurface = Color.White,
    background = Color.Black,
    onBackground = Color.White,
    secondary = Color(0xFF4CAF50),      // Green — confirmation actions
    onSecondary = Color.Black,
    tertiary = Color(0xFFFFC107),       // Amber — flash / warnings
)

@Composable
fun NativeScannerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = ScannerColorScheme,
        content = content
    )
}
