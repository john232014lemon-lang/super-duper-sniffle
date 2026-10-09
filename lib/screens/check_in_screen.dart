import 'package:flutter/material.dart';

import '../data/shift_store.dart';
import '../data/session_store.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../widgets/mock_qr_code.dart';
import 'shifts_screen.dart';
import '../data/catalog_store.dart';
import '../services/catalog_repository.dart';
import '../widgets/attendance_status.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _store = ShiftStore.instance;
  ShiftListing? _selectedShift;
  bool _scanned = false;
  bool _saving = false;
  String? _error;
  String? _scannedCode;
  String? _selectedAccount;
  Object _shiftKey(ShiftListing listing) => listing.shift.id ?? listing.shift;

  List<ShiftListing> get _eligibleShifts => _store.myShifts
      .where(
        (listing) =>
            !_store.isCheckedIn(listing.shift) &&
            !_store.isAwaitingConfirmation(listing.shift),
      )
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
    if (_selectedShift == null ||
        _store.qrCodeFor(_selectedShift!.shift) == null) {
      return;
    }
    setState(() {
      _scanned = true;
      _scannedCode = _store.qrCodeFor(_selectedShift!.shift);
    });
  }

  Future<void> _confirmCheckIn() async {
    if (_saving) return;
    final listing = _selectedShift;
    if (listing == null) return;
    final account = SessionStore.instance.accountId;
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
    if (confirmed != true || !mounted) return;
    if (account != SessionStore.instance.accountId ||
        _scannedCode != _store.qrCodeFor(listing.shift)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final submitted = await _store.submitCheckIn(listing.shift);
      if (!submitted || !mounted) return;
    } catch (error) {
      if (mounted) setState(() => _error = catalogError(error));
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    setState(() {
      _scanned = false;
      _scannedCode = null;
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
        title: Text(
          _store.lastCheckInConfirmed
              ? 'Attendance confirmed!'
              : 'Check-in sent!',
        ),
        content: Text(
          _store.lastCheckInConfirmed
              ? 'Your attendance is confirmed. As the assigned coordinator, you do not need to confirm yourself.'
              : 'You are checked in and awaiting coordinator confirmation. Points and rewards are added after attendance is confirmed.',
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
    final catalog = CatalogScope.maybeOf(context);
    if (catalog != null &&
        (catalog.attendanceLoading ||
            catalog.attendanceFailed ||
            catalog.shiftsLoading ||
            catalog.shiftsFailed)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Station check-in')),
        body: Center(
          child: catalog.shiftsLoading || catalog.shiftsFailed
              ? CatalogStatus(store: catalog, shifts: true)
              : AttendanceStatus(store: catalog),
        ),
        bottomNavigationBar: const BushelNavigationBar(selectedIndex: 2),
      );
    }
    final eligible = _eligibleShifts;
    final previous = _selectedShift;
    final current =
        eligible
            .where(
              (entry) => entry.shift.id != null
                  ? entry.shift.id == previous?.shift.id
                  : identical(entry.shift, previous?.shift),
            )
            .firstOrNull ??
        eligible.firstOrNull;
    if (current?.shift.id != previous?.shift.id ||
        (current?.shift.id == null &&
            !identical(current?.shift, previous?.shift)) ||
        _selectedAccount != SessionStore.instance.accountId) {
      _scanned = false;
      _scannedCode = null;
    }
    _selectedAccount = SessionStore.instance.accountId;
    _selectedShift = current;
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
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_saving) const LinearProgressIndicator(),
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
              _ScannerFrame(
                scanned: _scanned,
                qrCode: _selectedShift == null
                    ? null
                    : _store.qrCodeFor(_selectedShift!.shift),
              ),
              const SizedBox(height: 24),
              if (eligible.isEmpty)
                _NoEligibleShift(
                  hasAttendance: _store.myShifts.any(
                    (entry) =>
                        _store.isAwaitingConfirmation(entry.shift) ||
                        _store.isCheckedIn(entry.shift),
                  ),
                  onFindShift: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShiftsScreen(),
                    ),
                  ),
                )
              else ...[
                if (kidMode && eligible.length == 1)
                  _KidShiftCard(listing: current!)
                else
                  DropdownButtonFormField<Object>(
                    key: ValueKey((_selectedAccount, _shiftKey(current!))),
                    isExpanded: true,
                    initialValue: _shiftKey(current),
                    decoration: const InputDecoration(
                      labelText: 'Shift to check in',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: [
                      for (final listing in eligible)
                        DropdownMenuItem(
                          value: _shiftKey(listing),
                          child: Text(
                            '${listing.shift.title} · ${listing.shift.station}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                            _selectedShift = eligible
                                .where((listing) => _shiftKey(listing) == value)
                                .firstOrNull;
                            _scanned = false;
                            _scannedCode = null;
                          }),
                  ),
                if (current.shift.instructions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Location instructions: ${current.shift.instructions}',
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: kidMode ? 70 : null,
                  child: FilledButton.icon(
                    key: const ValueKey('simulate-scan'),
                    onPressed:
                        _saving ||
                            _store.qrCodeFor(_selectedShift!.shift) == null
                        ? null
                        : (_scanned ? _confirmCheckIn : _simulateScan),
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
                  _store.qrCodeFor(_selectedShift!.shift) == null
                      ? 'The shift coordinator has not generated a QR code yet.'
                      : (_scanned
                            ? 'Shift matched: ${_selectedShift!.shift.title}'
                            : 'This mock QR belongs only to the selected shift. Camera scanning will be added later.'),
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
  const _ScannerFrame({required this.scanned, required this.qrCode});

  final bool scanned;
  final String? qrCode;

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
          child: scanned
              ? const Icon(
                  Icons.check_circle,
                  color: Color(0xFF20B85A),
                  size: 108,
                )
              : qrCode == null
              ? const Icon(Icons.qr_code_2, color: Colors.white, size: 108)
              : MockQrCode(value: qrCode!),
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
  const _NoEligibleShift({
    required this.onFindShift,
    this.hasAttendance = false,
  });

  final VoidCallback onFindShift;
  final bool hasAttendance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Text(
              hasAttendance
                  ? 'Your check-ins are up to date'
                  : 'Sign up for a shift first',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(
              hasAttendance
                  ? 'Pending check-ins are waiting for coordinator confirmation. Confirmed check-ins have already earned points.'
                  : 'Your upcoming shifts will become available for station check-in.',
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
