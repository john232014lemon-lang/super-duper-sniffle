---
name: Bushel Incremental Plan
overview: Build one small slice at a time; favor manual QA and minimal smoke tests.
isProject: false
---

# Bushel build plan

Bushel helps families find food banks, join shifts, check in, and earn rewards. Work in this existing Flutter repository; the app starts at `lib/main.dart`.

## Current state

**September 29 data reset:** At the user's request, all live shifts, groups/votes, registrations, and attendance were cleared and verified empty. The earlier malformed legacy shifts are no longer present. Banks, profiles, family definitions, applications, contacts, and account preferences were preserved. This reset does not deploy the pending coordinator-contact rules.

| Slices | Status |
| --- | --- |
| 0–11 | Complete local mock app: discovery, shifts, groups/voting, families, provisional check-in, confirmation, and rewards |
| 12–13 | Firebase initialization and auth implemented; interactive Android/Web launch, login/logout, and restart verification still pending |
| 14–15 | Complete: explicit local demo mode and working shift calendar |
| 16–19 | Complete: Firestore foundation, private adult profiles, banks, shifts, capacity enforcement, and adult signups |
| 20 | Groups/voting implemented; live rules confirmed deployed by September 28 audit |
| 21 | Persistent family profiles, profile switching, and child places implemented; live rules confirmed deployed; goal-based challenge fields deployed September 28 |
| Additional | Bank-page coordinator applications implemented; only administrator database approval grants coordination under the new rules |
| 22–23 | Implemented: persistent QR/check-in/leader confirmation, derived points, earned badges, and family challenge progress; rules/indexes deployed September 28; manual client QA pending |

Use the existing Firebase project `bushel-volunteer-20260925`, `(default)` database in Dallas (`us-south1`). Do not create another project/database. Android still needs an SDK and device/emulator. Setup, schema, and application approval instructions are in `README.md`.

**Deployment approved and completed September 28.** The September 28 deployment includes attendance/QR/reward permissions and the earlier scheduling validation. September 29 time-range, text-limit, and instructions rules were subsequently approved, deployed, and verified against the local file. Both attendance collection-group indexes were verified READY; verification is recorded in the development log. See `docs/firestore_audit.md` for the three malformed legacy shifts and consistent group/registration counts. Legacy records were not changed; their intended schedules must not be guessed.

Demo runs with `flutter run -d chrome --dart-define=BUSHEL_DEMO=true`; it initializes no Firebase services and resets all local state with **Reset demo**. Normal startup requires Firebase authentication. Live failures must never fall back to demo data.

## Slice boundaries and next work

| Slice | Required behavior |
| --- | --- |
| 20: Groups | Adult signup/cancellation atomically maintains private group membership. One vote per adult/target per membership version. Two-thirds of all current adults must agree to removal. Removal cancels the adult and their child places, restores capacity, revokes group/My Shifts access, and prevents immediate rejoining. Adult membership changes invalidate old votes |
| 21: Families | Parent-owned kids, challenge titles, selected profile, and child bookings persist privately. Parents reserve children into their own shifts; each child consumes capacity. Kid Mode shows that child's bookings and cannot independently sign up, vote, or coordinate |
| Applications | Adults apply on the bank page. An administrator reviews `coordinatorApplications/{uid}/banks/{bankId}` and sets `status` to `approved` or `rejected`. Profile role preferences and legacy access records confer no permissions under the new rules |
| 22: Attendance | Persist per-shift mock QR, provisional check-in, and assigned-leader confirmation. Only members check in; only the assigned leader confirms; completion is recorded once |
| 23: Rewards | Confirmed attendance drives persistent points, badges, kid badge selection, and challenge progress. Trusted updates prevent forged rewards and duplicate awards |

Next: manually check Slices 20–23 against the deployed rules and indexes. Keep demo behavior local. Real scanning hardware/camera integration, secure QR tokens, notifications, AI features, map scaling, and production launch hardening remain later work.

Attendance uses one completion record per family participant/shift, with separate immutable family-removal markers. Pending check-ins earn nothing; the assigned, approved bank leader confirms current participants. Confirmed records derive 100 points each without a client-writable balance. Each confirmed child shift grants one badge choice, retained unless that family is removed from the shift; earned badges can be featured again. Family challenges use explicit goals of 1–100 distinct confirmed family shifts, including past shifts; several family members on one shift count once. Legacy text-only challenges need a new goal-based challenge and do not invent progress from their titles. See README for schema and deployment instructions.

## Testing policy for future agents

Parent-managed bookings: parents must first join a shift before booking a child. Family Center and My shifts show every child's booked shifts, with per-child signup/Leave controls and coordinator Call/Text actions. Adults can leave at any time; leaving the parent cancels their children's places as explained in the confirmation. Kid Mode cannot join or leave in live or demo mode. Coordinator phone sharing is optional in Profile; signed-in adults can read only the shared phone document, not the private profile. These contact/profile rules are prepared locally and await deployment approval; prior September 29 deployment does not include them.

New volunteer groups/shifts use a single local start time from `00:00` through `23:59`; `0:00` normalizes to `00:00` and `24:00` is rejected. Shift names allow 40 characters, stations 30, and optional location instructions 500. Instructions appear on shift cards and check-in. These September 29 rules changes were deployed after fresh explicit approval; the active rules exactly match the local file. Creation is limited to the current minute through the next 365 days, validated in the form/repository and deployed server rules. New records include `startsAt` and `utcOffsetMinutes`; existing shifts remain readable. Check-in uses stable dropdown values and handles an empty signup list. Leader QR controls remain available independently of attendance-query loading/errors.

**Manual testing is the default. Automated tests are a small smoke alarm, not a completion checklist.** The previous large Flutter and emulator/live suites have been deliberately retired; do not restore them as routine cleanup.

1. For each new feature, add **0–2 focused smoke tests at most**, and only for a plausible severe failure: app cannot launch, private data survives account changes, unauthorized actions become available, or important data is lost/duplicated. Zero new tests is appropriate for low-impact changes or when a smoke test already covers the risk. More automation requires an explicit user request.
2. Prefer short tests exercising real application code. Fixtures may provide inputs; they must not reimplement backend persistence, authorization, voting, or capacity logic. Keep setup small and fail unexpected fixture calls loudly.
3. Do not automate every field, label, badge, layout, calendar edge case, retry combination, screen route, or schema permutation. Avoid long scrolling/clicking scripts and large mock repositories. Move those scenarios to developer manual QA.
4. **Do not add or run emulator suites or live-backend tests by default.** Backend behavior and rules are checked manually when relevant. Keep production validation and security rules intact; deleting tests is not a reason to weaken them. Admin access bypasses rules and cannot establish client safety.
5. After implementation, run the relevant retained smoke test(s) once. Run `flutter analyze --no-pub` once when Dart code changes. For documentation-only changes, inspect the diff; do not run Flutter. The entire small smoke file is reasonable only for broad changes or suite maintenance. Do not rebuild every platform, fetch dependencies, or run unrelated checks by habit.
6. Rerun only when a failure or subsequent relevant code change justifies it. Read the useful failure output, fix the cause, and stop when the selected checks pass. Keep successful command output concise; no repeated full log dumps or coverage targets.
7. Release builds, emulator sessions, and live exercises are developer/manual tasks unless explicitly requested or necessary to investigate an actual build/platform failure. Report unperformed checks honestly; a fake-repository smoke test is not evidence of backend security or real persistence.

My shifts lists all bookings with clickable cards and a **View group & members** action. Home's upcoming-shifts shortcut opens that tab. Removal voting explains why fewer than three adults cannot satisfy the existing two-thirds rule without self-votes.

The retained offline suite is `test/smoke_test.dart` (fourteen checks). Run a relevant check with:

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

## September 29: family removal and coordinator clarity

Implemented locally: removal voting atomically cancels the parent and all child places, restores capacity, and writes an immutable family/shift revocation marker. Pending and confirmed attendance remain as audit records but no longer count toward points, badges, or family challenges. Badges earned on other shifts remain available. Voluntary leaving retains previously confirmed rewards. Removal still requires the existing two-thirds adult vote.

The assigned, approved coordinator now confirms their own parent check-in automatically; other adults and children still need confirmation. Family Center starts with booking instructions and places child booking controls above challenges. Groups shows one card per shift with explicit Members & removal votes and QR & attendance buttons.

Validation: all 14 offline smoke checks passed, Flutter analysis reported no issues, and the non-deploying Firebase Rules API returned no compilation errors. No emulator or signed-in live QA was run. Deployment is pending fresh approval: deploy firestore.rules (including the earlier optional coordinator contact rules) and firestore.indexes.json; wait for both revokedFamilies collection-group indexes to become READY before releasing this client. Earlier approvals do not cover this change.