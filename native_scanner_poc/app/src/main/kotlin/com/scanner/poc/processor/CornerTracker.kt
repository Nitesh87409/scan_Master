package com.scanner.poc.processor

import com.scanner.poc.model.DetectionState
import com.scanner.poc.model.DetectionStatus
import kotlin.math.hypot
import kotlin.math.max

/** Temporal filter used by the preview and capture pipeline. */
class CornerTracker {
    private var previous: FloatArray? = null
    private var confidence = 0f
    private var stableFrames = 0
    private var missedFrames = 0

    @Synchronized
    fun update(detection: DocumentDetection?, width: Int, height: Int): DetectionState {
        val diagonal = hypot(width.toDouble(), height.toDouble()).toFloat().coerceAtLeast(1f)
        if (detection == null) {
            missedFrames++
            // CameraX occasionally delivers a dark/blurred frame while exposure
            // and focus settle. Keep the last trustworthy quad through that short
            // gap instead of making the outline disappear and reappear.
            if (missedFrames > 18) {
                previous = null
                stableFrames = 0
                confidence = 0f
            } else confidence *= 0.96f
            return state(width, height)
        }
        missedFrames = 0
        val candidate = normalize(detection.corners, width, height)
        val old = previous
        val movement = old?.let { averageDistance(it, candidate) } ?: diagonal
        val jumpLimit = diagonal * 0.38f
        if (old != null && movement > jumpLimit && detection.confidence < 0.72f) {
            confidence *= 0.94f
            stableFrames = (stableFrames - 1).coerceAtLeast(0)
            return state(width, height)
        }
        // OpenCV can briefly return a second quad from a fold/shadow around the
        // page. Do not let that lower-confidence candidate replace a reliable
        // track when it also moves several percent of the frame in one frame.
        if (old != null && movement > diagonal * 0.012f && detection.confidence + 0.020f < confidence) {
            confidence *= 0.985f
            stableFrames = (stableFrames - 1).coerceAtLeast(0)
            return state(width, height)
        }
        val alpha = when {
            old == null -> 1f
            movement < diagonal * 0.012f -> 0.18f
            movement < diagonal * 0.05f -> 0.28f
            else -> 0.48f
        }
        val filtered = if (old == null) candidate else FloatArray(8) { i -> old[i] * (1f - alpha) + candidate[i] * alpha }
        if (old != null && movement < max(4f, diagonal * 0.012f)) stableFrames++ else stableFrames = (stableFrames - 1).coerceAtLeast(0)
        previous = filtered
        confidence = confidence * 0.65f + detection.confidence * 0.35f
        return state(width, height)
    }

    @Synchronized fun reset() { previous = null; confidence = 0f; stableFrames = 0; missedFrames = 0 }

    private fun state(width: Int, height: Int): DetectionState {
        val c = previous
        val inside = c?.let { cornersInside(it, width, height) } == true
        val ready = c != null && confidence >= 0.43f && stableFrames >= 5 && inside
        val status = when { ready -> DetectionStatus.READY; c == null -> DetectionStatus.SEARCHING; else -> DetectionStatus.HOLD_STEADY }
        return DetectionState(c?.copyOf(), confidence, stableFrames, ready, status)
    }

    private fun cornersInside(c: FloatArray, width: Int, height: Int): Boolean {
        val mx = width * 0.025f; val my = height * 0.025f
        for (i in 0 until 4) if (c[i * 2] !in mx..(width - mx) || c[i * 2 + 1] !in my..(height - my)) return false
        return true
    }

    private fun normalize(c: FloatArray, width: Int, height: Int): FloatArray = FloatArray(8) { i ->
        if (i % 2 == 0) c[i].coerceIn(0f, width.toFloat()) else c[i].coerceIn(0f, height.toFloat())
    }

    private fun averageDistance(a: FloatArray, b: FloatArray): Float {
        var total = 0f
        for (i in 0 until 4) total += hypot((a[i * 2] - b[i * 2]).toDouble(), (a[i * 2 + 1] - b[i * 2 + 1]).toDouble()).toFloat()
        return total / 4f
    }
}
