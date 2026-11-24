import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/check_in_token.dart';

class ShiftSignupLink {
  const ShiftSignupLink(this.url, this.expiresAt);

  static const _parameter = 'shiftSignup';
  static final _idPattern = RegExp(r'^[A-Za-z0-9]{20}$');

  final Uri url;
  final DateTime expiresAt;

  static String? get incomingId =>
      kIsWeb ? Uri.base.queryParameters[_parameter] : null;

  static Future<ShiftSignupLink> issue(String shiftId) async {
    final ref = FirebaseFirestore.instance.collection('shiftSignupLinks').doc();
    final db = FirebaseFirestore.instance;
    const issuedAt = 'issuedAt';
    await ref.set({'shiftId': shiftId, issuedAt: FieldValue.serverTimestamp()});
    final snapshot = await ref.get(const GetOptions(source: Source.server));
    final timestamp = snapshot.data()![issuedAt] as Timestamp;
    return ShiftSignupLink(
      Uri.https('${db.app.options.projectId}.web.app', '/', {
        _parameter: ref.id,
      }),
      timestamp.toDate().add(CheckInToken.lifetime),
    );
  }

  static Future<String?> resolve(String id) async {
    if (!_idPattern.hasMatch(id)) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shiftSignupLinks')
          .doc(id)
          .get(const GetOptions(source: Source.server));
      return doc.data()?['shiftId'] as String?;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return null;
      rethrow;
    }
  }
}
