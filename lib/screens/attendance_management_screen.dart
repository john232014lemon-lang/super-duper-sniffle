import 'package:flutter/material.dart';
import '../data/catalog_store.dart';
import '../data/mock_qr_presentation_store.dart';
import '../data/session_store.dart';
import '../models/attendance.dart';
import '../services/catalog_repository.dart';
import '../services/community_models.dart';
import '../models/check_in_token.dart';
import '../widgets/station_token_display.dart';
import '../demo_config.dart';

class AttendanceManagementScreen extends StatefulWidget {
  const AttendanceManagementScreen({
    super.key,
    required this.shiftId,
    required this.title,
  });
  final String shiftId;
  final String title;
  @override
  State<AttendanceManagementScreen> createState() =>
      _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState
    extends State<AttendanceManagementScreen> {
  CatalogStore? _store;
  late Stream<List<AttendanceEntry>> _entries;
  Stream<ShiftGroup>? _group;
  bool _saving = false;
  String? _error;
  CheckInToken? _token;
  String? _tokenOwner;
  void _subscribe() {
    _entries = _store!.repository.watchAttendance(
      _store!.uid,
      asLeader: true,
    );
    _group = _store!.repository.watchGroup(widget.shiftId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = CatalogScope.maybeOf(context);
    if (!identical(_store, store)) {
      _store = store;
      if (store != null) _subscribe();
    }
  }

  Future<void> _save(Future<void> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = catalogError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _statusLabel(AttendanceEntry? entry) {
    if (entry == null) return 'Not scanned yet';
    if (entry.status == 'confirmed') return 'Confirmed';
    if (entry.status == 'revoked') return 'Removed · rewards revoked';
    return 'Scanned · pending confirmation';
  }

  @override
  Widget build(BuildContext context) {
    final store = CatalogScope.maybeOf(context);
    final shift = store?.shifts
        .where((record) => record.shift.id == widget.shiftId)
        .firstOrNull;
    final allowed =
        store != null &&
        shift != null &&
        shift.creatorUid == store.uid &&
        !SessionStore.instance.isKidAccount &&
        store.coordinatorBanks.contains(shift.bankId);
    final qrReady =
        _token != null &&
        _tokenOwner == store?.uid &&
        (mockQrMode ||
            (_token != null &&
                CheckInToken.verifier(_token!.code) == shift?.qrTokenHash));
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} · QR & attendance')),
      body: store != null && (store.shiftsLoading || store.shiftsFailed)
          ? Center(child: CatalogStatus(store: store, shifts: true))
          : !allowed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Only this shift’s approved leader can manage check-ins.',
                  ),
                  if (store != null)
                    TextButton(
                      onPressed: store.retry,
                      child: const Text('Refresh access'),
                    ),
                ],
              ),
            )
          : StreamBuilder<List<AttendanceEntry>>(
              stream: _entries,
              builder: (context, snapshot) {
                final ready = snapshot.hasData && !snapshot.hasError;
                final entries = (ready ? snapshot.data! : <AttendanceEntry>[])
                    .where((entry) => entry.shiftId == widget.shiftId)
                    .toList();
                final pending = entries
                    .where((entry) => entry.status == 'pending')
                    .toList();
                final byParticipant = {
                  for (final entry in entries)
                    (entry.ownerUid, entry.participantId): entry,
                };
                return StreamBuilder<ShiftGroup>(
                  stream: _group,
                  builder: (context, groupSnapshot) {
                    final group = groupSnapshot.data;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            if (_error != null)
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            if (_saving) const LinearProgressIndicator(),
                            const Text(
                              mockQrMode
                                  ? 'Mock shift check-in QR'
                                  : 'Shift check-in QR',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              mockQrMode
                                  ? 'Mock codes work during the enabled presentation session, regardless of shift time. Only adult volunteers can redeem. Confirm attendance below to award points in Firebase. Codes expire in 15 minutes; rotating invalidates the old code.'
                                  : 'Codes last at most 15 minutes. Rotating invalidates the previous code. Reopening this screen requires a new code.',
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _saving
                                  ? null
                                  : () => _save(() async {
                                      final owner = store.uid;
                                      final token = await store.repository
                                          .publishQr(widget.shiftId);
                                      if (mockQrMode) {
                                        MockQrPresentationStore.instance
                                            .remember(widget.shiftId, token);
                                      }
                                      if (mounted &&
                                          identical(_store, store) &&
                                          !SessionStore.instance.isKidAccount) {
                                        setState(() {
                                          _token = token;
                                          _tokenOwner = owner;
                                        });
                                      }
                                    }),
                              child: Text(
                                mockQrMode
                                    ? (_token == null
                                          ? 'Generate mock QR'
                                          : 'Rotate mock QR')
                                    : shift.qrTokenHash == null
                                    ? 'Generate shift QR'
                                    : 'Rotate shift QR',
                              ),
                            ),
                            if (qrReady) StationTokenDisplay(token: _token!),
                            const SizedBox(height: 24),
                            if (snapshot.hasError) ...[
                              const Text(
                                'Could not load check-ins. You can still generate the shift QR.',
                              ),
                              TextButton(
                                onPressed: () => setState(_subscribe),
                                child: const Text('Retry check-ins'),
                              ),
                            ] else if (!ready)
                              const LinearProgressIndicator(),
                            if (ready && qrReady && group != null) ...[
                              const Text(
                                'Group check-in status',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Every booked adult and child appears after a QR is generated.',
                              ),
                              for (final entry in group.members.entries)
                                ListTile(
                                  title: Text(entry.value),
                                  subtitle: Text(
                                    _statusLabel(
                                      byParticipant[(entry.key, 'parent')],
                                    ),
                                  ),
                                  trailing:
                                      byParticipant[(entry.key, 'parent')]
                                              ?.status ==
                                          'pending'
                                      ? FilledButton(
                                          onPressed: _saving
                                              ? null
                                              : () => _save(
                                                  () => store.repository
                                                      .confirmEntry(
                                                        byParticipant[(
                                                          entry.key,
                                                          'parent',
                                                        )]!,
                                                      ),
                                                ),
                                          child: const Text('Confirm'),
                                        )
                                      : null,
                                ),
                              for (final child in group.childList)
                                ListTile(
                                  title: Text(child.name),
                                  subtitle: Text(
                                    'Child · ${_statusLabel(byParticipant[(child.parentUid, child.childId)])}',
                                  ),
                                  trailing:
                                      byParticipant[(
                                                    child.parentUid,
                                                    child.childId,
                                                  )]
                                                  ?.status ==
                                              'pending'
                                          ? FilledButton(
                                              onPressed: _saving
                                                  ? null
                                                  : () => _save(
                                                      () => store.repository
                                                          .confirmEntry(
                                                            byParticipant[(
                                                              child.parentUid,
                                                              child.childId,
                                                            )]!,
                                                          ),
                                                    ),
                                              child: const Text('Confirm'),
                                            )
                                          : null,
                                ),
                            ] else if (ready) ...[
                              if (entries.any(
                                (entry) => entry.status == 'revoked',
                              ))
                                const Text(
                                  'Removed families are excluded from attendance and rewards.',
                                ),
                              Text(
                                'Awaiting confirmation · ${pending.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Generate a QR to see every group member’s scan status. Confirm only people who attended.',
                              ),
                              if (pending.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No pending check-ins.'),
                                ),
                              for (final entry in pending)
                                Card(
                                  child: ListTile(
                                    title: Text(entry.name),
                                    subtitle: Text(
                                      entry.participantId == 'parent'
                                          ? 'Adult participant'
                                          : 'Parent-managed child',
                                    ),
                                    trailing: FilledButton(
                                      onPressed: _saving
                                          ? null
                                          : () => _save(
                                              () => store.repository
                                                  .confirmEntry(entry),
                                            ),
                                      child: const Text('Confirm'),
                                    ),
                                  ),
                                ),
                              Text(
                                '${entries.where((entry) => entry.confirmed).length} confirmed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              for (final entry in entries.where(
                                (entry) => entry.confirmed,
                              ))
                                ListTile(
                                  title: Text(entry.name),
                                  trailing: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                            if (ready &&
                                qrReady &&
                                groupSnapshot.hasError) ...[
                              const Text(
                                'Could not load group membership for the full roster. Pending confirmations still work below.',
                              ),
                              TextButton(
                                onPressed: () => setState(_subscribe),
                                child: const Text('Retry group list'),
                              ),
                              for (final entry in pending)
                                Card(
                                  child: ListTile(
                                    title: Text(entry.name),
                                    trailing: FilledButton(
                                      onPressed: _saving
                                          ? null
                                          : () => _save(
                                              () => store.repository
                                                  .confirmEntry(entry),
                                            ),
                                      child: const Text('Confirm'),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
