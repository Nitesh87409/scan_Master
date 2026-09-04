package com.scanner.poc

import android.content.Context
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.*
import androidx.lifecycle.viewmodel.compose.viewModel
import com.scanner.poc.model.IdCardStep
import com.scanner.poc.model.ScanMode
import com.scanner.poc.ui.*
import com.scanner.poc.ui.theme.NativeScannerTheme
import com.scanner.poc.util.PdfSaver
import com.scanner.poc.viewmodel.ScanViewModel

/**
 * MainActivity — Full Navigation (Phases 1–5)
 *
 * Navigation flow:
 *
 * DOCUMENT mode:
 *   CameraScreen → CropScreen → ReviewScreen → Save PDF
 *
 * ID CARD mode:
 *   CameraScreen [FRONT] → CropScreen → CameraScreen [BACK] → CropScreen → IdCardPreviewScreen → Save PDF
 */
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            NativeScannerTheme {
                val viewModel: ScanViewModel = viewModel()
                val currentMode by viewModel.currentMode.collectAsState()
                val capturedBitmap by viewModel.capturedBitmap.collectAsState()
                val croppedBitmap by viewModel.croppedBitmap.collectAsState()
                val frontBitmap by viewModel.frontBitmap.collectAsState()
                val backBitmap by viewModel.backBitmap.collectAsState()
                val idCardStep by viewModel.idCardStep.collectAsState()
                val liveCorners by viewModel.liveCorners.collectAsState()
                val liveImageSize by viewModel.liveImageSize.collectAsState()

                when {
                    // ── ID Card: Both sides done → Show merged preview ─────
                    currentMode == ScanMode.ID_CARD && idCardStep == IdCardStep.DONE
                            && frontBitmap != null && backBitmap != null -> {
                        IdCardPreviewScreen(
                            frontBitmap = frontBitmap!!,
                            backBitmap = backBitmap!!,
                            onSave = { mergedBitmap ->
                                val path = PdfSaver.saveBitmapAsPdf(
                                    this, mergedBitmap,
                                    "id_card_${System.currentTimeMillis()}"
                                )
                                Toast.makeText(this, "Saved: $path", Toast.LENGTH_LONG).show()
                                viewModel.resetIdCard()
                                viewModel.clearCapturedBitmap()
                                viewModel.clearCroppedBitmap()
                            },
                            onRetake = {
                                viewModel.resetIdCard()
                                viewModel.clearCapturedBitmap()
                                viewModel.clearCroppedBitmap()
                            }
                        )
                    }

                    // ── Crop Screen (after any photo is taken) ────────────
                    capturedBitmap != null && croppedBitmap == null -> {
                        CropScreen(
                            bitmap = capturedBitmap!!,
                            liveCorners = liveCorners,
                            liveImageSize = liveImageSize,
                            mode = currentMode,
                            onDone = { warped ->
                                if (currentMode == ScanMode.ID_CARD) {
                                    // ID Card mode: route cropped image to front or back
                                    if (idCardStep == IdCardStep.FRONT) {
                                        viewModel.setFrontBitmap(warped)
                                        // Clear capturedBitmap → go back to camera for BACK
                                        viewModel.clearCapturedBitmap()
                                    } else {
                                        viewModel.setBackBitmap(warped)
                                        viewModel.clearCapturedBitmap()
                                    }
                                } else {
                                    // Document mode: go to ReviewScreen
                                    viewModel.setCroppedBitmap(warped)
                                }
                            },
                            onRetake = {
                                viewModel.clearCapturedBitmap()
                            }
                        )
                    }

                    // ── Review Screen (Document mode only) ────────────────
                    croppedBitmap != null && currentMode == ScanMode.DOCUMENT -> {
                        ReviewScreen(
                            bitmap = croppedBitmap!!,
                            onRetake = {
                                viewModel.clearCapturedBitmap()
                                viewModel.clearCroppedBitmap()
                            },
                            onSave = { finalBitmap ->
                                val path = PdfSaver.saveBitmapAsPdf(
                                    this, finalBitmap,
                                    "scan_${System.currentTimeMillis()}"
                                )
                                Toast.makeText(this, "Saved: $path", Toast.LENGTH_LONG).show()
                                viewModel.clearCapturedBitmap()
                                viewModel.clearCroppedBitmap()
                            }
                        )
                    }

                    else -> {
                        CameraScreen(
                            onPhotoTaken = { bitmap ->
                                viewModel.setCapturedBitmap(bitmap)
                            },
                            idCardStep = idCardStep,
                            viewModel = viewModel
                        )
                    }
                }
            }
        }
    }
}
