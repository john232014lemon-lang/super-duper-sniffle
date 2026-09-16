import 'package:flutter/foundation.dart';

enum BushelRole { volunteer, coordinator, kid }

class FamilyChild {
  const FamilyChild({required this.id, required this.name});
  final String id;
  final String name;
}

class FamilyChallenge {
  const FamilyChallenge({
    required this.id,
    required this.title,
    required this.emoji,
  });
  final String id;
  final String title;
  final String emoji;
}

class SessionStore extends ChangeNotifier {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  String _parentName = 'Maya';
  BushelRole _parentRole = BushelRole.volunteer;
  String? _activeChildId;
  bool _familyAccount = false;
  final List<FamilyChild> _children = [];
  final List<FamilyChallenge> _challenges = [
    const FamilyChallenge(
      id: 'three-shifts',
      title: 'Sign up for 3 shifts!',
      emoji: '📅',
    ),
    const FamilyChallenge(
      id: 'pack-boxes',
      title: 'Pack 10 food boxes!',
      emoji: '📦',
    ),
    const FamilyChallenge(
      id: 'help-together',
      title: 'Volunteer together as a family!',
      emoji: '🤝',
    ),
  ];
  final Set<String> _unlockedKidBadges = {};
  String? _featuredKidBadge;

  String get userName => activeChild?.name ?? _parentName;
  BushelRole get role => activeChild == null ? _parentRole : BushelRole.kid;
  BushelRole get parentRole => _parentRole;
  bool get familyAccount => _familyAccount;
  bool get isKidAccount => activeChild != null;
  List<FamilyChild> get children => List.unmodifiable(_children);
  List<FamilyChallenge> get challenges => List.unmodifiable(_challenges);
  FamilyChild? get activeChild {
    if (_activeChildId == null) return null;
    for (final child in _children) {
      if (child.id == _activeChildId) return child;
    }
    return null;
  }

  Set<String> get unlockedKidBadges => Set.unmodifiable(_unlockedKidBadges);
  String? get featuredKidBadge => _featuredKidBadge;
  String get phoneNumber =>
      isKidAccount ? 'Managed by parent' : '(713) 555-0100';
  String get accountId => activeChild?.id ?? 'parent';

  void configureParent({
    required String name,
    required BushelRole role,
    required bool family,
  }) {
    _parentName = name;
    _parentRole = role == BushelRole.kid ? BushelRole.volunteer : role;
    _familyAccount = family;
    _activeChildId = null;
    notifyListeners();
  }

  void setRole(BushelRole role) {
    if (role == BushelRole.kid) return;
    _parentRole = role;
    _activeChildId = null;
    notifyListeners();
  }

  void addChild(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _familyAccount = true;
    _children.add(
      FamilyChild(id: 'child-${_children.length + 1}', name: trimmed),
    );
    notifyListeners();
  }

  void switchToChild(String id) {
    if (!_children.any((child) => child.id == id)) return;
    _activeChildId = id;
    notifyListeners();
  }

  void switchToParent() {
    _activeChildId = null;
    notifyListeners();
  }

  void addChallenge(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _challenges.add(
      FamilyChallenge(
        id: 'custom-${_challenges.length + 1}',
        title: trimmed,
        emoji: '⭐',
      ),
    );
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
