import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../data/coordinator_store.dart';
import '../widgets/bushel_navigation_bar.dart';
import 'home_screen.dart';

class FamilyCenterScreen extends StatefulWidget {
  const FamilyCenterScreen({super.key});

  @override
  State<FamilyCenterScreen> createState() => _FamilyCenterScreenState();
}

class _FamilyCenterScreenState extends State<FamilyCenterScreen> {
  final _session = SessionStore.instance;

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
    _session.addChild(name);
    CoordinatorStore.instance.addFamilyChild(_session.children.last);
  }

  Future<void> _addChallenge() async {
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
    _session.addChallenge(title);
  }

  void _switchAndGoHome({String? childId}) {
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
    final kidMode = _session.isKidAccount;
    return Scaffold(
      appBar: AppBar(title: const Text('Family Center')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
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
                      onPressed: _addChild,
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
                    onTap: () => _switchAndGoHome(childId: child.id),
                  ),
                const SizedBox(height: 24),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () => _switchAndGoHome(),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch back to parent'),
                ),
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
                      onPressed: _addChallenge,
                      tooltip: 'Create challenge',
                      icon: const Icon(Icons.add_task),
                    ),
                ],
              ),
              const SizedBox(height: 10),
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
                      kidMode ? 'You can do it!' : 'Visible to all your kids',
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
