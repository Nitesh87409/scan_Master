package com.scanner.poc.processor

import android.graphics.Bitmap
import android.content.Context
import android.util.Log
import com.scanner.poc.model.ScanMode
import com.scanner.poc.ui.TfliteDocumentScanner
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

data class DocumentDetection(val corners: FloatArray, val confidence: Float, val areaRatio: Float)

/** On-device detector tuned for light paper/cards on cluttered backgrounds. */
class DocumentDetector {
    private val openCv = OpenCvDocumentDetector()
    /**
     * The project already ships a four-corner TFLite model.  It is sampled at a
     * lower cadence and used as a semantic prior; OpenCV remains the fast
     * frame-by-frame tracker/fallback.  Keeping this optional also preserves
     * camera startup on devices where the model cannot be loaded.
     */
    private val neural: TfliteDocumentScanner?
    private var neuralCalls = 0
    private var lastNeural: DocumentDetection? = null
    private var neuralMisses = 0
    private var diagnosticCalls = 0

    constructor(context: Context? = null) {
        neural = context?.let { runCatching { TfliteDocumentScanner(it) }
            .onFailure { Log.w("ScannerDiag", "Corner model unavailable: ${it.message}") }
            .getOrNull() }
        Log.i("ScannerDiag", "Document corner model enabled=${neural != null}")
    }

    fun detect(source: Bitmap, mode: ScanMode): DocumentDetection? {
        if (source.width < 80 || source.height < 80) return null
        // The model is trained for documents, so do not let it alter the ID-card
        // path.  Running every sixth frame keeps latency low while adding a
        // semantic candidate when the paper edge is faint or partly shadowed.
        val model = neural
        var neuralCandidate: DocumentDetection? = null
        if (mode == ScanMode.DOCUMENT && model != null && neuralCalls++ % 6 == 0) {
            // A page can be presented at any in-plane angle. Try the cheap
            // native orientation first, then let the model evaluate the four
            // rotated views only when that pass is uncertain.
            val raw = runCatching { model.detectCorners(source) }.getOrNull()
                ?: runCatching { model.detectCorners(source, tryRotations = true) }.getOrNull()
            if (raw == null) Log.d("ScannerDiag", "neural document raw=null")
            val ml = raw?.let { validateNeural(it, source) }
            if (raw != null && ml == null) Log.d("ScannerDiag", "neural document rejected raw=${raw.joinToString(",")}")
            if (ml != null) Log.d("ScannerDiag", "neural document candidate area=${ml.areaRatio} conf=${ml.confidence} corners=${ml.corners.joinToString(",")}")
            neuralCandidate = ml?.takeIf { it.confidence >= .55f }
            if (neuralCandidate != null) {
                lastNeural = neuralCandidate
                neuralMisses = 0
            } else {
                neuralMisses++
                if (neuralMisses >= 8) lastNeural = null
            }
        }
        // Native contour/colour segmentation is the primary detector. The older
        // Kotlin implementation remains as a safe fallback for devices where the
        // OpenCV shared library cannot be loaded.
        val native = openCv.detect(source, mode)
        // Once the semantic document model is available, never promote an
        // unrelated OpenCV carpet/background rectangle while the model is
        // temporarily uncertain. This is what previously produced the large
        // green diamond and a false Ready state on close-up/tilted views.
        if (mode == ScanMode.DOCUMENT && neural != null && neuralCandidate == null) {
            if (lastNeural != null) return lastNeural
            return null
        }
        if (native != null) {
            val cv = native
            if (diagnosticCalls++ % 3 == 0) Log.d("ScannerDiag", "opencv result area=${cv.areaRatio} conf=${cv.confidence}")
            val ml = neuralCandidate
            val semantic = if (mode == ScanMode.DOCUMENT) (ml ?: lastNeural) else null
            if (semantic == null) return cv
            // The semantic model is the authority when it has seen the scene.
            // OpenCV may lock onto a fold/carpet rectangle between model frames;
            // only blend it when it agrees closely with the semantic prior.
            val diagonal = hypot(source.width.toFloat(), source.height.toFloat())
            val disagreement = (0 until 4).map { i ->
                hypot(semantic.corners[i * 2] - cv.corners[i * 2], semantic.corners[i * 2 + 1] - cv.corners[i * 2 + 1])
            }.average() / diagonal
            if (disagreement < .08 && ml == null) {
                val blended = FloatArray(8) { i -> semantic.corners[i] * .78f + cv.corners[i] * .22f }
                return DocumentDetection(blended, semantic.confidence, semantic.areaRatio)
            }
            return semantic
        }
        if (neuralCandidate != null) return neuralCandidate
        // 320px analysis is sufficient for stable page boundaries and keeps the
        // analyzer responsive on devices that expose a square 720px stream.
        val scale = min(1f, 320f / max(source.width, source.height).toFloat())
        val w = max(80, (source.width * scale).toInt()); val h = max(80, (source.height * scale).toInt())
        val frame = if (w != source.width || h != source.height) Bitmap.createScaledBitmap(source, w, h, true) else source
        val pixels = IntArray(w * h); frame.getPixels(pixels, 0, w, 0, 0, w, h)
        val gray = IntArray(w * h) { i ->
            val p = pixels[i]; (77 * (p shr 16 and 255) + 150 * (p shr 8 and 255) + 29 * (p and 255)) shr 8
        }
        val magnitude = IntArray(w * h); var sum = 0.0; var sumSq = 0.0; var count = 0
        for (y in 1 until h - 1) for (x in 1 until w - 1) {
            val i = y * w + x
            val sx = -gray[i - w - 1] - 2 * gray[i - 1] - gray[i + w - 1] + gray[i - w + 1] + 2 * gray[i + 1] + gray[i + w + 1]
            val sy = -gray[i - w - 1] - 2 * gray[i - w] - gray[i - w + 1] + gray[i + w - 1] + 2 * gray[i + w] + gray[i + w + 1]
            magnitude[i] = min(255, hypot(sx.toDouble(), sy.toDouble()).toInt())
            if (x > w * .04f && x < w * .96f && y > h * .04f && y < h * .96f) { sum += magnitude[i]; sumSq += magnitude[i].toDouble() * magnitude[i]; count++ }
        }
        var best: DocumentDetection? = null
        val globalBright = largestBrightComponent(gray, pixels, w, h)
        val seededBright = seededPaperComponent(gray, pixels, w, h)
        val bright = if (seededBright.size >= (w * h * .020f).toInt()) seededBright else globalBright
        diagnosticCalls++
        if (mode == ScanMode.DOCUMENT && bright.size >= (w * h * .035f).toInt()) {
            // For paper documents, a coherent bright interior is a hard prior. Do not
            // let the high edge density of cloth/cables win with a scene-wide diamond.
            val paper = fit(bright, w, h, scale, mode, magnitude, 0, true)
            if (paper != null && paper.areaRatio in .12f.. .82f && paper.confidence >= .42f) {
                if (frame !== source) frame.recycle()
                if (diagnosticCalls % 3 == 0) Log.d("ScannerDiag", "paper candidate bright=${bright.size} area=${paper.areaRatio} conf=${paper.confidence}")
                return paper
            }
        }
        val mean = sum / count.coerceAtLeast(1); val std = sqrt(max(0.0, sumSq / count.coerceAtLeast(1) - mean * mean))
        for (threshold in intArrayOf(max(28, (mean + std * .55).toInt()), max(40, (mean + std * .95).toInt()), 72).distinct()) {
            if (mode == ScanMode.DOCUMENT) break
            val points = ArrayList<Float>()
            for (y in (h * .04f).toInt() until (h * .96f).toInt() step 2) for (x in (w * .04f).toInt() until (w * .96f).toInt() step 2) if (magnitude[y * w + x] >= threshold) { points.add(x.toFloat()); points.add(y.toFloat()) }
            if (points.size >= 40) best = better(best, fit(points, w, h, scale, mode, magnitude, threshold, false))
        }
        // Paper/card interiors are usually brighter and less saturated than the scene. This
        // candidate prevents patterned backgrounds from winning on edge density alone.
        if (bright.size >= (w * h * .035f).toInt()) {
            val paper = fit(bright, w, h, scale, mode, magnitude, 0, true)
            // A coherent paper/card interior is stronger evidence than a scene-wide
            // edge rectangle (the failure mode shown in the reported screenshot).
            best = if (paper != null && paper.areaRatio in .12f.. .82f && paper.confidence >= .48f) paper else better(best, paper)
        }
        if (frame !== source) frame.recycle()
        val result = best?.takeIf {
            if (mode == ScanMode.DOCUMENT) it.areaRatio in .12f.. .82f && it.confidence >= .42f
            // ID mode must never promote a bright sheet/tabletop that fills the
            // camera view. A real card is expected to occupy a bounded region;
            // this also prevents the old full-frame green rectangle/"Ready" state.
            else it.areaRatio in .04f.. .58f && it.confidence >= .40f
        }
        if (diagnosticCalls % 3 == 0) {
            var minTone = 255; var maxTone = 0; var toneSum = 0L
            gray.forEach { minTone = min(minTone, it); maxTone = max(maxTone, it); toneSum += it }
            Log.d("ScannerDiag", "fallback candidate bright=${bright.size} result=${result != null} area=${result?.areaRatio ?: 0f} conf=${result?.confidence ?: 0f} tone=${minTone}-${maxTone} mean=${toneSum / gray.size}")
        }
        return result
    }

    private fun validateNeural(corners: FloatArray, source: Bitmap): DocumentDetection? {
        val width = source.width; val height = source.height
        if (corners.size < 8) return null
        val p = refinePaperEdges(FloatArray(8) { i -> corners[i].coerceIn(0f, if (i % 2 == 0) width.toFloat() else height.toFloat()) }, source)
        // Reject malformed/scene-wide predictions before they reach the tracker.
        val area = polygonArea(p)
        val areaRatio = (area / (width.toDouble() * height.toDouble())).toFloat()
        // Keep the semantic path usable for both wide shots and close-ups. The
        // readiness gate still requires all corners to be inside the frame;
        // this bound only controls whether a candidate can be tracked.
        if (areaRatio !in .025f.. .94f) return null
        val edges = floatArrayOf(
            hypot(p[0] - p[2], p[1] - p[3]), hypot(p[2] - p[4], p[3] - p[5]),
            hypot(p[4] - p[6], p[5] - p[7]), hypot(p[6] - p[0], p[7] - p[1])
        )
        if (edges.minOrNull()!! < min(width, height) * .035f) return null
        val ratio = max(edges[0], edges[2]) / min(edges[0], edges[2]).coerceAtLeast(1f)
        val ratio2 = max(edges[1], edges[3]) / min(edges[1], edges[3]).coerceAtLeast(1f)
        if (ratio > 3.5f || ratio2 > 3.5f) return null
        val cx = (p[0] + p[2] + p[4] + p[6]) / (4f * width)
        val cy = (p[1] + p[3] + p[5] + p[7]) / (4f * height)
        val center = (1f - hypot(cx - .5f, cy - .5f) / .72f).coerceIn(0f, 1f)
        val confidence = (.62f + .18f * center + .20f * (1f - kotlin.math.abs(areaRatio - .24f) / .55f).coerceIn(0f, 1f))
        return DocumentDetection(p, confidence, areaRatio)
    }

    /** Pull a semantic quad toward the real paper edge.  A neural box can be
     * semantically correct but a little loose on a folded page; compare pixels
     * just inside/outside each edge and choose the strongest paper/background
     * transition. This runs only on the sampled model frames. */
    private fun refinePaperEdges(input: FloatArray, bitmap: Bitmap): FloatArray {
        val out = input.copyOf()
        val cx = (input[0] + input[2] + input[4] + input[6]) * .25f
        val cy = (input[1] + input[3] + input[5] + input[7]) * .25f
        val maxOffset = min(bitmap.width, bitmap.height) * .18f
        for (edge in 0 until 4) {
            val ai = edge * 2; val bi = ((edge + 1) % 4) * 2
            val ax = input[ai]; val ay = input[ai + 1]; val bx = input[bi]; val by = input[bi + 1]
            val dx = bx - ax; val dy = by - ay; val len = hypot(dx, dy).coerceAtLeast(1f)
            var nx = -dy / len; var ny = dx / len
            val mx = (ax + bx) * .5f; val my = (ay + by) * .5f
            if ((cx - mx) * nx + (cy - my) * ny < 0f) { nx = -nx; ny = -ny }
            var bestOffset = 0f; var bestScore = edgeContrast(bitmap, ax, ay, bx, by, nx, ny, 0f)
            var offset = -maxOffset
            while (offset <= maxOffset) {
                if (kotlin.math.abs(offset) < 0.5f) { offset += 4f; continue }
                val score = edgeContrast(bitmap, ax, ay, bx, by, nx, ny, offset)
                if (score > bestScore + 1.2f) { bestScore = score; bestOffset = offset }
                offset += 4f
            }
            out[ai] = (ax + nx * bestOffset).coerceIn(0f, bitmap.width.toFloat())
            out[ai + 1] = (ay + ny * bestOffset).coerceIn(0f, bitmap.height.toFloat())
            out[bi] = (bx + nx * bestOffset).coerceIn(0f, bitmap.width.toFloat())
            out[bi + 1] = (by + ny * bestOffset).coerceIn(0f, bitmap.height.toFloat())
        }
        return out
    }

    private fun edgeContrast(bitmap: Bitmap, ax: Float, ay: Float, bx: Float, by: Float, nx: Float, ny: Float, offset: Float): Float {
        var score = 0f; var count = 0
        for (s in 1..9) {
            val t = s / 10f; val x = ax + (bx - ax) * t + nx * offset; val y = ay + (by - ay) * t + ny * offset
            val inside = pixelTone(bitmap, x + nx * 5f, y + ny * 5f)
            val outside = pixelTone(bitmap, x - nx * 5f, y - ny * 5f)
            score += inside - outside
            count++
        }
        return score / count.coerceAtLeast(1)
    }

    private fun pixelTone(bitmap: Bitmap, x: Float, y: Float): Float {
        val ix = x.toInt().coerceIn(0, bitmap.width - 1); val iy = y.toInt().coerceIn(0, bitmap.height - 1)
        val p = bitmap.getPixel(ix, iy); val r = (p shr 16) and 255; val g = (p shr 8) and 255; val b = p and 255
        val gray = (0.299f * r + 0.587f * g + 0.114f * b)
        val chroma = (max(r, max(g, b)) - min(r, min(g, b))).toFloat()
        return gray - chroma * .10f
    }

    private fun fit(points: List<Float>, w: Int, h: Int, scale: Float, mode: ScanMode, magnitude: IntArray, threshold: Int, interior: Boolean): DocumentDetection? {
        var best: DocumentDetection? = null
        for (angle in 0 until 180 step 5) {
            val rad = Math.toRadians(angle.toDouble()); val ca = cos(rad); val sa = sin(rad)
            var minX = Double.MAX_VALUE; var maxX = -Double.MAX_VALUE; var minY = Double.MAX_VALUE; var maxY = -Double.MAX_VALUE
            for (i in points.indices step 2) { val x = points[i].toDouble(); val y = points[i + 1].toDouble(); val rx = x * ca + y * sa; val ry = -x * sa + y * ca; minX = min(minX, rx); maxX = max(maxX, rx); minY = min(minY, ry); maxY = max(maxY, ry) }
            val areaRatio = (((maxX - minX) * (maxY - minY)) / (w * h).toDouble()).toFloat()
            if (areaRatio !in .10f.. .94f) continue
            val width = maxX - minX; val height = maxY - minY; val ratio = max(width, height) / min(width, height)
            val ratioScore = if (mode == ScanMode.ID_CARD) 1f - min(1f, abs(ratio.toFloat() - 1.585f) / .85f) else 1f - min(1f, abs(ratio.toFloat() - 1.414f) / 1.8f)
            val support = if (interior) .82f else edgeSupport(magnitude, w, h, minX, maxX, minY, maxY, ca, sa, threshold)
            val areaScore = ((areaRatio - .10f) / .60f).coerceIn(0f, 1f)
            val confidence = .48f * support + .30f * areaScore + .18f * ratioScore
            if (best == null || confidence > best!!.confidence) {
                val c = floatArrayOf((minX * ca - minY * sa).toFloat(), (minX * sa + minY * ca).toFloat(), (maxX * ca - minY * sa).toFloat(), (maxX * sa + minY * ca).toFloat(), (maxX * ca - maxY * sa).toFloat(), (maxX * sa + maxY * ca).toFloat(), (minX * ca - maxY * sa).toFloat(), (minX * sa + maxY * ca).toFloat())
                best = DocumentDetection(if (scale < .999f) FloatArray(8) { c[it] / scale } else c, confidence, areaRatio)
            }
        }
        return best
    }

    private fun largestBrightComponent(gray: IntArray, pixels: IntArray, w: Int, h: Int): List<Float> {
        val mask = BooleanArray(w * h) { i ->
            val p = pixels[i]; val r = p shr 16 and 255; val g = p shr 8 and 255; val b = p and 255
            val chroma = max(r, max(g, b)) - min(r, min(g, b))
            gray[i] > 105 && (chroma < 120 || gray[i] > 185)
        }
        val visited = BooleanArray(w * h); var largest = emptyList<Float>(); var largestSize = 0
        val queue = IntArray(w * h)
        for (start in 0 until w * h) {
            if (!mask[start] || visited[start]) continue
            var head = 0; var tail = 0; queue[tail++] = start; visited[start] = true; val component = ArrayList<Float>(); var touchesBorder = false
            while (head < tail) {
                val i = queue[head++]; val x = i % w; val y = i / w
                if (x < w * .03f || x > w * .97f || y < h * .03f || y > h * .97f) { touchesBorder = true; continue }
                component.add(x.toFloat()); component.add(y.toFloat())
                val neighbours = intArrayOf(i - 1, i + 1, i - w, i + w)
                for (n in neighbours) if (n in 0 until w * h && !visited[n] && mask[n]) { visited[n] = true; queue[tail++] = n }
            }
            if (!touchesBorder && component.size > largestSize) { largestSize = component.size; largest = component }
        }
        return largest
    }

    /** Region-grow from the brightest low-chroma seed near the image centre. This is the
     * important paper-only fallback for pages whose shadows/text split the global mask. */
    private fun seededPaperComponent(gray: IntArray, pixels: IntArray, w: Int, h: Int): List<Float> {
        var seed = -1; var seedValue = 0
        for (y in (h * .12f).toInt() until (h * .88f).toInt() step 4) for (x in (w * .12f).toInt() until (w * .88f).toInt() step 4) {
            val i = y * w + x; val p = pixels[i]; val r = p shr 16 and 255; val g = p shr 8 and 255; val b = p and 255; val chroma = max(r, max(g, b)) - min(r, min(g, b))
            if (gray[i] > seedValue && chroma < 105) { seed = i; seedValue = gray[i] }
        }
        if (seed < 0 || seedValue < 115) return emptyList()
        val minTone = (seedValue - 110).coerceAtLeast(72); val visited = BooleanArray(w * h); val queue = IntArray(w * h); var head = 0; var tail = 0
        queue[tail++] = seed; visited[seed] = true; val result = ArrayList<Float>(); var touchesBorder = false
        while (head < tail) {
            val i = queue[head++]; val x = i % w; val y = i / w
            if (x < w * .03f || x > w * .97f || y < h * .03f || y > h * .97f) { touchesBorder = true; continue }
            result.add(x.toFloat()); result.add(y.toFloat())
            for (n in intArrayOf(i - 1, i + 1, i - w, i + w, i - w - 1, i - w + 1, i + w - 1, i + w + 1)) if (n in 0 until w * h && !visited[n]) {
                val p = pixels[n]; val r = p shr 16 and 255; val g = p shr 8 and 255; val b = p and 255; val chroma = max(r, max(g, b)) - min(r, min(g, b))
                if (gray[n] >= minTone && chroma < 150) { visited[n] = true; queue[tail++] = n }
            }
        }
        return if (!touchesBorder && result.size > w * h * .012f) result else emptyList()
    }

    private fun edgeSupport(m: IntArray, w: Int, h: Int, minX: Double, maxX: Double, minY: Double, maxY: Double, ca: Double, sa: Double, threshold: Int): Float {
        var hit = 0; var total = 0; val spanX = (maxX - minX).coerceAtLeast(1.0); val spanY = (maxY - minY).coerceAtLeast(1.0)
        for (y in 0 until h step 2) for (x in 0 until w step 2) { val rx = x * ca + y * sa; val ry = -x * sa + y * ca; val near = min(abs(rx - minX) / spanX, abs(rx - maxX) / spanX) < .025 || min(abs(ry - minY) / spanY, abs(ry - maxY) / spanY) < .025; if (near) { total++; if (m[y * w + x] >= threshold) hit++ } }
        return (hit.toFloat() / total.coerceAtLeast(1)).coerceIn(0f, 1f)
    }

    private fun better(a: DocumentDetection?, b: DocumentDetection?): DocumentDetection? = when { b == null -> a; a == null || b.confidence > a.confidence -> b; else -> a }

    private fun polygonArea(p: FloatArray): Double = abs((0 until 4).sumOf { i ->
        val x1 = p[i * 2].toDouble(); val y1 = p[i * 2 + 1].toDouble()
        val j = (i + 1) % 4; val x2 = p[j * 2].toDouble(); val y2 = p[j * 2 + 1].toDouble()
        x1 * y2 - x2 * y1
    }) / 2.0
}
