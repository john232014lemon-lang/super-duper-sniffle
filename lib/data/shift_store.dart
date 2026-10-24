import 'package:flutter/foundation.dart';
import '../demo_config.dart';

import '../data/mock_food_banks.dart';
import '../models/food_bank.dart';
import '../models/shift_schedule.dart';
import '../models/check_in_token.dart';
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
  bool get usingMockQr => mockQrMode && usingLive;
  bool lastCheckInConfirmed = false;
  void bindCatalog(CatalogStore store) {
    _qrCodes.clear();
    _catalog?.removeListener(notifyListeners);
    _catalog = store;
    store.addListener(notifyListeners);
  }

  void unbindCatalog(CatalogStore store) {
    _qrCodes.clear();
    store.removeListener(notifyListeners);
    if (identical(_catalog, store)) _catalog = null;
  }

  bool _sameShift(FoodBankShift a, FoodBankShift b) =>
      a.id != null && b.id != null ? a.id == b.id : identical(a, b);

  void reset() {
    lastCheckInConfirmed = false;
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
  final Map<FoodBankShift, CheckInToken> _qrCodes = {};
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
      () => SessionStore.instance.isKidAccount ? [] : [_available.first],
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
  String? qrCodeFor(FoodBankShift shift) =>
      canManageShift(shift) ? _qrCodes[shift]?.code : null;
  CheckInToken? leaderToken(FoodBankShift shift) =>
      canManageShift(shift) ? _qrCodes[shift] : null;
  String tokenShiftId(FoodBankShift shift) =>
      shift.id ??
      'demo-${_available.indexWhere((entry) => identical(entry.shift, shift))}';
  DateTime? tokenStart(FoodBankShift shift) =>
      shift.startsAt ??
      (ShiftSchedule.minutes(shift.time) == null
          ? null
          : ShiftSchedule.start(shift.scheduledDate, shift.time));
  bool hasAttendance(FoodBankShift shift, String participantId) => usingLive
      ? _catalog!.attendance.any(
          (entry) =>
              entry.shiftId == shift.id && entry.participantId == participantId,
        )
      : (_completedByAccount[participantId]?.contains(shift) ?? false) ||
            (_pendingAttendance[shift]?.containsKey(participantId) ?? false);
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
        !SessionStore.instance.isKidAccount &&
        SessionStore.instance.role == BushelRole.coordinator &&
        listing.leaderAccountId == SessionStore.instance.accountId;
  }

  String? generateQrCode(FoodBankShift shift) {
    if (usingLive) return null;
    if (!canManageShift(shift)) return null;
    final start = tokenStart(shift);
    if (start == null) {
      throw const CatalogException(
        'This shift needs a valid start time before generating a QR.',
      );
    }
    late CheckInToken token;
    try {
      token = CheckInToken.generate(tokenShiftId(shift), start);
    } on FormatException catch (error) {
      throw CatalogException(error.message);
    }
    _qrCodes[shift] = token;
    notifyListeners();
    return token.code;
  }

  Future<void> addAvailable(FoodBank bank, FoodBankShift shift) async {
    final error = ShiftSchedule.validate(shift.scheduledDate, shift.time);
    if (error != null) throw CatalogException(error);
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
    if (SessionStore.instance.isKidAccount) {
      throw const CatalogException('Ask your parent to manage shift bookings.');
    }
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
    if (SessionStore.instance.isKidAccount) {
      throw const CatalogException('Ask your parent to manage shift bookings.');
    }
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
    for (final child in SessionStore.instance.children) {
      _myShiftsByAccount[child.id]?.removeWhere(
        (listing) => _sameShift(listing.shift, shift),
      );
    }
    notifyListeners();
  }

  List<ShiftListing> shiftsForChild(String childId) => usingLive
      ? available
            .where(
              (listing) =>
                  _catalog!.childSignups[listing.shift.id]?.contains(childId) ??
                  false,
            )
            .toList()
      : List.unmodifiable(_myShiftsByAccount[childId] ?? []);

  Future<void> setChildBooking(
    ShiftListing listing,
    String childId,
    bool join,
  ) async {
    if (SessionStore.instance.isKidAccount) {
      throw const CatalogException('Ask your parent to manage shift bookings.');
    }
    if (!SessionStore.instance.children.any((child) => child.id == childId)) {
      throw const CatalogException('Child account not found.');
    }
    if (usingLive) {
      await _catalog!.repository.setChildSignup(
        _catalog!.uid,
        listing.shift.id!,
        childId,
        join,
      );
      return;
    }
    if (join && !isSignedUp(listing.shift)) {
      throw const CatalogException(
        'Sign yourself up before adding your child.',
      );
    }
    final bookings = _myShiftsByAccount.putIfAbsent(childId, () => []);
    if (join &&
        !bookings.any((entry) => _sameShift(entry.shift, listing.shift))) {
      bookings.add(listing);
    }
    if (!join) {
      bookings.removeWhere((entry) => _sameShift(entry.shift, listing.shift));
    }
    notifyListeners();
  }

  bool checkIn(
    FoodBankShift shift,
    String code, {
    String participantId = 'parent',
    String? name,
  }) {
    if (usingLive) return false;
    if (SessionStore.instance.isKidAccount) {
      throw const CatalogException('Ask your parent to check you in.');
    }
    if (!isSignedUp(shift) ||
        (participantId != 'parent' &&
            !shiftsForChild(
              participantId,
            ).any((entry) => _sameShift(entry.shift, shift)))) {
      throw const CatalogException(
        'You need a current booking for this participant.',
      );
    }
    if (hasAttendance(shift, participantId)) {
      throw const CatalogException(
        'This participant has already checked in for this shift.',
      );
    }
    final token = _qrCodes[shift];
    final start = tokenStart(shift);
    if (start == null) {
      throw const CatalogException('This shift is unavailable for check-in.');
    }
    final error = CheckInToken.validate(
      code,
      tokenShiftId(shift),
      token == null ? null : CheckInToken.verifier(token.code),
      token?.expiresAt,
      start,
    );
    if (error != null) throw CatalogException(error);
    final accountId = participantId;
    (_pendingAttendance[shift] ??= {})[accountId] = AttendanceRecord(
      accountId: accountId,
      name: name ?? SessionStore.instance.userName,
    );
    if (accountId == 'parent' && canManageShift(shift)) {
      lastCheckInConfirmed = confirmAttendance(shift, accountId);
    }
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

  void revokeDemoFamily(FoodBankShift shift, String accountId) {
    if (usingLive) return;
    final accounts = {
      accountId,
      if (accountId == 'parent')
        ...SessionStore.instance.children.map((child) => child.id),
    };
    for (final id in accounts) {
      _myShiftsByAccount[id]?.removeWhere(
        (listing) => _sameShift(listing.shift, shift),
      );
      _pendingAttendance[shift]?.remove(id);
      if (_completedByAccount[id]?.remove(shift) ?? false) {
        _pointsByAccount[id] = ((_pointsByAccount[id] ?? 0) - 100).clamp(
          0,
          1 << 30,
        );
      }
    }
    if (accountId == 'parent') SessionStore.instance.clearDemoBadges();
    notifyListeners();
  }

  Future<bool> submitCheckIn(
    FoodBankShift shift,
    String code, {
    String participantId = 'parent',
    String? name,
  }) async {
    lastCheckInConfirmed = false;
    if (usingMockQr &&
        (SessionStore.instance.role != BushelRole.volunteer ||
            participantId != 'parent')) {
      throw const CatalogException(
        'Mock QR codes are for adult volunteers only.',
      );
    }
    if (SessionStore.instance.isKidAccount) {
      throw const CatalogException('Ask your parent to check you in.');
    }
    if (!usingLive) {
      return checkIn(shift, code, participantId: participantId, name: name);
    }
    final catalog = _catalog!;
    if (catalog.attendanceLoading ||
        catalog.attendanceFailed ||
        catalog.shiftsLoading ||
        catalog.shiftsFailed) {
      throw const CatalogException(
        'Wait for your shifts and attendance to load, then retry.',
      );
    }
    if (!isSignedUp(shift) ||
        (participantId != 'parent' &&
            !(catalog.childSignups[shift.id]?.contains(participantId) ??
                false))) {
      throw const CatalogException(
        'You need a current booking for this participant.',
      );
    }
    lastCheckInConfirmed = await catalog.repository.submitAttendance(
      catalog.uid,
      participantId,
      shift.id!,
      name ?? SessionStore.instance.userName,
      code,
    );
    return true;
  }
}
