import 'package:flutter/foundation.dart';

import '../data/mock_food_banks.dart';
import '../models/food_bank.dart';
import 'coordinator_store.dart';
import 'session_store.dart';
import 'catalog_store.dart';
import '../services/catalog_repository.dart';

class ShiftListing {
  const ShiftListing({
    required this.foodBank,
    required this.shift,
    required this.leaderAccountId,
  });

  final FoodBank foodBank;
  final FoodBankShift shift;
  final String leaderAccountId;
}

class AttendanceRecord {
  const AttendanceRecord({required this.accountId, required this.name});
  final String accountId;
  final String name;
}

class ShiftStore extends ChangeNotifier {
  ShiftStore._()
    : _available = [
        for (final bank in mockFoodBanks)
          for (final shift in bank.shifts)
            ShiftListing(
              foodBank: bank,
              shift: shift,
              leaderAccountId: 'parent',
            ),
      ] {
    // The home dashboard presents this as the user's next confirmed shift.
  }

  static final ShiftStore instance = ShiftStore._();

  CatalogStore? _catalog;
  bool get usingLive => _catalog != null;
  void bindCatalog(CatalogStore store) {
    _catalog?.removeListener(notifyListeners);
    _catalog = store;
    store.addListener(notifyListeners);
  }

  void unbindCatalog(CatalogStore store) {
    store.removeListener(notifyListeners);
    if (identical(_catalog, store)) _catalog = null;
  }

  bool _sameShift(FoodBankShift a, FoodBankShift b) =>
      a.id != null && b.id != null ? a.id == b.id : identical(a, b);

  void reset() {
    _available
      ..clear()
      ..addAll(ShiftStore._()._available);
    _myShiftsByAccount.clear();
    _completedByAccount.clear();
    _pointsByAccount.clear();
    _qrCodes.clear();
    _pendingAttendance.clear();
    notifyListeners();
  }

  final List<ShiftListing> _available;
  final Map<String, List<ShiftListing>> _myShiftsByAccount = {};
  final Map<String, Set<FoodBankShift>> _completedByAccount = {};
  final Map<String, int> _pointsByAccount = {};
  final Map<FoodBankShift, String> _qrCodes = {};
  final Map<FoodBankShift, Map<String, AttendanceRecord>> _pendingAttendance =
      {};

  List<ShiftListing> get available {
    if (!usingLive) return List.unmodifiable(_available);
    final catalog = _catalog!;
    if (catalog.banksFailed || catalog.shiftsFailed || catalog.shiftsLoading) {
      return [];
    }
    final banks = {for (final bank in catalog.banks) bank.id: bank};
    return [
      for (final record in catalog.shifts)
        if (banks.containsKey(record.bankId))
          ShiftListing(
            foodBank: banks[record.bankId]!,
            shift: record.shift,
            leaderAccountId: record.creatorUid,
          ),
    ];
  }

  List<ShiftListing> get myShifts {
    if (usingLive) {
      return available
          .where(
            (listing) => SessionStore.instance.isKidAccount
                ? (_catalog!.childSignups[listing.shift.id]?.contains(
                        SessionStore.instance.accountId,
                      ) ??
                      false)
                : _catalog!.signups.contains(listing.shift.id),
          )
          .toList();
    }
    final accountId = SessionStore.instance.accountId;
    final shifts = _myShiftsByAccount.putIfAbsent(
      accountId,
      () => [_available.first],
    );
    return List.unmodifiable(
      shifts.where(
        (listing) =>
            !identical(listing.shift, _available.first.shift) ||
            CoordinatorStore.instance.containsAccount(accountId),
      ),
    );
  }

  int get points => usingLive
      ? _catalog!.rewards.points(SessionStore.instance.accountId)
      : _pointsByAccount[SessionStore.instance.accountId] ?? 0;

  bool isSignedUp(FoodBankShift shift) =>
      myShifts.any((listing) => _sameShift(listing.shift, shift));

  bool isCheckedIn(FoodBankShift shift) => usingLive
      ? _catalog!.attendance.any(
          (e) =>
              e.shiftId == shift.id &&
              e.participantId == SessionStore.instance.accountId &&
              e.confirmed,
        )
      : _completedByAccount[SessionStore.instance.accountId]?.contains(shift) ??
            false;
  bool isAwaitingConfirmation(FoodBankShift shift) => usingLive
      ? _catalog!.attendance.any(
          (e) =>
              e.shiftId == shift.id &&
              e.participantId == SessionStore.instance.accountId &&
              !e.confirmed,
        )
      : _pendingAttendance[shift]?.containsKey(
              SessionStore.instance.accountId,
            ) ??
            false;
  String? qrCodeFor(FoodBankShift shift) => usingLive
      ? _catalog!.shifts
            .where((e) => e.shift.id == shift.id)
            .firstOrNull
            ?.qrCode
      : _qrCodes[shift];
  List<AttendanceRecord> pendingAttendance(FoodBankShift shift) =>
      List.unmodifiable(_pendingAttendance[shift]?.values ?? const []);
  ShiftListing? listingFor(FoodBankShift shift) {
    for (final listing in available) {
      if (_sameShift(listing.shift, shift)) return listing;
    }
    return null;
  }

  bool canManageShift(FoodBankShift shift) {
    if (usingLive) {
      final listing = listingFor(shift);
      return !SessionStore.instance.isKidAccount &&
          listing?.leaderAccountId == _catalog!.uid &&
          _catalog!.coordinatorBanks.contains(listing?.foodBank.id);
    }
    final listing = listingFor(shift);
    return listing != null &&
        SessionStore.instance.role == BushelRole.coordinator &&
        listing.leaderAccountId == SessionStore.instance.accountId;
  }

  String? generateQrCode(FoodBankShift shift) {
    if (usingLive) return null;
    if (!canManageShift(shift)) return null;
    final index = _available.indexWhere(
      (listing) => identical(listing.shift, shift),
    );
    final code = 'BUSHEL-SHIFT-${index + 1}-${shift.station.hashCode.abs()}';
    _qrCodes[shift] = code;
    notifyListeners();
    return code;
  }

  Future<void> addAvailable(FoodBank bank, FoodBankShift shift) async {
    if (usingLive) {
      await _catalog!.repository.createShift(_catalog!.uid, bank.id!, shift);
      return;
    }
    _available.add(
      ShiftListing(
        foodBank: bank,
        shift: shift,
        leaderAccountId: SessionStore.instance.accountId,
      ),
    );
    notifyListeners();
  }

  Future<void> signUp(FoodBank bank, FoodBankShift shift) async {
    if (usingLive) {
      await _catalog!.changeSignup(shift, true);
      return;
    }
    if (isSignedUp(shift)) return;
    (_myShiftsByAccount[SessionStore.instance.accountId] ??= []).add(
      ShiftListing(
        foodBank: bank,
        shift: shift,
        leaderAccountId: listingFor(shift)?.leaderAccountId ?? 'parent',
      ),
    );
    notifyListeners();
  }

  Future<void> cancelSignup(FoodBankShift shift) async {
    if (usingLive) {
      await _catalog!.changeSignup(shift, false);
      return;
    }
    final account = SessionStore.instance.accountId;
    // Materialize the existing mock signup before removing it.
    myShifts;
    _myShiftsByAccount[account]?.removeWhere(
      (listing) => _sameShift(listing.shift, shift),
    );
    notifyListeners();
  }

  bool checkIn(FoodBankShift shift) {
    if (usingLive) return false;
    if (!isSignedUp(shift) ||
        isCheckedIn(shift) ||
        isAwaitingConfirmation(shift) ||
        qrCodeFor(shift) == null) {
      return false;
    }
    final accountId = SessionStore.instance.accountId;
    (_pendingAttendance[shift] ??= {})[accountId] = AttendanceRecord(
      accountId: accountId,
      name: SessionStore.instance.userName,
    );
    notifyListeners();
    return true;
  }

  bool confirmAttendance(FoodBankShift shift, String accountId) {
    if (usingLive) return false;
    if (!canManageShift(shift)) return false;
    final record = _pendingAttendance[shift]?.remove(accountId);
    if (record == null) return false;
    (_completedByAccount[accountId] ??= {}).add(shift);
    _pointsByAccount[accountId] = (_pointsByAccount[accountId] ?? 0) + 100;
    notifyListeners();
    return true;
  }

  Future<bool> submitCheckIn(FoodBankShift shift) async {
    if (!usingLive) return checkIn(shift);
    final catalog = _catalog!;
    if (catalog.attendanceLoading ||
        catalog.attendanceFailed ||
        catalog.shiftsLoading ||
        catalog.shiftsFailed) {
      throw const CatalogException(
        'Wait for your shifts and attendance to load, then retry.',
      );
    }
    final code = qrCodeFor(shift);
    if (!isSignedUp(shift) || code == null) {
      throw const CatalogException(
        'You need a current signup and a shift QR code.',
      );
    }
    await catalog.repository.submitAttendance(
      catalog.uid,
      SessionStore.instance.accountId,
      shift.id!,
      SessionStore.instance.userName,
      code,
    );
    return true;
  }
}
