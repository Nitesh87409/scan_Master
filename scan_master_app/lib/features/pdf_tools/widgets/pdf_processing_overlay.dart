import 'package:flutter/material.dart';
import 'package:scan_master_app/l10n/app_localizations.dart';

class PdfProcessingOverlay extends StatelessWidget {
  final double progressValue;
  final String progressMessage;
  final VoidCallback onCancel;

  const PdfProcessingOverlay({
    super.key,
    required this.progressValue,
    required this.progressMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: progressValue,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      Text(
                        '${(progressValue * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Processing...',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progressMessage,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.processingBackground,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
