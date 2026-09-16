import 'package:flutter/foundation.dart';

import '../data/mock_food_banks.dart';
import '../models/food_bank.dart';
import 'coordinator_store.dart';
import 'session_store.dart';

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

  final List<ShiftListing> _available;
  final Map<String, List<ShiftListing>> _myShiftsByAccount = {};
  final Map<String, Set<FoodBankShift>> _completedByAccount = {};
  final Map<String, int> _pointsByAccount = {};
  final Map<FoodBankShift, String> _qrCodes = {};
  final Map<FoodBankShift, Map<String, AttendanceRecord>> _pendingAttendance =
      {};

  List<ShiftListing> get available => List.unmodifiable(_available);
  List<ShiftListing> get myShifts {
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

  int get points => _pointsByAccount[SessionStore.instance.accountId] ?? 0;

  bool isSignedUp(FoodBankShift shift) =>
      myShifts.any((listing) => identical(listing.shift, shift));

  bool isCheckedIn(FoodBankShift shift) =>
      _completedByAccount[SessionStore.instance.accountId]?.contains(shift) ??
      false;
  bool isAwaitingConfirmation(FoodBankShift shift) =>
      _pendingAttendance[shift]?.containsKey(SessionStore.instance.accountId) ??
      false;
  String? qrCodeFor(FoodBankShift shift) => _qrCodes[shift];
  List<AttendanceRecord> pendingAttendance(FoodBankShift shift) =>
      List.unmodifiable(_pendingAttendance[shift]?.values ?? const []);
  ShiftListing? listingFor(FoodBankShift shift) {
    for (final listing in _available) {
      if (identical(listing.shift, shift)) return listing;
    }
    return null;
  }

  bool canManageShift(FoodBankShift shift) {
    final listing = listingFor(shift);
    return listing != null &&
        SessionStore.instance.role == BushelRole.coordinator &&
        listing.leaderAccountId == SessionStore.instance.accountId;
  }

  String? generateQrCode(FoodBankShift shift) {
    if (!canManageShift(shift)) return null;
    final index = _available.indexWhere(
      (listing) => identical(listing.shift, shift),
    );
    final code = 'BUSHEL-SHIFT-${index + 1}-${shift.station.hashCode.abs()}';
    _qrCodes[shift] = code;
    notifyListeners();
    return code;
  }

  void addAvailable(FoodBank bank, FoodBankShift shift) {
    _available.add(
      ShiftListing(
        foodBank: bank,
        shift: shift,
        leaderAccountId: SessionStore.instance.accountId,
      ),
    );
    notifyListeners();
  }

  void signUp(FoodBank bank, FoodBankShift shift) {
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

  bool checkIn(FoodBankShift shift) {
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
    if (!canManageShift(shift)) return false;
    final record = _pendingAttendance[shift]?.remove(accountId);
    if (record == null) return false;
    (_completedByAccount[accountId] ??= {}).add(shift);
    _pointsByAccount[accountId] = (_pointsByAccount[accountId] ?? 0) + 100;
    notifyListeners();
    return true;
  }
}
