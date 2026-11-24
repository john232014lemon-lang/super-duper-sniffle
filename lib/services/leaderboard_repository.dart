import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/leaderboard_entry.dart';

class LeaderboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<bool> watchReady() => _db
      .doc('leaderboardStatus/current')
      .snapshots()
      .map((doc) => doc.data()?['ready'] == true);

  Stream<List<LeaderboardEntry>> watchLeaders() => _db
      .collection('leaderboard')
      .orderBy('points', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => LeaderboardEntry.decode(doc.id, doc.data()))
            .toList(),
      );
}
