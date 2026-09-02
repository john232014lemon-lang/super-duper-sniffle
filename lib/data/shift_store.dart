import 'package:flutter/foundation.dart';

import '../data/mock_food_banks.dart';
import '../models/food_bank.dart';

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
    _myShifts.add(_available.first);
  }

  static final ShiftStore instance = ShiftStore._();

  final List<ShiftListing> _available;
  final List<ShiftListing> _myShifts = [];
  final Set<FoodBankShift> _completedShifts = {};
  int _points = 0;

  List<ShiftListing> get available => List.unmodifiable(_available);
  List<ShiftListing> get myShifts => List.unmodifiable(_myShifts);
  int get points => _points;

  bool isSignedUp(FoodBankShift shift) =>
      _myShifts.any((listing) => identical(listing.shift, shift));

  bool isCheckedIn(FoodBankShift shift) => _completedShifts.contains(shift);

  void addAvailable(FoodBank bank, FoodBankShift shift) {
    _available.add(ShiftListing(foodBank: bank, shift: shift));
    notifyListeners();
  }

  void signUp(FoodBank bank, FoodBankShift shift) {
    if (isSignedUp(shift)) return;
    _myShifts.add(ShiftListing(foodBank: bank, shift: shift));
    notifyListeners();
  }

  bool checkIn(FoodBankShift shift) {
    if (!isSignedUp(shift) || isCheckedIn(shift)) return false;
    _completedShifts.add(shift);
    _points += 100;
    notifyListeners();
    return true;
  }
}
