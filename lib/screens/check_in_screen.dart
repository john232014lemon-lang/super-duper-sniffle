import 'package:flutter/material.dart';
import '../data/shift_store.dart';
import '../data/session_store.dart';
import '../data/catalog_store.dart';
import '../services/catalog_repository.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../widgets/attendance_status.dart';
import 'shifts_screen.dart';
import 'camera_scan_screen.dart';
import 'mock_camera_scan_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _store = ShiftStore.instance;
  final _codeInput = TextEditingController();
  ShiftListing? _selected;
  String _participant = 'parent';
  String? _code;
  String? _error;
  String? _account;
  bool _saving = false;
  Object _key(ShiftListing entry) => entry.shift.id ?? entry.shift;

  Map<String, String> _participants(ShiftListing entry) {
    final session = SessionStore.instance;
    return {
      if (!_store.hasAttendance(entry.shift, 'parent'))
        'parent': session.userName,
    };
  }

  List<FamilyChild> _bookedChildren(ShiftListing entry) => [
    for (final child in SessionStore.instance.children)
      if (_store
          .shiftsForChild(child.id)
          .any((booking) => _key(booking) == _key(entry)))
        child,
  ];

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    SessionStore.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    SessionStore.instance.removeListener(_refresh);
    _codeInput.dispose();
    super.dispose();
  }

  void _acceptCode(String value) {
    if (SessionStore.instance.isKidAccount || _saving) return;
    setState(() {
      _code = value.trim().isEmpty ? null : value.trim();
      _error = null;
      _codeInput.clear();
    });
  }

  Future<void> _scan() async {
    if (_saving || SessionStore.instance.isKidAccount || _selected == null) {
      return;
    }
    final shift = _key(_selected!);
    final owner = _account;
    final shiftId = _selected!.shift.id;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _store.usingMockQr && shiftId != null
            ? MockCameraScanScreen(shiftId: shiftId)
            : const CameraScanScreen(),
      ),
    );
    if (!mounted ||
        SessionStore.instance.isKidAccount ||
        owner != _account ||
        _selected == null ||
        shift != _key(_selected!)) {
      return;
    }
    if (code != null) _acceptCode(code);
  }

  Future<void> _submit() async {
    final listing = _selected;
    final code = _code;
    if (_saving ||
        listing == null ||
        code == null ||
        SessionStore.instance.isKidAccount) {
      return;
    }
    final participant = _participant;
    final name = _participants(listing)[participant];
    final owner = CatalogScope.maybeOf(context)?.uid ?? 'demo';
    if (name == null) return;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm check-in?'),
        content: Text(
          '$name${_bookedChildren(listing).map((child) => '\n${child.name}').join()}\n${listing.shift.title}\n${listing.foodBank.shortName}\nStation: ${listing.shift.station}',
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
    if (!mounted ||
        agreed != true ||
        SessionStore.instance.isKidAccount ||
        owner != (CatalogScope.maybeOf(context)?.uid ?? 'demo') ||
        participant != _participant ||
        _key(listing) != (_selected == null ? null : _key(_selected!))) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _store.submitCheckIn(
        listing.shift,
        code,
        participantId: participant,
        name: name,
      );
      if (!mounted) return;
      setState(() {
        _code = null;
        _codeInput.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _store.lastCheckInConfirmed
                ? 'Your family attendance is confirmed. As the assigned coordinator, you do not need to confirm yourself.'
                : 'Family check-in sent for $name and their booked children. Awaiting coordinator confirmation; no points earned yet.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = catalogError(error);
          _code = null;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    if (SessionStore.instance.isKidAccount ||
        (_store.usingMockQr &&
            SessionStore.instance.role != BushelRole.volunteer)) {
      _code = null;
      _codeInput.clear();
      return Scaffold(
        appBar: AppBar(title: const Text('Station check-in')),
        body: Center(
          child: Text(
            _store.usingMockQr
                ? 'Mock QR check-in is for adult volunteers only. Coordinators generate codes in Groups.'
                : 'Ask your parent to scan and check you in.',
          ),
        ),
        bottomNavigationBar: const BushelNavigationBar(selectedIndex: 2),
      );
    }
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
    final account = catalog?.uid ?? 'demo';
    final eligible = _store.myShifts
        .where((entry) => _participants(entry).isNotEmpty)
        .toList();
    final selected =
        eligible
            .where(
              (entry) => _selected != null && _key(entry) == _key(_selected!),
            )
            .firstOrNull ??
        eligible.firstOrNull;
    if (_account != account ||
        (selected == null ? null : _key(selected)) !=
            (_selected == null ? null : _key(_selected!))) {
      _code = null;
      _codeInput.clear();
      _participant = 'parent';
    }
    _account = account;
    _selected = selected;
    final people = selected == null
        ? <String, String>{}
        : _participants(selected);
    if (!people.containsKey(_participant) && people.isNotEmpty) {
      _participant = people.keys.first;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Station check-in')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_saving) const LinearProgressIndicator(),
              const Text(
                'Check in at your station',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (selected == null) ...[
                Text(
                  _store.myShifts.isEmpty
                      ? 'Sign up for a shift first'
                      : 'Your check-ins are up to date. Pending attendance awaits coordinator confirmation.',
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const ShiftsScreen(),
                    ),
                  ),
                  child: const Text('Find a shift'),
                ),
              ] else ...[
                DropdownButtonFormField<Object>(
                  key: ValueKey((account, _key(selected))),
                  initialValue: _key(selected),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Shift to check in',
                  ),
                  items: [
                    for (final entry in eligible)
                      DropdownMenuItem(
                        value: _key(entry),
                        child: Text(
                          '${entry.shift.title} · ${entry.shift.station}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _selected = eligible.firstWhere(
                            (entry) => _key(entry) == value,
                          );
                          _participant = 'parent';
                          _code = null;
                          _error = null;
                          _codeInput.clear();
                        }),
                ),
                const SizedBox(height: 16),
                Text('Checking in: ${SessionStore.instance.parentName} (you)'),
                const SizedBox(height: 8),
                Text(
                  _bookedChildren(selected).isEmpty
                      ? 'Children with a booking for this shift will be included automatically.'
                      : 'Also checking in: ${_bookedChildren(selected).map((child) => child.name).join(', ')}. Coordinator confirmation confirms your family together.',
                ),
                if (selected.shift.instructions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Location instructions: ${selected.shift.instructions}',
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  _store.usingMockQr
                      ? 'Scan or enter your coordinator’s mock code. Attendance is saved to Firebase; coordinator confirmation earns 100 points. Codes expire in 15 minutes.'
                      : 'Use the current code displayed by your assigned leader. Codes expire after at most 15 minutes.',
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR with camera'),
                ),
                TextField(
                  controller: _codeInput,
                  enabled: !_saving,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: 'Enter code'),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => _acceptCode(_codeInput.text),
                  child: const Text('Use entered code'),
                ),
                if (_code != null)
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm station check-in'),
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
