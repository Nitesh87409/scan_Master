package com.scanner.poc.ui

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.util.Log
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import kotlin.math.roundToInt

class TfliteDocumentScanner(context: Context) {

    private val interpreter: Interpreter
    private val inputWidth: Int
    private val inputHeight: Int
    private val predictionCount: Int
    
    private val inputBuffer: ByteBuffer
    private val outputBuffer: ByteBuffer

    init {
        val modelBuffer = loadModelBuffer(context, "document_corners_float16.tflite")
        interpreter = Interpreter(modelBuffer, Interpreter.Options().apply { setNumThreads(4) })
        interpreter.allocateTensors()
        
        val inputShape = interpreter.getInputTensor(0).shape()
        // Input shape is [1, height, width, 3] for NHWC
        inputHeight = inputShape[1]
        inputWidth = inputShape[2]
        
        val outputShape = interpreter.getOutputTensor(0).shape()
        // Output shape for YOLO pose is [1, channels, predictionCount]
        predictionCount = outputShape[2]
        Log.i("TfliteDocumentScanner", "inputType=${interpreter.getInputTensor(0).dataType()} outputType=${interpreter.getOutputTensor(0).dataType()} outputShape=${outputShape.contentToString()}")
        
        inputBuffer = ByteBuffer.allocateDirect(inputWidth * inputHeight * 3 * 4).order(ByteOrder.nativeOrder())
        outputBuffer = ByteBuffer.allocateDirect(interpreter.getOutputTensor(0).numBytes()).order(ByteOrder.nativeOrder())
        
        Log.i("TfliteDocumentScanner", "Initialized float16 model: Input $inputWidth x $inputHeight, Predictions $predictionCount")
    }

    fun detectCorners(bitmap: Bitmap, tryRotations: Boolean = false): FloatArray? {
        var bestResult: FloatArray? = null
        var bestOverallConfidence = Float.NEGATIVE_INFINITY
        
        val rotations = if (tryRotations) intArrayOf(0, 90, 180, 270) else intArrayOf(0)
        
        for (rotation in rotations) {
            val rotatedBitmap = if (rotation == 0) {
                bitmap
            } else {
                val matrix = android.graphics.Matrix().apply { postRotate(rotation.toFloat()) }
                Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            }
            
            val originalWidth = rotatedBitmap.width
            val originalHeight = rotatedBitmap.height

            val scale = minOf(inputWidth / originalWidth.toFloat(), inputHeight / originalHeight.toFloat())
            val scaledWidth = (originalWidth * scale).roundToInt().coerceAtLeast(1)
            val scaledHeight = (originalHeight * scale).roundToInt().coerceAtLeast(1)
            
            val padX = (inputWidth - scaledWidth) / 2f
            val padY = (inputHeight - scaledHeight) / 2f

            val scaledBitmap = Bitmap.createScaledBitmap(rotatedBitmap, scaledWidth, scaledHeight, true)
            val canvasBitmap = Bitmap.createBitmap(inputWidth, inputHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(canvasBitmap)
            canvas.drawColor(Color.rgb(114, 114, 114)) // Letterbox color
            canvas.drawBitmap(scaledBitmap, padX, padY, null)

            val pixels = IntArray(inputWidth * inputHeight)
            canvasBitmap.getPixels(pixels, 0, inputWidth, 0, 0, inputWidth, inputHeight)

            inputBuffer.rewind()
            pixels.forEach { pixel ->
                inputBuffer.putFloat(Color.red(pixel) / 255f)
                inputBuffer.putFloat(Color.green(pixel) / 255f)
                inputBuffer.putFloat(Color.blue(pixel) / 255f)
            }

            outputBuffer.rewind()
            interpreter.run(inputBuffer, outputBuffer)
            
            outputBuffer.rewind()
            val values = FloatArray(17 * predictionCount)
            outputBuffer.asFloatBuffer().get(values)
            
            val CLASS_CHANNEL = 4
            val KEYPOINT_START_CHANNEL = 5

            var bestIndex = 0
            var bestConfidence = Float.NEGATIVE_INFINITY
            
            for (anchorIndex in 0 until predictionCount) {
                val confidence = values[(CLASS_CHANNEL * predictionCount) + anchorIndex]
                if (confidence > bestConfidence) {
                    bestConfidence = confidence
                    bestIndex = anchorIndex
                }
            }
            
            if (rotatedBitmap !== bitmap) rotatedBitmap.recycle()
            if (scaledBitmap !== rotatedBitmap) scaledBitmap.recycle()
            canvasBitmap.recycle()

            if (bestConfidence > bestOverallConfidence) {
                bestOverallConfidence = bestConfidence
                
                fun decodeKeypoint(startChannel: Int): FloatArray {
                    val normalizedX = values[(startChannel * predictionCount) + bestIndex]
                    val normalizedY = values[((startChannel + 1) * predictionCount) + bestIndex]
                    
                    val letterboxedX = normalizedX * inputWidth
                    val letterboxedY = normalizedY * inputHeight
                    
                    val unpaddedX = ((letterboxedX - padX) / scale).coerceIn(0f, originalWidth.toFloat())
                    val unpaddedY = ((letterboxedY - padY) / scale).coerceIn(0f, originalHeight.toFloat())
                    
                    return floatArrayOf(unpaddedX, unpaddedY)
                }

                val tl = decodeKeypoint(KEYPOINT_START_CHANNEL + 0)
                val tr = decodeKeypoint(KEYPOINT_START_CHANNEL + 3)
                val br = decodeKeypoint(KEYPOINT_START_CHANNEL + 6)
                val bl = decodeKeypoint(KEYPOINT_START_CHANNEL + 9)
                
                val currentCorners = floatArrayOf(tl[0], tl[1], tr[0], tr[1], br[0], br[1], bl[0], bl[1])
                
                // Un-rotate the coordinates back to the original bitmap space
                val unrotatedCorners = if (rotation == 0) {
                    currentCorners
                } else {
                    val matrix = android.graphics.Matrix().apply { postRotate(-rotation.toFloat(), bitmap.width / 2f, bitmap.height / 2f) }
                    // Actually, if we rotated the image around its center? No, createBitmap rotates and translates.
                    // The easiest way to unrotate points is to map them through the INVERSE of the matrix used to rotate the bitmap.
                    val forwardMatrix = android.graphics.Matrix().apply {
                        postRotate(rotation.toFloat())
                        // We need to account for the translation that createBitmap does to keep coordinates positive.
                        val srcRect = android.graphics.RectF(0f, 0f, bitmap.width.toFloat(), bitmap.height.toFloat())
                        val dstRect = android.graphics.RectF()
                        mapRect(dstRect, srcRect)
                        postTranslate(-dstRect.left, -dstRect.top)
                    }
                    val inverseMatrix = android.graphics.Matrix()
                    forwardMatrix.invert(inverseMatrix)
                    
                    val mapped = FloatArray(8)
                    inverseMatrix.mapPoints(mapped, currentCorners)
                    mapped
                }
                
                bestResult = unrotatedCorners
            }
        }

        if (bestOverallConfidence < 0.25f) {
            Log.d("TfliteDocumentScanner", "Low confidence even after rotations: $bestOverallConfidence")
            // Return null so it falls back to the full-screen default instead of a mangled default box
            return null
        }

        return bestResult
    }

    private fun loadModelBuffer(context: Context, assetPath: String): ByteBuffer {
        val descriptor = context.assets.openFd(assetPath)
        return FileInputStream(descriptor.fileDescriptor).channel.use { channel ->
            channel.map(FileChannel.MapMode.READ_ONLY, descriptor.startOffset, descriptor.declaredLength)
        }
    }
}
