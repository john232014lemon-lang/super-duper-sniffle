import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class FoodBankShift {
  const FoodBankShift({
    required this.title,
    required this.scheduledDate,
    required this.time,
    required this.station,
    required this.spotsLeft,
  });

  final String title;
  final DateTime scheduledDate;
  String get date {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[scheduledDate.weekday - 1]}, ${months[scheduledDate.month - 1]} ${scheduledDate.day}';
  }

  final String time;
  final String station;
  final int spotsLeft;
}

class FoodBank {
  const FoodBank({
    required this.name,
    required this.shortName,
    required this.description,
    required this.address,
    required this.hours,
    required this.distance,
    required this.location,
    required this.accent,
    required this.icon,
    required this.shifts,
  });

  final String name;
  final String shortName;
  final String description;
  final String address;
  final String hours;
  final String distance;
  final LatLng location;
  final Color accent;
  final IconData icon;
  final List<FoodBankShift> shifts;
}
