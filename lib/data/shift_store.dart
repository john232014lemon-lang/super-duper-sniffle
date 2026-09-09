import 'package:flutter/foundation.dart';

import '../data/mock_food_banks.dart';
import '../models/food_bank.dart';
import 'coordinator_store.dart';
import 'session_store.dart';

class ShiftListing {
  const ShiftListing({required this.foodBank, required this.shift});

  final FoodBank foodBank;
  final FoodBankShift shift;
}

class ShiftStore extends ChangeNotifier {
  ShiftStore._()
    : _available = [
        for (final bank in mockFoodBanks)
          for (final shift in bank.shifts)
            ShiftListing(foodBank: bank, shift: shift),
      ] {
    // The home dashboard presents this as the user's next confirmed shift.
    for (final accountId in ['johnny', 'jimbo', 'jimmerson']) {
      _myShiftsByAccount[accountId] = [_available.first];
    }
  }

  static final ShiftStore instance = ShiftStore._();

  final List<ShiftListing> _available;
  final Map<String, List<ShiftListing>> _myShiftsByAccount = {};
  final Map<String, Set<FoodBankShift>> _completedByAccount = {};
  final Map<String, int> _pointsByAccount = {};

  List<ShiftListing> get available => List.unmodifiable(_available);
  List<ShiftListing> get myShifts {
    final accountId = SessionStore.instance.accountId;
    final shifts = _myShiftsByAccount[accountId] ?? const [];
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

  void addAvailable(FoodBank bank, FoodBankShift shift) {
    _available.add(ShiftListing(foodBank: bank, shift: shift));
    notifyListeners();
  }

  void signUp(FoodBank bank, FoodBankShift shift) {
    if (isSignedUp(shift)) return;
    (_myShiftsByAccount[SessionStore.instance.accountId] ??= []).add(
      ShiftListing(foodBank: bank, shift: shift),
    );
    notifyListeners();
  }

  bool checkIn(FoodBankShift shift) {
    if (!isSignedUp(shift) || isCheckedIn(shift)) return false;
    final accountId = SessionStore.instance.accountId;
    (_completedByAccount[accountId] ??= {}).add(shift);
    _pointsByAccount[accountId] = (_pointsByAccount[accountId] ?? 0) + 100;
    notifyListeners();
    return true;
  }
}
