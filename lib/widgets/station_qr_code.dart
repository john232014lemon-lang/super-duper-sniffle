import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StationQrCode extends StatelessWidget {
  const StationQrCode({super.key, required this.code, this.size = 260});
  final String code;
  final double size;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final extent = constraints.maxWidth < size ? constraints.maxWidth : size;
      return Semantics(
        label: 'Station check-in QR',
        child: QrImageView(
          data: code,
          size: extent,
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.M,
        ),
      );
    },
  );
}
