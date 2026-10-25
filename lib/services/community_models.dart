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
  const ShiftGroup({
    required this.members,
    this.childMembers = const {},
    required this.version,
  });
  final Map<String, String> members;
  /// parentUid → (childId → display name). Visible to group members/leaders.
  final Map<String, Map<String, String>> childMembers;
  final int version;
  int get votesNeeded => (members.length * 2 / 3).ceil();

  static String childVoteTarget(String parentUid, String childId) =>
      '$parentUid::$childId';

  static (String parentUid, String childId)? parseChildVoteTarget(String target) {
    final separator = target.indexOf('::');
    if (separator <= 0 || separator >= target.length - 2) return null;
    return (
      target.substring(0, separator),
      target.substring(separator + 2),
    );
  }

  Iterable<({String target, String parentUid, String childId, String name})>
  get childList sync* {
    for (final parent in childMembers.entries) {
      for (final child in parent.value.entries) {
        yield (
          target: childVoteTarget(parent.key, child.key),
          parentUid: parent.key,
          childId: child.key,
          name: child.value,
        );
      }
    }
  }
}

class RemovalVote {
  const RemovalVote({required this.version, required this.voters});
  final int version;
  final List<String> voters;
}
