/// Scheduling uses the device's local time, at minute precision.
class ShiftSchedule {
  static int? minutes(String value) {
    final match = RegExp(
      r'^(0?[1-9]|1[0-9]|2[0-3]):([0-5][0-9])$',
    ).firstMatch(value.trim());
    if (value.trim() == '24:00') return 1440;
    if (match == null) return null;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }

  static String normalize(String value) {
    final count = minutes(value)!;
    return '${(count ~/ 60).toString().padLeft(2, '0')}:${(count % 60).toString().padLeft(2, '0')}';
  }

  static DateTime start(DateTime date, String time) {
    final count = minutes(time)!;
    return DateTime(date.year, date.month, date.day, count ~/ 60, count % 60);
  }

  static String? validate(DateTime date, String time, {DateTime? now}) {
    if (minutes(time) == null) {
      return 'Enter a time from 01:00 to 24:00 (HH:mm).';
    }
    final clock = now ?? DateTime.now();
    final currentMinute = DateTime(
      clock.year,
      clock.month,
      clock.day,
      clock.hour,
      clock.minute,
    );
    final scheduled = start(date, time);
    if (scheduled.isBefore(currentMinute) ||
        scheduled.isAfter(currentMinute.add(const Duration(days: 365)))) {
      return 'Choose the current time or a future time within 365 days.';
    }
    // Do not silently shift nonexistent local times across a daylight-saving gap.
    final count = minutes(time)!;
    if (count != 1440 &&
        (scheduled.hour != count ~/ 60 || scheduled.minute != count % 60)) {
      return 'This local time is unavailable. Choose another time.';
    }
    return null;
  }
}
