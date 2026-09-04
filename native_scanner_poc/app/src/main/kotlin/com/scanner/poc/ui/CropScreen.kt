package com.scanner.poc.ui

import android.graphics.Bitmap
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.scanner.poc.processor.ImageWarper
import com.scanner.poc.processor.DocumentDetector
import com.scanner.poc.model.ScanMode
import androidx.compose.ui.platform.LocalContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.background
import androidx.compose.material3.CircularProgressIndicator
import android.util.Log
@Composable
fun CropScreen(
    bitmap: Bitmap,
    liveCorners: FloatArray?,
    liveImageSize: androidx.compose.ui.unit.IntSize,
    mode: ScanMode = ScanMode.DOCUMENT,
    onDone: (Bitmap) -> Unit,
    onRetake: () -> Unit
) {
    val context = LocalContext.current
    var cornersState by remember { mutableStateOf<FloatArray?>(null) }

    LaunchedEffect(bitmap) {
        withContext(Dispatchers.Default) {
            val detection = DocumentDetector(context).detect(bitmap, mode)
            val detected = detection?.corners
            Log.d("ScannerDiag", "crop detect mode=$mode bitmap=${bitmap.width}x${bitmap.height} found=${detection != null} confidence=${detection?.confidence ?: 0f} area=${detection?.areaRatio ?: 0f} corners=${detected?.joinToString(",") ?: "none"}")
            
            val liveScaled = if (liveCorners != null && liveImageSize.width > 0 && liveImageSize.height > 0 && isTrustworthyLiveQuad(liveCorners, liveImageSize)) {
                val scaleX = bitmap.width.toFloat() / liveImageSize.width
                val scaleY = bitmap.height.toFloat() / liveImageSize.height
                FloatArray(8) { i -> liveCorners[i] * if (i % 2 == 0) scaleX else scaleY }
            } else null
            // The preview quad is temporally filtered and came from the exact
            // frame the user saw. Prefer it when the high-resolution still
            // detector disagrees (motion blur/focus can make the still model
            // jump to a nearby fold). This prevents a correct live outline from
            // turning into a wrong crop immediately after pressing shutter.
            val finalCorners = if (liveScaled != null && (detected == null || quadDisagreement(liveScaled, detected, bitmap.width, bitmap.height) > .055f)) {
                liveScaled
            } else if (detected != null) {
                detected
            } else if (liveScaled != null) {
                liveScaled
            } else {
                val insetX = bitmap.width * 0.12f
                val insetY = bitmap.height * 0.12f
                floatArrayOf(insetX, insetY, bitmap.width - insetX, insetY,
                    bitmap.width - insetX, bitmap.height - insetY, insetX, bitmap.height - insetY)
            }
            cornersState = finalCorners
        }
    }

    if (cornersState == null) {
        Box(
            modifier = Modifier.fillMaxSize().background(Color.Black),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator(color = Color(0xFF00BCD4))
        }
        return
    }

    val detectedCorners = cornersState!!

    // Canvas display size (we need this to scale pixel coords → screen coords)
    var canvasSize by remember { mutableStateOf(IntSize.Zero) }

    // Current corner positions (in IMAGE pixel coordinates)
    // Initialized from OpenCV detection result
    val corners = remember(detectedCorners) {
        mutableStateListOf(
            Offset(x = detectedCorners[0], y = detectedCorners[1]), // Top-Left
            Offset(x = detectedCorners[2], y = detectedCorners[3]), // Top-Right
            Offset(x = detectedCorners[4], y = detectedCorners[5]), // Bottom-Right
            Offset(x = detectedCorners[6], y = detectedCorners[7])  // Bottom-Left
        )
    }

    val dotRadius = 20f  // Touch target radius in pixels (screen)

    // Scale factors: image pixel → canvas screen pixel
    val scaleX: Float = if (bitmap.width > 0) canvasSize.width.toFloat() / bitmap.width else 1f
    val scaleY: Float = if (bitmap.height > 0) canvasSize.height.toFloat() / bitmap.height else 1f

    // Convert image coords → screen coords for drawing
    fun toScreen(pt: Offset) = Offset(pt.x * scaleX, pt.y * scaleY)
    // Convert screen coords → image coords when user drags
    fun toImage(pt: Offset) = Offset(pt.x / scaleX, pt.y / scaleY)

    Column(
        modifier = Modifier.fillMaxSize().background(Color.Black),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(16.dp))

        Text(
            text = "Adjust Edges",
            color = Color.White,
            fontSize = 18.sp
        )
        Text(
            text = "Drag the corners to align with the document",
            color = Color.Gray,
            fontSize = 12.sp
        )

        Spacer(Modifier.height(8.dp))

        // ── Canvas: Image + Overlay + Corner Dots ─────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(8.dp)
        ) {
            Canvas(
                modifier = Modifier
                    .fillMaxSize()
                    .onGloballyPositioned { canvasSize = it.size }
                    .pointerInput(scaleX, scaleY) {
                        detectDragGestures { change, dragAmount ->
                            change.consume()
                            val touchPos = change.position

                            // Find which corner is closest to the touch point
                            val screenCorners = corners.map { toScreen(it) }
                            val closest = screenCorners
                                .mapIndexed { i, pt -> i to (pt - touchPos).getDistance() }
                                .minByOrNull { it.second }

                            // Only move if touch is within 60px of a corner
                            if (closest != null && closest.second < 60f) {
                                val idx = closest.first
                                val newScreenPos = screenCorners[idx] + dragAmount
                                corners[idx] = toImage(newScreenPos)
                            }
                        }
                    }
            ) {
                if (canvasSize == IntSize.Zero) return@Canvas

                // Draw the captured image as background
                drawImage(
                    image = bitmap.asImageBitmap(),
                    dstSize = androidx.compose.ui.unit.IntSize(canvasSize.width, canvasSize.height)
                )

                val screenCorners = corners.map { toScreen(it) }

                // Draw semi-transparent overlay outside the document area
                val path = Path().apply {
                    moveTo(screenCorners[0].x, screenCorners[0].y)
                    lineTo(screenCorners[1].x, screenCorners[1].y)
                    lineTo(screenCorners[2].x, screenCorners[2].y)
                    lineTo(screenCorners[3].x, screenCorners[3].y)
                    close()
                }

                // Draw the quadrilateral border
                drawPath(
                    path = path,
                    color = Color(0xFF00BCD4),
                    style = Stroke(width = 3.dp.toPx())
                )

                // Draw the 4 corner dots
                val dotColors = listOf(
                    Color(0xFF00BCD4), Color(0xFF00BCD4),
                    Color(0xFF00BCD4), Color(0xFF00BCD4)
                )
                screenCorners.forEachIndexed { i, pt ->
                    // Outer circle (filled)
                    drawCircle(color = dotColors[i], radius = dotRadius, center = pt)
                    // Inner circle (white)
                    drawCircle(color = Color.White, radius = dotRadius * 0.5f, center = pt)
                }
                // Eight-point scanner affordance. Only the four vertices are
                // passed to the perspective transform; edge points make the
                // detected boundary easier to read and adjust visually.
                screenCorners.indices.forEach { i ->
                    val a = screenCorners[i]
                    val b = screenCorners[(i + 1) % screenCorners.size]
                    val mid = Offset((a.x + b.x) * .5f, (a.y + b.y) * .5f)
                    drawCircle(color = Color(0xFF00BCD4), radius = dotRadius * .38f, center = mid)
                    drawCircle(color = Color.White, radius = dotRadius * .18f, center = mid)
                }
            }
        }

        // ── Action Buttons ─────────────────────────────────────────────────
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedButton(
                onClick = onRetake,
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
            ) {
                Text("🔄 Retake")
            }

            Button(
                onClick = {
                    // Build float array from current (possibly user-adjusted) corners
                    val cornersArray = floatArrayOf(
                        corners[0].x, corners[0].y,
                        corners[1].x, corners[1].y,
                        corners[2].x, corners[2].y,
                        corners[3].x, corners[3].y
                    )
                    // Apply perspective transform in Kotlin
                    val warped = ImageWarper.warpPerspective(bitmap, cornersArray)
                    onDone(warped)
                },
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF00BCD4))
            ) {
                Text("✂️ Crop & Done", color = Color.Black)
            }
        }

        Spacer(Modifier.height(8.dp))
    }
}

private fun quadDisagreement(a: FloatArray, b: FloatArray, width: Int, height: Int): Float {
    val diagonal = kotlin.math.hypot(width.toFloat(), height.toFloat()).coerceAtLeast(1f)
    return (0 until 4).map { i ->
        kotlin.math.hypot(a[i * 2] - b[i * 2], a[i * 2 + 1] - b[i * 2 + 1])
    }.average().toFloat() / diagonal
}

private fun isTrustworthyLiveQuad(c: FloatArray, size: androidx.compose.ui.unit.IntSize): Boolean {
    if (c.size < 8 || size.width <= 0 || size.height <= 0) return false
    val mx = size.width * .035f; val my = size.height * .035f
    for (i in 0 until 4) {
        val x = c[i * 2]; val y = c[i * 2 + 1]
        if (x !in mx..(size.width - mx) || y !in my..(size.height - my)) return false
    }
    var area = 0.0
    for (i in 0 until 4) {
        val j = (i + 1) % 4
        area += c[i * 2] * c[j * 2 + 1] - c[j * 2] * c[i * 2 + 1]
    }
    val ratio = kotlin.math.abs(area) / 2.0 / (size.width.toDouble() * size.height.toDouble())
    return ratio in .08.. .86
}
