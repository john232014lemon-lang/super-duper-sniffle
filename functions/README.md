# Leaderboard backend

This code targets the existing `bushel-volunteer-20260925` project, `(default)` Firestore database in `us-south1`. Nothing is deployed by installing or testing these files.

The app reads only `leaderboard/{adultUid}` (`displayName`, `points`) and `leaderboardStatus/current` (`ready`). Only signed-in clients can read them; clients cannot write them. Profiles, attendance, family information, and contact details retain their existing private rules. Only the first word of the adult profile name is published. Children do not appear. Only adults with positive confirmed points appear in the top 50.

Three retry-enabled Firestore functions recompute the affected adult's total when their parent attendance, family revocation, or profile changes. Each calculation reads the current ledger/profile/revocations in a transaction, counts distinct confirmed parent shifts, and removes the score when there are no eligible shifts or no profile. It does not apply event increments, so duplicate and out-of-order delivery do not duplicate awards. Updates are eventually consistent with existing personal Rewards. Voluntary cancellation retains confirmed points; removal revocations exclude them. Missing readiness information shows setup pending; stream failures show an error and Retry, never demo scores.

## Developer publication (not performed by the agent)

1. Use Node.js 22 and `npm ci` in this directory. The local authoring host used Node 24; the production Node 22 runtime has not been exercised. Firebase Functions requires an appropriately configured billing-enabled project, deployment access, and a runtime service account with Firestore access.
2. Publish the **complete** repository `firestore.rules` to the existing project's `(default)` database using the Firebase Console. Do not replace the existing private attendance/profile rules with public reads. Ensure the already-defined collection-group `ownerUid` indexes for `attendanceEntries` and `revokedFamilies` in `firestore.indexes.json` are READY. The leaderboard's `points` ordering uses the standard single-field index; no new composite index is required.
3. From the repository root, deploy only this functions codebase: `firebase deploy --only functions:leaderboard --project bushel-volunteer-20260925`. Confirm the three functions are running in `us-south1` before backfilling. Deployment remains a developer task under `plan.md`.
4. With trusted Application Default Credentials for the same project, run the following from this directory in PowerShell:

   ```powershell
   $env:GOOGLE_CLOUD_PROJECT = 'bushel-volunteer-20260925'
   npm run backfill -- --apply
   ```

   This intentionally writes only leaderboard projections and readiness. It does not modify attendance/rewards/profiles. It marks readiness false during the rebuild, processes existing profiles plus any stale leaderboard rows, then marks ready true. If it fails, investigate and rerun; readiness remains false. Historical attendance is included, with revoked shifts excluded. Do not place credentials in the repository. Future events keep the projection updated.
5. Verify through ordinary signed-in app clients: top scores should match each adult's Rewards total after updates settle. Signed-out reads and all direct client writes to leaderboard/status must be denied. Admin/backfill success does not prove client permissions.

`npm test` runs one offline score-calculation smoke test. No emulator or live-backend tests are part of this workflow.
