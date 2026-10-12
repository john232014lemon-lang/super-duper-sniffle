import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// The raw QR exists only in memory. Firestore receives a proof and its hash,
/// never the raw token. The public verifier cannot be submitted as a proof.
class CheckInToken {
  const CheckInToken(this.code, this.expiresAt);
  final String code;
  final DateTime expiresAt;
  static const lifetime = Duration(minutes: 15);
  // Rules cap expiry at server time + lifetime; device clocks may run ahead.
  static const clockSkewAllowance = Duration(minutes: 2);
  static const earlyWindow = Duration(minutes: 30);
  static const lateWindow = Duration(hours: 4);
  static String digest(String value) =>
      sha256.convert(utf8.encode(value)).toString();
  static String proof(String code) => digest(code);
  static String verifier(String code) => digest(proof(code));

  static CheckInToken generate(
    String shiftId,
    DateTime start, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final end = start.add(lateWindow);
    if (clock.isBefore(start.subtract(earlyWindow)) || !clock.isBefore(end)) {
      throw const FormatException(
        'QR generation opens 30 minutes before the shift and closes 4 hours after its start.',
      );
    }
    final random = Random.secure();
    final secret = List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final expiry = clock.add(lifetime - clockSkewAllowance);
    return CheckInToken(
      'BUSHEL1:${Uri.encodeComponent(shiftId)}:$secret',
      expiry.isBefore(end) ? expiry : end,
    );
  }

  static String? validate(
    String code,
    String shiftId,
    String? hash,
    DateTime? expiry,
    DateTime start, {
    DateTime? now,
  }) {
    final parts = code.split(':');
    if (parts.length != 3 ||
        parts[0] != 'BUSHEL1' ||
        parts[1] != Uri.encodeComponent(shiftId) ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(parts[2])) {
      return 'This code is invalid or belongs to another shift. Scan the selected shift’s QR.';
    }
    if (hash == null || expiry == null) {
      return 'Ask the assigned leader to generate a new QR.';
    }
    final clock = now ?? DateTime.now();
    if (!clock.isBefore(expiry) ||
        clock.isBefore(start.subtract(earlyWindow)) ||
        !clock.isBefore(start.add(lateWindow))) {
      return 'This code has expired or the shift check-in window is closed. Ask the leader for a new QR.';
    }
    if (verifier(code) != hash) {
      return 'This code is wrong or has been rotated. Scan the newest QR.';
    }
    return null;
  }
}
