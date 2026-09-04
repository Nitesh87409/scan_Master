package com.scanner.poc.processor

import android.graphics.Bitmap
import android.util.Log
import com.scanner.poc.model.ScanMode
import org.opencv.android.Utils
import org.opencv.core.Core
import org.opencv.core.Mat
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/**
 * Native OpenCV detector used before the conservative Kotlin fallback.  It deliberately
 * prefers a coherent low-chroma/bright interior, rather than selecting the strongest
 * arbitrary line rectangle in a patterned scene.
 */
class OpenCvDocumentDetector {
    companion object {
        private const val TAG = "ScannerDiag"
        @Volatile private var loaded = false
        private fun ensureLoaded(): Boolean = runCatching {
            if (!loaded) synchronized(this) {
                if (!loaded) {
                    System.loadLibrary("opencv_java4")
                    loaded = true
                }
            }
            true
        }.getOrElse {
            Log.w(TAG, "OpenCV unavailable; using Kotlin detector", it)
            false
        }
    }

    fun detect(source: Bitmap, mode: ScanMode): DocumentDetection? {
        if (!ensureLoaded() || source.width < 80 || source.height < 80) return null
        val scale = min(1f, 420f / max(source.width, source.height).toFloat())
        val w = max(80, (source.width * scale).toInt())
        val h = max(80, (source.height * scale).toInt())
        val scaled = if (w != source.width || h != source.height) Bitmap.createScaledBitmap(source, w, h, true) else source
        val rgba = Mat(); val rgb = Mat(); val hsv = Mat(); val gray = Mat(); val mask = Mat(); val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_ELLIPSE, Size(5.0, 5.0))
        return try {
            Utils.bitmapToMat(scaled, rgba)
            Imgproc.cvtColor(rgba, rgb, Imgproc.COLOR_RGBA2RGB)
            Imgproc.cvtColor(rgb, hsv, Imgproc.COLOR_RGB2HSV)
            Imgproc.cvtColor(rgb, gray, Imgproc.COLOR_RGB2GRAY)

            // Paper/card prior: bright, low-chroma regions. The second branch keeps
            // warm/aged paper and coloured cards while still rejecting dark cloth.
            val lowChromaBright = Mat(); val veryBright = Mat()
            // Beige patterned backgrounds often have low saturation too. Requiring a
            // higher value here keeps the mask focused on white paper instead of the rug.
            Core.inRange(hsv, Scalar(0.0, 0.0, 175.0), Scalar(180.0, 95.0, 255.0), lowChromaBright)
            Core.inRange(hsv, Scalar(0.0, 0.0, 205.0), Scalar(180.0, 180.0, 255.0), veryBright)
            Core.bitwise_or(lowChromaBright, veryBright, mask)
            Imgproc.morphologyEx(mask, mask, Imgproc.MORPH_CLOSE, kernel, Point(-1.0, -1.0), 1)
            Imgproc.morphologyEx(mask, mask, Imgproc.MORPH_OPEN, kernel)

            val contours = ArrayList<MatOfPoint>()
            Imgproc.findContours(mask, contours, Mat(), Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)
            var best: DocumentDetection? = null
            for (contour in contours) {
                val area = Imgproc.contourArea(contour)
                val areaRatio = (area / (w.toDouble() * h.toDouble())).toFloat()
                if (areaRatio !in 0.035f..0.60f || (mode == ScanMode.DOCUMENT && areaRatio > 0.28f)) { contour.release(); continue }
                val perimeter = Imgproc.arcLength(MatOfPoint2f(*contour.toArray()), true)
                val approx = MatOfPoint2f()
                Imgproc.approxPolyDP(MatOfPoint2f(*contour.toArray()), approx, perimeter * 0.035, true)
                // Paper edges are often broken by folds/shadows. When polygon
                // approximation does not yield four vertices, use the rotated
                // minimum-area rectangle of the coherent bright contour.
                val approxPoints = approx.toArray()
                val candidatePoints = if (approxPoints.size == 4 && Imgproc.isContourConvex(MatOfPoint(*approxPoints))) {
                    approxPoints
                } else if (areaRatio <= 0.55f) {
                    val rect = Imgproc.minAreaRect(MatOfPoint2f(*contour.toArray()))
                    Array(4) { Point() }.also { rect.points(it) }
                } else emptyArray()
                val points = orderCorners(candidatePoints)
                if (points == null || touchesBorder(points, w, h)) { approx.release(); contour.release(); continue }
                val candidate = score(points, areaRatio, hsv, mask, mode, w, h, scale)
                if (candidate != null && (best == null || candidate.confidence > best!!.confidence)) best = candidate
                approx.release(); contour.release()
            }
            if (best != null && best.confidence >= if (mode == ScanMode.DOCUMENT) .42f else .34f) best else null
        } catch (t: Throwable) {
            Log.w(TAG, "OpenCV detection failed: ${t.message}")
            null
        } finally {
            rgba.release(); rgb.release(); hsv.release(); gray.release(); mask.release(); kernel.release()
            if (scaled !== source) scaled.recycle()
        }
    }

    private fun score(points: Array<Point>, areaRatio: Float, hsv: Mat, mask: Mat, mode: ScanMode, w: Int, h: Int, scale: Float): DocumentDetection? {
        val width = (distance(points[0], points[1]) + distance(points[2], points[3])) / 2.0
        val height = (distance(points[0], points[3]) + distance(points[1], points[2])) / 2.0
        if (width < 24 || height < 24) return null
        val ratio = max(width, height) / min(width, height)
        val target = if (mode == ScanMode.ID_CARD) 1.585 else 1.414
        // A sheet of paper (≈1.30–1.33 in this portrait stream) must not be
        // accepted as an ID card. Keep a practical tolerance for common card
        // formats while rejecting the document-mode rectangle.
        if (mode == ScanMode.ID_CARD && ratio !in 1.34..1.95) return null
        val ratioScore = 1.0 - min(1.0, abs(ratio - target) / if (mode == ScanMode.ID_CARD) .95 else 2.0)
        val cx = points.map { it.x }.average() / w; val cy = points.map { it.y }.average() / h
        val centerScore = (1.0 - hypot(cx - .5, cy - .5) / .72).coerceIn(0.0, 1.0)
        val quadArea = polygonArea(points) / (w.toDouble() * h.toDouble())
        // The contour's filled area can look page-sized even when the fitted
        // rectangle has expanded into the surrounding background. Reject those
        // oversized quads in Document mode; the real page in this stream is
        // typically around 0.20–0.25 of the frame.
        if (mode == ScanMode.DOCUMENT && quadArea > 0.27) return null
        val fill = (areaRatio.toDouble() / quadArea.coerceAtLeast(.001)).coerceIn(0.0, 1.0)
        // A document has a broad interior. Sample the centre; patterned backgrounds
        // often have fragmented masks and score poorly on this fill/area combination.
        val interior = Mat.zeros(mask.rows(), mask.cols(), mask.type())
        Imgproc.fillConvexPoly(interior, MatOfPoint(*points), Scalar(255.0))
        val mean = Core.mean(hsv, interior)
        interior.release()
        val saturationScore = (1.0 - mean.`val`[1] / 210.0).coerceIn(0.0, 1.0)
        // Prefer a page-sized region. Very large regions are usually the background
        // (carpet/table) even when their colour is bright and low-chroma.
        // In the portrait analysis stream a normal page occupies roughly 20–25%
        // of the frame. A larger contour is commonly the surrounding cloth or a
        // shadow-expanded mask, so bias selection toward the page-sized candidate.
        val areaScore = (1.0 - abs(areaRatio - .22) / .36).coerceIn(0.0, 1.0)
        val confidence = (.30 * areaScore + .28 * fill + .18 * centerScore + .16 * saturationScore + .08 * ratioScore).toFloat()
        return DocumentDetection(points.flatMap { listOf((it.x / scale).toFloat(), (it.y / scale).toFloat()) }.toFloatArray(), confidence, quadArea.toFloat())
    }

    private fun orderCorners(points: Array<Point>): Array<Point>? {
        if (points.size != 4) return null
        val sorted = points.sortedWith(compareBy<Point> { it.y + it.x }.thenBy { it.x })
        val tl = sorted.first(); val br = sorted.last()
        val remaining = sorted.drop(1).dropLast(1)
        val tr = remaining.maxByOrNull { it.x - it.y } ?: return null
        val bl = remaining.minByOrNull { it.x - it.y } ?: return null
        return arrayOf(tl, tr, br, bl)
    }

    private fun touchesBorder(p: Array<Point>, w: Int, h: Int): Boolean = p.any { it.x < w * .025 || it.x > w * .975 || it.y < h * .025 || it.y > h * .975 }
    private fun distance(a: Point, b: Point) = hypot(a.x - b.x, a.y - b.y)
    private fun polygonArea(p: Array<Point>): Double = abs(p.indices.sumOf { i -> p[i].x * p[(i + 1) % p.size].y - p[(i + 1) % p.size].x * p[i].y }) / 2.0
}
