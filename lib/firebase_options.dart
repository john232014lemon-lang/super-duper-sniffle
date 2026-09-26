import 'package:firebase_core/firebase_core.dart';

/// Replaced by `dart pub global run flutterfire_cli:flutterfire configure`
/// after selecting an authenticated Firebase project and target platforms.
/// No placeholder credentials are sent to Firebase.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw StateError(
    'Firebase has not been configured. Run FlutterFire configure first.',
  );
}
