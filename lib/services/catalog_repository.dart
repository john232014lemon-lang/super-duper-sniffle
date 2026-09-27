import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/food_bank.dart';
import 'community_models.dart';
import '../data/session_store.dart';

class StoredShift {
  const StoredShift({
    required this.bankId,
    required this.creatorUid,
    required this.shift,
  });
  final String bankId;
  final String creatorUid;
  final FoodBankShift shift;
}

abstract class CatalogRepository {
  Stream<List<FoodBank>> watchBanks();
  Stream<List<StoredShift>> watchShifts();
  Stream<Set<String>> watchSignups(String uid);
  Stream<Set<String>> watchCoordinatorBanks(String uid);
  Future<void> createShift(String uid, String bankId, FoodBankShift shift);
  Future<void> setSignup(String uid, String shiftId, bool join);
  Stream<Map<String, String>> watchApplications(String uid);
  Future<void> applyToCoordinate(
    String uid,
    String bankId,
    String name,
    String contact,
    String reason,
  );
  Stream<FamilyData> watchFamily(String uid);
  Future<void> saveFamilyEntry(String uid, String field, String value);
  Future<void> switchFamilyProfile(String uid, String childId);
  Stream<Map<String, Set<String>>> watchChildSignups(String uid);
  Future<void> setChildSignup(
    String uid,
    String shiftId,
    String childId,
    bool join,
  );
  Stream<ShiftGroup> watchGroup(String shiftId);
  Stream<Map<String, RemovalVote>> watchVotes(String shiftId);
  Future<void> voteToRemove(String uid, String shiftId, String target);
  Future<void> finalizeRemoval(String uid, String shiftId, String target);
}

class CatalogException implements Exception {
  const CatalogException(this.message);
  final String message;
  @override
  String toString() => message;
}

String catalogError(Object error) {
  if (error is CatalogException) return error.message;
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'You do not have permission for this action. Refresh and try again.';
  }
  return 'Could not save this change. Check your connection and try again.';
}

class FirestoreCatalogRepository implements CatalogRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static FoodBank decodeBank(String id, Map<String, dynamic> data) => FoodBank(
    id: id,
    name: data['name'] as String,
    shortName: data['shortName'] as String,
    description: data['description'] as String,
    address: data['address'] as String,
    hours: data['hours'] as String,
    distance: data['distance'] as String? ?? 'See map',
    location: LatLng(
      (data['latitude'] as num).toDouble(),
      (data['longitude'] as num).toDouble(),
    ),
    accent: const Color(0xFF23B65E),
    icon: Icons.store_outlined,
    shifts: const [],
  );

  static StoredShift decodeShift(String id, Map<String, dynamic> data) {
    final date = (data['date'] as Timestamp).toDate().toUtc();
    return StoredShift(
      bankId: data['bankId'] as String,
      creatorUid: data['creatorUid'] as String,
      shift: FoodBankShift(
        id: id,
        title: data['title'] as String,
        // Date-only scheduling: preserve the stored calendar day in every timezone.
        scheduledDate: DateTime(date.year, date.month, date.day),
        time: data['time'] as String,
        station: data['station'] as String,
        spotsLeft: (data['capacity'] as int) - (data['signupCount'] as int),
      ),
    );
  }

  @override
  Stream<List<FoodBank>> watchBanks() => _db
      .collection('banks')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => decodeBank(doc.id, doc.data())).toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  @override
  Stream<List<StoredShift>> watchShifts() => _db
      .collection('shifts')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => decodeShift(doc.id, doc.data())).toList()
              ..sort(
                (a, b) =>
                    a.shift.scheduledDate.compareTo(b.shift.scheduledDate),
              ),
      );

  @override
  Stream<Set<String>> watchSignups(String uid) => _db
      .collection('registrations')
      .doc(uid)
      .collection('shifts')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  @override
  Stream<Set<String>> watchCoordinatorBanks(String uid) => _db
      .collection('coordinatorApplications')
      .doc(uid)
      .collection('banks')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where((doc) => doc.data()['status'] == 'approved')
            .map((doc) => doc.id)
            .toSet(),
      );

  @override
  Stream<Map<String, String>> watchApplications(String uid) => _db
      .collection('coordinatorApplications')
      .doc(uid)
      .collection('banks')
      .snapshots()
      .map(
        (snapshot) => {
          for (final doc in snapshot.docs)
            doc.id: doc.data()['status'] as String,
        },
      );

  @override
  Future<void> applyToCoordinate(
    String uid,
    String bankId,
    String name,
    String contact,
    String reason,
  ) => _db
      .collection('coordinatorApplications')
      .doc(uid)
      .collection('banks')
      .doc(bankId)
      .set({
        'name': name.trim(),
        'contact': contact.trim(),
        'reason': reason.trim(),
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

  @override
  Stream<FamilyData> watchFamily(String uid) => _db
      .collection('families')
      .doc(uid)
      .snapshots()
      .map((doc) => FamilyData.decode(doc.data()));

  @override
  Future<void> saveFamilyEntry(String uid, String field, String value) async {
    if (!['children', 'challenges'].contains(field)) {
      throw const CatalogException('Invalid family entry.');
    }
    final ref = _db.collection('families').doc(uid);
    final id = _db.collection('families').doc().id;
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      final data =
          doc.data() ??
          {
            'children': <String, dynamic>{},
            'challenges': <String, dynamic>{},
            'activeChildId': '',
          };
      data[field] = {
        ...Map<String, dynamic>.from(data[field]),
        id: value.trim(),
      };
      tx.set(ref, data);
    });
  }

  @override
  Future<void> switchFamilyProfile(String uid, String childId) =>
      _db.collection('families').doc(uid).update({'activeChildId': childId});

  @override
  Stream<Map<String, Set<String>>> watchChildSignups(String uid) => _db
      .collection('registrations')
      .doc(uid)
      .collection('shifts')
      .snapshots()
      .map(
        (snapshot) => {
          for (final doc in snapshot.docs)
            doc.id: Set<String>.from(doc.data()['childIds'] ?? []),
        },
      );

  @override
  Future<void> setChildSignup(
    String uid,
    String shiftId,
    String childId,
    bool join,
  ) => _db.runTransaction((tx) async {
    final ref = _db
        .collection('registrations')
        .doc(uid)
        .collection('shifts')
        .doc(shiftId);
    final shiftRef = _db.collection('shifts').doc(shiftId);
    final registration = await tx.get(ref);
    final shift = await tx.get(shiftRef);
    if (!registration.exists) {
      throw const CatalogException(
        'Sign yourself up before adding your child.',
      );
    }
    final ids = Set<String>.from(registration.data()?['childIds'] ?? []);
    if (ids.contains(childId) == join) return;
    final count = shift.data()!['signupCount'] as int;
    if (join && count >= shift.data()!['capacity']) {
      throw const CatalogException('This shift is full.');
    }
    join ? ids.add(childId) : ids.remove(childId);
    tx.update(ref, {'childIds': ids.toList()});
    tx.update(shiftRef, {'signupCount': count + (join ? 1 : -1)});
    tx.update(_db.collection('groups').doc(shiftId), {
      FieldPath(['seats', uid]): 1 + ids.length,
    });
  });

  @override
  Stream<ShiftGroup> watchGroup(String shiftId) => _db
      .collection('groups')
      .doc(shiftId)
      .snapshots()
      .map(
        (doc) => ShiftGroup(
          members: Map<String, String>.from(doc.data()?['members'] ?? {}),
          version: doc.data()?['version'] as int? ?? 0,
        ),
      );

  @override
  Stream<Map<String, RemovalVote>> watchVotes(String shiftId) => _db
      .collection('groups')
      .doc(shiftId)
      .collection('votes')
      .snapshots()
      .map(
        (snapshot) => {
          for (final doc in snapshot.docs)
            doc.id: RemovalVote(
              version: doc.data()['version'] as int,
              voters: List<String>.from(doc.data()['voters']),
            ),
        },
      );

  @override
  Future<void> voteToRemove(String uid, String shiftId, String target) async {
    final groupRef = _db.collection('groups').doc(shiftId);
    final voteRef = groupRef.collection('votes').doc(target);
    await _db.runTransaction((tx) async {
      final group = (await tx.get(groupRef)).data()!;
      final vote = (await tx.get(voteRef)).data();
      final voters = vote?['version'] == group['version']
          ? List<String>.from(vote!['voters'])
          : <String>[];
      if (voters.contains(uid)) return;
      voters.add(uid);
      tx.set(voteRef, {'version': group['version'], 'voters': voters});
    });
    await finalizeRemoval(uid, shiftId, target);
  }

  @override
  Future<void> finalizeRemoval(
    String uid,
    String shiftId,
    String target,
  ) => _db.runTransaction((tx) async {
    final groupRef = _db.collection('groups').doc(shiftId);
    final shiftRef = _db.collection('shifts').doc(shiftId);
    final registrationRef = _db
        .collection('registrations')
        .doc(target)
        .collection('shifts')
        .doc(shiftId);
    final group = (await tx.get(groupRef)).data()!;
    final vote = (await tx.get(
      groupRef.collection('votes').doc(target),
    )).data();
    final members = Map<String, dynamic>.from(group['members']);
    if (!members.containsKey(target) ||
        vote?['version'] != group['version'] ||
        (vote!['voters'] as List).length * 3 < members.length * 2) {
      return;
    }
    final shift = (await tx.get(shiftRef)).data()!;
    // Group seat counts avoid reading another family's private registration.
    final seats = Map<String, dynamic>.from(group['seats']);
    final removedSeats = seats.remove(target) as int;
    members.remove(target);
    tx.update(groupRef, {
      'members': members,
      'seats': seats,
      'version': (group['version'] as int) + 1,
      'banned': FieldValue.arrayUnion([target]),
    });
    tx.update(shiftRef, {
      'signupCount': (shift['signupCount'] as int) - removedSeats,
    });
    tx.delete(registrationRef);
  });

  @override
  Future<void> createShift(
    String uid,
    String bankId,
    FoodBankShift shift,
  ) async {
    final date = shift.scheduledDate;
    final ref = _db.collection('shifts').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'bankId': bankId,
      'creatorUid': uid,
      'title': shift.title,
      'date': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day)),
      'time': shift.time,
      'station': shift.station,
      'capacity': shift.spotsLeft,
      'signupCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('groups').doc(ref.id), {
      'members': <String, String>{},
      'seats': <String, int>{},
      'version': 0,
      'banned': <String>[],
    });
    await batch.commit();
  }

  @override
  Future<void> setSignup(String uid, String shiftId, bool join) =>
      _db.runTransaction((tx) async {
        final shiftRef = _db.collection('shifts').doc(shiftId);
        final registrationRef = _db
            .collection('registrations')
            .doc(uid)
            .collection('shifts')
            .doc(shiftId);
        final shift = await tx.get(shiftRef);
        final registration = await tx.get(registrationRef);
        if (!shift.exists) {
          throw const CatalogException('This shift is no longer available.');
        }
        if (registration.exists == join) {
          return; // Idempotent retries, never double-count.
        }
        final count = shift.data()!['signupCount'] as int;
        final capacity = shift.data()!['capacity'] as int;
        if (join && count >= capacity) {
          throw const CatalogException(
            'This shift is full. Please choose another.',
          );
        }
        final seats =
            1 + (registration.data()?['childIds'] as List? ?? []).length;
        tx.update(shiftRef, {'signupCount': count + (join ? 1 : -seats)});
        tx.update(_db.collection('groups').doc(shiftId), {
          FieldPath(['members', uid]): join
              ? SessionStore.instance.parentName
              : FieldValue.delete(),
          FieldPath(['seats', uid]): join ? 1 : FieldValue.delete(),
          'version': FieldValue.increment(1),
        });
        if (join) {
          tx.set(registrationRef, {'createdAt': FieldValue.serverTimestamp()});
        } else {
          tx.delete(registrationRef);
        }
      });
}
