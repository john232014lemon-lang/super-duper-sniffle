class FamilyData {
  const FamilyData({
    this.children = const {},
    this.challenges = const {},
    this.activeChildId = '',
    this.challengeTargets = const {},
  });
  final Map<String, String> children;
  final Map<String, String> challenges;
  final String activeChildId;
  final Map<String, int> challengeTargets;
  factory FamilyData.decode(Map<String, dynamic>? data) => FamilyData(
    children: Map<String, String>.from(data?['children'] ?? {}),
    challenges: Map<String, String>.from(data?['challenges'] ?? {}),
    activeChildId: data?['activeChildId'] as String? ?? '',
    challengeTargets: Map<String, int>.from(data?['challengeTargets'] ?? {}),
  );
}

class ShiftGroup {
  const ShiftGroup({required this.members, required this.version});
  final Map<String, String> members;
  final int version;
  int get votesNeeded => (members.length * 2 / 3).ceil();
}

class RemovalVote {
  const RemovalVote({required this.version, required this.voters});
  final int version;
  final List<String> voters;
}
