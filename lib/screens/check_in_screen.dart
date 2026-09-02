import 'package:flutter/material.dart';

import '../data/shift_store.dart';
import '../widgets/bushel_navigation_bar.dart';
import 'shifts_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _store = ShiftStore.instance;
  ShiftListing? _selectedShift;
  bool _scanned = false;

  List<ShiftListing> get _eligibleShifts => _store.myShifts
      .where((listing) => !_store.isCheckedIn(listing.shift))
      .toList();

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    if (_eligibleShifts.isNotEmpty) _selectedShift = _eligibleShifts.first;
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _simulateScan() {
    if (_selectedShift == null) return;
    setState(() => _scanned = true);
  }

  Future<void> _confirmCheckIn() async {
    final listing = _selectedShift;
    if (listing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm check-in?'),
        content: Text(
          '${listing.shift.title}\n${listing.foodBank.shortName}\nStation: ${listing.shift.station}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Check in'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _store.checkIn(listing.shift);
    if (!mounted) return;
    setState(() {
      _scanned = false;
      _selectedShift = _eligibleShifts.isEmpty ? null : _eligibleShifts.first;
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Color(0xFF20B85A),
          size: 58,
        ),
        title: const Text('You’re checked in!'),
        content: const Text(
          'Your shift is marked complete and you earned 100 points.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station check-in'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.stars, size: 17),
              label: Text('${_store.points} pts'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            children: [
              const Text(
                'Scan your station code',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the QR code posted at your volunteer station.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF718078), fontSize: 15),
              ),
              const SizedBox(height: 24),
              _ScannerFrame(scanned: _scanned),
              const SizedBox(height: 24),
              if (_eligibleShifts.isEmpty)
                _NoEligibleShift(
                  onFindShift: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShiftsScreen(),
                    ),
                  ),
                )
              else ...[
                DropdownButtonFormField<ShiftListing>(
                  isExpanded: true,
                  initialValue: _selectedShift,
                  decoration: const InputDecoration(
                    labelText: 'Shift to check in',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: [
                    for (final listing in _eligibleShifts)
                      DropdownMenuItem(
                        value: listing,
                        child: Text(
                          '${listing.shift.title} · ${listing.shift.station}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _selectedShift = value;
                    _scanned = false;
                  }),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const ValueKey('simulate-scan'),
                  onPressed: _scanned ? _confirmCheckIn : _simulateScan,
                  icon: Icon(_scanned ? Icons.check : Icons.qr_code_scanner),
                  label: Text(
                    _scanned ? 'Confirm station check-in' : 'Simulate QR scan',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _scanned
                      ? 'Station matched: ${_selectedShift!.shift.station}'
                      : 'Camera scanning will be added later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _scanned
                        ? const Color(0xFF168845)
                        : const Color(0xFF718078),
                    fontWeight: _scanned ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 2),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame({required this.scanned});

  final bool scanned;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 260,
      decoration: BoxDecoration(
        color: scanned ? const Color(0xFFE7F8EC) : const Color(0xFF10291D),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: Container(
          width: 176,
          height: 176,
          decoration: BoxDecoration(
            border: Border.all(
              color: scanned ? const Color(0xFF20B85A) : Colors.white,
              width: 4,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            scanned ? Icons.check_circle : Icons.qr_code_2,
            color: scanned ? const Color(0xFF20B85A) : Colors.white,
            size: 108,
          ),
        ),
      ),
    );
  }
}

class _NoEligibleShift extends StatelessWidget {
  const _NoEligibleShift({required this.onFindShift});

  final VoidCallback onFindShift;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Text(
              'Sign up for a shift first',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            const Text(
              'Your upcoming shifts will become available for station check-in.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onFindShift,
              child: const Text('Find a shift'),
            ),
          ],
        ),
      ),
    );
  }
}
