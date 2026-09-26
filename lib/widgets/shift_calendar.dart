import 'package:flutter/material.dart';

/// A month calendar with markers for dates containing shifts in the active tab.
class ShiftCalendar extends StatelessWidget {
  const ShiftCalendar({
    super.key,
    required this.selectedDate,
    required this.shiftDates,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final Iterable<DateTime> shiftDates;
  final ValueChanged<DateTime> onSelected;

  void _moveMonth(int offset) {
    final first = DateTime(selectedDate.year, selectedDate.month + offset);
    final lastDay = DateTime(first.year, first.month + 1, 0).day;
    onSelected(
      DateTime(
        first.year,
        first.month,
        selectedDate.day > lastDay ? lastDay : selectedDate.day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(selectedDate.year, selectedDate.month);
    final days = DateTime(first.year, first.month + 1, 0).day;
    final offset = first.weekday - 1;
    final rows = ((offset + days) / 7).ceil();
    final localizations = MaterialLocalizations.of(context);
    final markedDays = shiftDates
        .where((date) => date.year == first.year && date.month == first.month)
        .map((date) => date.day)
        .toSet();
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: first.year == 2000 && first.month == 1
                  ? null
                  : () => _moveMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                localizations.formatMonthYear(first),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: first.year == 2100 && first.month == 12
                  ? null
                  : () => _moveMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final day in const [
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun',
            ])
              Expanded(
                child: Center(
                  child: Text(day, style: const TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = row * 7 + column - offset + 1;
                      if (day < 1 || day > days) {
                        return const SizedBox(height: 48);
                      }
                      final date = DateTime(first.year, first.month, day);
                      final selected = day == selectedDate.day;
                      final hasShifts = markedDays.contains(day);
                      return Semantics(
                        selected: selected,
                        button: true,
                        label:
                            '${localizations.formatFullDate(date)}${hasShifts ? ', has shifts' : ''}',
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Material(
                              color: selected
                                  ? const Color(0xFF12813E)
                                  : const Color(0xFFF0F6F1),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                key: ValueKey(
                                  'calendar-${date.toIso8601String().substring(0, 10)}',
                                ),
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => onSelected(date),
                                child: SizedBox(
                                  height: 44,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$day',
                                        style: TextStyle(
                                          color: selected ? Colors.white : null,
                                          fontWeight: selected
                                              ? FontWeight.w900
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: hasShifts
                                              ? (selected
                                                    ? Colors.white
                                                    : const Color(0xFF12813E))
                                              : Colors.transparent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('• Dates with shifts', style: TextStyle(fontSize: 12)),
            TextButton(
              onPressed: () => onSelected(DateUtils.dateOnly(DateTime.now())),
              child: const Text('Today'),
            ),
          ],
        ),
      ],
    );
  }
}
