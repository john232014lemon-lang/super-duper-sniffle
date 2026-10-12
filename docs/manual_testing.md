# Developer manual checks

Pick the 2–4 checks relevant to your change; this is a menu, not a required full regression run. Use disposable developer accounts and records. Automated smoke checks do not prove backend permissions or persistence.

## Launch and accounts

- Run `flutter run -d chrome --dart-define=BUSHEL_DEMO=true`. Onboard, add a child or shift, then **Reset demo**. Expect onboarding again with previous private data cleared; no Firebase sign-in is needed.
- Run `flutter run -d chrome` for Firebase. Sign in, restart, sign out, and sign in as another adult. Expect the first account to restore after restart and its family/profile/signups to disappear on account change. An invalid password must not open the app.
- Disconnect during a save or load, then reconnect and retry. Expect a visible error and no false success or replacement of live data with demo content.

## Bank applications and shifts

- With the approved September 29 rules update now deployed, verify the 40-character name and 30-character station limits. Add multiline location instructions (up to 500 characters), restart, and check they appear on bank cards, My shifts, and check-in. Older shifts without instructions should still load.

- Try creating a group with `24:00`, `24:01`, a past time today, or a start beyond 365 days: expect validation errors and no creation. The current minute and a future start inside the window should work; a future `0:00` should save as `00:00`, and `23:59` should be accepted. Repeat invalid creation through an ordinary client after rules deployment to check server enforcement.
- Open Check-in with no bookings, then add/cancel bookings and return: expect an empty state or a valid dropdown, never the red assertion screen. As the approved shift creator, open **Manage check-ins** with no attendees or with attendance loading unavailable: **Generate shift QR** should remain accessible. Other coordinators must still be denied.

- Submit an application from bank details. While pending, **Add shift** must stay unavailable even with the Coordinator profile preference. Have an admin set that bank application's `status` to `approved`; creation should unlock only there. Set `rejected` and verify new creation is blocked again.
- Create a small-capacity shift and sign up. Restart and check **My shifts** and its group. Cancel and expect both membership and reserved capacity to update.
- With one place left, attempt signup from two ordinary adult sessions. Expect only one success and no count above capacity. A duplicate attempt must not reserve another place.

## Groups and voting

- Join three adults to a shift. One removal vote must not remove anyone; two different votes against the same target should remove that target's signup/group access and restore their places. Self-votes and repeated votes should not count.
- Cast one vote, change adult membership, and vote again. Expect earlier votes to be invalidated. A removed adult must not immediately rejoin. If finalization was interrupted, use **Complete removal** and check that capacity is restored only once.

## Family Center

- Join a shift as the parent, then use **Sign up for shift** under each child. Expect only the parent's booked shifts with free places. Restart: each child's booking should persist in Family Center and My shifts. Without a parent signup, child signup must fail through an ordinary client too.
- Use **Leave shift for [child]**: only that child's place is removed and one seat restored. Leave as the parent: the warning appears, and the parent plus all their child places are removed. This should work after the shift starts or attendance is confirmed. Kid Mode must show no join/leave actions and reject attempts through an ordinary client.
- After deploying the new contact rules, save a coordinator phone in **Your profile** and reopen that coordinator's booked child shift from another adult account. Expect Call/Text and the same number after restart; the buttons should open the device handlers. Clear the phone: expect **no number provided**. Offline/contact-permission failures should show a retry action rather than falsely claiming no number. Verify unauthenticated users cannot read contacts and other adults cannot read private profiles.

- Create a child and challenge, reserve a child place in one of the parent's shifts, and restart. Expect both family entries and the booking to persist. Switch to the child: only that child's bookings should appear, with no signup, voting, or coordinator actions. Switch back to the parent.
- Fill the last place with a child booking. Further bookings should fail. Cancel or vote out the parent and expect all their managed child places to be cancelled too.
- Sign in as another adult and verify they cannot read the first family's document or private registrations. Group members should see adult group data, not children's names or the parent's private registration.

## Backend permissions (only when the change affects them)

- Use ordinary authenticated app/client sessions for transaction flows. In the Firebase Rules Playground, check that another UID or an unauthenticated request cannot read `families/{parentUid}` or private registrations, and that an applicant cannot update their own status to `approved`.
- Admin console/CLI writes bypass security rules: use them to create fixtures or approve applications, never as proof of denied client access. A Playground check of one write also does not establish that a multi-document transaction works.
- If you choose to use local emulators manually, start them with `firebase emulators:start --only auth,firestore --project demo-bushel` and explicitly connect your client to them. The normal Flutter entry point does not automatically connect to emulators. Do not recreate an automated harness just to complete a slice.

## Attendance and rewards

Slices 22–23 rules/indexes were deployed September 28 after authorization; manual client QA is now the next step.

- As an approved shift creator, open **Manage check-ins** from bank details or **Shifts you lead** in Groups and generate the QR. As a signed-up adult, scan the current leader QR or enter it manually, selecting yourself or a booked child in parent mode. Restart: attendance should remain pending with zero new points and no badge choice. Demo mode should still work without Firebase.
- Confirm with the assigned approved leader: the participant should gain exactly 100 points, surviving restart and retries. Using ordinary clients, try confirming as another coordinator or creating confirmed attendance directly as a participant; both must be denied. Cancel/remove an unconfirmed participant and verify confirmation is denied.
- In Kid Mode, choose a badge after confirmation, then feature another previously earned badge and restart. Expect one permanent choice per confirmed child shift and the featured choice restored. Pending attendance and a sibling's attendance must not unlock this child's badges.
- Create a two-shift family goal. Confirm parent and child on the same shift: expect 1/2, not 2/2. Confirm a second distinct shift: expect completion. Past confirmed shifts count; old text-only challenges show an explicit legacy notice instead of guessed progress. Disconnect and retry: expect a visible error/loading state rather than demo rewards.

## Optional connection diagnostic

Run `flutter run -d chrome --target lib/firestore_smoke_main.dart`, sign in, and select **Run connection check**. Expect a write, server read, and deletion of your temporary diagnostic record. This is a manually invoked diagnostic, not an automated test suite.

## Current deployment boundary

The developer reported manually publishing the full repository rules and creating the indexes on October 9, including coordinator contacts, family removal, and revokedFamilies indexes. Verify both revokedFamilies collection-group indexes are READY before running removal/reward checks. Publication and index readiness have not been independently verified. The non-deploying Rules API authentication blocker cleared October 12. Slices 24–25 are implemented locally; publish the new secure-token rules before checking this revision. No new indexes are required.

- Open Home → **Your upcoming shifts**: expect My shifts to show all bookings, including dates outside today. Tap a card or **View group & members** to see that shift's members. Groups with fewer than three adults should explain why removal cannot reach the existing quorum.

## Family removal and coordinator check-in (after deployment)

- Book a parent and child, scan both, confirm attendance, and claim a child badge. With at least three adult members, reach the two-thirds removal threshold. Both bookings disappear, all their seats return, that shift loses its points/badge/challenge contribution after reload, and neither can rejoin or claim again. Another family and rewards earned on other shifts stay unchanged. Also try removing a family with only pending check-ins.
- Have the assigned, approved coordinator join and scan their own shift: confirmation and 100 points appear automatically, once. Another coordinator and the assigned coordinator's child must remain pending until confirmed.
- In parent mode, follow the instructions at the top of Family Center to add a kid, book yourself, then book/leave only that kid. Kid Mode has no signup, leave, or removal-voting action.
- A coordinator who also joined a shift should see one group card. Members & removal votes opens membership voting; QR & attendance opens QR creation and pending confirmations. A coordinator who has not joined can manage attendance but cannot vote.

## Authentication closeout (Slices 12–13)

Developer-reported verification completed on Web (Edge/Chrome) and Android emulator (Pixel 7): Firebase sign-in works, the session persists across app restart, logout returns to the sign-in screen, and an invalid password shows an error without opening the app. This records only those checks; account-switching and backend permissions are separate checks.

Optional future regression checks (not rerun by the agent):

- On Web and Pixel 7, sign in and restart the app: expect the signed-in session to restore.
- Log out, then attempt an invalid password: expect the sign-in screen to remain with a visible error and no app access.

Slices 24–25 manual checks below are pending developer execution after publication of the updated rules.

## Slice 24 secure tokens (after publishing updated rules; unperformed)

- Use ordinary signed-in clients. The assigned approved leader generates a QR within 30 minutes before / 4 hours after startsAt; another coordinator or member must be denied generation/rotation. Read the shift as a member: expect only qrTokenHash and qrExpiresAt, no raw secure code; attempts to submit the public verifier as a proof must fail.
- Save a code, rotate it, then enter the old code or a different shift's code: expect a clear rejection with no attendance. Wait to the displayed expiry (at most 15 minutes) and retry: expect expiry rejection. The new current code should still work within its window.
- Check in an ordinary booked adult and a booked child from parent mode: both remain pending with no rewards until the assigned leader confirms. Retry the same participant: expect already checked in, with one attendance record and one 100-point award after confirmation. The assigned approved leader's own adult check-in retains automatic confirmation.
- Cancel/remove a booking and attempt check-in with a valid QR through an ordinary client: expect denial. Switch to Kid Mode: expect no scan/entry/check-in actions and direct attendance creates denied. Demo mode follows the same local flow without Firebase.

## Slice 25 camera scanning (unperformed)

- Display a generated leader QR and scan it from a booked ordinary account on Pixel 7 and Web (Edge/Chrome over HTTPS or localhost). Select the correct shift and confirm: expect one pending attendance record and no new points until leader confirmation. Scan the same code for a booked child from parent mode: expect the child's own pending record. Demo uses the same local flow; its first seeded shift starts when the app launches.
- Deny camera permission on Android and Web: expect a clear denial message and **Enter code instead**. Enter the current code from the leader: expect the same pending attendance behavior. With no camera, a busy camera, or an unsupported platform, expect an explanatory message and the same manual fallback.
- Scan a QR for a different shift or a saved expired/rotated QR, then confirm: expect rejection and no new attendance. Scan the newest current QR: expect success only for a current booked participant. Double detection must not submit automatically or create duplicate attendance.
- Open/close the scanner and background/restore the app: expect the camera to release/pause and resume without duplicate results. Switch to Kid Mode: expect no camera or manual-entry/check-in controls; direct client attendance writes are denied. Scanning requires parent mode even for booked children.
