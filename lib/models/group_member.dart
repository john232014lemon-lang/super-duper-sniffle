class GroupMember {
  const GroupMember({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.shiftsCompleted,
    required this.voteCount,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String role;
  final int shiftsCompleted;
  final int voteCount;

  GroupMember copyWith({int? voteCount}) => GroupMember(
    id: id,
    name: name,
    phoneNumber: phoneNumber,
    role: role,
    shiftsCompleted: shiftsCompleted,
    voteCount: voteCount ?? this.voteCount,
  );
}

class ShiftGroup {
  const ShiftGroup({
    required this.id,
    required this.shiftTitle,
    required this.foodBankName,
    required this.date,
    required this.time,
    required this.station,
  });

  final String id;
  final String shiftTitle;
  final String foodBankName;
  final String date;
  final String time;
  final String station;
}
