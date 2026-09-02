import 'package:flutter/material.dart';

import '../data/shift_store.dart';
import '../data/session_store.dart';
import '../models/kid_badge.dart';
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
    KidBadge? earnedBadge;
    if (SessionStore.instance.role == BushelRole.kid && mounted) {
      earnedBadge = await _pickKidBadge();
    }
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
        content: Text(
          earnedBadge == null
              ? 'Your shift is marked complete and you earned 100 points.'
              : 'You earned 100 points and unlocked the ${earnedBadge.name} ${earnedBadge.emoji}',
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

  Future<KidBadge?> _pickKidBadge() async {
    final locked = kidBadges
        .where(
          (badge) =>
              !SessionStore.instance.unlockedKidBadges.contains(badge.id),
        )
        .toList();
    if (locked.isEmpty) return null;
    final badge = await showDialog<KidBadge>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pick a new badge! 🎉'),
        content: SizedBox(
          width: 520,
          height: 390,
          child: GridView.builder(
            itemCount: locked.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, index) {
              final option = locked[index];
              return Card(
                child: InkWell(
                  key: ValueKey('choose-${option.id}'),
                  onTap: () => Navigator.pop(context, option),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          option.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    if (badge != null) SessionStore.instance.unlockKidBadge(badge.id);
    return badge;
  }

  @override
  Widget build(BuildContext context) {
    final kidMode = SessionStore.instance.role == BushelRole.kid;
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
              Text(
                kidMode ? 'Ready, set, check in!' : 'Scan your station code',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                kidMode
                    ? 'Scan the code, help your team, then pick a badge!'
                    : 'Use the QR code posted at your volunteer station.',
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
                if (kidMode)
                  _KidShiftCard(listing: _selectedShift!)
                else
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
                SizedBox(
                  height: kidMode ? 70 : null,
                  child: FilledButton.icon(
                    key: const ValueKey('simulate-scan'),
                    onPressed: _scanned ? _confirmCheckIn : _simulateScan,
                    icon: Icon(_scanned ? Icons.check : Icons.qr_code_scanner),
                    label: Text(
                      _scanned
                          ? (kidMode
                                ? 'YES, CHECK ME IN!'
                                : 'Confirm station check-in')
                          : (kidMode ? 'PRETEND SCAN!' : 'Simulate QR scan'),
                    ),
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

class _KidShiftCard extends StatelessWidget {
  const _KidShiftCard({required this.listing});

  final ShiftListing listing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF4CE),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Text('📦', style: TextStyle(fontSize: 38)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.shift.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('Go to ${listing.shift.station}'),
                ],
              ),
            ),
          ],
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
