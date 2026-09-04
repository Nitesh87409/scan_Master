package com.scanner.poc.processor

import android.graphics.Bitmap
import android.graphics.Color
import kotlin.math.max
import kotlin.math.sqrt

object ImageWarper {
    fun warpPerspective(bitmap: Bitmap, corners: FloatArray): Bitmap {
        val tlX = corners[0]; val tlY = corners[1]
        val trX = corners[2]; val trY = corners[3]
        val brX = corners[4]; val brY = corners[5]
        val blX = corners[6]; val blY = corners[7]

        val widthA = sqrt(Math.pow((brX - blX).toDouble(), 2.0) + Math.pow((brY - blY).toDouble(), 2.0))
        val widthB = sqrt(Math.pow((trX - tlX).toDouble(), 2.0) + Math.pow((trY - tlY).toDouble(), 2.0))
        val maxWidth = max(widthA.toInt(), widthB.toInt())

        val heightA = sqrt(Math.pow((trX - brX).toDouble(), 2.0) + Math.pow((trY - brY).toDouble(), 2.0))
        val heightB = sqrt(Math.pow((tlX - blX).toDouble(), 2.0) + Math.pow((tlY - blY).toDouble(), 2.0))
        val maxHeight = max(heightA.toInt(), heightB.toInt())

        if (maxWidth <= 0 || maxHeight <= 0) return bitmap

        val output = Bitmap.createBitmap(maxWidth, maxHeight, Bitmap.Config.ARGB_8888)
        
        val dst = floatArrayOf(
            tlX, tlY,
            trX, trY,
            brX, brY,
            blX, blY
        )
        val src = floatArrayOf(
            0f, 0f,
            maxWidth.toFloat() - 1, 0f,
            maxWidth.toFloat() - 1, maxHeight.toFloat() - 1,
            0f, maxHeight.toFloat() - 1
        )
        
        val m = getPerspectiveTransform(src, dst)

        val srcPixels = IntArray(bitmap.width * bitmap.height)
        bitmap.getPixels(srcPixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
        val dstPixels = IntArray(maxWidth * maxHeight)

        for (y in 0 until maxHeight) {
            for (x in 0 until maxWidth) {
                val denom = m[6] * x + m[7] * y + m[8]
                if (denom == 0f) continue
                
                val srcX = (m[0] * x + m[1] * y + m[2]) / denom
                val srcY = (m[3] * x + m[4] * y + m[5]) / denom
                
                val ix = srcX.toInt()
                val iy = srcY.toInt()
                
                if (ix in 0 until bitmap.width && iy in 0 until bitmap.height) {
                    dstPixels[y * maxWidth + x] = srcPixels[iy * bitmap.width + ix]
                }
            }
        }
        
        output.setPixels(dstPixels, 0, maxWidth, 0, 0, maxWidth, maxHeight)
        return output
    }

    private fun getPerspectiveTransform(src: FloatArray, dst: FloatArray): FloatArray {
        val a = Array(8) { DoubleArray(8) }
        val b = DoubleArray(8)

        for (i in 0..3) {
            val sx = src[i * 2].toDouble()
            val sy = src[i * 2 + 1].toDouble()
            val dx = dst[i * 2].toDouble()
            val dy = dst[i * 2 + 1].toDouble()

            a[i * 2][0] = sx; a[i * 2][1] = sy; a[i * 2][2] = 1.0
            a[i * 2][3] = 0.0; a[i * 2][4] = 0.0; a[i * 2][5] = 0.0
            a[i * 2][6] = -dx * sx; a[i * 2][7] = -dx * sy
            b[i * 2] = dx

            a[i * 2 + 1][0] = 0.0; a[i * 2 + 1][1] = 0.0; a[i * 2 + 1][2] = 0.0
            a[i * 2 + 1][3] = sx; a[i * 2 + 1][4] = sy; a[i * 2 + 1][5] = 1.0
            a[i * 2 + 1][6] = -dy * sx; a[i * 2 + 1][7] = -dy * sy
            b[i * 2 + 1] = dy
        }

        val h = solve(a, b)
        return floatArrayOf(
            h[0].toFloat(), h[1].toFloat(), h[2].toFloat(),
            h[3].toFloat(), h[4].toFloat(), h[5].toFloat(),
            h[6].toFloat(), h[7].toFloat(), 1f
        )
    }

    private fun solve(a: Array<DoubleArray>, b: DoubleArray): DoubleArray {
        val n = 8
        for (i in 0 until n) {
            var pivot = i
            for (j in i + 1 until n) {
                if (Math.abs(a[j][i]) > Math.abs(a[pivot][i])) pivot = j
            }
            val tempA = a[i]; a[i] = a[pivot]; a[pivot] = tempA
            val tempB = b[i]; b[i] = b[pivot]; b[pivot] = tempB

            for (j in i + 1 until n) {
                if (a[i][i] == 0.0) continue
                val factor = a[j][i] / a[i][i]
                for (k in i until n) a[j][k] -= factor * a[i][k]
                b[j] -= factor * b[i]
            }
        }
        val x = DoubleArray(n)
        for (i in n - 1 downTo 0) {
            var sum = 0.0
            for (j in i + 1 until n) sum += a[i][j] * x[j]
            if (a[i][i] != 0.0) {
                x[i] = (b[i] - sum) / a[i][i]
            }
        }
        return x
    }
}
