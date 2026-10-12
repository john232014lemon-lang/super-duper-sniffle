import 'dart:async';
import 'package:flutter/material.dart';
import '../models/check_in_token.dart';
import 'station_qr_code.dart';

class StationTokenDisplay extends StatefulWidget {
  const StationTokenDisplay({super.key, required this.token});
  final CheckInToken token;
  @override
  State<StationTokenDisplay> createState() => _StationTokenDisplayState();
}

class _StationTokenDisplayState extends State<StationTokenDisplay> {
  Timer? _expiry;
  void _schedule() {
    _expiry?.cancel();
    final remaining = widget.token.expiresAt.difference(DateTime.now());
    if (remaining > Duration.zero) {
      _expiry = Timer(remaining, () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(StationTokenDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!DateTime.now().isBefore(widget.token.expiresAt)) {
      return const Text('This QR has expired. Generate or rotate a new QR.');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StationQrCode(code: widget.token.code),
        const SizedBox(height: 8),
        SelectableText(widget.token.code),
        Text('Expires: ${widget.token.expiresAt.toLocal()}'),
      ],
    );
  }
}
