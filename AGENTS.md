# Agent instructions

Read `plan.md` before starting a slice; its testing policy applies to all changes.

- Prefer developer-run manual testing. For a new feature, add at most 0–2 small smoke tests for severe regressions; zero is appropriate for low-risk changes or existing coverage.
- Do not add or recreate exhaustive widget, emulator, live-backend, schema-matrix, or fixture-heavy test suites unless the user explicitly asks.
- Run only the affected smoke checks, once after implementation. Rerun only after a relevant change or failure. No routine emulator runs, live tests, or release builds.
- Never weaken application validation or security rules to simplify tests. Manual checks must use ordinary signed-in clients when checking permissions; admin writes bypass rules.
- Finish each slice/feature with what changed, what was actually verified, and 2–4 concrete manual test ideas with expected results. Mark unperformed checks as unperformed.
- Update `plan.md` and `docs/development_log.md`. Do not commit, push, or deploy without user authorization.
