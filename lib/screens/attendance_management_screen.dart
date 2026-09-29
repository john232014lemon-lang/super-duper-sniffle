import 'package:flutter/material.dart';
import '../data/catalog_store.dart';
import '../data/session_store.dart';
import '../models/attendance.dart';
import '../services/catalog_repository.dart';
import '../widgets/mock_qr_code.dart';

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
  bool _saving = false;
  String? _error;
  void _subscribe() => _entries = _store!.repository.watchAttendance(
    _store!.uid,
    asLeader: true,
  );
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                    .where((entry) => !entry.confirmed)
                    .toList();
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
                          'Shift check-in QR',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Simulated QR for this shift. Camera scanning is a later feature.',
                        ),
                        const SizedBox(height: 16),
                        if (shift.qrCode == null)
                          FilledButton(
                            onPressed: _saving
                                ? null
                                : () => _save(
                                    () => store.repository.publishQr(
                                      widget.shiftId,
                                    ),
                                  ),
                            child: const Text('Generate shift QR'),
                          )
                        else
                          Center(
                            child: MockQrCode(value: shift.qrCode!, size: 180),
                          ),
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
                        if (ready) ...[
                          Text(
                            'Awaiting confirmation · ${pending.length}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Confirm only people who attended. Cancelled or removed participants cannot be confirmed.',
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
                                          () => store.repository.confirmEntry(
                                            entry,
                                          ),
                                        ),
                                  child: const Text('Confirm'),
                                ),
                              ),
                            ),
                          Text(
                            '${entries.where((entry) => entry.confirmed).length} confirmed',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
