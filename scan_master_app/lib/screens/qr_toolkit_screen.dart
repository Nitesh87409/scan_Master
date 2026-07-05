import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class QrToolkitScreen extends StatefulWidget {
  const QrToolkitScreen({super.key});

  @override
  State<QrToolkitScreen> createState() => _QrToolkitScreenState();
}

class _QrToolkitScreenState extends State<QrToolkitScreen> {
  String _qrDataToGenerate = '';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('QR Toolkit'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
              Tab(icon: Icon(Icons.qr_code), text: 'Generate QR'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScannerTab(),
            _buildGeneratorTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerTab() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Found: ${barcode.rawValue}'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        label: 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: barcode.rawValue!));
                        },
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ),
        const Expanded(
          flex: 1,
          child: Center(
            child: Text('Point camera at a QR code to scan', style: TextStyle(fontSize: 16)),
          ),
        )
      ],
    );
  }

  Widget _buildGeneratorTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Enter text or URL',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.link),
            ),
            onChanged: (val) {
              setState(() {
                _qrDataToGenerate = val;
              });
            },
          ),
          const SizedBox(height: 40),
          if (_qrDataToGenerate.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _qrDataToGenerate,
                  version: QrVersions.auto,
                  size: 220.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
