# Bushel

Bushel is a family-friendly Flutter app for finding food banks and volunteering together. The first version uses local mock data so the core experience can be built and tested one small feature at a time.

Firebase initialization and Email/Password authentication are implemented locally. Connecting a Firebase project and enabling its provider are still required before the app can sign in. Food banks, shifts, families, roles, and rewards remain mock data; Firestore starts in Slice 14.

## Run locally

```sh
flutter pub get
flutter run
```

## Firebase setup (slices 12 and 13)

The Firebase CLI is already installed on this machine, and FlutterFire CLI 1.4.1 has been activated. Finish setup with your Google account and intended Firebase project:

```sh
firebase login
firebase projects:list
dart pub global run flutterfire_cli:flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,web
```

Android and Web are suggested targets; choose the actual supported platforms before configuring. The command replaces `lib/firebase_options.dart` with generated project options. The current file deliberately throws a configuration error rather than using fabricated credentials. Until configuration is complete, app startup displays an error with Retry.

In the selected Firebase project's console, open **Authentication > Get started > Sign-in method**, enable **Email/Password** (email-link sign-in is not needed), and save. Do not create Firestore for these slices.

On Windows, enable **Developer Mode** in Settings if Flutter reports that plugin symlinks are unavailable. Then run `flutter pub get` again. Native Windows execution and Android execution have not yet been verified.

Follow the official [FlutterFire setup](https://firebase.google.com/docs/flutter/setup) and [Email/Password authentication](https://firebase.google.com/docs/auth/flutter/password-auth) instructions when finishing project configuration.

## Authentication behavior and verification

- Signed-out adults see Sign in / Create account. Children are still added through the parent's Family Center.
- Firebase's auth-state stream restores an existing sign-in. Profile/onboarding choices remain in memory until Slice 15, so restarting the app restores authentication but requires profile setup again.
- Sign out is available on the profile screen. Logout or a changed authenticated user removes the old navigation stack and resets mock session, family, group, shift, and reward data.
- Volunteer/Coordinator choices only change the mock experience; they grant no backend permissions.
- Initialization and authentication failures have visible retry/error states. Mock widget tests can instantiate `BushelApp` directly; production `main()` always uses the Firebase startup/auth gate.

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
```

After configuration, verify on each selected target: create an adult test account, finish onboarding, sign out from Profile, sign in again, restart to confirm auth restoration, and enter an incorrect password to check the error. Sign in as a second account and confirm the first account's local family/shift data is gone. Live Firebase verification is pending project access.
