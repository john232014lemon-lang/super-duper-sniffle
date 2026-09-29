import 'package:flutter/material.dart';

import '../data/shift_store.dart';
import '../data/catalog_store.dart';
import '../services/catalog_repository.dart';
import '../data/coordinator_store.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../widgets/shift_calendar.dart';
import 'coordinator_screen.dart';
import 'live_group_screen.dart';
import '../data/session_store.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key, this.initialDate, this.showMyShifts = false});
  final DateTime? initialDate;
  final bool showMyShifts;

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final _store = ShiftStore.instance;
  int _tab = 0;
  bool _busy = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _tab = widget.showMyShifts ? 1 : 0;
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
    if (confirmed != true || !mounted) return;
    await _change(listing, true);
  }

  Future<void> _cancel(ShiftListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this signup?'),
        content: Text(listing.shift.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep signup'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel signup'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _change(listing, false);
  }

  Future<void> _change(ShiftListing listing, bool join) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (join) {
        await _store.signUp(listing.foodBank, listing.shift);
      } else {
        await _store.cancelSignup(listing.shift);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              join ? 'Shift added to My shifts.' : 'Signup cancelled.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(catalogError(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    final allShifts = _tab == 0 ? _store.available : _store.myShifts;
    final shifts = allShifts
        .where(
          (listing) =>
              DateUtils.isSameDay(listing.shift.scheduledDate, _selectedDate),
        )
        .toList();
    // My shifts must remain reachable even when a legacy booking has a bad date.
    final displayed = _tab == 1
        ? (allShifts.toList()..sort(
            (a, b) => a.shift.scheduledDate.compareTo(b.shift.scheduledDate),
          ))
        : shifts;
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
              if (_tab == 0)
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
                _tab == 1
                    ? (SessionStore.instance.isKidAccount
                          ? 'All your booked shifts · your parent manages group membership'
                          : 'All your booked shifts · tap a card to open its group')
                    : MaterialLocalizations.of(
                        context,
                      ).formatFullDate(_selectedDate),
              ),
              const SizedBox(height: 12),
              if (catalog != null &&
                  (catalog.shiftsLoading || catalog.shiftsFailed))
                CatalogStatus(store: catalog, shifts: true)
              else if (displayed.isEmpty)
                _EmptyShifts(myShifts: _tab == 1)
              else
                ...displayed.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(
                      listing: listing,
                      signedUp: _store.isSignedUp(listing.shift),
                      checkedIn: _store.isCheckedIn(listing.shift),
                      showSignup:
                          _tab == 0 &&
                          !(catalog != null &&
                              SessionStore.instance.isKidAccount),
                      onSignup: _busy ? null : () => _confirmSignup(listing),
                      onCancel:
                          _tab == 1 &&
                              catalog != null &&
                              !_busy &&
                              !SessionStore.instance.isKidAccount
                          ? () => _cancel(listing)
                          : null,
                      onOpenGroup:
                          _tab == 1 && !SessionStore.instance.isKidAccount
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => catalog == null
                                    ? const GroupDetailScreen()
                                    : LiveGroupScreen(
                                        shiftId: listing.shift.id!,
                                        title: listing.shift.title,
                                      ),
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
    this.onCancel,
  });

  final ShiftListing listing;
  final bool signedUp;
  final bool checkedIn;
  final bool showSignup;
  final VoidCallback? onSignup;
  final VoidCallback? onCancel;
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
              if (onCancel != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel signup'),
                  ),
                ),
              if (onOpenGroup != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onOpenGroup,
                    icon: const Icon(Icons.groups_outlined),
                    label: const Text('View group & members'),
                  ),
                ),
              if (showSignup) ...[
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    key: ValueKey('signup-${shift.title}'),
                    onPressed: signedUp || shift.spotsLeft <= 0
                        ? null
                        : onSignup,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(110, 44),
                    ),
                    child: Text(
                      signedUp
                          ? 'Signed up'
                          : shift.spotsLeft <= 0
                          ? 'Full'
                          : 'Sign up',
                    ),
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
          if (CatalogScope.maybeOf(context) != null &&
              SessionStore.instance.isKidAccount)
            const Text(
              'Your parent manages your shift places in Family Center.',
            ),
          Text(
            myShifts ? 'No booked shifts' : 'No shifts on this day',
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
