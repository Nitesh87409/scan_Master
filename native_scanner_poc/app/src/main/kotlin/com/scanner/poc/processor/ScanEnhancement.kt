package com.scanner.poc.processor

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint

enum class EnhancementMode { ORIGINAL, AUTO, GRAYSCALE, BLACK_WHITE }

object ScanEnhancement {
    fun apply(source: Bitmap, mode: EnhancementMode): Bitmap {
        if (mode == EnhancementMode.ORIGINAL) return source
        val output = source.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        when (mode) {
            EnhancementMode.AUTO -> {
                val matrix = ColorMatrix().apply {
                    setSaturation(1.08f)
                    postConcat(ColorMatrix(floatArrayOf(
                        1.10f, 0f, 0f, 0f, -10f,
                        0f, 1.10f, 0f, 0f, -10f,
                        0f, 0f, 1.10f, 0f, -10f,
                        0f, 0f, 0f, 1f, 0f
                    )))
                }
                paint.colorFilter = ColorMatrixColorFilter(matrix)
            }
            EnhancementMode.GRAYSCALE -> paint.colorFilter = ColorMatrixColorFilter(ColorMatrix().apply { setSaturation(0f) })
            EnhancementMode.BLACK_WHITE -> {
                val pixels = IntArray(output.width * output.height)
                output.getPixels(pixels, 0, output.width, 0, 0, output.width, output.height)
                for (i in pixels.indices) {
                    val luma = (0.299f * android.graphics.Color.red(pixels[i]) + 0.587f * android.graphics.Color.green(pixels[i]) + 0.114f * android.graphics.Color.blue(pixels[i]))
                    val v = if (luma > 165f) 255 else 0
                    pixels[i] = android.graphics.Color.rgb(v, v, v)
                }
                output.setPixels(pixels, 0, output.width, 0, 0, output.width, output.height)
                return output
            }
            EnhancementMode.ORIGINAL -> Unit
        }
        canvas.drawBitmap(source, 0f, 0f, paint)
        return output
    }
}
