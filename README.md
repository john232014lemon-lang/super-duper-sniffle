# Bushel

Bushel is a family-friendly Flutter app for finding food banks and volunteering together. The first version uses local mock data so the core experience can be built and tested one small feature at a time.

Android and Web are configured for Firebase project `bushel-volunteer-20260925`. Firebase initialization and Email/Password authentication are implemented; live API signup now works. Profiles, banks, shifts, and adult signups use Firestore in Dallas, Texas. Groups, families, and coordinator applications are implemented but await the new rules deployment; attendance and rewards remain later slices. Slices 14-15 provide a local demo mode and working shift calendar without Firebase login.

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

The testing policy in [plan.md](plan.md) favors manual QA. Only nine offline smoke checks remain; use a relevant check for a small change, or the small suite for changes spanning several boundaries:

```sh
flutter test --no-pub test/smoke_test.dart
```

Run `flutter analyze --no-pub` once when Dart code changes. Release builds, emulator runs, and live tests are not routine slice requirements. Future agents should add at most 0–2 high-value smoke checks per feature and finish with 2–4 manual testing ideas. See [the manual testing menu](docs/manual_testing.md) for account switching, failed saves, and backend permission checks.

## Adult profiles (Slice 17)

Normal startup saves the adult's name, preferred Volunteer/Coordinator experience, and family setting to `profiles/{uid}`, with a server `updatedAt` timestamp. Onboarding waits for a successful save; Profile's **Use this mode** saves the selected experience. Failed saves retain the form for retry. Returning adults skip onboarding. Logout clears local state and late responses cannot restore the old session.

Profiles are private to their authenticated owner. Rules validate the allowed fields and deny collection queries and forged permission fields. `preferredRole` is only a display preference; with the new rules, coordinator privileges come from approved bank applications. Kids, challenges, and groups have Firestore implementations described below. Attendance and rewards remain for later slices. Demo mode never reads or writes Firebase.

## Food banks and shifts (Slices 18–19)

Normal mode streams discovery cards, map markers, bank details, shifts, and signups from Firestore. Empty/error states never fall back to mock banks. Date filtering keeps the stored calendar day across timezones. **My shifts** supports cancellation; creation and signup failures can be retried. Slice 21 adds parent-managed child places. Persistent attendance and rewards are implemented in Slices 22–23 below.

| Path | Purpose | Client access |
| --- | --- | --- |
| `banks/{bankId}` | Name, address, hours, description, coordinates | Signed-in read; trusted admin writes |
| `coordinatorApplications/{uid}/banks/{bankId}` | Application and administrator-controlled status | Owner read/create pending; trusted admin review |
| `shifts/{shiftId}` | Bank, creator UID, date, time, station, capacity, signup count | Signed-in read; approved coordinator creates |
| `registrations/{uid}/shifts/{shiftId}` | One registration per adult and shift | Owner-only read; atomic signup/cancellation |

Signup and cancellation use [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions). The new rules require registration, group membership, and capacity changes together. They reject duplicates and count tampering. Removing another adult requires a verified two-thirds vote, regardless of coordinator role. No Cloud Functions or billing setup is needed.

No mock catalog records or permanent approvals were imported. A trusted project administrator can use the Firebase CLI login to import real records and review submitted applications. Refresh an expired CLI session with `firebase projects:list` (or `firebase login --reauth` if required). The helper targets `bushel-volunteer-20260925` and never prints tokens.

Create a JSON array of bank records. Each record needs `id`, `name`, `shortName`, `description`, `address`, `hours`, numeric `latitude`/`longitude`, and optionally `distance`. Use stable IDs such as `houston-central`; omit distance unless it is meaningful for the catalog. The helper creates new records atomically and refuses to overwrite existing ones.

```sh
python tools/firebase/catalog_admin.py import-banks path/to/banks.json
python tools/firebase/catalog_admin.py approve --uid FIREBASE_AUTH_UID --bank BANK_ID
python tools/firebase/catalog_admin.py reject --uid FIREBASE_AUTH_UID --bank BANK_ID
```

Use the adult's Firebase Authentication UID, not their email or local `parent` ID. Approval requires an existing application. After approval, open that bank's details and choose **Add shift**. The form accepts a date, time, station, and 1–500 spots. The profile's Volunteer/Coordinator switch cannot create approvals. `grant`/`revoke` remain aliases for approving/rejecting existing applications; legacy `coordinatorAccess` records do not grant access under the new rules.

## Coordinator applications and Slices 20–21

**Deployment status:** The Slice 20–21 implementation was verified before the test-suite reduction; historical results are in `docs/development_log.md`. Production rules deployment remains pending explicit authorization. The previously deployed Slice 19 rules are unchanged. Deploy the new rules before using this app revision with live data. A prior read-only audit found zero existing shifts requiring migration; recheck before a later deployment.

On a bank's detail page, an adult selects **Apply to coordinate** and provides their name, contact information, and experience/reason. The form retains input after a failed save. A successful submission stays **pending** and cannot grant privileges. Each adult has one application per bank; rejected applications require administrator follow-up.

For database approval, open the existing project's Firestore database and navigate to:

```text
coordinatorApplications / FIREBASE_AUTH_UID / banks / BANK_ID
```

Review `name`, `contact`, `reason`, and `submittedAt`, then set the string field `status` to **`approved`**. Set it to **`rejected`** to deny or revoke coordination. The app streams this status and unlocks **Add shift** only for the approved bank. Clients cannot edit status, resubmit/overwrite applications, approve themselves, or inspect another person's application. The administrator commands above perform the same review action and check for concurrent changes.

| Path | Stored data and access |
| --- | --- |
| `groups/{shiftId}` | Adult display names, seat counts, membership version, removed UIDs; readable only by current group members |
| `groups/{shiftId}/votes/{targetUid}` | Voter UIDs and membership version; current adults vote once per target/version, never for themselves |
| `families/{parentUid}` | Child names, family challenge titles, selected child ID; private to the authenticated parent |
| `registrations/{parentUid}/shifts/{shiftId}.childIds` | Child places managed by that parent; private and atomically counted toward capacity |

Open a group by tapping a shift in **My shifts**, or through the coordinator **Groups** page. Creating a shift does not automatically join its group. The removal threshold is `ceil(2 × current adult members / 3)`, including the target in the denominator. Children do not independently vote. Adult joins/cancellations/removals increment the membership version, invalidating old votes. The final vote attempts an atomic removal; **Complete removal** can retry if that follow-up was interrupted. Server rules validate the quorum and require group removal, registration deletion, and capacity restoration together. Removal also cancels the target parent's child places and prevents their immediate rejoining of that shift.

In **Family Center**, parents create kids and challenges, switch profiles, and reserve child places in shifts they have already joined. Each child consumes one slot. Cancelling the parent's signup cancels all their child places. Kid Mode shows that child's persisted signups and routes shift management to the parent. The selected profile persists under the shared parent account, so switching it also affects the account's other sessions. Kids have no separate authentication identity; the rules reject signup, coordinator, and vote actions while Kid Mode is selected. Attendance, rewards, and goal-based challenge progress are implemented below.

After deployment approval, use:

```sh
python tools/firebase/catalog_admin.py audit-groups
firebase deploy --only firestore:rules,firestore:indexes --project bushel-volunteer-20260925
```

If the audit reports legacy shifts missing groups, backfill their group membership from existing registrations before deploying; do not initialize an occupied shift with an empty group. New shifts create their empty groups atomically.

Use the relevant [manual checks](docs/manual_testing.md) after an authorized deployment. The automated emulator/live harnesses have been removed; do not recreate them by default.

## Attendance and rewards (Slices 22–23)

Implemented locally; rules and indexes have **not** been deployed or manually verified against the live backend. The QR is a persisted simulation, not camera scanning or a secure attendance token.

An approved bank coordinator who created a shift opens **Manage check-ins** on the bank page, or **Shifts you lead** under Groups. Generate the shift QR once. Booked adults and children can simulate scanning on Check-in; submission stays pending until that assigned, still-approved leader confirms. Removed/cancelled participants cannot be confirmed. Duplicate submissions/confirmations use the same record and cannot award twice.

| Path | Purpose |
| --- | --- |
| `shifts/{shiftId}.qrCode` | Immutable mock shift code, published by the assigned approved leader |
| `attendance/{shiftId}/families/{ownerUid}/attendanceEntries/{participantId}` | `parent` or child ID; pending then confirmed with server timestamps; owner and assigned leader can read |
| `rewardPreferences/{uid}/people/{childId}` | Featured badge backed by a confirmed record for that child |
| `families/{uid}.challengeTargets` | Goal per challenge ID, 1–100 distinct completed family shifts |

Confirmed attendance is the persistent reward ledger: **100 points per participant per shift**, with adult badge thresholds derived from those points. There are no client-writable balances or Cloud Functions to deploy. Every confirmed child shift offers one permanent badge choice in **My badge garden**. Featuring an already earned badge consumes no new choice. Profile links to rewards/badge selection. Loading and failed attendance reads have retry states and never substitute mock rewards.

Challenge progress includes all past confirmed family shifts, counting one shift once even when multiple family members attended. Legacy text-only challenges remain visible with a notice to create a goal-based challenge; titles such as pounds or hours are not interpreted as shift goals. Challenges grant no additional points.

The assigned leader can see participant names, including booked children's names, for attendance management; other group members cannot read those attendance records. Attendance history and earned rewards remain after signup cancellation. The existing parent-managed Kid Mode uses the parent's authentication identity.

Deploy both rules and `firestore.indexes.json` after approval, then wait for indexes to finish building. Owner/leader queries use collection-group single-field indexes, as described in [Firebase index documentation](https://firebase.google.com/docs/firestore/query-data/index-overview). Follow the [manual attendance checks](docs/manual_testing.md#attendance-and-rewards) with ordinary authenticated clients; offline smoke checks do not validate Firestore permissions.

## Firestore foundation (Slice 16)

- Project: `bushel-volunteer-20260925`; database: `(default)`; Standard edition, Native mode.
- Location: **Dallas, Texas (`us-south1`)**. The existing database is already created; do not create another for this slice.
- The earlier Slice 19 rules are deployed; the current `firestore.rules` adds Slices 20–23 and is pending authorization. Only the authenticated owner can create/get/delete `smokeTests/{uid}/runs/{runId}`. Test data must use the fixed message and a server timestamp. Diagnostic queries/updates remain denied. Profiles, banks, shifts, and registrations have the separate rules above; unmigrated collections remain denied.
- Adult profiles, banks, shifts, and adult registrations use Firestore. Demo mode still initializes no Firebase services.

Run the separate Flutter diagnostic, sign in, then click **Run connection check**:

```sh
flutter run -d chrome --target lib/firestore_smoke_main.dart
```

It writes a unique test document, reads from the server, deletes it, and verifies deletion. This entry point is separate from normal app/demo flows. If connectivity or sign-in changes interrupt cleanup, rerun or inspect the current user's `smokeTests` documents.

Backend QA is developer-driven. Use ordinary authenticated client sessions or the Rules Playground for access checks; administrator operations bypass security rules. Optional manual emulator guidance is in `docs/manual_testing.md`. No automated emulator or live test suite is required before finishing a slice.

Windows native plugin setup still reports a Developer Mode/symlink requirement; Android execution also needs the missing Android SDK/device. The Web diagnostic build succeeds with `--no-pub` using the resolved dependencies.
