---
name: Bushel Incremental Plan
overview: Build one small feature at a time. Continue locally while Firebase access is blocked.
todos:
  - id: mock-slices-0-11
    content: Complete the mock app through Family Center and per-shift attendance
    status: completed
  - id: slice-12-firebase-core
    content: Android and Web configured; finish platform launch verification
    status: in_progress
  - id: slice-13-auth
    content: Auth code ready; school account restriction blocks setup and live verification
    status: in_progress
  - id: slice-14-demo-mode
    content: Local demo mode with no Firebase login, visible label, and full reset
    status: completed
  - id: slice-15-shift-calendar
    content: Working mock calendar with date filtering, signup, and dated custom shifts
    status: completed
  - id: slice-16-firestore
    content: After Firebase access is restored, add Firestore and test ownership rules
    status: pending
  - id: firebase-migrations-17-23
    content: Move profiles, banks, shifts, groups, families, attendance, and rewards to Firestore separately
    status: pending
isProject: false
---

# Bushel Build Plan

Bushel helps families find food banks, join shifts, check in, and earn rewards.

## Where we are

- Mock slices **0-11 are complete**. App data still lives in memory.
- **12-13 are partly done:** Android and Web are configured for `bushel-volunteer-20260925`; auth screens and services are built. Analysis, 23 local tests, and the Web build passed; live platform verification is still pending.
- Live Authentication setup is blocked by the school account's under-18 access restriction. Android launch testing also needs an SDK and device/emulator.
- **14-15 are complete:** local demo mode and the shift calendar work without Firebase login. All 27 tests and the demo Web build pass. Resume 12-13 before starting 16.

## Completed mock slices

| Slice | Feature | Status |
| --- | --- | --- |
| 0 | Flutter setup and Bushel theme | Complete |
| 1 | Discover food banks | Complete |
| 2 | Bank details and mock shifts | Complete |
| 3 | Create shifts, sign up, and view My Shifts | Complete |
| 4 | Map with bank markers and previews | Complete |
| 5 | Onboarding and local role selection | Complete |
| 6 | Simulated check-in | Complete; confirmation added in 11 |
| 7 | Points and three reward badges | Complete |
| 8 | Kid Mode and 25 selectable badges | Complete |
| 9 | Shift groups and two-thirds removal voting | Complete |
| 10 | Parent-managed kids and Family Center challenges | Complete |
| 11 | Per-shift mock QR and coordinator confirmation | Complete; points awarded only after confirmation |

## Completed local features

Run with `flutter run -d chrome --dart-define=BUSHEL_DEMO=true`. Omit the flag to use normal Firebase startup. Demo changes stay in memory; **Reset demo** clears them and returns to onboarding.

| Slice | Feature | Done when |
| --- | --- | --- |
| 14 | Local demo mode | Complete: explicit launch flag skips Firebase; labeled demo supports adult onboarding and parent-managed kids. Reset clears all mock stores and navigation. Normal startup still requires auth |
| 15 | Working shift calendar | Complete: month navigation, day selection, shift markers, and date filtering in Available/My Shifts. Signup updates both views; validated custom dates land on the right day; empty dates show guidance |

Keep both slices local. Demo mode uses no Firebase services; it does not grant access to real accounts or bypass school restrictions. Calendar data stays in memory until its later migration.

## Resume Firebase when access is available

Slices 12-13 retain their numbers. Former Firestore slices 14-21 are now **16-23**.

**Resume order:** resolve account access, finish 12-13, then implement 16-23 in order. The Firebase CLI is already installed; reuse the existing project and generated configuration.

| Slice | Feature | Done when |
| --- | --- | --- |
| 12 | Firebase core setup | FlutterFire configuration and `firebase_core` initialization are in place. App launches on Android and Web; initialization failures show a retry state |
| 13 | Email/Password auth | Enable the provider in Authentication; verify the existing `firebase_auth` service and UI with real signup, login, logout, invalid-password errors, and auth restoration after restart. Logout clears old routes and mock account data |
| 16 | Firestore setup and smoke test | Add `cloud_firestore`, choose the database region, create/connect the database, and verify one user's test-document write/read/delete. Version rules and test that signed-out and other-user access is denied; no open test-mode rules remain |
| 17 | Adult profiles | Onboarding/profile data is saved by auth UID and restored after login. Private profiles are isolated; a UI role switch cannot grant backend permissions |
| 18 | Food banks | Discover, map markers, and bank details load from Firestore with loading, empty, and error states. Ordinary users cannot edit bank records |
| 19 | Shifts and signup | Coordinator-created shifts, signup/cancellation, and My Shifts persist and update across sessions. Keep the calendar's date filtering working. Enforce coordinator-only creation, capacity, and duplicate-signup prevention in the backend |
| 20 | Groups and voting | Groups follow shift membership. Eligible members vote once per target; a trusted two-thirds removal also removes the signup and My Shifts access |
| 21 | Family Center | Parent-owned kids, profile switching, challenges, and child shift participation persist under the parent's authenticated account. Unrelated families cannot access them; kids have no independent signup or coordinator privileges |
| 22 | Attendance | Persist mock shift QR, provisional check-in, and leader confirmation. Only members check in; only the assigned leader confirms; completion is recorded once |
| 23 | Rewards | Confirmed attendance drives persistent points, earned badges, kid badge selections, and challenge progress. Trusted updates prevent forged rewards or duplicate awards |

For each migration, keep other areas on mocks. Test persistence, allowed access, and denied access; use the Firebase Emulator Suite for rules tests. Profile persistence waits for 17, so restoring auth alone does not restore onboarding choices yet.

For setup and verification commands, see `README.md`. Live auth backend checks use `tools/firebase/auth_smoke_test.py`; also test login/logout and restart in the app on each target.

## Working rules

1. Work in the existing repo (`lib/main.dart`, root `plan.md`); do not create a nested project or replace Git history/remotes.
2. Implement one slice per request unless multiple are explicitly requested.
3. Test the changed flow, fix issues, and update this plan plus `docs/development_log.md`.
4. Stop at the slice boundary. Commit or push only when requested.

**Explicitly later:** real QR hardware/camera scanning, production-secure QR tokens, push notifications, AI assistant, map API scaling, and production launch hardening.

**Next backend step:** finish the blocked setup and verification in 12-13, then request Slice 16. Firestore and migrations remain unstarted.
