package com.scanner.poc.model

/** Snapshot of the on-device detector used by the camera UI. */
data class DetectionState(
    val corners: FloatArray? = null,
    val confidence: Float = 0f,
    val stableFrames: Int = 0,
    val ready: Boolean = false,
    val status: DetectionStatus = DetectionStatus.SEARCHING
) {
    override fun equals(other: Any?): Boolean = other is DetectionState &&
        confidence == other.confidence && stableFrames == other.stableFrames &&
        ready == other.ready && status == other.status && corners.contentEquals(other.corners)

    override fun hashCode(): Int = 31 * (corners?.contentHashCode() ?: 0) +
        31 * confidence.hashCode() + stableFrames + ready.hashCode() + status.hashCode()
}

enum class DetectionStatus { SEARCHING, HOLD_STEADY, READY }
