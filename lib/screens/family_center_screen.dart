import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../data/coordinator_store.dart';
import '../data/catalog_store.dart';
import '../widgets/family_shift_bookings.dart';
import '../services/catalog_repository.dart';
import '../widgets/bushel_navigation_bar.dart';
import '../widgets/family_entry_dialog.dart';
import '../widgets/attendance_status.dart';
import 'home_screen.dart';

class FamilyCenterScreen extends StatefulWidget {
  const FamilyCenterScreen({super.key});

  @override
  State<FamilyCenterScreen> createState() => _FamilyCenterScreenState();
}

class _FamilyCenterScreenState extends State<FamilyCenterScreen> {
  final _session = SessionStore.instance;
  bool _saving = false;
  String? _error;
  Future<bool> _save(Future<void> Function() action) async {
    if (_saving) return false;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = catalogError(error));
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _session.addListener(_refresh);
  }

  @override
  void dispose() {
    _session.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _addChild() async {
    final live = CatalogScope.maybeOf(context);
    if (live != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => FamilyEntryDialog(store: live, childEntry: true),
      );
      return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a kid account'),
        content: TextField(
          key: const ValueKey('kid-name-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Kid’s name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create kid account'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    if (!mounted) return;
    final catalog = CatalogScope.maybeOf(context);
    if (catalog != null) {
      await _save(
        () => catalog.repository.saveFamilyEntry(catalog.uid, 'children', name),
      );
      return;
    }
    _session.addChild(name);
    CoordinatorStore.instance.addFamilyChild(_session.children.last);
  }

  Future<void> _addChallenge() async {
    final live = CatalogScope.maybeOf(context);
    if (live != null) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => FamilyEntryDialog(store: live, childEntry: false),
      );
      return;
    }
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a challenge'),
        content: TextField(
          key: const ValueKey('challenge-field'),
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Example: Help at 2 food banks!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add challenge'),
          ),
        ],
      ),
    );
    if (title == null || title.trim().isEmpty) return;
    if (!mounted) return;
    final catalog = CatalogScope.maybeOf(context);
    if (catalog != null) {
      await _save(
        () => catalog.repository.saveFamilyEntry(
          catalog.uid,
          'challenges',
          title,
        ),
      );
      return;
    }
    _session.addChallenge(title);
  }

  Future<void> _switchAndGoHome({String? childId}) async {
    final catalog = CatalogScope.maybeOf(context);
    if (catalog != null &&
        !await _save(
          () => catalog.repository.switchFamilyProfile(
            catalog.uid,
            childId ?? '',
          ),
        )) {
      return;
    }
    if (!mounted) return;
    if (childId == null) {
      _session.switchToParent();
    } else {
      _session.switchToChild(childId);
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(name: _session.userName),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    final kidMode = _session.isKidAccount;
    return Scaffold(
      appBar: AppBar(title: const Text('Family Center')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!kidMode)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Manage your kids here\n\n1. Tap Add kid to create a child account.\n2. Open Shifts and join a shift yourself first.\n3. Return to Family → Your kids’ shifts. Tap Sign up for shift next to a child.\n4. Use Leave shift for a child to remove only their place. If you leave your own shift, their places are removed too.\n\nSwitch to a kid account only for their check-in and badges. Kids cannot join or leave shifts.',
                    ),
                  ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_saving || (catalog?.familyLoading ?? false))
                const LinearProgressIndicator(),
              if (catalog?.familyFailed ?? false)
                TextButton(
                  onPressed: catalog!.retry,
                  child: const Text('Could not load family. Retry'),
                ),
              Text(
                kidMode ? 'Hi, ${_session.userName}!' : 'Your family',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                kidMode
                    ? 'Pick a challenge and keep helping!'
                    : 'Create kid accounts and swap profiles here.',
              ),
              const SizedBox(height: 22),
              if (!kidMode) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Family accounts',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed:
                          _saving ||
                              (catalog?.familyLoading ?? false) ||
                              (catalog?.familyFailed ?? false)
                          ? null
                          : _addChild,
                      icon: const Icon(Icons.add),
                      label: const Text('Add kid'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _AccountTile(
                  name: _session.userName,
                  subtitle: 'Parent · ${_session.parentRole.name}',
                  active: true,
                  onTap: null,
                ),
                for (final child in _session.children)
                  _AccountTile(
                    name: child.name,
                    subtitle: 'Kid account',
                    active: false,
                    onTap:
                        _saving ||
                            (catalog?.familyLoading ?? false) ||
                            (catalog?.familyFailed ?? false)
                        ? null
                        : () => _switchAndGoHome(childId: child.id),
                  ),
                const SizedBox(height: 24),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _switchAndGoHome(),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch back to parent'),
                ),
                const SizedBox(height: 24),
              ],
              if (!kidMode) ...[
                const FamilyShiftBookings(),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Family challenges',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!kidMode)
                    IconButton.filledTonal(
                      onPressed:
                          _saving ||
                              (catalog?.familyLoading ?? false) ||
                              (catalog?.familyFailed ?? false)
                          ? null
                          : _addChallenge,
                      tooltip: 'Create challenge',
                      icon: const Icon(Icons.add_task),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (catalog != null &&
                  (catalog.attendanceLoading || catalog.attendanceFailed))
                AttendanceStatus(store: catalog),
              for (final challenge in _session.challenges)
                Card(
                  child: ListTile(
                    leading: Text(
                      challenge.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      challenge.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      catalog == null
                          ? (kidMode
                                ? 'You can do it!'
                                : 'Visible to all your kids')
                          : catalog.attendanceLoading ||
                                catalog.attendanceFailed
                          ? 'Progress unavailable until attendance loads.'
                          : !catalog.family.challengeTargets.containsKey(
                              challenge.id,
                            )
                          ? 'Legacy challenge: create a new challenge with a completed-shift goal to track progress.'
                          : '${catalog.rewards.familyShifts.clamp(0, catalog.family.challengeTargets[challenge.id]!)} / ${catalog.family.challengeTargets[challenge.id]} confirmed family shifts${catalog.rewards.familyShifts >= catalog.family.challengeTargets[challenge.id]! ? ' · Complete!' : ''}',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 5),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.name,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });
  final String name;
  final String subtitle;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        child: Icon(active ? Icons.person : Icons.child_care),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
      trailing: onTap == null
          ? const Chip(label: Text('Active'))
          : const Icon(Icons.swap_horiz),
      onTap: onTap,
    ),
  );
}
