import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/food_bank.dart';

Future<pw.MemoryImage> _bushelMark() async {
  const icon = Icons.volunteer_activism;
  const size = 160.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(0, 0, size, size),
      const ui.Radius.circular(36),
    ),
    ui.Paint()..color = const ui.Color(0xff0c2a1b),
  );
  final builder =
      ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.center))
        ..pushStyle(
          ui.TextStyle(
            color: const ui.Color(0xffffffff),
            fontFamily: icon.fontPackage == null
                ? icon.fontFamily
                : 'packages/${icon.fontPackage}/${icon.fontFamily}',
            fontSize: 94,
          ),
        );
  builder.addText(String.fromCharCode(icon.codePoint));
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: size));
  canvas.drawParagraph(paragraph, ui.Offset(0, (size - paragraph.height) / 2));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return pw.MemoryImage(png!.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<Uint8List> buildShiftQrSheet({
  required FoodBankShift shift,
  required FoodBank bank,
  required String code,
  required String expiration,
  required bool signup,
}) async {
  final logo = await _bushelMark();
  final pdf = pw.Document();
  final heading = pw.TextStyle(
    fontSize: 26,
    fontWeight: pw.FontWeight.bold,
    color: PdfColor.fromInt(0xff0c2a1b),
  );
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(48),
      build: (_) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Image(logo, width: 58, height: 58),
          pw.SizedBox(height: 12),
          pw.Text(
            'BUSHEL',
            style: pw.TextStyle(letterSpacing: 3, fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            signup ? 'Volunteer shift signup' : 'Station check-in',
            style: heading,
          ),
          pw.SizedBox(height: 22),
          pw.SizedBox(
            height: 110,
            width: 500,
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              child: pw.Column(
                children: [
                  pw.Text(
                    shift.title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(bank.name, style: const pw.TextStyle(fontSize: 14)),
                  pw.Text(
                    '${shift.date}, ${shift.scheduledDate.year} | ${shift.time}',
                  ),
                  if (bank.address.isNotEmpty) pw.Text(bank.address),
                  if (shift.station.isNotEmpty)
                    pw.Text('Station: ${shift.station}'),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            color: PdfColors.white,
            padding: const pw.EdgeInsets.all(24),
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: code,
              width: 208,
              height: 208,
              drawText: false,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            signup
                ? 'Scan with your phone camera. Sign in to Bushel and confirm your signup.'
                : 'Open Bushel, select the shift under Check in, and scan this code in the app.',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 13),
          ),
          if (!signup) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Check-in opens 30 minutes before and closes 4 hours after the shift starts.',
              textAlign: pw.TextAlign.center,
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'QR expires $expiration',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    ),
  );
  return pdf.save();
}

Future<void> printShiftQrSheet({
  required FoodBankShift shift,
  required FoodBank bank,
  required String code,
  required String expiration,
  required bool signup,
}) async {
  final bytes = await buildShiftQrSheet(
    shift: shift,
    bank: bank,
    code: code,
    expiration: expiration,
    signup: signup,
  );
  await Printing.layoutPdf(
    name: signup ? 'bushel-shift-signup.pdf' : 'bushel-station-check-in.pdf',
    format: PdfPageFormat.letter,
    dynamicLayout: false,
    onLayout: (_) => bytes,
  );
}
