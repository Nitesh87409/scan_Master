package com.scanner.poc.ui

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/**
 * IdCardScreen — Phase 5
 *
 * Step 1: User scans FRONT of ID card.
 * Step 2: User scans BACK of ID card.
 * Both go through CropScreen (edge detect + perspective).
 * After both are done, this screen stitches them onto a single A4 page.
 */
@Composable
fun IdCardPreviewScreen(
    frontBitmap: Bitmap,
    backBitmap: Bitmap,
    onSave: (Bitmap) -> Unit,
    onRetake: () -> Unit
) {
    // Merge front + back onto a single A4 canvas immediately
    val mergedBitmap = remember(frontBitmap, backBitmap) {
        mergeIdCard(frontBitmap, backBitmap)
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(androidx.compose.ui.graphics.Color.Black),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(Modifier.height(16.dp))

        Text(
            "ID Card Preview",
            color = androidx.compose.ui.graphics.Color.White,
            fontSize = 18.sp
        )
        Text(
            "Front (top) + Back (bottom) on single page",
            color = androidx.compose.ui.graphics.Color.Gray,
            fontSize = 12.sp
        )

        Spacer(Modifier.height(8.dp))

        Image(
            bitmap = mergedBitmap.asImageBitmap(),
            contentDescription = "ID Card merged",
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f)
                .padding(16.dp),
            contentScale = ContentScale.Fit
        )

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
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = androidx.compose.ui.graphics.Color.White
                )
            ) {
                Text("🔄 Rescan")
            }

            Button(
                onClick = { onSave(mergedBitmap) },
                modifier = Modifier.weight(1f),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = androidx.compose.ui.graphics.Color(0xFF00BCD4)
                )
            ) {
                Text("💾 Save PDF", color = androidx.compose.ui.graphics.Color.Black)
            }
        }

        Spacer(Modifier.height(16.dp))
    }
}

/**
 * Stitch FRONT and BACK bitmaps onto a single A4-sized white canvas.
 * Front goes on the top half, Back goes on the bottom half.
 *
 * Uses Android's native Canvas API — no extra library needed.
 */
fun mergeIdCard(front: Bitmap, back: Bitmap): Bitmap {
    // A4 at 200dpi: 1654 x 2339 pixels
    val a4Width = 1654
    val a4Height = 2339

    val result = Bitmap.createBitmap(a4Width, a4Height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(result)

    // White background
    canvas.drawColor(Color.WHITE)

    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    val margin = 60  // margin in pixels
    val slotHeight = (a4Height / 2) - (margin * 2)
    val slotWidth = a4Width - (margin * 2)

    // ── Draw FRONT (top half) ──────────────────────────────────────────────
    val frontScaled = scaleBitmapToFit(front, slotWidth, slotHeight)
    val frontLeft = (a4Width - frontScaled.width) / 2f
    val frontTop = margin.toFloat()
    canvas.drawBitmap(frontScaled, frontLeft, frontTop, paint)

    // ── Divider line ───────────────────────────────────────────────────────
    val dividerPaint = Paint().apply {
        color = Color.LTGRAY
        strokeWidth = 2f
    }
    val midY = a4Height / 2f
    canvas.drawLine(margin.toFloat(), midY, (a4Width - margin).toFloat(), midY, dividerPaint)

    // ── Draw BACK (bottom half) ────────────────────────────────────────────
    val backScaled = scaleBitmapToFit(back, slotWidth, slotHeight)
    val backLeft = (a4Width - backScaled.width) / 2f
    val backTop = midY + margin
    canvas.drawBitmap(backScaled, backLeft, backTop, paint)

    return result
}

/** Scale bitmap to fit within maxWidth x maxHeight while maintaining aspect ratio */
private fun scaleBitmapToFit(src: Bitmap, maxWidth: Int, maxHeight: Int): Bitmap {
    val widthRatio = maxWidth.toFloat() / src.width
    val heightRatio = maxHeight.toFloat() / src.height
    val scale = minOf(widthRatio, heightRatio)
    val newWidth = (src.width * scale).toInt()
    val newHeight = (src.height * scale).toInt()
    return Bitmap.createScaledBitmap(src, newWidth, newHeight, true)
}
