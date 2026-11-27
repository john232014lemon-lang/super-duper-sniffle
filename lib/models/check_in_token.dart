import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// The raw QR exists only in memory. Firestore receives a proof and its hash,
/// never the raw token. The public verifier cannot be submitted as a proof.
class CheckInToken {
  const CheckInToken(this.code, this.expiresAt);
  final String code;
  final DateTime expiresAt;
  static const lifetime = Duration(hours: 24);
  static const generationLeadTime = Duration(hours: 24);
  static const earlyWindow = Duration(minutes: 30);
  static const lateWindow = Duration(hours: 4);
  static String digest(String value) =>
      sha256.convert(utf8.encode(value)).toString();
  static String proof(String code) => digest(code);
  static String verifier(String code) => digest(proof(code));

  static CheckInToken generateMock(String shiftId, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final token = generate(shiftId, clock, now: clock);
    return CheckInToken(
      token.code.replaceFirst('BUSHEL1:', 'BUSHELMOCK:'),
      token.expiresAt,
    );
  }

  static const _manualAlphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  static final _manualPattern = RegExp(r'^[' + _manualAlphabet + r']{10}$');

  String get manualCode {
    final bytes = sha256.convert(utf8.encode('manual:$code')).bytes;
    return List.generate(10, (i) {
      final offset = i * 5;
      final index = offset ~/ 8;
      final pair = (bytes[index] << 8) | bytes[index + 1];
      return _manualAlphabet[(pair >> (11 - offset % 8)) & 31];
    }).join();
  }

  static String submissionProof(
    String code,
    String shiftId, {
    bool mock = false,
  }) {
    final normalized = code.trim().toUpperCase();
    if (!_manualPattern.hasMatch(normalized)) return proof(code);
    return proof(
      'BUSHELMANUAL:${mock ? 'mock' : 'real'}:${Uri.encodeComponent(shiftId)}:$normalized',
    );
  }

  String get manualVerifier {
    final parts = code.split(':');
    return digest(
      submissionProof(
        manualCode,
        Uri.decodeComponent(parts[1]),
        mock: parts[0] == 'BUSHELMOCK',
      ),
    );
  }

  static String? validateMock(
    String code,
    String shiftId,
    String? hash,
    DateTime? expiry, {
    String? manualHash,
    DateTime? now,
  }) => _validate(
    code,
    shiftId,
    hash,
    expiry,
    manualHash: manualHash,
    mock: true,
    now: now,
  );

  static CheckInToken generate(
    String shiftId,
    DateTime start, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final end = start.add(lateWindow);
    if (clock.isBefore(start.subtract(generationLeadTime)) ||
        !clock.isBefore(end)) {
      throw const FormatException(
        'QR generation opens 24 hours before the shift and closes 4 hours after its start.',
      );
    }
    final random = Random.secure();
    final secret = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return CheckInToken(
      'BUSHEL1:${Uri.encodeComponent(shiftId)}:$secret',
      clock.add(lifetime),
    );
  }

  static String? validate(
    String code,
    String shiftId,
    String? hash,
    DateTime? expiry,
    DateTime start, {
    String? manualHash,
    DateTime? now,
  }) => _validate(
    code,
    shiftId,
    hash,
    expiry,
    manualHash: manualHash,
    start: start,
    now: now,
  );

  static String? _validate(
    String code,
    String shiftId,
    String? hash,
    DateTime? expiry, {
    String? manualHash,
    DateTime? start,
    DateTime? now,
    bool mock = false,
  }) {
    final manual = _manualPattern.hasMatch(code.trim().toUpperCase());
    final parts = code.split(':');
    if (!manual &&
        (parts.length != 3 ||
            parts[0] != (mock ? 'BUSHELMOCK' : 'BUSHEL1') ||
            parts[1] != Uri.encodeComponent(shiftId) ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(parts[2]))) {
      return mock
          ? 'Use a coordinator-generated mock code.'
          : 'This code is invalid or belongs to another shift. Scan the selected shift?s QR.';
    }
    if (hash == null || expiry == null) {
      return 'Ask the assigned leader to generate a new QR.';
    }
    final clock = now ?? DateTime.now();
    if (!clock.isBefore(expiry)) return 'This is an old qr code';
    if (start != null &&
        (clock.isBefore(start.subtract(earlyWindow)) ||
            !clock.isBefore(start.add(lateWindow)))) {
      return 'The shift check-in window is closed. Ask the leader for a new QR.';
    }
    if (digest(submissionProof(code, shiftId, mock: mock)) !=
        (manual ? manualHash : hash)) {
      return 'This code is wrong or has been rotated. Scan the newest QR.';
    }
    return null;
  }
}
