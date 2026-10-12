import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/session_store.dart';

/// Returns a code only; all membership/token validation stays in check-in.
class CameraScanScreen extends StatefulWidget {
  const CameraScanScreen({super.key});
  @override
  State<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends State<CameraScanScreen> {
  bool _returned = false;
  String? _error;
  int _attempt = 0;
  @override
  void initState() {
    super.initState();
    SessionStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SessionStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _detected(BarcodeCapture capture) {
    if (_returned || !mounted || SessionStore.instance.isKidAccount) return;
    final code = capture.barcodes
        .where((barcode) => barcode.format == BarcodeFormat.qrCode)
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null) return;
    _returned = true;
    Navigator.pop(context, code);
  }

  Widget _cameraError(MobileScannerException error) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera permission was denied. Allow it in your browser or device settings, or enter the code instead.',
      MobileScannerErrorCode.unsupported =>
        'No supported camera is available. Enter the code instead.',
      _ =>
        'Could not open the camera. It may be busy or unavailable. Enter the code instead.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kid = SessionStore.instance.isKidAccount;
    final supported = kIsWeb || defaultTargetPlatform == TargetPlatform.android;
    final secureWeb =
        !kIsWeb ||
        Uri.base.scheme == 'https' ||
        ['localhost', '127.0.0.1', '::1', '[::1]'].contains(Uri.base.host);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan station QR')),
      body: kid
          ? const Center(
              child: Text('Ask your parent to scan and check you in.'),
            )
          : Column(
              children: [
                Expanded(
                  child: !supported
                      ? const Center(
                          child: Text(
                            'Camera scanning is available on Android and Web. Enter the code instead.',
                          ),
                        )
                      : !secureWeb
                      ? const Center(
                          child: Text(
                            'Web camera access requires HTTPS or localhost. Enter the code instead.',
                          ),
                        )
                      : MobileScanner(
                          key: ValueKey(_attempt),
                          // Without a supplied controller, the plugin manages camera
                          // pause/resume and disposal when this route closes.
                          onDetect: _detected,
                          errorBuilder: (_, error) => _cameraError(error),
                          onDetectError: (_, _) {
                            if (mounted) {
                              setState(
                                () => _error =
                                    'Could not read that QR. Try again or enter the code instead.',
                              );
                            }
                          },
                        ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!),
                  ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Point the camera at your assigned leader’s current QR.',
                  ),
                ),
                if (supported && secureWeb)
                  TextButton(
                    onPressed: () => setState(() {
                      _attempt++;
                      _error = null;
                    }),
                    child: const Text('Retry camera'),
                  ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Enter code instead'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
