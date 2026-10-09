import 'package:flutter/material.dart';
import '../data/catalog_store.dart';
import '../data/session_store.dart';
import '../services/catalog_repository.dart';
import '../services/community_models.dart';

class LiveGroupScreen extends StatefulWidget {
  const LiveGroupScreen({
    super.key,
    required this.shiftId,
    required this.title,
  });
  final String shiftId;
  final String title;
  @override
  State<LiveGroupScreen> createState() => _LiveGroupScreenState();
}

class _LiveGroupScreenState extends State<LiveGroupScreen> {
  CatalogStore? _store;
  late Stream<ShiftGroup> _group;
  late Stream<Map<String, RemovalVote>> _votes;
  bool _busy = false;
  String? _error;
  void _subscribe() {
    _group = _store!.repository.watchGroup(widget.shiftId);
    _votes = _store!.repository.watchVotes(widget.shiftId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = CatalogScope.maybeOf(context);
    if (!identical(store, _store)) {
      _store = store;
      if (store != null) _subscribe();
    }
  }

  Future<void> _vote(
    String target,
    String name,
    int needed,
    bool finalize,
  ) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(finalize ? 'Complete removal?' : 'Vote to remove $name?'),
        content: Text(
          'Removal needs $needed votes, at least two-thirds of current adult members. It revokes family points and badges from this shift, even after check-in. It cancels this member’s signup and any child places they manage. Votes reset when adult membership changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(finalize ? 'Complete removal' : 'Submit vote'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repository = _store!.repository;
      if (finalize) {
        await repository.finalizeRemoval(_store!.uid, widget.shiftId, target);
      } else {
        await repository.voteToRemove(_store!.uid, widget.shiftId, target);
      }
    } catch (error) {
      if (mounted) setState(() => _error = catalogError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _retry() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Could not load this group.'),
      TextButton(
        onPressed: () => setState(_subscribe),
        child: const Text('Retry'),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final store = CatalogScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} · Members')),
      body:
          store == null ||
              !store.signups.contains(widget.shiftId) ||
              SessionStore.instance.isKidAccount
          ? const Center(
              child: Text('You are no longer a member of this group.'),
            )
          : StreamBuilder<ShiftGroup>(
              stream: _group,
              builder: (context, groupSnapshot) {
                if (groupSnapshot.hasError) return Center(child: _retry());
                if (!groupSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final group = groupSnapshot.data!;
                if (!group.members.containsKey(store.uid)) {
                  return const Center(
                    child: Text('You are no longer a member of this group.'),
                  );
                }
                return StreamBuilder<Map<String, RemovalVote>>(
                  stream: _votes,
                  builder: (context, votesSnapshot) {
                    if (votesSnapshot.hasError) return Center(child: _retry());
                    if (!votesSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text(
                              '${group.members.length} adult members · ${group.votesNeeded} votes needed for removal',
                            ),
                            const Text(
                              'Child places are managed privately by their parents. Adult membership changes reset removal votes.',
                            ),
                            if (group.members.length < 3)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Removal voting needs at least 3 adults. Two-thirds of all members must vote, and nobody can vote for themselves. You can cancel your own signup from My shifts.',
                                ),
                              ),
                            if (_error != null)
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            if (_busy) const LinearProgressIndicator(),
                            for (final entry in group.members.entries)
                              Builder(
                                builder: (context) {
                                  final vote = votesSnapshot.data![entry.key];
                                  final voters = vote?.version == group.version
                                      ? vote!.voters
                                      : <String>[];
                                  final self = entry.key == store.uid;
                                  final voted = voters.contains(store.uid);
                                  final ready =
                                      voters.length >= group.votesNeeded;
                                  return Card(
                                    child: ListTile(
                                      title: Text(entry.value),
                                      subtitle: Text(
                                        '${voters.length}/${group.votesNeeded} removal votes',
                                      ),
                                      trailing: TextButton(
                                        onPressed:
                                            _busy ||
                                                self ||
                                                group.members.length < 3 ||
                                                (voted && !ready)
                                            ? null
                                            : () => _vote(
                                                entry.key,
                                                entry.value,
                                                group.votesNeeded,
                                                ready,
                                              ),
                                        child: Text(
                                          self
                                              ? 'You'
                                              : ready
                                              ? 'Complete removal'
                                              : voted
                                              ? 'Voted'
                                              : 'Vote out',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
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
