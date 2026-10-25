import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import '../models/check_in_token.dart';
import '../demo_config.dart';
import '../data/session_store.dart';
import 'catalog_repository.dart' show CatalogException;

abstract class AttendanceRepository {
  Stream<List<AttendanceEntry>> watchAttendance(
    String uid, {
    bool asLeader = false,
  });
  Stream<Map<String, String>> watchFeaturedBadges(String uid);
  Future<CheckInToken> publishQr(String shiftId);
  Future<bool> submitAttendance(
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

  Future<void> _requireMockAccess(Transaction tx, String shiftId) async {
    final settings = await tx.get(_firestore.doc('settings/mockQr'));
    final data = settings.data();
    final expiry = (data?['expiresAt'] as Timestamp?)?.toDate();
    if (data?['enabled'] != true ||
        expiry == null ||
        !DateTime.now().isBefore(expiry) ||
        !(data?['shiftIds'] as List? ?? []).contains(shiftId)) {
      throw const CatalogException(
        'Mock QR is not enabled for this shift. Ask the project administrator to enable the presentation session.',
      );
    }
  }

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
  }) {
    late StreamController<List<AttendanceEntry>> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    List<AttendanceEntry>? entries;
    Set<(String, String)>? revoked;
    void emit() {
      if (entries != null && revoked != null) {
        controller.add(
          entries!
              .map(
                (entry) => revoked!.contains((entry.ownerUid, entry.shiftId))
                    ? entry.revoke()
                    : entry,
              )
              .toList(),
        );
      }
    }

    controller = StreamController<List<AttendanceEntry>>(
      onListen: () {
        final field = asLeader ? 'leaderUid' : 'ownerUid';
        subscriptions.add(
          _firestore
              .collectionGroup('attendanceEntries')
              .where(field, isEqualTo: uid)
              .snapshots()
              .listen(
                (snapshot) {
                  entries = snapshot.docs
                      .map((doc) => AttendanceEntry.decode(doc.data()))
                      .toList();
                  emit();
                },
                onError: (Object error, StackTrace stack) {
                  entries = null;
                  controller.addError(error, stack);
                },
              ),
        );
        subscriptions.add(
          _firestore
              .collectionGroup('revokedFamilies')
              .where(field, isEqualTo: uid)
              .snapshots()
              .listen(
                (snapshot) {
                  revoked = snapshot.docs
                      .map(
                        (doc) => (
                          doc.data()['ownerUid'] as String,
                          doc.data()['shiftId'] as String,
                        ),
                      )
                      .toSet();
                  emit();
                },
                onError: (Object error, StackTrace stack) {
                  revoked = null;
                  controller.addError(error, stack);
                },
              ),
        );
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

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
  Future<CheckInToken> publishQr(String shiftId) =>
      _firestore.runTransaction((tx) async {
        if (SessionStore.instance.isKidAccount) {
          throw const CatalogException(
            'Only the approved adult coordinator can generate codes.',
          );
        }
        final ref = _firestore.collection('shifts').doc(shiftId);
        final shift = await tx.get(ref);
        if (mockQrMode) {
          await _requireMockAccess(tx, shiftId);
          final token = CheckInToken.generateMock(shiftId);
          tx.set(_firestore.collection('mockQrTokens').doc(shiftId), {
            'qrTokenHash': CheckInToken.verifier(token.code),
            'expiresAt': Timestamp.fromDate(token.expiresAt),
          });
          return token;
        }
        final start = (shift.data()?['startsAt'] as Timestamp?)?.toDate();
        if (!shift.exists || start == null) {
          throw const CatalogException(
            'This shift needs a valid start time before generating a QR.',
          );
        }
        late CheckInToken token;
        try {
          token = CheckInToken.generate(shiftId, start);
        } on FormatException catch (error) {
          throw CatalogException(error.message);
        }
        tx.update(ref, {
          'qrTokenHash': CheckInToken.verifier(token.code),
          'qrExpiresAt': Timestamp.fromDate(token.expiresAt),
          'qrCode': FieldValue.delete(),
        });
        return token;
      });

  @override
  Future<bool> submitAttendance(
    String uid,
    String participantId,
    String shiftId,
    String name,
    String code,
  ) async {
    if (SessionStore.instance.isKidAccount || participantId != 'parent') {
      throw const CatalogException(
        'A parent checks in the whole booked family.',
      );
    }
    if (mockQrMode &&
        (SessionStore.instance.isKidAccount ||
            SessionStore.instance.role != BushelRole.volunteer ||
            participantId != 'parent')) {
      throw const CatalogException(
        'Mock QR codes are for adult volunteers only.',
      );
    }
    try {
      return await _firestore.runTransaction((tx) async {
        final ref = _entry(uid, participantId, shiftId);
        final existing = await tx.get(ref);
        final shift = await tx.get(
          _firestore.collection('shifts').doc(shiftId),
        );
        final registration = await tx.get(
          _firestore
              .collection('registrations')
              .doc(uid)
              .collection('shifts')
              .doc(shiftId),
        );
        final data = shift.data();
        final start = (data?['startsAt'] as Timestamp?)?.toDate();
        if (!registration.exists ||
            (participantId != 'parent' &&
                !(registration.data()?['childIds'] as List? ?? []).contains(
                  participantId,
                ))) {
          throw const CatalogException(
            'You need a current booking for this participant.',
          );
        }
        if (existing.exists) {
          throw const CatalogException(
            'This participant has already checked in for this shift.',
          );
        }
        if (data == null || start == null) {
          throw const CatalogException(
            'This shift is unavailable for check-in.',
          );
        }
        if (mockQrMode && data['creatorUid'] == uid) {
          throw const CatalogException(
            'The assigned coordinator cannot redeem their own mock code.',
          );
        }
        String? error;
        if (mockQrMode) {
          await _requireMockAccess(tx, shiftId);
          final mock = await tx.get(
            _firestore.collection('mockQrTokens').doc(shiftId),
          );
          error = CheckInToken.validateMock(
            code,
            shiftId,
            mock.data()?['qrTokenHash'] as String?,
            (mock.data()?['expiresAt'] as Timestamp?)?.toDate(),
          );
        } else {
          error = CheckInToken.validate(
            code,
            shiftId,
            data['qrTokenHash'] as String?,
            (data['qrExpiresAt'] as Timestamp?)?.toDate(),
            start,
          );
        }
        if (error != null) throw CatalogException(error);
        var selfConfirmed = false;
        if (!mockQrMode &&
            participantId == 'parent' &&
            data['creatorUid'] == uid) {
          final approval = await tx.get(
            _firestore
                .collection('coordinatorApplications')
                .doc(uid)
                .collection('banks')
                .doc(data['bankId'] as String),
          );
          selfConfirmed = approval.data()?['status'] == 'approved';
        }
        // Read the current booking/family in this transaction, not cached UI data.
        final childIds = (registration.data()?['childIds'] as List? ?? [])
            .cast<String>()
            .toSet()
            .toList();
        final family = childIds.isEmpty
            ? null
            : await tx.get(_firestore.collection('families').doc(uid));
        final children =
            (family?.data()?['children'] as Map<String, dynamic>?) ?? {};
        final childEntries = <String, DocumentSnapshot<Map<String, dynamic>>>{};
        for (final id in childIds) {
          if (children[id] is! String) {
            throw const CatalogException(
              'Refresh your family bookings before checking in.',
            );
          }
          childEntries[id] = await tx.get(_entry(uid, id, shiftId));
        }
        Map<String, dynamic> fields(String pid, String participantName) => {
          'ownerUid': uid,
          'participantId': pid,
          'shiftId': shiftId,
          'leaderUid': data['creatorUid'],
          'name': participantName,
          'tokenProof': CheckInToken.proof(code),
          if (mockQrMode) 'mockQr': true,
          'status': selfConfirmed ? 'confirmed' : 'pending',
          if (selfConfirmed) 'confirmedAt': FieldValue.serverTimestamp(),
          'checkedInAt': FieldValue.serverTimestamp(),
        };
        tx.set(ref, {...fields('parent', name), 'checkedInChildIds': childIds});
        for (final id in childIds) {
          final existingChild = childEntries[id]!;
          if (!existingChild.exists) {
            tx.set(_entry(uid, id, shiftId), {
              ...fields(id, children[id] as String),
              'familyCheckIn': true,
            });
          } else if (selfConfirmed &&
              existingChild.data()?['status'] == 'pending') {
            tx.update(existingChild.reference, {
              'status': 'confirmed',
              'confirmedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        return selfConfirmed;
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const CatalogException(
          'Check-in was denied. The QR may have expired or rotated, or your membership or parent-mode access changed. Refresh and scan the newest QR.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> confirmEntry(
    AttendanceEntry entry,
  ) => _firestore.runTransaction((tx) async {
    final ref = _entry(entry.ownerUid, entry.participantId, entry.shiftId);
    final current = await tx.get(ref);
    if (!current.exists) {
      throw const CatalogException('This check-in no longer exists.');
    }
    final targets = <DocumentReference<Map<String, dynamic>>>[];
    if (current.data()!['status'] == 'pending') targets.add(ref);
    if (entry.participantId == 'parent') {
      final registration = await tx.get(
        _firestore
            .collection('registrations')
            .doc(entry.ownerUid)
            .collection('shifts')
            .doc(entry.shiftId),
      );
      final booked = (registration.data()?['childIds'] as List? ?? [])
          .cast<String>()
          .toSet();
      final checkedIn = (current.data()?['checkedInChildIds'] as List? ?? [])
          .cast<String>();
      for (final id in checkedIn.toSet().intersection(booked)) {
        final child = await tx.get(_entry(entry.ownerUid, id, entry.shiftId));
        if (child.data()?['status'] == 'pending') targets.add(child.reference);
      }
    }
    for (final target in targets) {
      tx.update(target, {
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
    }
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
