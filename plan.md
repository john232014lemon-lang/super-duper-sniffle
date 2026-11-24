# Bushel build plan

Bushel is the existing Flutter app starting at `lib/main.dart`. Use Firebase project `bushel-volunteer-20260925`, `(default)` database in Dallas (`us-south1`); do not create another project/database.

## Current state

- November 23 iOS QR scanning: enabled the existing check-in camera on iPhone using the camera permission description already in Runner. Denied camera access still offers manual entry. Physical iPhone verification requires a new IPA containing the fix.

- November 21 GitHub sync: fast-forwarded to `3628d20`, which supplies the **iOS unsigned IPA** workflow for manual runs and pushes to main. The local iOS 15.0 deployment-target edit is pending publication.

- November 21 iPhone sideloading: synced main to `0b7ade8`, which supplied Android/iOS/Web Firebase config and iOS camera/location usage strings. Added the manual unsigned IPA workflow on macOS with Flutter 3.50.0 and Swift Package Manager. Raised the iOS deployment target to 15.0 for Firebase. Windows installation and seven-day refresh instructions are in `docs/iphone.md`. GitHub Actions and physical iPhone verification are pending.

- November 14 cloud main sync: fetched origin and fast-forwarded local main from 7c8b74d to 5ce17ac, bringing in `docs/iphone.md`. No conflicts; uncommitted expired-QR and leaderboard work retained. HEAD and origin/main match. This remote commit contains iPhone build instructions only; no workflow implementation was requested or added during sync. No push or deployment.

- November 14 leaderboard: Home and Rewards link to a top-50 all-time adult leaderboard, ordered by confirmed points with shared ranks and current-account highlighting. Only first names/points are published; children stay private. Added trusted transactional Firebase Functions projections for parent attendance, family revocations, and profile changes, read-only signed-in rules, and a guarded historical backfill. No client-writable balances or public attendance/profile access. Demo lists only its own adult's actual points. **Live setup remains pending:** developer must publish complete rules, deploy the leaderboard functions codebase, verify existing ownerUid indexes, and run the initial backfill per `functions/README.md`. No backend deployment/data mutation performed. Actual verification and outstanding manual checks are in the development log.

- November 14 expired QR wording: expired real/mock QR validation and leader QR display now say exactly `This is an old qr code`. Closed check-in windows keep a separate explanation; validation and permissions remain intact. Analysis and the existing secure QR validation smoke check passed. Manual UI checks remain unperformed; see development log.

- November 14 Flutter/Material migration: installed latest stable Flutter 3.50.0 / Dart 3.14.0; project minimums now match. All 37 app/test Material imports use `material_ui` 1.11.0 and the lockfile records SDK-required dependency updates. Official temporary `MaterialUiCompatibilityBridge` preserves legacy map/QR/scanner theme/localization access; its intentional deprecation is suppressed only on that line until those dependencies migrate. Remaining Dart fix scan found nothing; final analysis is clean. Offline smoke and manual verification results are recorded in the development log. No Firebase/rules changes or deployment. Upgrade doctor could not locate the Android SDK in this environment; Android setup/manual QA remains developer work.

- October 25 signup permission diagnosis: read-only inspection found the active Firestore release still dated October 24 (`2026-10-24T16:39:56.808399Z`). Its group update allowlist excludes `childMembers`, but both current MCFB group documents contain that field, so every signup group update is denied. `b@b.co` is enabled and in parent mode, with no group membership/bans in either empty group. The current complete local `firestore.rules` includes the required child roster support and compiles with zero issues. Developer must manually publish that complete file to the existing project's `(default)` database; no deployment or data mutation was performed for this diagnosis. Refreshing the client alone cannot resolve the server mismatch.

- October 25 presentation cleanup: under `BUSHEL_MOCK` only, auto-sign-in uses Firebase Auth `a@a.co` / `b@b.co` (John C and the second demo adult) when `--dart-define=BUSHEL_MOCK_PASSWORD=…` is set; Profile shows **Switch account** instead of Sign out. In all modes, parent-booked kids are written to `groups/{shiftId}.childMembers` on signup so they appear in Members immediately; adults can vote kids out before check-in (two-thirds adult quorum, no self-vote / own-kids, Kid Mode blocked). After a leader generates a QR, QR & attendance lists every adult and child with not scanned / scanned·pending / confirmed. Updated `firestore.rules` (local; publish manually). Passwords stay in dart-defines / local `.env` notes—never committed. Follow-up: child vote finalization no longer `get`s the parent’s private registration (that read denied non-owner voters); remaining `childIds` come from group `childMembers`, matching adult removal’s seats-only pattern.
- October 24 family check-in: one parent scan creates pending attendance for the parent and all children already booked for that shift, in real and mock QR modes. One approved leader confirmation confirms parent and booked children together, awarding each 100 points and each child one badge choice. Cancelled child bookings are excluded; removal/duplicate protections remain. Kid Mode has no Check in tab or scan CTA; Home shows per-shift Not checked in / Checked in, points and badge choices. Local demo also follows family confirmation and per-child badge ownership. The complete updated firestore.rules must be manually published before Firebase use; no new indexes. This change has not been deployed, and historical parent-only records are not backfilled. Actual verification is recorded in the development log.
- October 24 Flutter launcher crash diagnosis: `flutter_01.log` and installed Flutter 3.44.8 source identify the terminal `w`/`W` widget-tree dump dereferencing a missing VM-service connection in `ResidentHandlers.debugDumpApp`. Added restart/terminal-input guidance in README. No app, Firebase, or SDK edits were needed for this report. Browser relaunch and hot reload remain unperformed manual checks.
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

## Next slices

### Slice 25 — Printable shift QR sheets

- Continue the existing Slice 25 QR work with **Print signup sheet** and **Print station check-in sheet** in the assigned coordinator’s shift tools. Each action produces a one-page US Letter PDF with the Bushel logo above a high-contrast QR, a clear purpose title, food bank, shift date and local time, location or station, scan instructions, and expiration. Use the existing Bushel app icon unless a dedicated print logo is supplied.
- Signup QRs open the specified shift on Bushel Web over HTTPS using Firebase Hosting on the existing project. After sign-in, return volunteers to the shift and use the existing booking flow. Expired links explain the expiry and offer a link to browse shifts.
- Newly issued signup and check-in QRs last 24 hours. Allow check-in QR generation up to 24 hours before shift start, and accept attendance only from 30 minutes before through four hours after shift start, while the QR is valid and the volunteer is eligible. Rotation invalidates the previous check-in code. Printing reuses the current code when available and never silently rotates it.
- Apply the 24-hour credential lifetime to mock QRs while retaining the mock session’s expiry and allowlist. Existing codes keep their stored expiration. Roll out the client and Firestore validation changes together.
- Verify with a focused offline QR time-boundary check. Print and scan both sheets on an iPhone. Signup should resume the exact shift after login. Check-in should work for eligible volunteers inside the attendance window and reject expired or rotated codes and attempts outside the window.

### Slice 26 — Live coordinator shift dashboard

- Add **Shift dashboard** under **Shifts you lead**. Show booked adults and tasks grouped by station with **To do**, **In progress**, and **Done** statuses. The assigned approved coordinator creates tasks, assigns or reassigns adults by dragging their names onto tasks, and updates progress. Include an accessible **Assign volunteer** picker for touch and keyboard use.
- Show live task updates and a shift-wide message thread. Currently booked adults can post messages and see their own assignments. Only the assigned approved coordinator manages progress. Kid Mode and removed or cancelled members lose access. Family bookings stay under the adult account.
- Store tasks and messages under the shift. Recheck approval and booking eligibility when assigning and use transactions to surface conflicting edits as a refresh-and-retry message. Keep task progress separate from attendance and rewards. Assignment events feed the notification system in Slice 27.
- Verify with ordinary signed-in coordinator and volunteer accounts. Drag a booked adult onto a task and confirm the assignment and progress appear live. Exchange messages, check that an adult volunteer cannot edit progress, and confirm a removed member loses dashboard access.

### Slice 27 — Notification inbox and Android push

- Connect the Home bell to a live inbox with an unread badge. Open **Notification settings** from the inbox or Profile. Include controls for reminders, schedule changes and cancellations, station assignments and reassignments, and coordinator announcements. Keep thread replies in the thread unless the coordinator posts an announcement.
- Remind eligible adults 24 hours before the current shift start. Send schedule changes to currently booked adults and assignment alerts to the affected adult. Use stable event IDs for one inbox item per event despite retries. Recheck current booking and shift time before reminder delivery. Open the relevant shift or assignment after verifying access.
- Deliver inbox alerts across supported platforms. Add opt-in Android push through Firebase Cloud Messaging with account-scoped device registrations and sign-out cleanup. Keep lock-screen push text generic. Android permission denial still allows inbox delivery. The free Sideloadly iPhone build uses the inbox.
- Verify with a focused offline deduplication check. Change a shift time and reassign a station. Each intended recipient should get one inbox item per event, and reminders should follow the revised time. Check Android permission and settings behavior and confirm inbox delivery on iPhone.

### Slice 28 — Edit display name and profile photo

- Let signed-in adults edit their display name and choose, replace, or remove a photo from their device library. Use the existing name field and its 80-character limit so changes reach current name consumers.
- Keep photos private to the owning account in an owner-scoped Firebase Storage path. Use initials when no photo is set. Keep the previous photo if replacement fails.
- Verify that the new name and photo persist after reopening the app, removal restores initials, and a different signed-in account cannot read or edit the photo.

### Rollout for Slices 25–28

- Use the existing `bushel-volunteer-20260925` project. Document Firebase Hosting, Functions, Scheduler, Storage, rules, and index setup. Verify billing and bucket availability before rollout. Deploy compatible client and backend QR changes together. Implementation commits, pushes, and deployments require separate authorization.
- Update this plan and the development log after each implementation slice. Use ordinary signed-in clients to verify permissions.

## Testing policy

### Congressional App Challenge mock QR demo (October 23)

Corrected after user clarification: `flutter run -d chrome --dart-define=BUSHEL_MOCK=true` uses Firebase startup and all live data; only QR credentials are simulated. The flag takes precedence over BUSHEL_DEMO. Assigned approved coordinators publish separate mock tokens; booked adult volunteers submit pending Firebase attendance; coordinator confirmation earns the usual 100 points once per shift. Kids cannot redeem independently; a parent Volunteer scan includes booked children. The assigned coordinator cannot redeem a mock code. Mock tokens expire in 15 minutes, ignore shift times during the enabled presentation session, and never overwrite real shift QR fields. Under BUSHEL_MOCK only, Scan QR with camera opens a fake viewfinder showing the session’s generated mock QR and a Scan this QR button (no real camera); without the flag the real camera path is unchanged. Fully local BUSHEL_DEMO remains separate.

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
