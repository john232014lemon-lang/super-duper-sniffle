import 'package:flutter/foundation.dart';

import '../models/group_member.dart';
import 'session_store.dart';
import 'mock_food_banks.dart';
import 'shift_store.dart';

class CoordinatorStore extends ChangeNotifier {
  CoordinatorStore._();

  static final CoordinatorStore instance = CoordinatorStore._();

  void reset() {
    _members
      ..clear()
      ..addAll(CoordinatorStore._()._members);
    _votersByTarget.clear();
    notifyListeners();
  }

  static final ShiftGroup sharedShiftGroup = ShiftGroup(
    id: 'sorting-packing-jun-20',
    shiftTitle: 'Sorting & Packing Line',
    foodBankName: 'Second Harvest Food Bank',
    date: mockFoodBanks.first.shifts.first.date,
    time: mockFoodBanks.first.shifts.first.time,
    station: 'Warehouse A',
  );

  final List<GroupMember> _members = [
    const GroupMember(
      id: 'parent',
      name: 'Maya',
      phoneNumber: '(713) 555-0142',
      role: 'Coordinator',
      shiftsCompleted: 12,
      voteCount: 0,
    ),
    const GroupMember(
      id: 'riley',
      name: 'Riley Chen',
      phoneNumber: '(832) 555-0188',
      role: 'Volunteer',
      shiftsCompleted: 8,
      voteCount: 0,
    ),
    const GroupMember(
      id: 'sam',
      name: 'Sam Patel',
      phoneNumber: '(281) 555-0164',
      role: 'Volunteer',
      shiftsCompleted: 17,
      voteCount: 0,
    ),
  ];
  final Map<String, Set<String>> _votersByTarget = {};

  List<GroupMember> get members => List.unmodifiable(_members);
  int get votesNeeded =>
      (_members.where((member) => member.role != 'Kid').length * 2 / 3).ceil();
  bool containsAccount(String id) => _members.any((member) => member.id == id);
  bool get currentAccountIsMember =>
      containsAccount(SessionStore.instance.accountId);
  bool hasVotedFor(String id) =>
      _votersByTarget[id]?.contains(SessionStore.instance.accountId) ?? false;
  bool canVoteFor(String id) =>
      currentAccountIsMember &&
      !SessionStore.instance.isKidAccount &&
      _members.any((member) => member.id == id && member.role != 'Kid') &&
      id != SessionStore.instance.accountId &&
      !hasVotedFor(id);

  void configureParent(String name, BushelRole role) {
    final index = _members.indexWhere((member) => member.id == 'parent');
    final updated = GroupMember(
      id: 'parent',
      name: name,
      phoneNumber: '(713) 555-0100',
      role: role == BushelRole.coordinator ? 'Coordinator' : 'Volunteer',
      shiftsCompleted: 1,
      voteCount: index < 0 ? 0 : _members[index].voteCount,
    );
    if (index < 0) {
      _members.insert(0, updated);
    } else {
      _members[index] = updated;
    }
    notifyListeners();
  }

  void addFamilyChild(FamilyChild child) {
    if (containsAccount(child.id)) return;
    _members.add(
      GroupMember(
        id: child.id,
        name: child.name,
        phoneNumber: 'Managed by parent',
        role: 'Kid',
        shiftsCompleted: 0,
        voteCount: 0,
      ),
    );
    notifyListeners();
  }

  bool voteToRemove(String id) {
    final voterId = SessionStore.instance.accountId;
    if (!canVoteFor(id)) return false;
    final index = _members.indexWhere((member) => member.id == id);
    if (index < 0) return false;
    (_votersByTarget[id] ??= {}).add(voterId);
    final updated = _members[index].copyWith(
      voteCount: _members[index].voteCount + 1,
    );
    if (updated.voteCount >= votesNeeded) {
      _members.removeAt(index);
      if (id == 'parent') {
        final children = SessionStore.instance.children
            .map((child) => child.id)
            .toSet();
        _members.removeWhere((member) => children.contains(member.id));
      }
      ShiftStore.instance.revokeDemoFamily(
        mockFoodBanks.first.shifts.first,
        id,
      );
      notifyListeners();
      return true;
    }
    _members[index] = updated;
    notifyListeners();
    return false;
  }
}
