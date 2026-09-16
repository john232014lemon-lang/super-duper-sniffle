import 'package:flutter/material.dart';

import '../data/session_store.dart';
import '../models/kid_badge.dart';
import 'home_screen.dart';
import 'family_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _session = SessionStore.instance;

  KidBadge? get _featured {
    final id = _session.featuredKidBadge;
    if (id == null) return null;
    return kidBadges.where((badge) => badge.id == id).firstOrNull;
  }

  void _finish() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(name: _session.userName),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = _featured;
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFFE2F6E8),
                  child: Text(
                    featured?.emoji ?? '🌱',
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _session.userName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                featured?.name ?? 'Choose a Kid Mode badge after check-in',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF718078)),
              ),
              const SizedBox(height: 6),
              Text(
                _session.phoneNumber,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),
              const Text(
                'Choose your experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (!_session.isKidAccount)
                SegmentedButton<BushelRole>(
                  segments: const [
                    ButtonSegment(
                      value: BushelRole.volunteer,
                      icon: Icon(Icons.volunteer_activism_outlined),
                      label: Text('Volunteer'),
                    ),
                    ButtonSegment(
                      value: BushelRole.coordinator,
                      icon: Icon(Icons.groups_outlined),
                      label: Text('Coordinator'),
                    ),
                  ],
                  selected: {_session.parentRole},
                  showSelectedIcon: false,
                  onSelectionChanged: (roles) => setState(() {
                    _session.setRole(roles.first);
                  }),
                ),
              const SizedBox(height: 20),
              if (_session.familyAccount) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FamilyCenterScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.family_restroom),
                  label: const Text('Open Family Center'),
                ),
                const SizedBox(height: 20),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, size: 34),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kid badges',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '${_session.unlockedKidBadges.length} of ${kidBadges.length} unlocked',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _finish,
                child: const Text('Use this mode'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
