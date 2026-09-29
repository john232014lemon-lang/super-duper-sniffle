import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food_bank.dart';
import '../services/catalog_repository.dart';
import 'session_store.dart';
import '../services/community_models.dart';
import '../models/attendance.dart';

class CatalogStore extends ChangeNotifier {
  CatalogStore({required this.uid, required this.repository}) {
    SessionStore.instance.applyFamily(const FamilyData());
    retry();
  }
  final String uid;
  final CatalogRepository repository;
  List<FoodBank> banks = [];
  List<StoredShift> shifts = [];
  Set<String> signups = {};
  Set<String> coordinatorBanks = {};
  Map<String, String> applications = {};
  Map<String, Set<String>> childSignups = {};
  FamilyData family = const FamilyData();
  List<AttendanceEntry> attendance = [];
  Map<String, String> featuredBadges = {};
  AttendanceRewards get rewards => AttendanceRewards(attendance);
  bool get attendanceLoading => _loading.contains('attendance');
  bool get attendanceFailed => _errors.contains('attendance');
  bool get rewardsLoading => attendanceLoading || _loading.contains('badges');
  bool get rewardsFailed => attendanceFailed || _errors.contains('badges');
  void _refreshBadges() => SessionStore.instance.applyRewards({
    for (final id in attendance.map((e) => e.participantId).toSet())
      id: rewards.badges(id),
  }, featuredBadges);
  bool get familyLoading => _loading.contains('family');
  bool get familyFailed => _errors.contains('family');
  bool get applicationsLoading => _loading.contains('applications');
  bool get applicationsFailed => _errors.contains('applications');
  final Set<String> _loading = {};
  final Set<String> _errors = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final Set<String> busy = {};
  bool _disposed = false;
  int _generation = 0;
  bool get banksLoading => _loading.contains('banks');
  bool get banksFailed => _errors.contains('banks');
  bool get shiftsLoading => _loading.any(
    (key) => ['banks', 'shifts', 'signups', 'children'].contains(key),
  );
  bool get shiftsFailed => _errors.any(
    (key) => ['banks', 'shifts', 'signups', 'children'].contains(key),
  );
  bool get accessFailed => _errors.contains('access');

  void retry() {
    final generation = ++_generation;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _errors.clear();
    _loading.clear();
    _loading.addAll([
      'banks',
      'shifts',
      'signups',
      'access',
      'applications',
      'family',
      'children',
      'attendance',
      'badges',
    ]);
    banks = [];
    shifts = [];
    signups = {};
    coordinatorBanks = {};
    applications = {};
    childSignups = {};
    attendance = [];
    featuredBadges = {};
    _refreshBadges();
    void listen<T>(String key, Stream<T> stream, void Function(T) accept) {
      _subscriptions.add(
        stream.listen(
          (value) {
            if (_disposed || generation != _generation) return;
            accept(value);
            _loading.remove(key);
            _errors.remove(key);
            notifyListeners();
          },
          onError: (Object error) {
            if (_disposed || generation != _generation) return;
            _loading.remove(key);
            _errors.add(key);
            if (key == 'access') coordinatorBanks = {};
            if (key == 'attendance') attendance = [];
            if (key == 'badges') featuredBadges = {};
            if (key == 'attendance' || key == 'badges') _refreshBadges();
            notifyListeners();
          },
        ),
      );
    }

    listen('banks', repository.watchBanks(), (value) => banks = value);
    listen('attendance', repository.watchAttendance(uid), (value) {
      attendance = value;
      _refreshBadges();
    });
    listen('badges', repository.watchFeaturedBadges(uid), (value) {
      featuredBadges = value;
      _refreshBadges();
    });
    listen('shifts', repository.watchShifts(), (value) => shifts = value);
    listen('signups', repository.watchSignups(uid), (value) => signups = value);
    listen(
      'applications',
      repository.watchApplications(uid),
      (value) => applications = value,
    );
    listen(
      'children',
      repository.watchChildSignups(uid),
      (value) => childSignups = value,
    );
    listen('family', repository.watchFamily(uid), (value) {
      family = value;
      SessionStore.instance.applyFamily(value);
    });
    listen(
      'access',
      repository.watchCoordinatorBanks(uid),
      (value) => coordinatorBanks = value,
    );
    notifyListeners();
  }

  Future<void> changeSignup(FoodBankShift shift, bool join) async {
    if (SessionStore.instance.isKidAccount) {
      throw const CatalogException(
        'Ask your parent to manage your shifts in Family Center.',
      );
    }
    final id = shift.id!;
    if (_disposed || busy.contains(id)) return;
    if (shiftsLoading || shiftsFailed) {
      throw const CatalogException('Refresh shifts before trying again.');
    }
    busy.add(id);
    notifyListeners();
    try {
      await repository.setSignup(uid, id, join);
    } finally {
      busy.remove(id);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

class CatalogScope extends InheritedNotifier<CatalogStore> {
  const CatalogScope({
    super.key,
    required CatalogStore store,
    required super.child,
  }) : super(notifier: store);
  static CatalogStore? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CatalogScope>();
    return scope?.notifier;
  }
}

class CatalogStatus extends StatelessWidget {
  const CatalogStatus({super.key, required this.store, this.shifts = false});
  final CatalogStore store;
  final bool shifts;
  @override
  Widget build(BuildContext context) {
    final loading = shifts ? store.shiftsLoading : store.banksLoading;
    final failed = shifts ? store.shiftsFailed : store.banksFailed;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const CircularProgressIndicator()
          else if (failed) ...[
            Text(
              shifts ? 'Could not load shifts.' : 'Could not load food banks.',
            ),
            TextButton(onPressed: store.retry, child: const Text('Retry')),
          ] else
            Text(
              shifts
                  ? 'No shifts published yet.'
                  : 'No food banks published yet.',
            ),
        ],
      ),
    );
  }
}
