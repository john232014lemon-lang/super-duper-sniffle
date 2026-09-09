import 'package:flutter/foundation.dart';

import '../models/group_member.dart';
import 'session_store.dart';

class CoordinatorStore extends ChangeNotifier {
  CoordinatorStore._();

  static final CoordinatorStore instance = CoordinatorStore._();
  static const ShiftGroup sharedShiftGroup = ShiftGroup(
    id: 'sorting-packing-jun-20',
    shiftTitle: 'Sorting & Packing Line',
    foodBankName: 'Second Harvest Food Bank',
    date: 'Sat, Jun 20',
    time: '9:00–12:00 AM',
    station: 'Warehouse A',
  );

  final List<GroupMember> _members = [
    const GroupMember(
      id: 'johnny',
      name: 'Sir Johnny John Jimmy',
      phoneNumber: '(713) 555-0142',
      role: 'Coordinator',
      shiftsCompleted: 12,
      voteCount: 0,
    ),
    const GroupMember(
      id: 'jimbo',
      name: 'Lil Jimbo',
      phoneNumber: '(832) 555-0188',
      role: 'Kid',
      shiftsCompleted: 8,
      voteCount: 0,
    ),
    const GroupMember(
      id: 'jimmerson',
      name: 'Jimmerson Jimmies',
      phoneNumber: '(281) 555-0164',
      role: 'Volunteer',
      shiftsCompleted: 17,
      voteCount: 0,
    ),
  ];
  final Map<String, Set<String>> _votersByTarget = {};

  List<GroupMember> get members => List.unmodifiable(_members);
  int get votesNeeded => (_members.length * 2 / 3).ceil();
  bool containsAccount(String id) => _members.any((member) => member.id == id);
  bool get currentAccountIsMember =>
      containsAccount(SessionStore.instance.accountId);
  bool hasVotedFor(String id) =>
      _votersByTarget[id]?.contains(SessionStore.instance.accountId) ?? false;
  bool canVoteFor(String id) =>
      currentAccountIsMember &&
      id != SessionStore.instance.accountId &&
      !hasVotedFor(id);

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
      notifyListeners();
      return true;
    }
    _members[index] = updated;
    notifyListeners();
    return false;
  }
}
