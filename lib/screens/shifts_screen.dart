import 'package:flutter/material.dart';

import '../data/shift_store.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final _store = ShiftStore.instance;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
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
    final shifts = _tab == 0 ? _store.available : _store.myShifts;
    return Scaffold(
      appBar: AppBar(title: const Text('Shifts')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              const Text(
                'June 2026 · find your slot',
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
              const _MockDateStrip(),
              const SizedBox(height: 24),
              Text(
                _tab == 0 ? 'Available times' : 'Your upcoming shifts',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (shifts.isEmpty)
                const _EmptyShifts()
              else
                ...shifts.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(
                      listing: listing,
                      signedUp: _store.isSignedUp(listing.shift),
                      showSignup: _tab == 0,
                      onSignup: () => _confirmSignup(listing),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockDateStrip extends StatelessWidget {
  const _MockDateStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _DateTile(day: 'THU', date: '18'),
        SizedBox(width: 8),
        _DateTile(day: 'FRI', date: '19'),
        SizedBox(width: 8),
        _DateTile(day: 'SAT', date: '20', selected: true),
        SizedBox(width: 8),
        _DateTile(day: 'SUN', date: '21'),
        SizedBox(width: 8),
        _DateTile(day: 'MON', date: '22'),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.day,
    required this.date,
    this.selected = false,
  });

  final String day;
  final String date;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF18A94F) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE1E8E2)),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF718078),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              date,
              style: TextStyle(
                color: selected ? Colors.white : null,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.listing,
    required this.signedUp,
    required this.showSignup,
    required this.onSignup,
  });

  final ShiftListing listing;
  final bool signedUp;
  final bool showSignup;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    final shift = listing.shift;
    return Card(
      margin: EdgeInsets.zero,
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
                    '${shift.spotsLeft} slots',
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
    );
  }
}

class _EmptyShifts extends StatelessWidget {
  const _EmptyShifts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 48,
            color: Color(0xFF91A098),
          ),
          SizedBox(height: 12),
          Text('No shifts yet', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 4),
          Text('Sign up for an available time to see it here.'),
        ],
      ),
    );
  }
}
