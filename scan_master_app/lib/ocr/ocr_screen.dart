import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  String _extractedText = '';
  bool _isProcessing = false;
  File? _selectedImage;
  TextRecognitionScript _selectedScript = TextRecognitionScript.latin;
  TextRecognizer? _currentRecognizer;

  @override
  void dispose() {
    _currentRecognizer?.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _extractedText = '';
      });
      _extractText(_selectedImage!);
    }
  }

  Future<void> _extractText(File imageFile) async {
    if (_isProcessing) return; // Prevent concurrent executions
    setState(() => _isProcessing = true);
    
    try {
      // Safely close any existing recognizer before creating a new one
      if (_currentRecognizer != null) {
        await _currentRecognizer!.close();
        _currentRecognizer = null;
      }

      final inputImage = InputImage.fromFile(imageFile);
      _currentRecognizer = TextRecognizer(script: _selectedScript);
      
      final RecognizedText recognizedText = await _currentRecognizer!.processImage(inputImage);
      
      if (mounted) {
        setState(() {
          _extractedText = recognizedText.text;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _extractedText = 'Failed to extract text. Error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showLanguageSelector() {
    final languages = [
      {'script': TextRecognitionScript.latin, 'name': 'English / European (Latin)'},
      {'script': TextRecognitionScript.devanagiri, 'name': 'Hindi / Indian (Devanagari)'},
      {'script': TextRecognitionScript.japanese, 'name': 'Japanese'},
      {'script': TextRecognitionScript.korean, 'name': 'Korean'},
      {'script': TextRecognitionScript.chinese, 'name': 'Chinese'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ...languages.map((lang) {
                final isSelected = _selectedScript == lang['script'];
                return ListTile(
                  leading: Icon(
                    Icons.language,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                  title: Text(
                    lang['name'] as String,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (_selectedScript != lang['script']) {
                      setState(() {
                        _selectedScript = lang['script'] as TextRecognitionScript;
                      });
                      if (_selectedImage != null && !_isProcessing) {
                        _extractText(_selectedImage!);
                      }
                    }
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR (Text Extractor)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: _showLanguageSelector,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Row(
                  children: [
                    Icon(Icons.g_translate, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OCR Language', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                          const SizedBox(height: 2),
                          Text(
                            _selectedScript == TextRecognitionScript.latin ? 'English / European (Latin)' :
                            _selectedScript == TextRecognitionScript.devanagiri ? 'Hindi / Indian (Devanagari)' :
                            _selectedScript == TextRecognitionScript.japanese ? 'Japanese' :
                            _selectedScript == TextRecognitionScript.korean ? 'Korean' : 'Chinese',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 28),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_extractedText.isNotEmpty)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: SingleChildScrollView(
                  child: Text(_extractedText, style: const TextStyle(fontSize: 16)),
                ),
              ),
            )
          else if (_selectedImage != null)
            const Expanded(child: Center(child: Text('No text found in image.')))
          else
            const Expanded(child: Center(child: Text('Select an image to extract text.'))),
          
          if (_extractedText.isNotEmpty && !_isProcessing)
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _extractedText));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text Copied!')));
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy All Text'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              ),
            )
        ],
      ),
    );
  }
}
