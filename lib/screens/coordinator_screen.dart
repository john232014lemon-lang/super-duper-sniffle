import 'package:flutter/material.dart';

import '../data/coordinator_store.dart';
import '../data/session_store.dart';
import '../data/shift_store.dart';
import '../models/group_member.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../widgets/mock_qr_code.dart';
import '../data/catalog_store.dart';
import 'live_group_screen.dart';
import 'attendance_management_screen.dart';

class CoordinatorScreen extends StatelessWidget {
  const CoordinatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    if (catalog != null) {
      final records = catalog.shifts
          .where(
            (record) =>
                record.creatorUid == catalog.uid ||
                catalog.signups.contains(record.shift.id),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Your shift groups')),
        body: catalog.shiftsLoading || catalog.shiftsFailed
            ? Center(child: CatalogStatus(store: catalog, shifts: true))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Each shift has one group. Members handles removal voting; QR & attendance handles check-in confirmation.',
                  ),
                  if (records.isEmpty)
                    const Text('Join or create a shift to see it here.'),
                  for (final record in records)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.shift.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('${record.shift.date} · ${record.shift.time}'),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (catalog.signups.contains(record.shift.id) &&
                                    !SessionStore.instance.isKidAccount)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.groups_outlined),
                                    label: const Text(
                                      'Members & removal votes',
                                    ),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => LiveGroupScreen(
                                          shiftId: record.shift.id!,
                                          title: record.shift.title,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (record.creatorUid == catalog.uid &&
                                    !SessionStore.instance.isKidAccount)
                                  FilledButton.icon(
                                    icon: const Icon(Icons.fact_check_outlined),
                                    label: const Text('QR & attendance'),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            AttendanceManagementScreen(
                                              shiftId: record.shift.id!,
                                              title: record.shift.title,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (!catalog.signups.contains(record.shift.id))
                              const Text(
                                'Join this shift to take part in its member group and removal voting.',
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
        bottomNavigationBar: const BushelNavigationBar(selectedIndex: 4),
      );
    }
    final group = CoordinatorStore.sharedShiftGroup;
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Your shift groups',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Every shift creates a group with everyone signed up.',
                style: TextStyle(color: Color(0xFF68756D)),
              ),
              const SizedBox(height: 20),
              Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                child: InkWell(
                  key: const ValueKey('open-shift-group'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const GroupDetailScreen(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.groups,
                          color: Color(0xFF18A94F),
                          size: 36,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          group.shiftTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(group.foodBankName),
                        const SizedBox(height: 12),
                        Text('${group.date} · ${group.time}'),
                        Text(
                          '${group.station} · ${CoordinatorStore.instance.members.length} members',
                        ),
                        const SizedBox(height: 14),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'View group  →',
                            style: TextStyle(
                              color: Color(0xFF12813E),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 4),
    );
  }
}

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _store = CoordinatorStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    ShiftStore.instance.addListener(_refresh);
    SessionStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    ShiftStore.instance.removeListener(_refresh);
    SessionStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _showProfile(GroupMember member) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFE2F6E8),
              child: Text(member.name.substring(0, 1)),
            ),
            const SizedBox(height: 14),
            Text(
              member.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            Text(member.role, style: const TextStyle(color: Color(0xFF68756D))),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Phone number'),
              subtitle: Text(member.phoneNumber),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: const Text('Shifts completed'),
              subtitle: Text('${member.shiftsCompleted} shifts'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmVote(GroupMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vote to remove member?'),
        content: Text(
          'Your vote to remove ${member.name} will be recorded. Removal needs ${_store.votesNeeded} votes—at least two-thirds of this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit vote'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final removed = _store.voteToRemove(member.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            removed
                ? '${member.name} was removed from the shift group.'
                : 'Your vote for ${member.name} was recorded.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final group = CoordinatorStore.sharedShiftGroup;
    final shiftStore = ShiftStore.instance;
    if (shiftStore.usingLive) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shift group')),
        body: const Center(child: Text('Shift groups are coming soon.')),
      );
    }
    final shift = shiftStore.available.first.shift;
    final qrCode = shiftStore.qrCodeFor(shift);
    final pending = shiftStore.pendingAttendance(shift);
    return Scaffold(
      appBar: AppBar(title: const Text('Shift group')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                group.shiftTitle,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text('${group.foodBankName} · ${group.date} · ${group.time}'),
              const SizedBox(height: 18),
              if (shiftStore.canManageShift(shift)) ...[
                Card(
                  color: const Color(0xFFE8F7ED),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Text(
                          'Shift check-in QR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (qrCode == null)
                          FilledButton.icon(
                            key: const ValueKey('generate-shift-qr'),
                            onPressed: () => shiftStore.generateQrCode(shift),
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Generate QR for this shift'),
                          )
                        else ...[
                          MockQrCode(value: qrCode, size: 160),
                          const SizedBox(height: 8),
                          const Text(
                            'This code works only for this shift.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Awaiting confirmation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Chip(label: Text('${pending.length}')),
                  ],
                ),
                const SizedBox(height: 8),
                if (pending.isEmpty)
                  const Text('No one is waiting for attendance confirmation.')
                else
                  for (final record in pending)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_pin_circle_outlined),
                        title: Text(record.name),
                        subtitle: const Text(
                          'Checked in · awaiting confirmation',
                        ),
                        trailing: FilledButton(
                          key: ValueKey('confirm-${record.accountId}'),
                          onPressed: () => shiftStore.confirmAttendance(
                            shift,
                            record.accountId,
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    ),
                const SizedBox(height: 22),
              ],
              const Text(
                'Everyone signed up for this shift',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text('${_store.members.length} members'),
              const SizedBox(height: 14),
              for (final member in _store.members) ...[
                _MemberCard(
                  member: member,
                  votesNeeded: _store.votesNeeded,
                  hasVoted: _store.hasVotedFor(member.id),
                  canVote: _store.canVoteFor(member.id),
                  onProfile: () => _showProfile(member),
                  onVote: () => _confirmVote(member),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.votesNeeded,
    required this.hasVoted,
    required this.canVote,
    required this.onProfile,
    required this.onVote,
  });

  final GroupMember member;
  final int votesNeeded;
  final bool hasVoted;
  final bool canVote;
  final VoidCallback onProfile;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(member.name.substring(0, 1))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(member.role),
                    Text(member.phoneNumber),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'View ${member.name} profile',
                onPressed: onProfile,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text('${member.voteCount}/$votesNeeded removal votes'),
              ),
              OutlinedButton.icon(
                key: ValueKey('vote-${member.id}'),
                onPressed: canVote ? onVote : null,
                icon: Icon(hasVoted ? Icons.check : Icons.how_to_vote_outlined),
                label: Text(
                  hasVoted ? 'Voted' : (canVote ? 'Vote out' : 'You'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
