Read `AGENTS.md`, `plan.md`, `README.md`, `docs/manual_testing.md`, and the latest entries in `docs/development_log.md` first. Follow the plan's working rules and testing policy. I am explicitly requesting the three parts below in order. Stop and report after each part if something blocks it.

## Part 1: Close out Slices 12–13 and clean up

1. Mark Slices 12–13 complete in `plan.md`. Developer manual verification on both Web (Edge/Chrome) and the Android emulator (Pixel 7): Firebase sign-in works, the session persists across app restart, logout returns to the sign-in screen, and an invalid password shows an error without opening the app. Record exactly this in `docs/development_log.md` and don't claim checks beyond it.
2. Remove stale references to the "three malformed legacy shifts" / `docs/firestore_audit.md` from `plan.md`. The September 29 data reset deleted those shifts. Update or archive `docs/firestore_audit.md` so it no longer reads as current.
3. Inspect the uncommitted changes in `analysis_options.yaml` and `pubspec.lock`. Explain what changed and whether to keep them. Don't revert or commit them without asking me.
4. Note in `plan.md` that the pending rules/indexes deployment (coordinator contacts, family removal, `revokedFamilies` indexes) is mine to do manually. The CLI deploy failed with a 403 permission error on my side. Don't attempt deployment.
5. Make `plan.md` short and current, keeping the testing policy and the definition of done.

## Part 2: Slice 24, secure QR tokens

Replace the guessable mock codes (`BUSHEL-SHIFT-{index}-{hash}`) with real tokens:
- Only the assigned, approved leader can generate or rotate a shift's token. Use a cryptographically secure random token (at least 128 bits, e.g. `Random.secure()`).
- Members must not be able to read the raw token from Firestore. They can only get it by scanning. Store only a hash plus an expiry (for example, `expiresAt` tied to the shift's time window). If feasible, verify the check-in in security rules with `hashing.sha256`. Check the rules-language support before relying on it.
- Check-in still requires being a current shift member and still creates provisional (pending) attendance. Confirmation, points, badges, and challenges keep working as they do now. Expired, rotated, wrong-shift, or already-used tokens are rejected with a clear message.
- Keep demo mode fully local, using the same token flow with in-memory data.
- No Cloud Functions or paid-plan features unless you ask me first. Prepare the rules changes locally, validate them with the non-deploying rules check, and list exactly what I need to deploy.

## Part 3: Slice 25, real camera QR scanning

- Leaders display the token as a real scannable QR code (e.g. `qr_flutter`), replacing the mock QR widget.
- Members scan with the device camera (e.g. `mobile_scanner`) on Android and Web. Add the Android camera permission and handle denied, unavailable, or unsupported cameras. Include a manual "enter code" fallback.
- Scanning feeds the same Slice 24 check-in path, with no separate logic.
- Kid Mode cannot scan or check in independently.

## Testing and handoff

- At most 1–2 focused smoke tests per slice, only for severe failures (for example, a non-member or expired token is accepted, or a raw token becomes readable). Run `flutter analyze --no-pub` once, plus the relevant smoke tests.
- Don't run emulator or live-backend suites. Don't deploy, commit, or push.
- Update `plan.md`, `docs/development_log.md`, `docs/manual_testing.md`, and the README schema notes.
- Finish with: what changed, what was actually verified, exact deployment steps for me, and 2–4 manual tests per slice with expected results. Include camera permission denial and an expired or wrong token.