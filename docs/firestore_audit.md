# Firestore audit — 2026-09-28

**September 29 cleanup:** The user subsequently requested clearing all shift data. Shifts, groups/votes, registrations, and attendance were deleted and verified empty. The legacy records listed below are historical and no longer exist. Non-shift account/bank/family data was preserved.

**Post-audit update:** The user approved the prepared rules/index deployment. Deployment succeeded September 28 (release timestamp `2026-09-29T02:15:18.620415Z`). The active rules exactly match the repository, and both attendance collection-group indexes were verified READY; details are recorded in `docs/development_log.md`. The findings below describe the pre-deployment snapshot. Legacy shift records remain unchanged.

Read-only inspection of `bushel-volunteer-20260925`, `(default)`. No live records or active rules were changed. Three shifts and three corresponding groups were returned, with no additional pages. The reported fourth shift was not present in this database snapshot.

## Confirmed causes

- The active `cloud.firestore` release was updated at `2026-09-27T19:19:29.607679Z`. Its source contains groups/families/application rules (Slices 20–21), but no attendance/reward/QR grants and no new scheduling fields. Earlier documentation saying production was still at Slice 19 was stale.
- New shift creation sends `startsAt` and `utcOffsetMinutes`. The active field allowlist rejects them, even when the form is valid.
- Active rules deny QR updates and attendance queries. Retrying the same client cannot resolve this mismatch.
- `attendanceEntries.ownerUid` and `.leaderUid` have only inherited COLLECTION indexes, not the required COLLECTION_GROUP indexes.
- Every existing shift creator has an approved application for its bank. Group seats, checked member registrations, and shift signup counts agree. No removal vote records were present in these groups.

## Legacy shifts

| Shift | Document ID | Stored date | Stored time | Adults / seats |
| --- | --- | --- | --- | --- |
| Do work | `RpCvTrLTyHGKgpObIJ55` | 2099-12-31 | `25:70--5:0` | 2 / 2 |
| Why It no work | `a4fjy8h0VFHhQurATF1L` | 2024-02-29 | `-5:00` | 1 / 1 |
| rtfgcenamlk | `edWSISP5pHOxBwrKLcqH` | 2000-01-01 | `-5:00` | 1 / 1 |

All three lack `startsAt`. None has a QR field. These dates/times are invalid for new creation, but existing records remain readable and do not cause the new-shift permission error. Their intended replacement schedules cannot be inferred. Do not silently reschedule or delete booked shifts; obtain replacement dates/times or an explicit cleanup request first.

Removal currently requires two-thirds of **all** adult members; self-votes are forbidden. A one-person group has no removal target. A two-person group requires two votes but has only one eligible voter. Thus these groups cannot currently complete a removal, by policy rather than missing group records. The UI now explains the minimum of three adults. Changing that voting policy is separate from repairing deployment.

## Prepared fix and validation

- Deploy the repository's `firestore.rules` and `firestore.indexes.json` together after authorization. This enables the already implemented scheduling, QR, attendance, reward, and challenge behavior while retaining approved-bank and assigned-leader restrictions.
- Firebase's non-deploying [Rules test API](https://firebase.google.com/docs/reference/rules/rest/v1/projects/test) compiled the source with no issues after removing an unused helper. This was source validation, not a live client authorization test.
- My shifts now shows all booked shifts, including legacy dates, with clickable cards and an explicit **View group & members** button. Home's upcoming-shifts shortcut opens that tab. One targeted offline navigation smoke check passed; Flutter analysis is clean.

After authorized deployment, wait for both collection-group indexes to reach READY, restart the client, and manually create a valid shift, generate its QR, and load attendance. Test removal with three distinct adult members: two votes should remove the target and restore their booked capacity. Also verify another coordinator cannot manage the shift's attendance.

The audit itself was read-only; the subsequently approved deployment is recorded above. Legacy-data cleanup was not performed.
