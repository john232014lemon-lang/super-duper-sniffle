import 'package:flutter/foundation.dart';

enum BushelRole { volunteer, coordinator, kid }

class SessionStore extends ChangeNotifier {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String userName = 'Maya';
  BushelRole _role = BushelRole.volunteer;
  final Set<String> _unlockedKidBadges = {};
  String? _featuredKidBadge;

  BushelRole get role => _role;
  Set<String> get unlockedKidBadges => Set.unmodifiable(_unlockedKidBadges);
  String? get featuredKidBadge => _featuredKidBadge;

  String get roleProfileName => switch (_role) {
    BushelRole.coordinator => 'Sir Johnny John Jimmy',
    BushelRole.kid => 'Lil Jimbo',
    BushelRole.volunteer => 'Jimmerson Jimmies',
  };
  String get phoneNumber => switch (_role) {
    BushelRole.coordinator => '(713) 555-0142',
    BushelRole.kid => '(832) 555-0188',
    BushelRole.volunteer => '(281) 555-0164',
  };
  String get accountId => switch (_role) {
    BushelRole.coordinator => 'johnny',
    BushelRole.kid => 'jimbo',
    BushelRole.volunteer => 'jimmerson',
  };

  void setRole(BushelRole role) {
    final changed = _role != role || userName != _nameFor(role);
    _role = role;
    userName = _nameFor(role);
    if (!changed) return;
    notifyListeners();
  }

  String _nameFor(BushelRole role) => switch (role) {
    BushelRole.coordinator => 'Sir Johnny John Jimmy',
    BushelRole.kid => 'Lil Jimbo',
    BushelRole.volunteer => 'Jimmerson Jimmies',
  };

  void unlockKidBadge(String id) {
    _unlockedKidBadges.add(id);
    _featuredKidBadge = id;
    notifyListeners();
  }

  void featureKidBadge(String id) {
    if (!_unlockedKidBadges.contains(id)) return;
    _featuredKidBadge = id;
    notifyListeners();
  }
}
