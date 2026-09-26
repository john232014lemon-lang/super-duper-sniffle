import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../data/session_store.dart';

class AdultProfile {
  const AdultProfile({
    required this.name,
    required this.role,
    required this.family,
  });
  final String name;
  // A presentation preference, never an authorization role.
  final BushelRole role;
  final bool family;

  factory AdultProfile.fromMap(Map<String, dynamic> data) {
    final name = data['name'];
    final role = data['preferredRole'];
    final family = data['familyAccount'];
    if (name is! String ||
        name.trim().isEmpty ||
        name.length > 80 ||
        !['volunteer', 'coordinator'].contains(role) ||
        family is! bool) {
      throw const FormatException('Invalid adult profile');
    }
    return AdultProfile(
      name: name,
      role: role == 'coordinator'
          ? BushelRole.coordinator
          : BushelRole.volunteer,
      family: family,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'preferredRole': role.name,
    'familyAccount': family,
  };
}

abstract class ProfileRepository {
  Future<AdultProfile?> load(String uid);
  Future<void> save(String uid, AdultProfile profile);
}

class FirestoreProfileRepository implements ProfileRepository {
  @override
  Future<AdultProfile?> load(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    return snapshot.exists ? AdultProfile.fromMap(snapshot.data()!) : null;
  }

  @override
  Future<void> save(String uid, AdultProfile profile) => FirebaseFirestore
      .instance
      .collection('profiles')
      .doc(uid)
      .set({...profile.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
}

/// Lives above the Navigator, including routes replacing onboarding.
class ProfileScope extends InheritedWidget {
  const ProfileScope({
    super.key,
    required this.uid,
    required this.repository,
    required this.isCurrent,
    required super.child,
  });
  final String uid;
  final ProfileRepository repository;
  final bool Function() isCurrent;
  Future<void> save(AdultProfile profile) => repository.save(uid, profile);
  static ProfileScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileScope>();
  @override
  bool updateShouldNotify(ProfileScope oldWidget) =>
      uid != oldWidget.uid || repository != oldWidget.repository;
}
