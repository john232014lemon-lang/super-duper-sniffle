class AttendanceEntry {
  const AttendanceEntry({
    required this.ownerUid,
    required this.participantId,
    required this.shiftId,
    required this.leaderUid,
    required this.name,
    required this.status,
    this.badgeId,
  });
  final String ownerUid;
  final String participantId;
  final String shiftId;
  final String leaderUid;
  final String name;
  final String status;
  final String? badgeId;
  bool get confirmed => status == 'confirmed';
  factory AttendanceEntry.decode(Map<String, dynamic> data) => AttendanceEntry(
    ownerUid: data['ownerUid'] as String,
    participantId: data['participantId'] as String,
    shiftId: data['shiftId'] as String,
    leaderUid: data['leaderUid'] as String,
    name: data['name'] as String,
    status: data['status'] as String,
    badgeId: data['badgeId'] as String?,
  );
}

// No writable balance: confirmed per-person/per-shift records are the ledger.
class AttendanceRewards {
  AttendanceRewards(Iterable<AttendanceEntry> entries)
    : confirmed = {
        for (final entry in entries.where((e) => e.confirmed))
          (entry.ownerUid, entry.participantId, entry.shiftId): entry,
      }.values.toList();
  final List<AttendanceEntry> confirmed;
  int points(String participantId) => completed(participantId).length * 100;
  List<AttendanceEntry> completed(String participantId) =>
      confirmed.where((entry) => entry.participantId == participantId).toList();
  Set<String> badges(String participantId) => completed(
    participantId,
  ).map((entry) => entry.badgeId).whereType<String>().toSet();
  int get familyShifts =>
      confirmed.map((entry) => entry.shiftId).toSet().length;
}
