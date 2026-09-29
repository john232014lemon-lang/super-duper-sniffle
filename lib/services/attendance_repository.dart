import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import 'catalog_repository.dart' show CatalogException;

abstract class AttendanceRepository {
  Stream<List<AttendanceEntry>> watchAttendance(
    String uid, {
    bool asLeader = false,
  });
  Stream<Map<String, String>> watchFeaturedBadges(String uid);
  Future<void> publishQr(String shiftId);
  Future<void> submitAttendance(
    String uid,
    String participantId,
    String shiftId,
    String name,
    String code,
  );
  Future<void> confirmEntry(AttendanceEntry entry);
  Future<void> chooseBadge(
    String uid,
    String participantId,
    String shiftId,
    String badgeId,
  );
}

class FirestoreAttendanceRepository implements AttendanceRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _entry(
    String uid,
    String pid,
    String sid,
  ) => _firestore
      .collection('attendance')
      .doc(sid)
      .collection('families')
      .doc(uid)
      .collection('attendanceEntries')
      .doc(pid);

  @override
  Stream<List<AttendanceEntry>> watchAttendance(
    String uid, {
    bool asLeader = false,
  }) => _firestore
      .collectionGroup('attendanceEntries')
      .where(asLeader ? 'leaderUid' : 'ownerUid', isEqualTo: uid)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => AttendanceEntry.decode(doc.data()))
            .toList(),
      );

  @override
  Stream<Map<String, String>> watchFeaturedBadges(String uid) => _firestore
      .collection('rewardPreferences')
      .doc(uid)
      .collection('people')
      .snapshots()
      .map(
        (snapshot) => {
          for (final doc in snapshot.docs)
            doc.id: doc.data()['badgeId'] as String,
        },
      );

  @override
  Future<void> publishQr(String shiftId) =>
      _firestore.runTransaction((tx) async {
        final ref = _firestore.collection('shifts').doc(shiftId);
        final shift = await tx.get(ref);
        if (!shift.exists) {
          throw const CatalogException('This shift no longer exists.');
        }
        if (shift.data()!['qrCode'] != null) return;
        tx.update(ref, {'qrCode': 'BUSHEL-SHIFT-$shiftId'});
      });

  @override
  Future<void> submitAttendance(
    String uid,
    String participantId,
    String shiftId,
    String name,
    String code,
  ) => _firestore.runTransaction((tx) async {
    final ref = _entry(uid, participantId, shiftId);
    final existing = await tx.get(ref);
    if (existing.exists) return;
    final shift = await tx.get(_firestore.collection('shifts').doc(shiftId));
    if (!shift.exists || shift.data()!['qrCode'] != code) {
      throw const CatalogException(
        'This code does not match the shift. Try scanning again.',
      );
    }
    tx.set(ref, {
      'ownerUid': uid,
      'participantId': participantId,
      'shiftId': shiftId,
      'leaderUid': shift.data()!['creatorUid'],
      'name': name,
      'code': code,
      'status': 'pending',
      'checkedInAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> confirmEntry(AttendanceEntry entry) =>
      _firestore.runTransaction((tx) async {
        final ref = _entry(entry.ownerUid, entry.participantId, entry.shiftId);
        final current = await tx.get(ref);
        if (!current.exists) {
          throw const CatalogException('This check-in no longer exists.');
        }
        if (current.data()!['status'] == 'confirmed') return;
        tx.update(ref, {
          'status': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
        });
      });

  @override
  Future<void> chooseBadge(
    String uid,
    String participantId,
    String shiftId,
    String badgeId,
  ) => _firestore.runTransaction((tx) async {
    final ref = _entry(uid, participantId, shiftId);
    final entry = await tx.get(ref);
    if (!entry.exists || entry.data()!['status'] != 'confirmed') {
      throw const CatalogException(
        'Wait for your coordinator to confirm attendance.',
      );
    }
    final earned = entry.data()!['badgeId'];
    if (earned != null && earned != badgeId) {
      throw const CatalogException(
        'This completed shift already earned a different badge.',
      );
    }
    if (earned == null) tx.update(ref, {'badgeId': badgeId});
    tx.set(
      _firestore
          .collection('rewardPreferences')
          .doc(uid)
          .collection('people')
          .doc(participantId),
      {'badgeId': badgeId, 'shiftId': shiftId},
    );
  });
}
