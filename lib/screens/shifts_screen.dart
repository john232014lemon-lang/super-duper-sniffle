import 'package:flutter/material.dart';

import '../data/shift_store.dart';
import '../data/coordinator_store.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../widgets/shift_calendar.dart';
import 'coordinator_screen.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final _store = ShiftStore.instance;
  int _tab = 0;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _store.addListener(_refresh);
    CoordinatorStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    CoordinatorStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _confirmSignup(ShiftListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm this shift?'),
        content: Text(
          '${listing.shift.title}\n${listing.shift.date} · ${listing.shift.time}\n${listing.foodBank.shortName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm signup'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _store.signUp(listing.foodBank, listing.shift);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Shift added to My shifts.')));
  }

  @override
  Widget build(BuildContext context) {
    final allShifts = _tab == 0 ? _store.available : _store.myShifts;
    final shifts = allShifts
        .where(
          (listing) =>
              DateUtils.isSameDay(listing.shift.scheduledDate, _selectedDate),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Shifts')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              const Text(
                'Find a day to lend a hand',
                style: TextStyle(color: Color(0xFF718078)),
              ),
              const SizedBox(height: 18),
              SegmentedButton<int>(
                segments: [
                  const ButtonSegment(value: 0, label: Text('Available')),
                  ButtonSegment(
                    value: 1,
                    label: Text('My shifts · ${_store.myShifts.length}'),
                  ),
                ],
                selected: {_tab},
                showSelectedIcon: false,
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
              const SizedBox(height: 18),
              ShiftCalendar(
                selectedDate: _selectedDate,
                shiftDates: allShifts.map(
                  (listing) => listing.shift.scheduledDate,
                ),
                onSelected: (date) => setState(() => _selectedDate = date),
              ),
              const SizedBox(height: 24),
              Text(
                _tab == 0 ? 'Available times' : 'Your upcoming shifts',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                MaterialLocalizations.of(context).formatFullDate(_selectedDate),
              ),
              const SizedBox(height: 12),
              if (shifts.isEmpty)
                _EmptyShifts(myShifts: _tab == 1)
              else
                ...shifts.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(
                      listing: listing,
                      signedUp: _store.isSignedUp(listing.shift),
                      checkedIn: _store.isCheckedIn(listing.shift),
                      showSignup: _tab == 0,
                      onSignup: () => _confirmSignup(listing),
                      onOpenGroup: _tab == 1
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const GroupDetailScreen(),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 3),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.listing,
    required this.signedUp,
    required this.checkedIn,
    required this.showSignup,
    required this.onSignup,
    this.onOpenGroup,
  });

  final ShiftListing listing;
  final bool signedUp;
  final bool checkedIn;
  final bool showSignup;
  final VoidCallback onSignup;
  final VoidCallback? onOpenGroup;

  @override
  Widget build(BuildContext context) {
    final shift = listing.shift;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: onOpenGroup == null ? null : const ValueKey('open-my-shift-group'),
        onTap: onOpenGroup,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.time.split('–').first,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          shift.date,
                          style: const TextStyle(
                            color: Color(0xFF718078),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${listing.foodBank.shortName} · ${shift.station}',
                          style: const TextStyle(
                            color: Color(0xFF718078),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F7EC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      checkedIn ? 'Complete' : '${shift.spotsLeft} slots',
                      style: const TextStyle(
                        color: Color(0xFF12813E),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (showSignup) ...[
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: ValueKey('signup-${shift.title}'),
                    onPressed: signedUp ? null : onSignup,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(110, 44),
                    ),
                    child: Text(signedUp ? 'Signed up' : 'Sign up'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyShifts extends StatelessWidget {
  const _EmptyShifts({required this.myShifts});
  final bool myShifts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_month_outlined,
            size: 48,
            color: Color(0xFF91A098),
          ),
          const SizedBox(height: 12),
          Text(
            myShifts ? 'No signups for this day' : 'No shifts on this day',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            myShifts
                ? 'Choose Available to find a shift to join.'
                : 'Try another date.',
          ),
        ],
      ),
    );
  }
}
