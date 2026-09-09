import 'package:flutter/material.dart';

import '../data/mock_food_banks.dart';
import '../data/session_store.dart';
import '../models/kid_badge.dart';
import 'food_bank_detail_screen.dart';
import 'food_bank_map_screen.dart';
import 'check_in_screen.dart';
import 'coordinator_screen.dart';
import 'profile_screen.dart';
import '../widgets/bushel_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.name});

  final String name;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  void _comingSoon(String destination) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$destination is coming in a future update.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_session.role == BushelRole.kid) {
      return _KidHomeScreen(
        name: widget.name,
        onProfile: _openProfile,
        onCheckIn: _openCheckIn,
      );
    }
    return Scaffold(
      key: const ValueKey('home'),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  sliver: SliverList.list(
                    children: [
                      _HomeHeader(
                        name: widget.name,
                        role: _session.role,
                        onProfile: _openProfile,
                      ),
                      if (_session.role == BushelRole.coordinator) ...[
                        const SizedBox(height: 14),
                        _CoordinatorNotice(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CoordinatorScreen(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _NextShiftCard(onCheckIn: _openCheckIn),
                      const SizedBox(height: 18),
                      const _ImpactStats(),
                      const SizedBox(height: 26),
                      _SectionHeader(
                        title: 'Food banks near you',
                        action: 'See map',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FoodBankMapScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 176,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FoodBankCard(
                              name: 'Second Harvest',
                              status: 'Open · 12 shifts open',
                              distance: '0.8 mi',
                              accent: const Color(0xFFEF5269),
                              icon: Icons.inventory_2_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FoodBankDetailScreen(
                                    foodBank: mockFoodBanks[0],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _FoodBankCard(
                              name: 'Loaves & Fishes',
                              status: 'Open · 4 shifts open',
                              distance: '1.4 mi',
                              accent: const Color(0xFF23B65E),
                              icon: Icons.groups_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FoodBankDetailScreen(
                                    foodBank: mockFoodBanks[1],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _FoodBankCard(
                              name: 'Martha’s Kitchen',
                              status: 'Open · 2 shifts open',
                              distance: '2.1 mi',
                              accent: const Color(0xFF2D8FC7),
                              icon: Icons.soup_kitchen_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FoodBankDetailScreen(
                                    foodBank: mockFoodBanks[2],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _SectionHeader(
                        title: 'Help needed today',
                        action: 'All',
                        onPressed: () => _comingSoon('All shifts'),
                      ),
                      const SizedBox(height: 12),
                      _HelpCard(
                        title: 'Delivery drivers',
                        detail: 'Second Harvest · 2–4 PM',
                        icon: Icons.local_shipping,
                        color: const Color(0xFF2CC56A),
                        action: 'Claim',
                        onTap: () => _comingSoon('Shift signup'),
                      ),
                      const SizedBox(height: 10),
                      _HelpCard(
                        title: 'Produce sorting',
                        detail: 'Loaves & Fishes · 3–5 PM',
                        icon: Icons.eco,
                        color: const Color(0xFFFFAD17),
                        action: '3 left',
                        onTap: () => _comingSoon('Shift signup'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BushelNavigationBar(selectedIndex: 0, onHome: () {}),
    );
  }

  void _openCheckIn() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CheckInScreen()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.role,
    required this.onProfile,
  });

  final String name;
  final BushelRole role;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF20B85A), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'San Jose, CA',
                    style: TextStyle(
                      color: Color(0xFF68756D),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Hi, '),
                    TextSpan(
                      text: name,
                      style: const TextStyle(color: Color(0xFF31C663)),
                    ),
                    const TextSpan(text: ' 🌱'),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                role == BushelRole.coordinator
                    ? 'Coordinator mode'
                    : 'Volunteer mode',
                style: const TextStyle(
                  color: Color(0xFF718078),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          tooltip: 'Notifications',
          icon: const Badge(child: Icon(Icons.notifications_outlined)),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onProfile,
          tooltip: 'Open profile',
          icon: const CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFFDCF3E3),
            child: Icon(Icons.person, color: Color(0xFF126D3A)),
          ),
        ),
      ],
    );
  }
}

class _CoordinatorNotice extends StatelessWidget {
  const _CoordinatorNotice({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFE8F3FF),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.groups, color: Color(0xFF287EB5)),
        title: const Text(
          'Coordinator mode',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text('Manage volunteer profiles and removal votes.'),
        trailing: const Icon(Icons.arrow_forward),
      ),
    );
  }
}

class _KidHomeScreen extends StatelessWidget {
  const _KidHomeScreen({
    required this.name,
    required this.onProfile,
    required this.onCheckIn,
  });

  final String name;
  final VoidCallback onProfile;
  final VoidCallback onCheckIn;

  KidBadge? get _featured {
    final id = SessionStore.instance.featuredKidBadge;
    if (id == null) return null;
    for (final badge in kidBadges) {
      if (badge.id == id) return badge;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final featured = _featured;
    return Scaffold(
      key: const ValueKey('kid-home'),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hi, $name! 🌈',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Open profile',
                      onPressed: onProfile,
                      icon: Text(
                        featured?.emoji ?? '🌱',
                        style: const TextStyle(fontSize: 25),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFC83D), Color(0xFFFF8F55)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR NEXT ADVENTURE',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Sorting & Packing Line',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text('Saturday · 9:00 AM · Warehouse A'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 74,
                  child: FilledButton.icon(
                    onPressed: onCheckIn,
                    icon: const Icon(Icons.qr_code_scanner, size: 30),
                    label: const Text(
                      'CHECK IN & PICK A BADGE',
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text(
                          featured?.emoji ?? '🔒',
                          style: const TextStyle(fontSize: 52),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My favorite badge',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                featured?.name ?? 'Unlock one after check-in!',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Card(
                  color: Color(0xFFE5F8EC),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 38)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Help out, check in, and grow your badge garden!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BushelNavigationBar(selectedIndex: 0),
    );
  }
}

class _NextShiftCard extends StatelessWidget {
  const _NextShiftCard({required this.onCheckIn});

  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22B95C), Color(0xFF62D483)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x302ABB61),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x33103822),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '▣  YOUR NEXT SHIFT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sorting & Packing Line',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.store_outlined, color: Colors.white, size: 17),
              SizedBox(width: 6),
              Text(
                'Second Harvest Food Bank',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAT · JUN 20',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '9:00–12:00 AM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onCheckIn,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                icon: const Icon(Icons.qr_code, size: 17),
                label: const Text('Check in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactStats extends StatelessWidget {
  const _ImpactStats();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '1.2k',
            label: 'MEALS PACKED',
            color: Color(0xFF22B95C),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '48h',
            label: 'HOURS GIVEN',
            color: Color(0xFFF4A000),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '6',
            label: 'BANKS HELPED',
            color: Color(0xFF199ED4),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF718078),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onPressed,
  });

  final String title;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}

class _FoodBankCard extends StatelessWidget {
  const _FoodBankCard({
    required this.name,
    required this.status,
    required this.distance,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String status;
  final String distance;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.92),
                  const Color(0xFF123C2B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          distance,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(icon, color: Colors.white, size: 38),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE4EAE5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFF78867E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  action,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
