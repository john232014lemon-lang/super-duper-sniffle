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

  void setRole(BushelRole role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }

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
