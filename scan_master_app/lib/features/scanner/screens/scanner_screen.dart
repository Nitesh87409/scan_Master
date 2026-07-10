import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scan_master_app/features/scanner/screens/filter_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Camera permission is required to scan documents.\nPlease enable it in settings.';
        });
        return;
      }

      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No camera found on this device.';
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error initializing camera:\n$e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile image = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FilterScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, color: Colors.white54, size: 64),
                SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 24),
                if (_errorMessage!.contains('permission'))
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    child: Text('Open Settings'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(child: CircularProgressIndicator(color: Colors.white)),
            Positioned(
              top: 50,
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Back Button
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Capture Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
                child: Icon(Icons.camera_alt, color: Colors.black, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
