# Bushel

Bushel is a family-friendly Flutter app for finding food banks and volunteering together. The first version uses local mock data so the core experience can be built and tested one small feature at a time.

Android and Web are configured for Firebase project `bushel-volunteer-20260925`. Firebase initialization and Email/Password authentication are implemented; live API signup now works. Slice 16 creates the Firestore foundation in Dallas, Texas, but food banks, shifts, families, roles, and rewards still use mock data. Slices 14-15 provide a local demo mode and working shift calendar without Firebase login.

## Run locally

```sh
flutter pub get
flutter run -d chrome --dart-define=BUSHEL_DEMO=true
```

The explicit `BUSHEL_DEMO` flag opens mock onboarding without initializing Firebase. Choose Volunteer or Coordinator; enable family mode to create and switch to kid profiles. A persistent **Local demo** bar labels every screen. **Reset demo** immediately clears local profiles, kids, custom shifts, signups, votes, attendance, points, and badges, then returns to onboarding. Restarting also loses in-memory changes. Map tiles still require internet.

On Shifts, use the month arrows, select a day, or tap **Today**. Dots mark dates with shifts in the selected Available/My Shifts tab. Mock shifts start on the launch date and span three days. Coordinators can add shifts from bank details with the date picker or a valid `YYYY-MM-DD` date; those shifts remain available throughout the current session.

To build the local demo: `flutter build web --dart-define=BUSHEL_DEMO=true`. To use normal Firebase startup, run `flutter run -d chrome` without the flag. Firebase errors never switch into demo mode automatically.

## Firebase setup (slices 12 and 13)

The Firebase CLI and FlutterFire CLI 1.4.1 are installed. Android (`com.bushel.bushel`) and Web have been registered. `.firebaserc` selects Bushel by default, and the generated options, Android service file, and Google Services Gradle plugin are in place. To regenerate the configuration:

```sh
firebase login
dart pub global run flutterfire_cli:flutterfire configure --project=bushel-volunteer-20260925 --platforms=android,web --android-package-name=com.bushel.bushel
```

`lib/firebase_options.dart` now contains real generated configuration for Android and Web. Other platforms intentionally report unsupported configuration. The Firebase client identifiers are not admin credentials; never commit service-account files or login tokens.

**Authentication status:** the Slice 16 live test successfully created and deleted temporary Email/Password users. The earlier `CONFIGURATION_NOT_FOUND` error no longer occurs. Full login/logout/restart testing in Flutter remains pending; the reported school-account restriction on console access was not changed by this work.

`flutter pub get` and the Web release build pass on this machine. Android cannot yet be built or launched because `flutter doctor -v` reports a missing Android SDK and no Android device/emulator is connected. Install the Android toolchain and connect a device or emulator, then run `flutter run -d <android-device-id>`. Native Windows is not configured for Firebase.

Follow the official [FlutterFire setup](https://firebase.google.com/docs/flutter/setup) and [Email/Password authentication](https://firebase.google.com/docs/auth/flutter/password-auth) instructions when finishing project configuration.

## Authentication behavior and verification

- Signed-out adults see Sign in / Create account. Children are still added through the parent's Family Center.
- Firebase's auth-state stream restores an existing sign-in. Slice 17 loads the adult profile from `profiles/{uid}` before opening Home or Family Center. Only a missing profile starts onboarding; read errors offer Retry and Sign out.
- Sign out is available on the profile screen. Logout or a changed authenticated user removes the old navigation stack and resets mock session, family, group, shift, and reward data.
- Volunteer/Coordinator choices only change the mock experience; they grant no backend permissions.
- Initialization and authentication failures have visible retry/error states. Mock widget tests can instantiate `BushelApp` or `DemoApp` directly; `main()` uses the Firebase startup/auth gate unless `BUSHEL_DEMO=true` is explicitly set.

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
```

After enabling the provider, run the opt-in backend smoke test:

```sh
python tools/firebase/auth_smoke_test.py
```

It uses each configured client API key to test signup, sign-in, token refresh, and incorrect-password rejection, and deletes its temporary accounts. It prints no passwords or tokens. This is a backend check, not proof of Android execution or browser session persistence.

On each selected target, also verify: create an adult test account, finish onboarding, sign out from Profile, sign in again, restart to confirm auth and profile restoration, and enter an incorrect password to check the error. Sign in as a second account and confirm the first account's profile and local family/shift data are gone. All 35 local tests pass. Live Firebase UI verification still needs available browser/Android tooling.

## Adult profiles (Slice 17)

Normal startup saves the adult's name, preferred Volunteer/Coordinator experience, and family setting to `profiles/{uid}`, with a server `updatedAt` timestamp. Onboarding waits for a successful save; Profile's **Use this mode** saves the selected experience. Failed saves retain the form for retry. Returning adults skip onboarding. Logout clears local state and late responses cannot restore the old session.

Profiles are private to their authenticated owner. Rules validate the allowed fields and deny collection queries and forged permission fields. `preferredRole` is only a display preference; backend coordinator privileges are not granted. Kid profiles, challenges, banks, shifts, groups, attendance, and rewards still use mocks. Demo mode never reads or writes Firebase.

## Firestore foundation (Slice 16)

- Project: `bushel-volunteer-20260925`; database: `(default)`; Standard edition, Native mode.
- Location: **Dallas, Texas (`us-south1`)**. The existing database is already created; do not create another for this slice.
- `firestore.rules` is deployed. Only the authenticated owner can create/get/delete `smokeTests/{uid}/runs/{runId}`. Test data must use the fixed message and a server timestamp. Diagnostic queries/updates remain denied. Adult profiles have the separate owner-only rules described above; other app collections remain denied.
- Adult profiles use Firestore. Demo mode still initializes no Firebase services.

Run the separate Flutter diagnostic, sign in, then click **Run connection check**:

```sh
flutter run -d chrome --target lib/firestore_smoke_main.dart
```

It writes a unique test document, reads from the server, deletes it, and verifies deletion. This entry point is separate from normal app/demo flows. If connectivity or sign-in changes interrupt cleanup, rerun or inspect the current user's `smokeTests` documents.

Rules/backend checks use Python 3 and the Firebase CLI. Emulator tests also require Java 21+ on PATH:

```sh
firebase emulators:exec --only auth,firestore --project demo-bushel "python tools/firebase/firestore_smoke_test.py --emulator"
python tools/firebase/firestore_smoke_test.py --live
```

Both modes create temporary accounts/documents and clean them up. The emulator uses only loopback services and a `demo-` project; it never falls back to live data. All 45 checks pass in both modes: diagnostic access, profile persistence with a fresh token, owner access, other-user/signed-out rejection, schema validation, and denied privilege escalation. These checks do not claim an Android launch or interactive Flutter verification.

A checksum-verified portable Java 21 runtime was downloaded to the ignored `.dart_tool/firestore-tools/` directory for this machine's test run; system Java was left unchanged. In PowerShell, select it for the current terminal before the emulator command:

```powershell
$env:JAVA_HOME = (Get-ChildItem .dart_tool/firestore-tools -Directory | Select-Object -First 1).FullName
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
```

Deploy future rule changes only after rerunning the emulator checks:

```sh
firebase deploy --only firestore:rules --project bushel-volunteer-20260925
```

Windows native plugin setup still reports a Developer Mode/symlink requirement; Android execution also needs the missing Android SDK/device. The Web diagnostic build succeeds with `--no-pub` using the resolved dependencies.
