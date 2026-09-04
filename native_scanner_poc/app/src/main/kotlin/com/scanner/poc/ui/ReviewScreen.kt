package com.scanner.poc.ui

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.scanner.poc.processor.EnhancementMode
import com.scanner.poc.processor.ScanEnhancement

@Composable
fun ReviewScreen(bitmap: Bitmap, onRetake: () -> Unit, onSave: (Bitmap) -> Unit) {
    var selected by remember { mutableStateOf(EnhancementMode.AUTO) }
    val preview = remember(bitmap, selected) { ScanEnhancement.apply(bitmap, selected) }
    Column(Modifier.fillMaxSize().background(Color.Black), horizontalAlignment = Alignment.CenterHorizontally) {
        Text("Review scan", color = Color.White, fontSize = 20.sp, modifier = Modifier.padding(top = 18.dp))
        Image(preview.asImageBitmap(), "Scanned document", Modifier.fillMaxWidth().weight(1f).padding(16.dp), contentScale = ContentScale.Fit)
        Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            EnhancementMode.values().forEach { mode ->
                FilterChip(selected = selected == mode, onClick = { selected = mode }, label = { Text(mode.label()) })
            }
        }
        Row(Modifier.fillMaxWidth().padding(16.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            OutlinedButton(onClick = onRetake, Modifier.weight(1f), shape = RoundedCornerShape(12.dp), colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)) { Text("Retake") }
            Button(onClick = { onSave(preview) }, Modifier.weight(1f), shape = RoundedCornerShape(12.dp), colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF00D4FF))) { Text("Save", color = Color.Black) }
        }
    }
}

private fun EnhancementMode.label() = when (this) {
    EnhancementMode.ORIGINAL -> "Original"
    EnhancementMode.AUTO -> "Auto"
    EnhancementMode.GRAYSCALE -> "Gray"
    EnhancementMode.BLACK_WHITE -> "B&W"
}
