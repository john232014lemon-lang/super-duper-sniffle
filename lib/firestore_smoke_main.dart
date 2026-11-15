import 'package:material_ui/material_ui.dart';

import 'firebase_bootstrap.dart';
import 'screens/firestore_smoke_screen.dart';

/// Opt-in developer entry point; the normal app and demo are unchanged.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseBootstrap(signedInHome: FirestoreSmokeScreen()));
}
