# Bushel build plan

Bushel is the existing Flutter app starting at `lib/main.dart`. Use Firebase project `bushel-volunteer-20260925`, `(default)` database in Dallas (`us-south1`); do not create another project/database.

## Current state

- October 25 presentation cleanup: under `BUSHEL_MOCK` only, auto-sign-in uses Firebase Auth `a@a.co` / `b@b.co` (John C and the second demo adult) when `--dart-define=BUSHEL_MOCK_PASSWORD=…` is set; Profile shows **Switch account** instead of Sign out. In all modes, parent-booked kids are written to `groups/{shiftId}.childMembers` on signup so they appear in Members immediately; adults can vote kids out before check-in (two-thirds adult quorum, no self-vote / own-kids, Kid Mode blocked). After a leader generates a QR, QR & attendance lists every adult and child with not scanned / scanned·pending / confirmed. Updated `firestore.rules` (local; publish manually). Passwords stay in dart-defines / local `.env` notes—never committed. Follow-up: child vote finalization no longer `get`s the parent’s private registration (that read denied non-owner voters); remaining `childIds` come from group `childMembers`, matching adult removal’s seats-only pattern.
- October 23 real catalog addition: created `banks/montgomery-county-food-bank` in the existing Firebase database and approved the existing John C coordinator profile for that bank. Created Produce Rescue Center (PM), October 26, 2026, 1–4 PM Central with 1 open place, and Evening Volunteer Shift, October 27, 2026, 5–7 PM Central with 3 open places, plus their empty groups. Counts match the public VolunteerHub pages' displayed availability at import time. Full time ranges and external registration links are in instructions; the existing schema stores normalized start time only. These are independent snapshots, not VolunteerHub reservations or synchronization. Read-back verified all six documents. Signed-in app QA remains unperformed. Create-only import and source manifest are in `tools/firebase/import_montgomery_county.py` and `tools/firebase/montgomery_county_202610.json`; do not rerun apply expecting updates (existing records are protected).
- October 24 demo access: administrator-owned `settings/mockQr` was provisioned (enabled, expires 2026-11-01T05:00:00Z, both MCFB shift IDs). Live rules initially lacked mock QR blocks (permission-denied on Generate mock QR); the complete local `firestore.rules` was deployed October 24 and read-back confirmed `mockQrTokens`/`mockQrEnabled`. Profile `john` (`pw3Z0Mwp8JaXaeQ3Rvk2j5OC5AG2`) was approved for `montgomery-county-food-bank`, preferredRole set to coordinator, and both imported shifts' `creatorUid` retargeted to that UID. Original John C approval remains. Food bank upcoming shifts are a vertical scrollable list with full instructions; Manage check-ins buttons have spacing. Demo data cleanup the same day: deleted mock-bank test shifts and one extra non-imported MCFB shift; cleared registrations/attendance/mock tokens on the two imported MCFB shifts (signupCount 0, empty groups); attendance-derived points are zero for all accounts. Signed-in UI confirmation after cleanup unperformed.

- Slices 0–11 and 14–21: implemented, including local demo, discovery, shifts, groups, family bookings, and administrator-approved coordination.
- Slices 12–13: complete. Developer manual verification on Web (Edge/Chrome) and Android emulator (Pixel 7): Firebase sign-in works, the session persists across app restart, logout returns to the sign-in screen, and an invalid password shows an error without opening the app.
- Slices 22–23: implemented attendance, leader confirmation, derived rewards, badges, and family goals; signed-in client QA remains pending.
- September 29 reset cleared shifts, groups/votes, registrations, and attendance; preserved banks, profiles, family definitions, applications, contacts, and account preferences.
- Scheduling rules were deployed September 29. On October 9, the developer reported manually publishing the entire repository rules file (including coordinator contacts and family removal/reward revocations) and creating the indexes. Active-source equality and index READY status have not been independently verified. The earlier CLI deployment failed with 403. Future deployment remains the developer's manual task; agents must not attempt it.
- Slice 24: implemented locally October 12. Secure 256-bit random QR tokens, rotation, 15-minute expiry bounded to 30 minutes before / 4 hours after shift start, hash-proof validation, current-member/parent-only check-in, and parent-managed child attendance. New rules require developer manual publication. Source compilation passed; six unique affected offline smoke checks passed across Slices 24–25. Final Flutter analysis is clean (rerun after brace-style fixes). Slice 25: implemented locally with real leader QRs and Android/Web camera scanning plus manual fallback. Publish the updated rules manually; no new indexes. Camera and signed-in client QA remain developer work.

Demo: `flutter run -d chrome --dart-define=BUSHEL_DEMO=true`. It initializes no Firebase services; Reset demo clears local state. Normal startup requires Firebase authentication; live failures never fall back to demo data.

Keep parent-managed child bookings, Kid Mode permission restrictions, two-thirds adult removal voting, assigned approved leader confirmation, and immutable attendance/reward history. Removal revokes the family's rewards for that shift; voluntary leaving retains confirmed rewards. Pending attendance earns nothing; confirmed attendance earns 100 points per participant, and family goals count distinct shifts. See README for schema details.

## Testing policy

### Congressional App Challenge mock QR demo (October 23)

Corrected after user clarification: `flutter run -d chrome --dart-define=BUSHEL_MOCK=true` uses Firebase startup and all live data; only QR credentials are simulated. The flag takes precedence over BUSHEL_DEMO. Assigned approved coordinators publish separate mock tokens; booked adult volunteers submit pending Firebase attendance; coordinator confirmation earns the usual 100 points once per shift. Kids/child participants and the assigned coordinator cannot redeem. Mock tokens expire in 15 minutes, ignore shift times during the enabled presentation session, and never overwrite real shift QR fields. Under BUSHEL_MOCK only, Scan QR with camera opens a fake viewfinder showing the session’s generated mock QR and a Scan this QR button (no real camera); without the flag the real camera path is unchanged. Fully local BUSHEL_DEMO remains separate.

Backend allowlist is live: `settings/mockQr` enabled with presentation expiry and both MCFB shift IDs; complete mock-QR `firestore.rules` released October 24. Missing/disabled/expired settings still deny the mock path. No new indexes. Set `enabled: false` when the presentation ends. Signed-in client/camera QA remains unperformed.

**Manual testing is the default. Automated tests are a small smoke alarm, not a completion checklist.** The previous large Flutter and emulator/live suites have been deliberately retired; do not restore them as routine cleanup.

1. For each new feature, add **0–2 focused smoke tests at most**, and only for a plausible severe failure: app cannot launch, private data survives account changes, unauthorized actions become available, or important data is lost/duplicated. Zero new tests is appropriate for low-impact changes or when a smoke test already covers the risk. More automation requires an explicit user request.
2. Prefer short tests exercising real application code. Fixtures may provide inputs; they must not reimplement backend persistence, authorization, voting, or capacity logic. Keep setup small and fail unexpected fixture calls loudly.
3. Do not automate every field, label, badge, layout, calendar edge case, retry combination, screen route, or schema permutation. Avoid long scrolling/clicking scripts and large mock repositories. Move those scenarios to developer manual QA.
4. **Do not add or run emulator suites or live-backend tests by default.** Backend behavior and rules are checked manually when relevant. Keep production validation and security rules intact; deleting tests is not a reason to weaken them. Admin access bypasses rules and cannot establish client safety.
5. After implementation, run the relevant retained smoke test(s) once. Run `flutter analyze --no-pub` once when Dart code changes. For documentation-only changes, inspect the diff; do not run Flutter. The entire small smoke file is reasonable only for broad changes or suite maintenance. Do not rebuild every platform, fetch dependencies, or run unrelated checks by habit.
6. Rerun only when a failure or subsequent relevant code change justifies it. Read the useful failure output, fix the cause, and stop when the selected checks pass. Keep successful command output concise; no repeated full log dumps or coverage targets.
7. Release builds, emulator sessions, and live exercises are developer/manual tasks unless explicitly requested or necessary to investigate an actual build/platform failure. Report unperformed checks honestly; a fake-repository smoke test is not evidence of backend security or real persistence.

My shifts lists all bookings with clickable cards and a **View group & members** action. Home's upcoming-shifts shortcut opens that tab. Removal voting explains why fewer than three adults cannot satisfy the existing two-thirds rule without self-votes.

The retained offline suite is `test/smoke_test.dart`. Run a relevant check with:

```sh
flutter test --no-pub test/smoke_test.dart --plain-name "part of the test name"
```

Run the small suite when a change spans its boundaries:

```sh
flutter test --no-pub test/smoke_test.dart
```

See `docs/manual_testing.md` for a menu of manual checks. Select only what the current slice affects; do not turn that menu into a mandatory full regression run.

## Definition of done and agent handoff

- Implement the requested slice in the existing repo, preserve unrelated changes, and fix known issues within scope. Implement multiple slices only when explicitly requested.
- Update this plan and `docs/development_log.md` with behavior, actual verification, and outstanding work. Keep historical test counts in the log, not as current quality targets.
- Every final slice/feature response must briefly state what changed and what was actually verified, then give developers **2–4 specific manual test ideas with expected results**. Include at least one relevant failure/permission boundary when applicable. Do not just say “test manually.”
- Clearly distinguish implemented work, pending deployment, and checks not performed. Do not claim manual or live verification that did not happen.
- Stop at the slice boundary. Do not commit, push, or deploy without user authorization.
