import 'package:cloud_firestore/cloud_firestore.dart';

import 'catalog_repository.dart';

enum ShiftTaskStatus {
  todo('To do'),
  inProgress('In progress'),
  done('Done');

  const ShiftTaskStatus(this.label);
  final String label;
}

class ShiftTask {
  ShiftTask(QueryDocumentSnapshot<Map<String, dynamic>> document)
    : id = document.id,
      title = document.data()['title'] as String,
      station = document.data()['station'] as String,
      assigneeUid = document.data()['assigneeUid'] as String,
      revision = document.data()['revision'] as int,
      status = ShiftTaskStatus.values.byName(
        document.data()['status'] as String,
      );

  final String id;
  final String title;
  final String station;
  final String assigneeUid;
  final int revision;
  final ShiftTaskStatus status;
}

class ShiftBoardMessage {
  ShiftBoardMessage(Map<String, dynamic> data)
    : authorName = data['authorName'] as String,
      body = data['body'] as String,
      sentAt = (data['sentAt'] as Timestamp?)?.toDate();

  final String authorName;
  final String body;
  final DateTime? sentAt;
}

class ShiftDashboardRepository {
  ShiftDashboardRepository(this.shiftId, this.uid);

  final String shiftId;
  final String uid;
  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _shift =>
      _db.collection('shifts').doc(shiftId);
  CollectionReference<Map<String, dynamic>> get _tasks =>
      _shift.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _messages =>
      _shift.collection('messages');

  Stream<List<ShiftTask>> watchTasks({required bool coordinator}) {
    final query = coordinator
        ? _tasks
        : _tasks.where('assigneeUid', isEqualTo: uid);
    return query.snapshots().map((snapshot) {
      final tasks = snapshot.docs.map(ShiftTask.new).toList();
      return tasks..sort((a, b) {
        final station = a.station.toLowerCase().compareTo(
          b.station.toLowerCase(),
        );
        return station == 0
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : station;
      });
    });
  }

  Stream<List<ShiftBoardMessage>> watchMessages() => _messages
      .orderBy('sentAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => ShiftBoardMessage(doc.data())).toList(),
      );

  Future<void> createTask(String title, String station) => _tasks.doc().set({
    'title': title.trim(),
    'station': station.trim(),
    'status': ShiftTaskStatus.todo.name,
    'assigneeUid': '',
    'revision': 1,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateTask(
    ShiftTask task, {
    String? assigneeUid,
    ShiftTaskStatus? status,
  }) => _db.runTransaction((transaction) async {
    final ref = _tasks.doc(task.id);
    final current = (await transaction.get(ref)).data();
    if (current == null || current['revision'] != task.revision) {
      throw const CatalogException(
        'This task changed. Review the latest version and try again.',
      );
    }
    if ((assigneeUid == null || assigneeUid == task.assigneeUid) &&
        (status == null || status == task.status)) {
      return;
    }
    if (assigneeUid != null &&
        assigneeUid.isNotEmpty &&
        assigneeUid != task.assigneeUid) {
      final group = await transaction.get(
        _db.collection('groups').doc(shiftId),
      );
      final members = group.data()?['members'] as Map<String, dynamic>?;
      if (members?.containsKey(assigneeUid) != true) {
        throw const CatalogException('That volunteer is no longer booked.');
      }
    }
    transaction.update(ref, {
      'assigneeUid': ?assigneeUid,
      'status': ?status?.name,
      'revision': task.revision + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });

  Future<void> postMessage(String body) async {
    final profile = await _db
        .collection('profiles')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    final name = profile.data()?['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const CatalogException('Set your profile name before posting.');
    }
    await _messages.doc().set({
      'authorUid': uid,
      'authorName': name,
      'body': body.trim(),
      'sentAt': FieldValue.serverTimestamp(),
    });
  }
}
