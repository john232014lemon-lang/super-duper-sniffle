import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/food_bank.dart';

const mockFoodBanks = <FoodBank>[
  FoodBank(
    name: 'Second Harvest Food Bank',
    shortName: 'Second Harvest',
    description:
        'Second Harvest connects neighbors with nutritious groceries while building a hunger-free community across Silicon Valley.',
    address: '4001 North First Street, San Jose',
    hours: 'Mon–Sat · 8:00 AM–5:00 PM',
    distance: '0.8 mi',
    location: LatLng(29.7607, -95.3695),
    accent: Color(0xFFEF5269),
    icon: Icons.inventory_2_outlined,
    shifts: [
      FoodBankShift(
        title: 'Sorting & Packing Line',
        date: 'Sat, Jun 20',
        time: '9:00 AM–12:00 PM',
        station: 'Warehouse A',
        spotsLeft: 6,
      ),
      FoodBankShift(
        title: 'Delivery Drivers',
        date: 'Sat, Jun 20',
        time: '2:00–4:00 PM',
        station: 'Loading Bay',
        spotsLeft: 3,
      ),
      FoodBankShift(
        title: 'Family Grocery Packing',
        date: 'Sun, Jun 21',
        time: '10:00 AM–12:00 PM',
        station: 'Community Room',
        spotsLeft: 9,
      ),
    ],
  ),
  FoodBank(
    name: 'Loaves & Fishes Family Kitchen',
    shortName: 'Loaves & Fishes',
    description:
        'Loaves & Fishes serves hot, nutritious meals and essential groceries with dignity to families, seniors, and unhoused neighbors.',
    address: '1500 Berger Drive, San Jose',
    hours: 'Mon–Fri · 9:00 AM–6:00 PM',
    distance: '1.4 mi',
    location: LatLng(29.7497, -95.3584),
    accent: Color(0xFF23B65E),
    icon: Icons.groups_outlined,
    shifts: [
      FoodBankShift(
        title: 'Produce Sorting',
        date: 'Today',
        time: '3:00–5:00 PM',
        station: 'Produce Station',
        spotsLeft: 3,
      ),
      FoodBankShift(
        title: 'Dinner Service',
        date: 'Tomorrow',
        time: '4:30–7:00 PM',
        station: 'Family Kitchen',
        spotsLeft: 5,
      ),
    ],
  ),
  FoodBank(
    name: 'Martha’s Kitchen',
    shortName: 'Martha’s Kitchen',
    description:
        'Martha’s Kitchen provides meals, mobile food distribution, and welcoming volunteer programs for communities throughout Santa Clara County.',
    address: '311 Willow Street, San Jose',
    hours: 'Tue–Sat · 10:00 AM–7:00 PM',
    distance: '2.1 mi',
    location: LatLng(29.7714, -95.3901),
    accent: Color(0xFF2D8FC7),
    icon: Icons.soup_kitchen_outlined,
    shifts: [
      FoodBankShift(
        title: 'Meal Prep Crew',
        date: 'Fri, Jun 19',
        time: '1:00–3:30 PM',
        station: 'Main Kitchen',
        spotsLeft: 4,
      ),
      FoodBankShift(
        title: 'Community Meal Service',
        date: 'Fri, Jun 19',
        time: '4:00–6:30 PM',
        station: 'Dining Hall',
        spotsLeft: 7,
      ),
    ],
  ),
];
