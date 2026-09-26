# Bushel

Bushel is a family-friendly Flutter app for finding food banks and volunteering together. The first version uses local mock data so the core experience can be built and tested one small feature at a time.

Android and Web are configured for Firebase project `bushel-volunteer-20260925`. Firebase initialization and Email/Password authentication are implemented, but school-account access blocks live Authentication setup. Food banks, shifts, families, roles, and rewards remain mock data; Firestore starts in Slice 16. Slices 14-15 add a local demo mode and working shift calendar so development can continue without Firebase login.

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

**Remaining console step:** open [Bushel Authentication](https://console.firebase.google.com/project/bushel-volunteer-20260925/authentication), click **Get started**, then enable **Email/Password** under **Sign-in method** (email-link sign-in is not needed), and save. The last live check returned `CONFIGURATION_NOT_FOUND`; no Authentication configuration exists yet. Do not create Firestore for these slices.

`flutter pub get` and the Web release build pass on this machine. Android cannot yet be built or launched because `flutter doctor -v` reports a missing Android SDK and no Android device/emulator is connected. Install the Android toolchain and connect a device or emulator, then run `flutter run -d <android-device-id>`. Native Windows is not configured for Firebase.

Follow the official [FlutterFire setup](https://firebase.google.com/docs/flutter/setup) and [Email/Password authentication](https://firebase.google.com/docs/auth/flutter/password-auth) instructions when finishing project configuration.

## Authentication behavior and verification

- Signed-out adults see Sign in / Create account. Children are still added through the parent's Family Center.
- Firebase's auth-state stream restores an existing sign-in. Profile/onboarding choices remain in memory until Slice 17, so restarting the app restores authentication but requires profile setup again.
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

On each selected target, also verify: create an adult test account, finish onboarding, sign out from Profile, sign in again, restart to confirm auth restoration, and enter an incorrect password to check the error. Sign in as a second account and confirm the first account's local family/shift data is gone. All 27 local tests pass, including demo reset, date filtering, signup, leap-year navigation, and custom-date validation. Live Firebase UI verification remains pending Authentication setup and available browser/Android tooling.
