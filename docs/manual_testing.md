# Developer manual checks

Pick the 2–4 checks relevant to your change; this is a menu, not a required full regression run. Use disposable developer accounts and records. Automated smoke checks do not prove backend permissions or persistence.

## Launch and accounts

- Run `flutter run -d chrome --dart-define=BUSHEL_DEMO=true`. Onboard, add a child or shift, then **Reset demo**. Expect onboarding again with previous private data cleared; no Firebase sign-in is needed.
- Run `flutter run -d chrome` for Firebase. Sign in, restart, sign out, and sign in as another adult. Expect the first account to restore after restart and its family/profile/signups to disappear on account change. An invalid password must not open the app.
- Disconnect during a save or load, then reconnect and retry. Expect a visible error and no false success or replacement of live data with demo content.

## Bank applications and shifts

- Try creating a group with `00:59`, `24:01`, a past time today, or a start beyond 365 days: expect validation errors and no creation. The current minute and a future start inside the window should work; `24:00` means next midnight. Repeat invalid creation through an ordinary client after rules deployment to check server enforcement.
- Open Check-in with no bookings, then add/cancel bookings and return: expect an empty state or a valid dropdown, never the red assertion screen. As the approved shift creator, open **Manage check-ins** with no attendees or with attendance loading unavailable: **Generate shift QR** should remain accessible. Other coordinators must still be denied.

- Submit an application from bank details. While pending, **Add shift** must stay unavailable even with the Coordinator profile preference. Have an admin set that bank application's `status` to `approved`; creation should unlock only there. Set `rejected` and verify new creation is blocked again.
- Create a small-capacity shift and sign up. Restart and check **My shifts** and its group. Cancel and expect both membership and reserved capacity to update.
- With one place left, attempt signup from two ordinary adult sessions. Expect only one success and no count above capacity. A duplicate attempt must not reserve another place.

## Groups and voting

- Join three adults to a shift. One removal vote must not remove anyone; two different votes against the same target should remove that target's signup/group access and restore their places. Self-votes and repeated votes should not count.
- Cast one vote, change adult membership, and vote again. Expect earlier votes to be invalidated. A removed adult must not immediately rejoin. If finalization was interrupted, use **Complete removal** and check that capacity is restored only once.

## Family Center

- Create a child and challenge, reserve a child place in one of the parent's shifts, and restart. Expect both family entries and the booking to persist. Switch to the child: only that child's bookings should appear, with no signup, voting, or coordinator actions. Switch back to the parent.
- Fill the last place with a child booking. Further bookings should fail. Cancel or vote out the parent and expect all their managed child places to be cancelled too.
- Sign in as another adult and verify they cannot read the first family's document or private registrations. Group members should see adult group data, not children's names or the parent's private registration.

## Backend permissions (only when the change affects them)

- Use ordinary authenticated app/client sessions for transaction flows. In the Firebase Rules Playground, check that another UID or an unauthenticated request cannot read `families/{parentUid}` or private registrations, and that an applicant cannot update their own status to `approved`.
- Admin console/CLI writes bypass security rules: use them to create fixtures or approve applications, never as proof of denied client access. A Playground check of one write also does not establish that a multi-document transaction works.
- If you choose to use local emulators manually, start them with `firebase emulators:start --only auth,firestore --project demo-bushel` and explicitly connect your client to them. The normal Flutter entry point does not automatically connect to emulators. Do not recreate an automated harness just to complete a slice.

## Attendance and rewards

Slices 22–23 are implemented locally; deploy rules and indexes only after authorization before doing live QA.

- As an approved shift creator, open **Manage check-ins** from bank details or **Shifts you lead** in Groups and generate the QR. As a signed-up adult or booked child, simulate scanning and submit. Restart: attendance should remain pending with zero new points and no badge choice. Demo mode should still work without Firebase.
- Confirm with the assigned approved leader: the participant should gain exactly 100 points, surviving restart and retries. Using ordinary clients, try confirming as another coordinator or creating confirmed attendance directly as a participant; both must be denied. Cancel/remove an unconfirmed participant and verify confirmation is denied.
- In Kid Mode, choose a badge after confirmation, then feature another previously earned badge and restart. Expect one permanent choice per confirmed child shift and the featured choice restored. Pending attendance and a sibling's attendance must not unlock this child's badges.
- Create a two-shift family goal. Confirm parent and child on the same shift: expect 1/2, not 2/2. Confirm a second distinct shift: expect completion. Past confirmed shifts count; old text-only challenges show an explicit legacy notice instead of guessed progress. Disconnect and retry: expect a visible error/loading state rather than demo rewards.

## Optional connection diagnostic

Run `flutter run -d chrome --target lib/firestore_smoke_main.dart`, sign in, and select **Run connection check**. Expect a write, server read, and deletion of your temporary diagnostic record. This is a manually invoked diagnostic, not an automated test suite.

## Current deployment boundary

The Slice 20–23/application rules and attendance collection-group indexes have not been deployed. Do not expect these live flows to work under the old Slice 19 rules. Production deployment still needs explicit authorization; reducing automated tests does not authorize deployment. After an approved deployment, use the relevant checks above and clean up disposable records/accounts.
