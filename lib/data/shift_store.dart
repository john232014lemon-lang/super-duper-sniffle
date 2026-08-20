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
      ];

  static final ShiftStore instance = ShiftStore._();

  final List<ShiftListing> _available;
  final List<ShiftListing> _myShifts = [];

  List<ShiftListing> get available => List.unmodifiable(_available);
  List<ShiftListing> get myShifts => List.unmodifiable(_myShifts);

  bool isSignedUp(FoodBankShift shift) =>
      _myShifts.any((listing) => identical(listing.shift, shift));

  void addAvailable(FoodBank bank, FoodBankShift shift) {
    _available.add(ShiftListing(foodBank: bank, shift: shift));
    notifyListeners();
  }

  void signUp(FoodBank bank, FoodBankShift shift) {
    if (isSignedUp(shift)) return;
    _myShifts.add(ShiftListing(foodBank: bank, shift: shift));
    notifyListeners();
  }
}
