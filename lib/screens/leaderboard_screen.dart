import 'package:material_ui/material_ui.dart';

import '../data/catalog_store.dart';
import '../data/session_store.dart';
import '../data/shift_store.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_repository.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = CatalogScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: catalog == null
              ? const _DemoLeaderboard()
              : _LiveLeaderboard(key: ValueKey(catalog.uid), uid: catalog.uid),
        ),
      ),
    );
  }
}

class _DemoLeaderboard extends StatelessWidget {
  const _DemoLeaderboard();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([ShiftStore.instance, SessionStore.instance]),
    builder: (context, _) => _Rankings(
      entries: [
        if (ShiftStore.instance.demoAdultPoints > 0)
          LeaderboardEntry(
            id: 'parent',
            displayName: SessionStore.instance.parentName
                .trim()
                .split(RegExp(r'\s+'))
                .first,
            points: ShiftStore.instance.demoAdultPoints,
          ),
      ],
      currentUid: 'parent',
      demo: true,
    ),
  );
}

class _LiveLeaderboard extends StatefulWidget {
  const _LiveLeaderboard({super.key, required this.uid});
  final String uid;
  @override
  State<_LiveLeaderboard> createState() => _LiveLeaderboardState();
}

class _LiveLeaderboardState extends State<_LiveLeaderboard> {
  final _repository = LeaderboardRepository();
  late Stream<bool> _ready;
  late Stream<List<LeaderboardEntry>> _leaders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _ready = _repository.watchReady();
    _leaders = _repository.watchLeaders();
  }

  Widget _error() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load the leaderboard. Please try again.'),
          TextButton(
            onPressed: () => setState(_load),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: _ready,
    builder: (context, status) {
      if (status.hasError) return _error();
      if (!status.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (status.data != true) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The leaderboard is being set up. Please check back soon.',
            ),
          ),
        );
      }
      return StreamBuilder<List<LeaderboardEntry>>(
        stream: _leaders,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error();
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Rankings(entries: snapshot.data!, currentUid: widget.uid);
        },
      );
    },
  );
}

class _Rankings extends StatelessWidget {
  const _Rankings({
    required this.entries,
    required this.currentUid,
    this.demo = false,
  });
  final List<LeaderboardEntry> entries;
  final String currentUid;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]
      ..sort((a, b) {
        final score = b.points.compareTo(a.points);
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          size: 56,
          color: Color(0xFF168845),
        ),
        const SizedBox(height: 12),
        Text(
          demo ? 'Local demo leaderboard' : 'Top volunteers',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          demo
              ? 'Only this demo session is shown. Confirm a parent check-in to earn points.'
              : 'Top 50 adults by all-time points. Each confirmed shift earns 100 points. Updates may take a moment.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'First names only. Children’s points stay private. Equal points share a rank.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF718078), fontSize: 12),
        ),
        const SizedBox(height: 24),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No confirmed points yet. Your next shift can start the board!',
              textAlign: TextAlign.center,
            ),
          ),
        for (var index = 0; index < sorted.length; index++)
          Builder(
            builder: (context) {
              final entry = sorted[index];
              final rank =
                  sorted.indexWhere((other) => other.points == entry.points) +
                  1;
              final isYou = entry.id == currentUid;
              return Card(
                color: isYou ? const Color(0xFFE2F6E8) : null,
                child: ListTile(
                  leading: CircleAvatar(child: Text('$rank')),
                  title: Text('${entry.displayName}${isYou ? ' (You)' : ''}'),
                  trailing: Text(
                    '${entry.points} pts',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class LeaderboardButton extends StatelessWidget {
  const LeaderboardButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LeaderboardScreen())),
    icon: const Icon(Icons.leaderboard_outlined),
    label: const Text('Leaderboard'),
  );
}
