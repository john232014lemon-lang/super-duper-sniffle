import 'package:flutter/material.dart';
import '../data/mock_qr_presentation_store.dart';
import '../data/session_store.dart';
import '../widgets/station_qr_code.dart';

/// BUSHEL_MOCK only: fake viewfinder showing the session’s generated mock QR.
/// Returns a code only; membership/token validation stays in check-in.
class MockCameraScanScreen extends StatefulWidget {
  const MockCameraScanScreen({super.key, required this.shiftId});
  final String shiftId;

  @override
  State<MockCameraScanScreen> createState() => _MockCameraScanScreenState();
}

class _MockCameraScanScreenState extends State<MockCameraScanScreen> {
  bool _returned = false;

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

  void _scan(String code) {
    if (_returned || !mounted || SessionStore.instance.isKidAccount) return;
    _returned = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    final kid = SessionStore.instance.isKidAccount;
    final token = MockQrPresentationStore.instance.tokenFor(widget.shiftId);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan station QR')),
      body: kid
          ? const Center(
              child: Text('Ask your parent to scan and check you in.'),
            )
          : Column(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: const Color(0xFF1A1A1A),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: token == null
                            ? const Text(
                                'No mock QR for this shift in this demo session. Generate one as the coordinator first (same browser session), or enter the code instead.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              )
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF22B95C),
                                    width: 3,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Mock camera · demo QR in frame',
                                        style: TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: 220,
                                        child: StationQrCode(
                                          code: token.code,
                                          size: 220,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Presentation mode: tap Scan to use the coordinator’s current mock QR. No real camera is used.',
                    textAlign: TextAlign.center,
                  ),
                ),
                if (token != null)
                  FilledButton.icon(
                    onPressed: () => _scan(token.code),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan this QR'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Enter code instead'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
