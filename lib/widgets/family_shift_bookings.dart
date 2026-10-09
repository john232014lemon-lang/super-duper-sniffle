import 'package:flutter/material.dart';
import '../data/catalog_store.dart';
import '../data/session_store.dart';
import '../data/shift_store.dart';
import '../services/catalog_repository.dart';
import '../screens/shifts_screen.dart';
import 'coordinator_contact.dart';

class FamilyShiftBookings extends StatefulWidget {
  const FamilyShiftBookings({super.key});
  @override
  State<FamilyShiftBookings> createState() => _FamilyShiftBookingsState();
}

class _FamilyShiftBookingsState extends State<FamilyShiftBookings> {
  final _shifts = ShiftStore.instance;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _shifts.addListener(_refresh);
    SessionStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    _shifts.removeListener(_refresh);
    SessionStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _change(ShiftListing listing, String childId, bool join) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _shifts.setChildBooking(listing, childId, join);
    } catch (error) {
      if (mounted) setState(() => _error = catalogError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _choose(String childId, String name) async {
    final booked = _shifts.shiftsForChild(childId);
    final choices = _shifts.myShifts
        .where(
          (listing) =>
              listing.shift.spotsLeft > 0 &&
              !booked.any(
                (b) => b.shift.id != null
                    ? b.shift.id == listing.shift.id
                    : identical(b.shift, listing.shift),
              ),
        )
        .toList();
    final chosen = await showDialog<ShiftListing>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Sign up $name'),
        children: choices.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Join a shift with an open place first. Your child may already be booked into all your shifts.',
                  ),
                ),
              ]
            : [
                for (final listing in choices)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, listing),
                    child: Text(
                      '${listing.shift.title}\n${listing.shift.date} · ${listing.shift.time}',
                    ),
                  ),
              ],
      ),
    );
    if (chosen != null && mounted) await _change(chosen, childId, true);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionStore.instance;
    final catalog = CatalogScope.maybeOf(context);
    if (session.isKidAccount) return const SizedBox.shrink();
    final unavailable =
        catalog != null &&
        (catalog.familyLoading ||
            catalog.familyFailed ||
            catalog.shiftsLoading ||
            catalog.shiftsFailed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your kids’ shifts',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const Text(
          'Join a shift yourself, then reserve a place for each child. If you leave, their places are also removed.',
        ),
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ShiftsScreen())),
          child: const Text('Find a shift to join'),
        ),
        if (_saving) const LinearProgressIndicator(),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (unavailable) ...[
          const Text('Family bookings are loading or unavailable.'),
          TextButton(onPressed: catalog.retry, child: const Text('Retry')),
        ] else ...[
          if (session.children.isEmpty)
            const Text('Add a kid account to start booking.'),
          for (final child in session.children) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _choose(child.id, child.name),
                  icon: const Icon(Icons.add),
                  label: const Text('Sign up for shift'),
                ),
              ],
            ),
            if (_shifts.shiftsForChild(child.id).isEmpty)
              const Text('No shifts booked.'),
            for (final listing in _shifts.shiftsForChild(child.id))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.shift.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${listing.foodBank.shortName}\n${listing.shift.date} · ${listing.shift.time}\n${listing.shift.station}',
                      ),
                      if (listing.shift.instructions.isNotEmpty)
                        Text(listing.shift.instructions),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => _change(listing, child.id, false),
                        child: Text('Leave shift for ${child.name}'),
                      ),
                      CoordinatorContact(
                        key: ValueKey(listing.leaderAccountId),
                        uid: listing.leaderAccountId,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}
