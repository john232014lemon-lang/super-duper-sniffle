import 'package:flutter/material.dart';
import '../data/catalog_store.dart';

class AttendanceStatus extends StatelessWidget {
  const AttendanceStatus({
    super.key,
    required this.store,
    this.rewards = false,
  });
  final CatalogStore store;
  final bool rewards;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rewards ? store.rewardsLoading : store.attendanceLoading)
          const CircularProgressIndicator()
        else ...[
          Text(
            rewards ? 'Could not load rewards.' : 'Could not load attendance.',
          ),
          TextButton(onPressed: store.retry, child: const Text('Retry')),
        ],
      ],
    ),
  );
}
