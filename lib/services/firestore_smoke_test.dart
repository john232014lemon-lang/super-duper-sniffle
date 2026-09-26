import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Explicit diagnostic only. No app stores are migrated or written here.
Future<void> runFirestoreSmokeTest() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw StateError('Sign in before checking the database.');
  final ref = FirebaseFirestore.instance
      .collection('smokeTests')
      .doc(uid)
      .collection('runs')
      .doc();
  var created = false;
  try {
    await ref.set({
      'message': 'Bushel connection test',
      'createdAt': FieldValue.serverTimestamp(),
    });
    created = true;
    final snapshot = await ref.get(const GetOptions(source: Source.server));
    final data = snapshot.data();
    if (data?['message'] != 'Bushel connection test' ||
        data?['createdAt'] is! Timestamp) {
      throw StateError('The database returned unexpected test data.');
    }
  } finally {
    if (created) await ref.delete();
  }
  final deleted = await ref.get(const GetOptions(source: Source.server));
  if (deleted.exists) throw StateError('The test document was not deleted.');
}
