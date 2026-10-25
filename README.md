# Bushel

Bushel is a family-friendly Flutter app for finding food banks and volunteering together. The first version uses local mock data so the core experience can be built and tested one small feature at a time.

Android and Web are configured for Firebase project `bushel-volunteer-20260925`. Firebase initialization and Email/Password authentication are implemented. Profiles, banks, shifts, signups, groups, families, and coordinator applications use Firestore in Dallas, Texas. Attendance, rewards, and scheduling validation are implemented, with their matching production rules/indexes deployed September 28 after user approval. Slices 14-15 provide a local demo mode and working shift calendar without Firebase login.

## Run locally

```sh
flutter pub get
flutter run -d chrome --dart-define=BUSHEL_DEMO=true
```

The explicit `BUSHEL_DEMO` flag opens mock onboarding without initializing Firebase. Choose Volunteer or Coordinator; enable family mode to create and switch to kid profiles. A persistent **Local demo** bar labels every screen. **Reset demo** immediately clears local profiles, kids, custom shifts, signups, votes, attendance, points, and badges, then returns to onboarding. Restarting also loses in-memory changes. Map tiles still require internet.

For the Congressional App Challenge presentation, run:

```sh
flutter run -d chrome --dart-define=BUSHEL_MOCK=true
```

`BUSHEL_MOCK` uses normal Firebase initialization, sign-in, profiles, banks, shifts, bookings, attendance, and rewards. The banner reads **Mock QR · Firebase data is live**. It also takes precedence over `BUSHEL_DEMO` if both flags are supplied. The separate `BUSHEL_DEMO` flag alone still opens the fully local sandbox.

An assigned, approved coordinator (such as john for Montgomery County Food Bank) opens **Groups → QR & attendance → Generate mock QR**, then shares the displayed code or QR image. A different signed-in adult Volunteer books that shift and opens **Scan → Scan QR with camera**. In `BUSHEL_MOCK` only, that button opens a fake camera viewfinder with the session’s generated mock QR already in frame; **Scan this QR** feeds the normal check-in confirm path (no real camera). Without the mock flag, the real camera scanner is used. Manual code entry still works either way. The check-in is saved as pending in Firebase. The coordinator confirms it in **QR & attendance**, awarding the existing **100 points per shift**. Reloading, signing out/back in, or using separate devices retains this Firebase history. Normal badge thresholds remain unchanged (Harvesting Hero starts at 500 points). The fake-camera QR is kept only in the current app session after generate/rotate (not in Firestore); regenerate if the session was fully reloaded before scanning.

Only the QR credential is simulated: mock codes use a distinct `BUSHELMOCK` prefix, expire after 15 minutes, rotate independently of real tokens, and can work outside the scheduled shift window during an enabled presentation session. Kids never redeem codes independently. Parent Volunteer check-in automatically includes that parent's children who are booked for the shift; all remain pending until the coordinator confirms the parent. Coordinators using the Coordinator role and the shift's assigned coordinator cannot redeem mock codes. Bookings, membership, family-removal revocations, duplicate attendance protection, leader confirmation and rewards remain real. Mock attendance is marked `mockQr: true`; it uses the same per-person/per-shift attendance record, so it cannot award a second set of points for that shift later.

**Backend setup required before mock QR works:**

1. In the Firebase Console for `bushel-volunteer-20260925`, manually publish the complete current `firestore.rules`. No index changes are needed. Publishing remains a developer task; the agent has not deployed these rules.
2. In Firestore `(default)`, create/update the administrator-owned document `settings/mockQr` with Boolean `enabled: true`, Timestamp `expiresAt` set to the intended presentation end, and Array `shiftIds` containing the exact shift IDs you will demonstrate. For the imported shifts those are `mcfb-32fb545a-9d5d-476a-8127-e8c4621e3456` and `mcfb-26c13c3d-8a03-4f49-b73d-59fa2447b82a`. Clients cannot write this setting. A missing/disabled/expired setting or unlisted shift denies mock generation and redemption; the build flag alone grants no backend access. Set `enabled: false` when finished.

Mock verifiers are stored separately at `mockQrTokens/{shiftId}` with `qrTokenHash` and `expiresAt`; raw codes are not saved. Real shift QR fields and real check-in time windows are unchanged. Run without `BUSHEL_MOCK` for the real QR path. Live failures never fall back to local mock data.

On Shifts, use the month arrows, select a day, or tap **Today**. Dots mark dates with shifts in the selected Available/My Shifts tab. Mock shifts start on the launch date and span three days. Coordinators can add shifts from bank details with the date picker or a valid `YYYY-MM-DD` date; those shifts remain available throughout the current session.

To build the local demo: `flutter build web --dart-define=BUSHEL_DEMO=true`. To use normal Firebase startup, run `flutter run -d chrome` without the flag. Firebase errors never switch into demo mode automatically.

## Firebase setup (slices 12 and 13)

### Flutter terminal crash: debugDumpApp

If Flutter exits with `ResidentHandlers.debugDumpApp` and a null-check error, the installed SDK's terminal widget-tree dump tried to use a missing VM-service connection. In Flutter 3.44.8, typing `w` or `W` in the running terminal invokes that command. This stack trace identifies a tooling failure, not an application QR exception.

Wait for the PowerShell prompt (or stop a still-running command with Ctrl+C), then restart:

```sh
flutter run -d chrome --dart-define=BUSHEL_MOCK=true
```

Keep app interaction in the browser. While Flutter owns the terminal, it interprets keystrokes as commands: do not paste another shell command there until it exits. Use `r` for hot reload or `R` for hot restart when the app is connected; avoid `w`/`W`. If another crash happens without terminal input, retain the earlier startup output as well as the new crash report so a connection failure can be investigated separately.

The Firebase CLI and FlutterFire CLI 1.4.1 are installed. Android (`com.bushel.bushel`) and Web have been registered. `.firebaserc` selects Bushel by default, and the generated options, Android service file, and Google Services Gradle plugin are in place. To regenerate the configuration:

```sh
firebase login
dart pub global run flutterfire_cli:flutterfire configure --project=bushel-volunteer-20260925 --platforms=android,web --android-package-name=com.bushel.bushel
```

`lib/firebase_options.dart` now contains real generated configuration for Android and Web. Other platforms intentionally report unsupported configuration. The Firebase client identifiers are not admin credentials; never commit service-account files or login tokens.

**Authentication status:** Slices 12–13 are complete based on developer manual verification on Web (Edge/Chrome) and Android emulator (Pixel 7): sign-in works, sessions persist across app restart, logout returns to sign-in, and invalid passwords show an error without opening the app.

Web and Android emulator authentication were manually verified by the developer. Native Windows is not configured for Firebase.

Follow the official [FlutterFire setup](https://firebase.google.com/docs/flutter/setup) and [Email/Password authentication](https://firebase.google.com/docs/auth/flutter/password-auth) instructions when finishing project configuration.

## Authentication behavior and verification

- Signed-out adults see Sign in / Create account. Children are still added through the parent's Family Center.
- Firebase's auth-state stream restores an existing sign-in. Slice 17 loads the adult profile from `profiles/{uid}` before opening Home or Family Center. Only a missing profile starts onboarding; read errors offer Retry and Sign out.
- Sign out is available on the profile screen. Logout or a changed authenticated user removes the old navigation stack and resets mock session, family, group, shift, and reward data.
- Volunteer/Coordinator choices only change the mock experience; they grant no backend permissions.
- Initialization and authentication failures have visible retry/error states. Mock widget tests can instantiate `BushelApp` or `DemoApp` directly; `main()` uses the Firebase startup/auth gate unless `BUSHEL_DEMO=true` is explicitly set.

The testing policy in [plan.md](plan.md) favors manual QA. The retained offline smoke suite is intentionally small; use a relevant check for a small change, or the small suite for changes spanning several boundaries:

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

**Deployment status:** On October 9, the developer reported manually publishing the full repository rules file and creating the indexes, including coordinator contacts, family removal, and revokedFamilies indexes. Active-source equality and index READY status remain unverified. The September 29 reset deleted the previously audited shifts. Future deployment remains the developer's manual task.

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

### Parent bookings and coordinator contact (September 29 update)

Parents must also be signed up for their children's shifts. **Family Center** and **My shifts** now show all kids' bookings, with **Sign up for shift** and **Leave shift for [child]** controls. Leaving a child removes only that place. Adults can use **Leave shift** at any time; the confirmation explains that leaving as a parent also removes their children's places. Kid Mode cannot join or leave, including in the demo.

Coordinators can save an optional phone under **Your profile**. The form explains that it is shared with signed-in adults and can be cleared. Each child's booked-shift card shows **Call coordinator**, **Text coordinator**, or **Coordinator: no number provided**. A device phone/SMS handler is needed; unsupported devices show a message and the selectable number. These actions use the official [Flutter url_launcher plugin](https://pub.dev/packages/url_launcher).

**Contact rules were reported manually published by the developer on October 9; independent verification is pending.** New profile saves include a phone field and atomically publish only that phone to `coordinatorContacts/{uid}`. Rules deny collection listing, permit signed-in adult document reads, and restrict writes to the owner with matching private profile data. Other profile fields remain private. Verify the manually published rules include this contact schema before checking profile/onboarding saves. No changes to attendance indexes or existing booking records are needed.

New shifts/groups accept a single local start time from `00:00` to `23:59` and must start in the current minute or within the next 365 days. `0:00` normalizes to `00:00`; `24:00` is invalid. Names allow 40 characters, stations 30, and optional multiline location instructions 500. Instructions are shown on bank shift cards, My shifts, and check-in. **September 29 rules update deployed and verified after explicit approval:** production accepts the corrected time range and optional instructions, and enforces the shorter field limits. New records store `startsAt` and the local `utcOffsetMinutes` alongside the calendar date and normalized time. Deployed rules validate their consistency and the window using [Firebase request time](https://firebase.google.com/docs/reference/rules/rules.firestore.Request). Existing shifts remain readable; the September 29 creation-rule update is deployed.

Check-in handles empty or changing signup lists without retaining obsolete dropdown values. QR generation is available to the assigned approved leader even when the attendance query is loading or fails. An empty bank first needs a shift created by an approved coordinator; QR codes belong to shifts, not banks. The approved rules deployment includes QR permissions; assigned-leader and approved-bank restrictions still apply.

The developer reported manually publishing the entire earlier rules file and creating its indexes October 9. Slice 24 changes the local rules again and requires manual publication before using secure check-in. Index READY status and signed-in token/camera behavior remain unverified.

The assigned approved bank leader opens **Manage check-ins** on the bank page or **Shifts you lead** under Groups. Generate or rotate a real QR within 30 minutes before through 4 hours after the shift start. Each QR expires after at most 15 minutes. Raw codes exist only in leader app memory; reopening the screen requires rotation, invalidating codes displayed in other sessions. Members scan on Android/Web or enter the displayed code manually. Parents scan once for themselves and all their children booked for that shift; Kid Mode cannot scan or check in independently. Ordinary member submissions remain pending until the assigned approved leader confirms; the existing leader adult self-confirmation exception remains. Removed/cancelled participants cannot be confirmed. Duplicate participant check-in is rejected; confirmation retries cannot award twice.

| Path | Purpose |
| --- | --- |
| `shifts/{shiftId}.qrTokenHash`, `.qrExpiresAt` | Public verification hash and expiry only; assigned approved leader generates/rotates |
| `attendance/{shiftId}/families/{ownerUid}/attendanceEntries/{participantId}` | `parent` or child ID; `tokenProof` (hash, never raw QR), pending then confirmed with server timestamps; owner and assigned leader can read |
| `rewardPreferences/{uid}/people/{childId}` | Featured badge backed by a confirmed record for that child |
| `families/{uid}.challengeTargets` | Goal per challenge ID, 1–100 distinct completed family shifts |

Parent check-in creates the parent's record and missing booked-child records atomically. Parent records snapshot `checkedInChildIds`; new child records carry `familyCheckIn: true` and the same proof/check-in timestamp. Existing attendance is retained, never overwritten. The coordinator's parent **Confirm** action confirms pending booked children in the same transaction; cancelled children are skipped and removed families still cannot earn rewards. No extra seats are booked by scanning. Book children in Family Center first, before parent check-in.

Kid Mode has **Home, Shifts, Badges**, and (for families) **Family** navigation, with no Check in tab or scan button. Home lists each booked shift as **Not checked in** until family attendance is confirmed, then **Checked in**, with the child's points and badge-choice count. Pending records earn neither points nor badge choices; loading/errors retain retry states. Each child gets 100 points and one independent badge choice per confirmed shift. The separate local demo follows the same family confirmation behavior and keeps each child's badges separate.

**Family check-in backend update is pending:** manually publish the complete current `firestore.rules` before using this flow in Firebase. No new indexes. Assigned approved leaders may get the specific shift's registration to verify current child bookings, but cannot list another account's registrations or read their private profile. Earlier October 24 rules publication predates this change. This work does not migrate historical parent-only attendance into child attendance.

Confirmed attendance is the persistent reward ledger: **100 points per participant per shift**, with adult badge thresholds derived from those points. There are no client-writable balances or Cloud Functions to deploy. Every confirmed child shift offers one badge choice (revoked if that family is removed from the shift) in **My badge garden**. Featuring an already earned badge consumes no new choice. Profile links to rewards/badge selection. Loading and failed attendance reads have retry states and never substitute mock rewards.

Challenge progress includes all past confirmed family shifts, counting one shift once even when multiple family members attended. Legacy text-only challenges remain visible with a notice to create a goal-based challenge; titles such as pounds or hours are not interpreted as shift goals. Challenges grant no additional points.

The assigned leader can see participant names, including booked children's names, for attendance management; other group members cannot read those attendance records. Attendance history and earned rewards remain after signup cancellation. The existing parent-managed Kid Mode uses the parent's authentication identity.

Both rules and `firestore.indexes.json` were deployed after approval; deployment verification is recorded in the development log. Owner/leader queries use collection-group single-field indexes, as described in [Firebase index documentation](https://firebase.google.com/docs/firestore/query-data/index-overview). Follow the [manual attendance checks](docs/manual_testing.md#attendance-and-rewards) with ordinary authenticated clients; offline smoke checks do not validate Firestore permissions.

## Firestore foundation (Slice 16)

- Project: `bushel-volunteer-20260925`; database: `(default)`; Standard edition, Native mode.
- Location: **Dallas, Texas (`us-south1`)**. The existing database is already created; do not create another for this slice.
- Slices 20–21 rules are deployed; the current `firestore.rules` adds attendance, rewards, and scheduling validation and was deployed September 28 after approval. Only the authenticated owner can create/get/delete `smokeTests/{uid}/runs/{runId}`. Test data must use the fixed message and a server timestamp. Diagnostic queries/updates remain denied. Profiles, banks, shifts, and registrations have the separate rules above; unmigrated collections remain denied.
- Adult profiles, banks, shifts, and adult registrations use Firestore. Demo mode still initializes no Firebase services.

Run the separate Flutter diagnostic, sign in, then click **Run connection check**:

```sh
flutter run -d chrome --target lib/firestore_smoke_main.dart
```

It writes a unique test document, reads from the server, deletes it, and verifies deletion. This entry point is separate from normal app/demo flows. If connectivity or sign-in changes interrupt cleanup, rerun or inspect the current user's `smokeTests` documents.

Backend QA is developer-driven. Use ordinary authenticated client sessions or the Rules Playground for access checks; administrator operations bypass security rules. Optional manual emulator guidance is in `docs/manual_testing.md`. No automated emulator or live test suite is required before finishing a slice.

Developer Mode is needed for Windows plugin symlinks. Android/Web authentication was manually verified by the developer; camera testing remains pending.

### Pending removal/attendance update

`attendanceRevocations/{shiftId}/revokedFamilies/{uid}` stores immutable `{ownerUid, leaderUid, shiftId, revokedAt}` markers created atomically by valid removal votes. Attendance readers combine these with the retained audit entries to exclude the entire removed family from points, badges, and challenges. Rules prevent further confirmation or badge awards for revoked attendance. Collection-group indexes on `revokedFamilies.ownerUid` and `revokedFamilies.leaderUid` are required. The developer reported manually publishing these rules and creating the indexes on October 9. Verify both revokedFamilies indexes are READY before releasing the client.

The assigned, approved shift coordinator auto-confirms their own QR check-in. Groups now combines membership voting and QR/attendance navigation into one card per shift. Family Center begins with parent booking instructions and provides child booking controls before challenges. Voluntary leaving retains confirmed rewards; removal by vote revokes that family's rewards for the removed shift only.

## Secure tokens and camera scanning (Slices 24–25)

A token is `BUSHEL1:<URI-encoded shift ID>:<64 lowercase hex characters>` containing 256 cryptographically random bits from Random.secure. Let H(x) be lowercase hex SHA-256 of UTF-8 x: the client computes `tokenProof = H(rawCode)`, and the shift stores `qrTokenHash = H(tokenProof)`. Firestore rules validate `hashing.sha256(tokenProof).toHexString().lower() == qrTokenHash` plus server-time expiry, current group membership, current participant registration, parent mode, and the canonical create-only attendance path. This two-stage hash prevents the readable shift verifier from becoming a check-in credential. Raw secure tokens are never stored in Firestore. Attendance proofs are sensitive bearer credentials in private owner/leader records; do not publish them. Codes may be shared across booked participants; replay rejection is per participant/shift, not consumption by the first scanner.

`qrExpiresAt` is bounded to 15 minutes after generation and 4 hours after immutable `startsAt`; check-in opens 30 minutes before start. Expired, rotated, malformed/wrong-shift codes and repeated attendance receive visible errors. Generation requires valid startsAt; legacy shifts without it require trusted schedule repair, never guessed times. Publishing a new token removes the old mock qrCode field; old clients cannot create new mock codes or check in under the updated rules. Existing attendance history remains readable and confirmable under its existing member/revocation checks. No Cloud Functions or paid-plan features are introduced.

Leaders display real QRs with [qr_flutter](https://pub.dev/packages/qr_flutter). Members use [mobile_scanner](https://pub.dev/packages/mobile_scanner) on Android/Web. Android declares CAMERA permission with optional camera hardware, so devices without a camera keep manual entry. Camera access occurs only after **Scan QR with camera**; scanner routes pause/resume and release the camera through the plugin lifecycle. Denied, busy, missing, or unsupported cameras offer **Enter code instead**. Web requires HTTPS or localhost and may load a barcode-reader library on first use; initialization/network errors retain manual entry. Camera scanning and manual entry submit through the same token/attendance code; neither automatically grants attendance.

### Developer manual deployment

No agent deployment is authorized. The October 9 manual publication predates these secure-token rules.

1. In Firebase Console, open project `bushel-volunteer-20260925` → Firestore Database → `(default)` → Rules. Replace the entire editor contents with the current local `firestore.rules` and **Publish**. This includes the coordinator-contact and family-removal rules already reported published plus the new token/parent-mode rules. Alternatively, after fixing CLI permissions, run `firebase deploy --only firestore:rules --project bushel-volunteer-20260925` (use `firebase.cmd` for the npm CLI on Windows if the standalone executable is blocked).
2. No indexes changed for Slices 24–25. Verify the existing COLLECTION_GROUP ascending indexes on `revokedFamilies.ownerUid`, `revokedFamilies.leaderUid`, `attendanceEntries.ownerUid`, and `attendanceEntries.leaderUid` are READY. If the earlier indexes were not fully created, deploy the unchanged `firestore.indexes.json` with `firebase deploy --only "firestore:rules,firestore:indexes" --project bushel-volunteer-20260925` and wait for readiness.
3. Restart updated ordinary signed-in clients and perform the relevant secure-token and camera checks in `docs/manual_testing.md`. Offline tests and source compilation do not prove live permissions or camera operation.

The current rules source passed the non-deploying Rules API check October 12. Developer Android/Web camera, permissions, persistence, and token checks remain unperformed by the agent.
