package com.scanner.poc.viewmodel

import android.graphics.Bitmap
import androidx.lifecycle.ViewModel
import com.scanner.poc.model.IdCardStep
import com.scanner.poc.model.ScanMode
import com.scanner.poc.model.DetectionState
import com.scanner.poc.processor.CornerTracker
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * ScanViewModel: Single source of truth for all scanning state.
 *
 * Phase 1: currentMode, isFlashOn, capturedBitmap
 * Phase 3: croppedBitmap
 * Phase 5: frontBitmap, backBitmap, idCardStep
 */
class ScanViewModel : ViewModel() {

    private val cornerTracker = CornerTracker()

    private val _currentMode = MutableStateFlow(ScanMode.DOCUMENT)
    val currentMode: StateFlow<ScanMode> = _currentMode.asStateFlow()

    private val _isFlashOn = MutableStateFlow(false)
    val isFlashOn: StateFlow<Boolean> = _isFlashOn.asStateFlow()

    // Live AR Overlay Corners (Phase 3 Real-time)
    private val _liveCorners = MutableStateFlow<FloatArray?>(null)
    val liveCorners: StateFlow<FloatArray?> = _liveCorners.asStateFlow()

    private val _liveImageSize = MutableStateFlow(androidx.compose.ui.unit.IntSize.Zero)
    val liveImageSize: StateFlow<androidx.compose.ui.unit.IntSize> = _liveImageSize.asStateFlow()

    private val _detectionState = MutableStateFlow(DetectionState())
    val detectionState: StateFlow<DetectionState> = _detectionState.asStateFlow()

    // Raw captured bitmap (before crop)
    private val _capturedBitmap = MutableStateFlow<Bitmap?>(null)
    val capturedBitmap: StateFlow<Bitmap?> = _capturedBitmap.asStateFlow()

    // Cropped & straightened bitmap (after perspective transform)
    private val _croppedBitmap = MutableStateFlow<Bitmap?>(null)
    val croppedBitmap: StateFlow<Bitmap?> = _croppedBitmap.asStateFlow()

    // Phase 5: ID Card bitmaps
    private val _frontBitmap = MutableStateFlow<Bitmap?>(null)
    val frontBitmap: StateFlow<Bitmap?> = _frontBitmap.asStateFlow()

    private val _backBitmap = MutableStateFlow<Bitmap?>(null)
    val backBitmap: StateFlow<Bitmap?> = _backBitmap.asStateFlow()

    // Which side of ID card are we scanning?
    private val _idCardStep = MutableStateFlow(IdCardStep.FRONT)
    val idCardStep: StateFlow<IdCardStep> = _idCardStep.asStateFlow()

    fun setMode(mode: ScanMode) {
        if (_currentMode.value != mode) {
            _currentMode.value = mode
            cornerTracker.reset()
            _detectionState.value = DetectionState()
            _liveCorners.value = null
        }
    }
    fun toggleFlash() { _isFlashOn.value = !_isFlashOn.value }

    fun updateLiveCorners(corners: FloatArray?) { _liveCorners.value = corners }
    fun updateLiveImageSize(size: androidx.compose.ui.unit.IntSize) { _liveImageSize.value = size }

    fun updateDetection(corners: FloatArray?, confidence: Float, width: Int, height: Int) {
        val detection = corners?.let { com.scanner.poc.processor.DocumentDetection(it, confidence, 0f) }
        val state = cornerTracker.update(detection, width, height)
        _detectionState.value = state
        _liveCorners.value = state.corners
        _liveImageSize.value = androidx.compose.ui.unit.IntSize(width, height)
    }

    fun resetDetection() {
        cornerTracker.reset()
        _detectionState.value = DetectionState()
        _liveCorners.value = null
    }

    fun setCapturedBitmap(bitmap: Bitmap) { _capturedBitmap.value = bitmap }
    fun clearCapturedBitmap() { _capturedBitmap.value = null }

    fun setCroppedBitmap(bitmap: Bitmap) { _croppedBitmap.value = bitmap }
    fun clearCroppedBitmap() { _croppedBitmap.value = null }

    fun setFrontBitmap(bitmap: Bitmap) {
        _frontBitmap.value = bitmap
        _idCardStep.value = IdCardStep.BACK  // Automatically move to BACK step
    }

    fun setBackBitmap(bitmap: Bitmap) {
        _backBitmap.value = bitmap
        _idCardStep.value = IdCardStep.DONE
    }

    fun resetIdCard() {
        _frontBitmap.value = null
        _backBitmap.value = null
        _idCardStep.value = IdCardStep.FRONT
    }
}
