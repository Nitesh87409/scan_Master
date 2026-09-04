package com.scanner.poc.util

import android.content.ContentValues
import android.content.Context
import android.graphics.Bitmap
import android.graphics.pdf.PdfDocument
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * PdfSaver — Phase 5
 *
 * Converts a Bitmap to a PDF and saves it to the device storage.
 * Uses Android's built-in PdfDocument API — no extra library needed.
 */
object PdfSaver {

    /**
     * Save a Bitmap as a PDF file.
     *
     * @param context App context
     * @param bitmap  The merged A4 bitmap (from mergeIdCard or a regular scan)
     * @param fileName Desired file name (without extension)
     * @return The saved file path, or null on failure
     */
    fun saveBitmapAsPdf(context: Context, bitmap: Bitmap, fileName: String): String? {
        return try {
            val pdf = PdfDocument()
            val pageInfo = PdfDocument.PageInfo.Builder(bitmap.width, bitmap.height, 1).create()
            val page = pdf.startPage(pageInfo)

            // Draw bitmap onto the PDF page canvas
            page.canvas.drawBitmap(bitmap, 0f, 0f, null)
            pdf.finishPage(page)

            // Save using MediaStore (works on Android 10+)
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, "$fileName.pdf")
                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOCUMENTS + "/ScannerPOC")
            }

            val uri = context.contentResolver.insert(
                MediaStore.Files.getContentUri("external"), contentValues
            )

            uri?.let {
                context.contentResolver.openOutputStream(it)?.use { stream ->
                    pdf.writeTo(stream)
                }
                pdf.close()
                // Return the file name as confirmation
                "$fileName.pdf saved to Documents/ScannerPOC"
            } ?: run {
                // Fallback for older Android: save to app's files dir
                val file = File(context.filesDir, "$fileName.pdf")
                FileOutputStream(file).use { stream -> pdf.writeTo(stream) }
                pdf.close()
                file.absolutePath
            }
        } catch (e: Exception) {
            android.util.Log.e("PdfSaver", "Failed to save PDF: ${e.message}")
            null
        }
    }
}
