package com.scanner.poc.ui

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Matrix
import android.util.Log
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.compose.CameraXViewfinder
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.core.AspectRatio
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceRequest
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import com.scanner.poc.model.DetectionStatus
import com.scanner.poc.model.IdCardStep
import com.scanner.poc.model.ScanMode
import com.scanner.poc.processor.DocumentDetector
import com.scanner.poc.viewmodel.ScanViewModel
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
import android.graphics.BitmapFactory
import android.media.ExifInterface
import android.hardware.camera2.CaptureRequest
import androidx.camera.camera2.interop.Camera2Interop
import java.io.File

@Composable
fun CameraScreen(
    onPhotoTaken: (Bitmap) -> Unit,
    idCardStep: IdCardStep = IdCardStep.FRONT,
    viewModel: ScanViewModel
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val mode by viewModel.currentMode.collectAsState()
    val flashOn by viewModel.isFlashOn.collectAsState()
    val detection by viewModel.detectionState.collectAsState()
    var hasPermission by remember { mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) }
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { hasPermission = it }
    var surfaceRequest by remember { mutableStateOf<SurfaceRequest?>(null) }
    var camera by remember { mutableStateOf<Camera?>(null) }
    var canvasSize by remember { mutableStateOf(IntSize.Zero) }
    val executor = remember { Executors.newSingleThreadExecutor() }
    val detector = remember { DocumentDetector(context) }
    val diagnosticFrames = remember { AtomicInteger() }
    val imageCapture = remember {
        val builder = ImageCapture.Builder().setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
        // Keep the rear camera in continuous-picture AF so focus follows the
        // document while the phone is moved instead of locking on the background.
        Camera2Interop.Extender(builder).setCaptureRequestOption(
            CaptureRequest.CONTROL_AF_MODE,
            CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
        )
        builder.build()
    }
    val imageAnalysis = remember {
        // Keep analysis and Preview on the same 4:3 crop. The device otherwise
        // selects a 720x720 analysis stream, which shifts/scales corners on screen.
        ImageAnalysis.Builder().setTargetAspectRatio(AspectRatio.RATIO_4_3)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
    }
    LaunchedEffect(Unit) { if (!hasPermission) permissionLauncher.launch(Manifest.permission.CAMERA) }
    LaunchedEffect(hasPermission, lifecycleOwner, mode) {
        if (!hasPermission) return@LaunchedEffect
        try {
            viewModel.resetDetection()
            val provider = ProcessCameraProvider.getInstance(context).get()
            val preview = Preview.Builder().build().also { p -> p.setSurfaceProvider { request -> surfaceRequest = request } }
            imageAnalysis.setAnalyzer(executor) { proxy ->
                var rotated: Bitmap? = null
                try {
                    val source = proxy.toBitmap()
                    val degrees = proxy.imageInfo.rotationDegrees
                    rotated = if (degrees == 0) source else Bitmap.createBitmap(source, 0, 0, source.width, source.height, Matrix().apply { postRotate(degrees.toFloat()) }, true)
                    if (rotated !== source) source.recycle()
                    val found = detector.detect(rotated!!, mode)
                    viewModel.updateDetection(found?.corners, found?.confidence ?: 0f, rotated!!.width, rotated!!.height)
                    val frameNo = diagnosticFrames.incrementAndGet()
                    if (frameNo % 15 == 0) Log.d("ScannerDiag", "frame=$frameNo mode=$mode size=${rotated!!.width}x${rotated!!.height} found=${found != null} confidence=${found?.confidence ?: 0f} area=${found?.areaRatio ?: 0f} corners=${found?.corners?.joinToString(",") ?: "none"}")
                } catch (t: Throwable) { Log.w(TAG, "Frame analysis failed: ${t.message}") }
                finally { rotated?.recycle(); proxy.close() }
            }
            provider.unbindAll()
            camera = provider.bindToLifecycle(lifecycleOwner, CameraSelector.DEFAULT_BACK_CAMERA, preview, imageCapture, imageAnalysis)
        } catch (t: Throwable) { Log.e(TAG, "Camera binding failed", t) }
    }
    LaunchedEffect(camera, flashOn) { camera?.cameraControl?.enableTorch(flashOn) }
    DisposableEffect(Unit) { onDispose { imageAnalysis.clearAnalyzer(); executor.shutdown() } }

    Box(Modifier.fillMaxSize().background(Color.Black)) {
        surfaceRequest?.let { CameraXViewfinder(surfaceRequest = it, modifier = Modifier.fillMaxSize()) }
        Canvas(Modifier.fillMaxSize().onSizeChanged { canvasSize = it }) {
            val c = detection.corners
            val imageSize = viewModel.liveImageSize.value
            if (mode == ScanMode.ID_CARD) {
                val guideWidth = minOf(size.width * .86f, size.height * .44f)
                val guideHeight = guideWidth / 1.585f
                val left = (size.width - guideWidth) / 2f
                val top = (size.height - guideHeight) / 2f
                drawRoundRect(color = Color.White.copy(alpha = if (c == null) .72f else .22f), topLeft = Offset(left, top), size = androidx.compose.ui.geometry.Size(guideWidth, guideHeight), cornerRadius = CornerRadius(14.dp.toPx()), style = Stroke(width = 2.dp.toPx()))
            }
            if (c != null && imageSize.width > 0 && canvasSize.width > 0) {
                val scale = maxOf(size.width / imageSize.width, size.height / imageSize.height)
                val ox = (size.width - imageSize.width * scale) / 2f
                val oy = (size.height - imageSize.height * scale) / 2f
                fun point(i: Int) = Offset(c[i * 2] * scale + ox, c[i * 2 + 1] * scale + oy)
                val points = (0..3).map(::point)
                val path = Path().apply { moveTo(points[0].x, points[0].y); points.drop(1).forEach { lineTo(it.x, it.y) }; close() }
                val readyColor = if (detection.ready) Color(0xFF39E58C) else Color(0xFF00D4FF)
                drawPath(path, readyColor.copy(alpha = .95f), style = Stroke(width = 4.dp.toPx()))
                points.forEach { drawCircle(readyColor, 11.dp.toPx(), it); drawCircle(Color.White, 4.dp.toPx(), it) }
                // CamScanner-style eight visible control points: the four real
                // projective corners plus one midpoint on every edge.  Midpoints
                // are visual affordances only; perspective warping still uses
                // the mathematically required four corners.
                if (mode == ScanMode.DOCUMENT) {
                    points.indices.forEach { i ->
                        val a = points[i]; val b = points[(i + 1) % points.size]
                        val mid = Offset((a.x + b.x) * .5f, (a.y + b.y) * .5f)
                        drawCircle(readyColor, 6.dp.toPx(), mid)
                        drawCircle(Color.White, 2.5.dp.toPx(), mid)
                    }
                }
            }
        }
        if (!hasPermission) Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { Text("Camera permission is required", color = Color.White) }
        Row(Modifier.fillMaxWidth().padding(16.dp).align(Alignment.TopCenter), horizontalArrangement = Arrangement.SpaceBetween) {
            StatusPill(when (detection.status) { DetectionStatus.READY -> "✓ Ready to scan"; DetectionStatus.HOLD_STEADY -> "Hold steady"; else -> if (mode == ScanMode.ID_CARD) "Find card" else "Find document" }, if (detection.ready) Color(0xFF39E58C) else Color.White)
            IconButton(onClick = { viewModel.toggleFlash() }) { Text(if (flashOn) "⚡" else "♢", color = if (flashOn) Color(0xFFFFC107) else Color.White, fontSize = 25.sp) }
        }
        if (mode == ScanMode.ID_CARD) {
            Column(Modifier.align(Alignment.TopCenter).padding(top = 72.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(if (idCardStep == IdCardStep.FRONT) "Front side" else "Back side", color = Color.White, fontWeight = FontWeight.Bold)
                Text("Fit the whole card inside the outline", color = Color.LightGray, fontSize = 12.sp)
            }
        }
        Column(Modifier.fillMaxWidth().align(Alignment.BottomCenter).background(Color(0xE6000000)).padding(top = 14.dp, bottom = 22.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(15.dp)) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ModeTab("Document", mode == ScanMode.DOCUMENT) { viewModel.setMode(ScanMode.DOCUMENT) }
                ModeTab("ID Card", mode == ScanMode.ID_CARD) { viewModel.setMode(ScanMode.ID_CARD) }
            }
            Box(Modifier.size(76.dp).background(Color.White, CircleShape).border(4.dp, if (detection.ready) Color(0xFF39E58C) else Color(0xFF00BCD4), CircleShape).clickable {
                captureSampledJpeg(imageCapture, context, onPhotoTaken)
            }, contentAlignment = Alignment.Center) { Box(Modifier.size(60.dp).background(Color.White, CircleShape)) }
        }
    }
}

@Composable private fun StatusPill(text: String, color: Color) { Text(text, color = color, fontWeight = FontWeight.SemiBold, modifier = Modifier.background(Color(0xB8000000), RoundedCornerShape(18.dp)).padding(horizontal = 14.dp, vertical = 8.dp)) }
@Composable private fun ModeTab(label: String, selected: Boolean, onClick: () -> Unit) { Text(label, color = if (selected) Color.Black else Color.White, fontWeight = if (selected) FontWeight.Bold else FontWeight.Normal, modifier = Modifier.background(if (selected) Color(0xFF00D4FF) else Color(0x40FFFFFF), RoundedCornerShape(20.dp)).clickable(onClick = onClick).padding(horizontal = 24.dp, vertical = 9.dp)) }

private fun imageProxyToBitmap(image: ImageProxy): Bitmap {
    val buffer = image.planes[0].buffer
    val bytes = ByteArray(buffer.remaining()); buffer.get(bytes)
    val raw = android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return image.toBitmap()
    val degrees = image.imageInfo.rotationDegrees
    if (degrees == 0) return raw
    val rotated = Bitmap.createBitmap(raw, 0, 0, raw.width, raw.height, Matrix().apply { postRotate(degrees.toFloat()) }, true)
    raw.recycle(); return rotated
}

private fun captureSampledJpeg(
    imageCapture: ImageCapture,
    context: android.content.Context,
    onPhotoTaken: (Bitmap) -> Unit
) {
    val file = runCatching { File.createTempFile("scan_capture_", ".jpg", context.cacheDir) }.getOrNull()
    if (file == null) {
        Log.e(TAG, "Unable to create capture file")
        return
    }
    val options = ImageCapture.OutputFileOptions.Builder(file).build()
    // Use a capture-scoped executor. The analyzer executor is torn down when the
    // camera screen is recreated (retake/mode switch); reusing it here caused
    // CameraX callbacks to hit a terminated pool and crash with
    // RejectedExecutionException.
    val captureExecutor = Executors.newSingleThreadExecutor()
    imageCapture.takePicture(options, captureExecutor, object : ImageCapture.OnImageSavedCallback {
        override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
            try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(file.absolutePath, bounds)
                val longest = maxOf(bounds.outWidth, bounds.outHeight).coerceAtLeast(1)
                var sample = 1
                while (longest / sample > 2400) sample *= 2
                val decoded = BitmapFactory.decodeFile(file.absolutePath, BitmapFactory.Options().apply { inSampleSize = sample; inPreferredConfig = Bitmap.Config.ARGB_8888 })
                if (decoded != null) onPhotoTaken(applyExifOrientation(decoded, ExifInterface(file.absolutePath).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL))) else Log.e(TAG, "Capture decode returned null")
            } catch (t: Throwable) { Log.e(TAG, "Capture decode failed", t) }
            finally { file.delete(); captureExecutor.shutdown() }
        }
        override fun onError(exception: ImageCaptureException) { file.delete(); captureExecutor.shutdown(); Log.e(TAG, "Capture failed", exception) }
    })
}

private fun applyExifOrientation(bitmap: Bitmap, orientation: Int): Bitmap {
    val matrix = Matrix()
    when (orientation) {
        ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.setScale(-1f, 1f)
        ExifInterface.ORIENTATION_ROTATE_180 -> matrix.setRotate(180f)
        ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.setScale(1f, -1f)
        ExifInterface.ORIENTATION_TRANSPOSE -> { matrix.setRotate(90f); matrix.postScale(-1f, 1f) }
        ExifInterface.ORIENTATION_ROTATE_90 -> matrix.setRotate(90f)
        ExifInterface.ORIENTATION_TRANSVERSE -> { matrix.setRotate(-90f); matrix.postScale(-1f, 1f) }
        ExifInterface.ORIENTATION_ROTATE_270 -> matrix.setRotate(-90f)
        else -> return bitmap
    }
    val corrected = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    if (corrected !== bitmap) bitmap.recycle()
    return corrected
}
private const val TAG = "CameraScreen"
