class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.points,
  });

  final String id;
  final String displayName;
  final int points;

  factory LeaderboardEntry.decode(String id, Map<String, dynamic> data) {
    final name = data['displayName'];
    final points = data['points'];
    if (name is! String ||
        name.trim().isEmpty ||
        points is! int ||
        points <= 0) {
      throw const FormatException('Invalid leaderboard entry');
    }
    return LeaderboardEntry(id: id, displayName: name, points: points);
  }
}
