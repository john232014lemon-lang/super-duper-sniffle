# Bushel Development Log

## 2026-09-28 — Approved Firestore deployment

The user explicitly approved deployment of the prepared rules and indexes. Ran `firebase deploy --only "firestore:rules,firestore:indexes" --project bushel-volunteer-20260925 --non-interactive`; deployment succeeded. Read back the active rules and verified an exact match to local `firestore.rules`. Release update: `2026-09-29T02:15:18.620415Z` (September 28, Chicago); ruleset `f42fefb4-d62b-4108-9764-7eafcb8f4022`.

Both attendance collection-group indexes (`ownerUid` and `leaderUid`) were verified READY after their build completed. Existing shifts, registrations, and schedules were not modified. No app build, hosting deployment, client mutation test, commit, or push was performed. Manual client checks remain: valid shift creation, assigned-leader QR generation, and attendance loading/check-in.

## 2026-09-28 — Live permission audit and group navigation

**Request:** Investigate failed shift creation, QR generation, attendance loading, old malformed schedules, and inaccessible removal screens.

**Live findings:** Read-only inspection confirmed the deployed rules are Slices 20–21 (release updated September 27), not the previously documented Slice 19. They reject the newer scheduling fields and contain no attendance/QR grants. Required attendance collection-group indexes are absent. Found three shifts, all with malformed times and past/far-future dates; each has its group and consistent member-registration/seat/signup counts. All creators have approved applications. No removal votes exist; groups contain two, one, and one adults, making removal impossible under the unchanged two-thirds/no-self-vote policy. Detailed findings and IDs are in `docs/firestore_audit.md`. No dates were guessed or records changed.

**Changes:** My shifts shows all booked shifts instead of hiding them behind a selected calendar date. Cards remain clickable and now expose **View group & members**; Home opens My shifts directly when bookings exist. Small groups explain the voting limit. Removed an unused rules helper flagged during source compilation.

**Verification:** One targeted offline navigation smoke check passed; Flutter analysis clean. Firebase Rules API source compilation returned no issues after removing the helper. This was not an emulator suite or a live client permission test. Deployment requires approval; production writes, legacy cleanup, release builds, commits, and pushes were not performed.

## 2026-09-28 — Scheduling bounds, empty check-in, and QR access

**Request:** Restrict times to 01:00–24:00 and group creation to now through one year ahead; fix the reported ShiftListing dropdown assertion and coordinator QR access.

**Changes:** Added shared schedule validation for the creation form, repository, and demo store. New times normalize to HH:mm; 24:00 means midnight ending the selected date. The creation window uses current-minute precision and a rolling 365-day year. Date picker bounds match the window; typed dates are checked with time on submission. New Firestore fields `startsAt` and `utcOffsetMinutes` bind the stored calendar date/time to the actual instant; pending rules enforce format, consistency, and the server-time window. Existing records remain readable.

**Fixes:** Dropdown values now use persistent shift IDs (shift identity in demo), with selection reconciled after updates and no dropdown for an empty list. QR generation no longer waits for a successful attendance query; the approved creator can generate it even with no attendees or a query error. Approval/assigned-leader enforcement remains intact. Production QR writes may still fail until the pending rules are deployed.

**Verification:** The three affected smoke checks passed: schedule bounds, populated/empty/repopulated check-in streams, and QR controls during attendance failure. Added only two smoke tests and extended an existing one. The QR fixture initially lost its error before subscription; corrected that fixture and reran only that failed check. Static analysis passed after one brace-style fix. No emulator, live backend test, build, deployment, commit, or push. Manual checks were added to `docs/manual_testing.md`; rules/index deployment and client QA remain pending.

## 2026-09-28 — Slices 22–23: persisted attendance and rewards

**Request:** Build Slices 22 and 23, retaining the manual-first testing policy.

**Implemented:** Persisted per-shift simulated QR, private participant attendance, and assigned approved leader confirmation. Bank details and coordinator Groups expose attendance management without requiring the creator to join the group. Check-in follows live registrations, handles stream updates, and displays loading/error/retry states. Canonical per-person/per-shift records and transactions make retries idempotent; rules prohibit direct confirmed creates, deletions, forged totals, or confirmation by other coordinators.

**Rewards:** Confirmed records derive 100 points per participant per shift and existing adult badge thresholds. Each confirmed child shift grants one immutable badge choice; a proof-backed featured badge persists independently. Family goals explicitly count 1–100 all-time distinct confirmed family shifts, deduplicating multiple family members. Legacy text challenges retain an explanatory notice. No Cloud Function, writable balance, real QR scanner, or token security was introduced. Demo behavior remains local.

**Verification:** Nine offline smoke checks passed, including two new checks for duplicate/pending reward exclusion and live check-in stream updates. Static analysis initially reported six brace-style issues; after fixing those, analysis passed with no issues. No emulator, live backend test, release build, or deployment was run. Backend permission/persistence checks remain manual and are listed in `docs/manual_testing.md`.

**Deployment:** Production remains on Slice 19 rules. Slices 20–23 require authorized deployment of rules and the new owner/leader attendance collection-group indexes, followed by manual client QA. Child attendance names are visible to the assigned leader, not general group members. No commit or push was performed.

## 2026-09-27 — Manual-first QA and test-suite reduction

**Request:** Refactor the plan, minimize automated testing/token overhead, remove redundant or elaborate tests (especially emulator tests), and require manual testing ideas in future agent handoffs.

**Changes:** Reorganized `plan.md` around current status, remaining slice boundaries, and a manual-first testing policy. Added root `AGENTS.md` so future agents discover that policy. New features receive at most 0–2 small smoke tests for severe regressions; low-risk work may need none. Routine emulator/live suites and release builds are no longer completion requirements. Final feature responses must include 2–4 specific developer manual checks with expected results.

**Pruning:** Replaced 46 Flutter tests across six files with seven short offline checks in `test/smoke_test.dart`: demo startup/reset, Firebase fail-closed startup, logout cleanup, late-account response isolation, no mock fallback for failed live data, approval-dependent coordinator UI, and parent-managed Kid Mode bookings. Removed long navigation/scroll scripts, field/schema permutations, redundant retry tests, badge/calendar detail checks, and fake persistence/voting implementations. Deleted all five automated backend scripts, including the 164-check emulator/live harness and standalone Auth runner. Kept the manually invoked Flutter connection diagnostic. Extracted the small HTTP helper into `tools/firebase/firestore_rest.py` so catalog administration remains functional.

**Manual QA:** Added `docs/manual_testing.md` as a pick-the-relevant-checks menu, not a mandatory full regression run. Updated README commands and removed retired-suite instructions. App behavior and Firestore security rules were not changed by this cleanup. Historical test counts in older log entries describe earlier runs, not the current testing policy.

**Verification:** Ran analysis once (clean), the reduced seven-test suite once (all pass, about two seconds of test execution), and `catalog_admin.py --help` to check local imports without contacting Firebase. No emulator, live-data test, release build, or deployment was run for this cleanup. Manual application/backend checks remain developer work. The previous deployment authorization boundary is unchanged.

## 2026-09-27 — Slices 20–21 and coordinator applications

**Request:** Build both groups/voting and persistent Family Center, plus applications on bank pages that administrators approve in the database.

**Implemented:** Bank-specific applications with required contact/reason fields, pending/approved/rejected status, retained form input on errors, and approval-controlled shift creation. Trusted administrators review the application document directly or use `catalog_admin.py approve/reject`; legacy grants no longer authorize coordination under the new rules.

**Groups:** Shift creation initializes a group. Adult signup/cancellation changes registration, capacity, and group membership atomically. Current adults vote once per target per membership version. Firestore rules verify a two-thirds quorum; removal atomically deletes the registration and adult/child places, restores capacity, revokes group access, and blocks immediate rejoining. Membership changes invalidate stale votes. Interrupted finalization has a retry action. Other families cannot read private registrations.

**Families:** Parent-owned kids, challenge titles, and profile selection persist in a private family document. Parents reserve capacity-counted child places in their own shifts. Kid Mode restores the child's real shifts and cannot independently sign up, coordinate, or vote. Attendance/reward/challenge progress remains outside this slice; demo mode stays local.

**Validation:** Clean Flutter analysis; all 46 Flutter tests pass; Web build succeeds. All 164 emulator backend checks pass (45 foundation, 43 catalog, 76 community). Tests include denial paths, last-slot races, stale/duplicate votes, atomic removal cleanup, family privacy, and persistence. Temporary emulator fixtures are cleaned up. The read-only live audit found zero existing shifts needing group migration.

**Deployment boundary:** Automatic approval review rejected production Firestore rules deployment and isolated live tests because the user had not explicitly authorized those production security changes. No new rules were deployed and no live test fixtures were created. Implementation is ready; live deployment/tests await user approval. Interactive platform verification remains open. No commit or push was made; pre-existing workspace changes were preserved.

## Project Overview

- **App Name:** Bushel
- **Purpose:** A family-friendly food bank volunteering app for discovering nearby food banks, viewing volunteer shifts, checking in, tracking community impact, and supporting coordinator and Kid Mode experiences.
- **Target Users:** Individual volunteers, families and children volunteering together, and food bank coordinators.

## Features Implemented

1. Flutter repository scaffold and Bushel Material 3 theme - **Status: Complete**
2. Responsive onboarding welcome screen - **Status: Complete**
3. Name, role, and family onboarding choices - **Status: Complete**
4. Mock volunteer home dashboard - **Status: Complete**
5. Three-bank mock discovery carousel - **Status: Complete**
6. Food bank detail pages with descriptions and operating information - **Status: Complete**
7. Mock bank shifts with dates, stations, and remaining capacity - **Status: Complete**
8. Recommended food banks on detail pages - **Status: Complete**
9. Local custom shift creation and sideways shift carousel - **Status: Complete**
10. Available shift signup and My Shifts schedule - **Status: Complete**
11. Mock map with tappable food bank markers - **Status: Complete**
12. Full calendar, real map provider, rewards, Kid Mode, and coordinator dashboard - **Status: Not Started**
13. Simulated station QR check-in with points - **Status: Complete**
14. Rewards progress with three point-based badges - **Status: Complete**
15. Kid Mode with simplified check-in and 25 selectable badges - **Status: Complete**

## Prompts Used

### Project Setup: Repository Root

**Prompt:**

> .
> └── bushel/
>     └── super-giggle (git root)/
>         ├── docs/
>         │   └── plan.md
>         ├── lib/
>         │   └── main.dart
>         └── rest of flutter stuff
>
> Edit plan.md so that project repository matches this root

**Result:** Updated the build plan to treat `bushel/super-giggle/` as the existing Git root and use root-relative Flutter paths.

**Modifications:** Removed instructions to create a nested repository, run `git init`, or replace the existing remote. Removed a machine-specific path from the setup instructions.

### Feature: Slice 0 Flutter Setup

**Prompt:**

> implement slice 0. follow docs at plan.md, don't commit work once finished

**Result:** Generated the Flutter scaffold directly in the existing Git root, added Bushel branding, configured a warm green Material 3 theme, created a minimal landing screen, and added a project README.

**Modifications:** Updated platform display names, replaced the generated counter test, and preserved the existing Git history and remote. No commit was created.

### Screen: Onboarding

**Prompt:**

> setup onboarding using this ui. and information

**Result:** Created a responsive onboarding flow inspired by the supplied visual reference. It includes a branded hero, first-name entry, volunteer/coordinator selection, family volunteering toggle, and local session state.

**Modifications:** Added mobile scrolling, form validation, a family/Kid Mode option based on the project plan, and widget tests for successful onboarding and missing-name validation.

### Screen: Home Dashboard

**Prompt:**

> we want to implement this home screen that opens after you onboard. this screen should just show mock data for now, and will late link to other screens we are adding

**Result:** Added a responsive mock home dashboard that opens after onboarding. It shows a personalized greeting, next shift, impact statistics, nearby food banks, urgent volunteer opportunities, and bottom navigation.

**Modifications:** Added temporary “coming soon” snackbars to future navigation and action points so later screens can be connected without prematurely implementing them.

### Feature: Slice 2 Food Bank Details

**Prompt:**

> I have this existing code: the home screen with 2 mock food banks Begin work on slice 2 Add the following features: - one more mock food bank - bank shifts, description, and the recomended food banks at the bottom

**Result:** Added Martha’s Kitchen as the third food bank and created navigable detail pages for all three banks. Each detail page contains a description, address, hours, upcoming shifts, stations, availability, and recommended banks.

**Modifications:** Moved food-bank content into reusable mock models and a shared data file. Kept signup as a Slice 3 placeholder and added an interaction test for home-to-detail navigation and recommendations.

### Documentation: Development Log

**Prompt:**

> create a development_log.md file in docs which will keep track of our progress. this will track prompts used day to day to create new features and solve bugs, follow this format:

**Result:** Created this development log and backfilled the project history using the prompts and outcomes recorded in the development conversation.

**Modifications:** Added current statuses, implementation notes, resolved challenges, lessons learned, and planned improvements.

### Feature: Slice 3 Custom Shifts

**Prompt:**

> Begin work on slice 3
> Add the following features:
> - Give people the ability to add their own shifts
> - Shifts should pop up in the sideways scroll bar like they already were

**Result:** Added a local custom-shift form to each food bank detail screen. Newly created shifts appear immediately in the horizontally scrolling upcoming-shifts row.

**Modifications:** Added required validation for shift name, date, time, station, and available spots. Custom shifts remain in memory for the current detail-screen session, and automated coverage verifies creation and horizontal-list display.

### Feature: Shift Signup and My Shifts

**Prompt:**

> shifts should be viewable as a list of different times and show available slots with a button to sign up. if you click that button and then confirm the shift is added to your shifts, viewable on the shifts page. shifts page will eventually show a calendar populated with available shifts.

**Result:** Added a schedule screen with Available and My shifts views, a mock date strip, time-based shift cards, remaining slot counts, signup confirmation, and shared local signup state.

**Modifications:** Connected the home bottom navigation to the Shifts page and reused the signup flow on food-bank detail cards. The date strip is intentionally a calendar placeholder until the full available-shift calendar is implemented.

### Feature: Slice 4 Mock Food Bank Map

**Prompt:**

> I want to implement the next step can you help me.

**Result:** Implemented Slice 4 as a lightweight mock map containing all three food banks, a current-location marker, selectable bank pins, a bank preview, and navigation to food bank details.

**Modifications:** Connected both the Banks bottom-navigation destination and the home screen’s See map action. The map is drawn locally without API keys, network access, or a map SDK so it remains consistent with the mock-first plan.

### Feature: Interactive Houston Map

**Prompt:**

> Implement fluttermap, latlong2, and geolocator. for the map make sure it is centered around Houston to start. have a find my location button but don't implement functionality yet. use a simple ui that matches the rest of the project.

**Result:** Replaced the illustrated map with an interactive `flutter_map` centered on Houston, backed by `latlong2` coordinates and OpenStreetMap tiles. Added `geolocator` for the future location feature.

**Modifications:** Added Houston-area coordinates to each mock food bank, preserved tappable branded markers and detail previews, included map attribution, and added a Find my location button that only displays a coming-soon message without requesting location access.

### Feature: Map Key and Persistent Navigation

**Prompt:**

> i want there to be a key to the map. this key will show different banks by having an arrow point to the bank locations. i want to fix the navigation bar because make the navagation bar stick in all pages

**Result:** Added a map key that pairs every food bank with its marker color and lets users select a bank directly. Added the shared Bushel navigation bar to the main post-onboarding screens.

**Modifications:** Changed map markers to colored location arrows, kept the bank preview behavior, and made Home, Banks, and Shifts consistently accessible from Home, Map, Shifts, and food-bank detail pages. Scan and Community remain visible placeholders for future slices.

### Improvement: Map Key Leader Arrows

**Prompt:**

> Make the key arrows point to map locations.

**Result:** Connected each map-key entry to its corresponding food-bank marker with a matching colored leader arrow.

**Modifications:** The arrow endpoints are calculated from each bank’s geographic coordinate and repaint as the interactive map moves. The overlay ignores pointer input so map panning, zooming, and marker taps continue working normally.

### Improvement: Directional Map Key Icons

**Prompt:**

> remove the lines, point the color arrow icons next to each name of food bank towards where its location is on the map. so if you were looking off way to the left of Houston all 3 icons would be pointing to the rightside of screen

**Result:** Removed the map-spanning leader lines and converted the colored key icons into live directional arrows.

**Modifications:** Each icon calculates its direction from the key to the bank’s projected screen coordinate. The arrows rotate as the map moves, including pointing right when the food banks are off-screen to the right.

### Feature: Slice 6 QR Check-in

**Prompt:**

> Work on slice 6

**Result:** Added a mock station QR scanner flow for signed-up shifts. Users simulate a scan, verify the matched station, confirm check-in, mark the shift complete, and earn 100 local points.

**Modifications:** Connected the persistent Scan navigation item and the home next-shift Check in button. Added an empty state for users without eligible shifts, duplicate check-in protection, a local points counter, completion status on the Shifts page, and widget-test coverage. Real camera scanning and production station IDs remain deferred.

### Bug Fix: Home Navigation and Check-in Consistency

**Prompt:**

> Bug fixes: clicking on the home button does not send you to the home screen. the check in button from the home screen does not have simulate qr, is a separate screen than then clicking scan from navigation bar

**Problem:** Primary navigation used replacement routes, which could remove the original Home route. The dashboard displayed a next shift even though the shared store initially had no signed-up shift, causing its check-in route to show an empty state.

**Solution:** The Home destination now rebuilds a canonical Home screen using the session’s onboarding name and clears stale primary routes. The dashboard’s displayed next shift is seeded as an initial mock signup, so both the home Check in button and Scan navigation open the same eligible simulated QR flow.

**Prompt used:** The bug-fix prompt above.

### Feature: Slice 7 Rewards Badges

**Prompt:**

> begin work on slice 7, i want to implement badges harvesting hero 500 points, family feeder 2000 points, and material mover for 10000 points

**Result:** Added a Rewards screen driven by the shared check-in points total, with Harvesting Hero at 500 points, Family Feeder at 2,000 points, and Material Mover at 10,000 points.

**Modifications:** Replaced the Community navigation placeholder with Rewards. Added total points, next-badge progress, earned count, individual badge progress bars, locked and earned visual states, and live updates when points change.

### Feature: Slice 8 Kid Mode

**Prompt:**

> implement slice 8. for kid mode make 25 kid friendly badges with different animals, plants, fruits, and veggies as the icons / name : example donkey badge, carrot badge, bunny badge, kids get to choose the badges to unlock after every check in. make a simple profile page accessible from clicking icon in top right on home: this shows your badge, and has a 3 way radio button toggle between volunteer, coordinator, and kid mode. which will change the rest of the app. implement all of kid mode simplified ui and check in process

**Result:** Added a complete Kid Mode presentation with a simplified home, large check-in controls, a three-destination navigation bar, a 25-item animal/plant/fruit/vegetable badge garden, and badge choice after successful check-in.

**Modifications:** Added a shared Volunteer/Coordinator/Kid role to session state and a profile screen opened from the home avatar. The profile displays the featured Kid badge and switches app modes. Kid check-in uses simpler language and larger controls, then requires the child to choose one locked badge. Coordinator selection changes the home presentation while its full dashboard remains reserved for Slice 9.

### Feature: Slice 9 Coordinator Group Management

**Prompt:**

> Build slice nine from plan.md

**Result:** Added a coordinator dashboard with a mock volunteer group, phone numbers on member profiles, and a local vote-to-remove workflow.

**Modifications:** Coordinator mode now exposes a Team destination and a dashboard shortcut on Home. Coordinators can open member profiles, review contact and participation details, submit one confirmed vote per member, see vote progress, and remove a member when the two-vote threshold is reached. All state remains local and mock-first.

### Change: Group-wide Removal Voting

**Prompt:**

> Anyone can start and vote in a group kick if they votes 2/3 of the total or more

**Result:** Opened group-removal voting to every member and replaced the fixed vote count with a dynamic two-thirds threshold.

**Modifications:** Added group management access to every profile. Any member may initiate or join a vote, each local user can vote once per target, and the target is removed when the yes votes reach at least two-thirds of the current group size, rounded up.

### Change: Shift-based Group Workflow and Mock Accounts

**Prompt:**

> we need to fix the workflow of groups. for each 'profile' add a fake user so that we can test. coordinator will be sir johnny john jimmy, kid will be lil jimbo, and volunteer will be jimmerson jimmies. coordinator will have one group with all 3 of them inside. groups are connected to shifts, a group is simply everyone signed up for a shift. make it so each account has one shift, which is this group of them 3. coordinators have all their groups in a 'groups' tab which you have already set up. kids and volunteers can their group by clicking on their shifts from the shift tab -> my shifts

**Result:** Reworked groups to represent the people signed up for a specific shift and added a distinct mock account for each app role.

**Modifications:** Coordinator Sir Johnny John Jimmy, kid Lil Jimbo, and volunteer Jimmerson Jimmies now share the same seeded Sorting & Packing shift and group. Coordinator mode lists the group in Groups. Volunteer and Kid Mode open it by selecting the shift under My Shifts. The group contains all three profiles, phone numbers, and the existing two-thirds removal voting flow.

### Change: Separate Test Accounts and Group Permissions

**Prompt:**

> ensure all 3 accounts are separate testing accounts with different voting capabilities. make it so the app opens up at home not the signin page since we are using these 3 testing accounts currently. once someone is removed they can no longer see that under 'my shifts'. ensure coordinators are only ones able to make new shifts on the food bank pages.

**Result:** Converted the three role profiles into separate in-memory test accounts and made account membership and permissions affect the app workflow.

**Modifications:** The app now opens directly on the active test account’s Home screen. Shifts, check-ins, points, and removal votes are tracked per account. Each account casts its own vote and cannot vote twice or vote for itself. Removed members lose access to the shared shift under My Shifts. Only the coordinator account sees the Add shift action on food-bank pages.

### Feature: Slice 10 Family Center

**Prompt:**

> Begin work on slice 10. for this slice we are going to further work on family/kids accounts. remove the 3 test accounts and reinstate the signup. kids can only be added by their parents so the two options for signup are coordinator or volunteer. if you signup with a 'family' account you get a new page -> family center. here you can signup your kids for their kids accounts and swap between parent/kid account. parents can also create challenges for their kids that will be visible for the kids in the 'family center'. for now add 3 basic challenges for example (signup for 3 shifts!)

**Result:** Restored signup and added a parent-managed Family Center for creating kid accounts, switching between family profiles, and sharing challenges.

**Modifications:** Removed the three named testing identities. Signup now offers only Volunteer and Coordinator roles, with the family option opening Family Center after setup. Parents can create kid accounts and custom challenges; kids can only enter Kid Mode through a parent-created account and can switch back to the parent. Three starter challenges are included and visible in both parent and kid Family Center views.

### Feature: Slice 11 Per-shift QR Attendance

**Prompt:**

> build slice 11

**Result:** Added a mock per-shift QR attendance workflow with coordinator generation, participant selection and provisional check-in, and coordinator confirmation.

**Modifications:** Shift listings now record their leader. Only the coordinator who leads a shift can generate its deterministic in-app QR code. Signed-up users choose an eligible shift in Scan, see that shift’s code, and submit a check-in awaiting confirmation. The coordinator’s shift group shows pending attendees and confirms them individually; only confirmation completes the shift and awards 100 points. Physical camera scanning remains deferred.

### Documentation: Firebase Phase Plan (2026-09-15)

**Prompt:** Update the plan after the completed mock slices with separate Firebase setup, Authentication, Firestore, and app-area migration slices; do not implement Firebase yet.

**Result:** Marked mock slices 0-11 complete and added planned slices 12-21 with explicit completion criteria for FlutterFire/core initialization, Email/Password auth, a restricted Firestore smoke test, and separate profile, bank, shift, group, family, attendance, and rewards migrations.

**Modifications:** Updated the YAML todos and queued next implementation prompt. Kept physical QR scanning, push, AI, and other deferred scope explicitly later. This documentation update installs no packages, configures no Firebase resources, and changes no app code.

### Slices 12-13: Firebase Core and Authentication (2026-09-15)

**Prompt:** Build slices 12 and 13.

**Result:** Added `firebase_core` and `firebase_auth`, activated FlutterFire CLI, and implemented startup loading/error/retry, an injectable auth service, adult Email/Password registration/login, restored-auth routing, and profile logout. Auth changes clear the navigation stack and all local mock account data. Firestore and profile persistence remain deferred.

**Validation:** All 23 widget/unit tests pass, including five new auth tests for initialization retry, validation and credential errors, registration, restored sessions, nested-route logout, account isolation, and logout failure. The web release build passed. Static analysis passes after fixing two formatting-related lint findings. Live Firebase behavior remains unverified.

**Remaining setup:** Firebase CLI requires `firebase login`; the intended project and platforms must be selected before FlutterFire configuration and enabling Email/Password. The options file currently reports missing configuration rather than supplying fake credentials. Live signup/login/restart verification remains pending. Flutter also reported that Windows Developer Mode is required for native plugin symlinks. Both slices remain in progress in `plan.md`.

### Slices 12-13: Android and Web Firebase Configuration (2026-09-25)

**Prompt:** Finish slices 12 and 13; configure Android and Web.

**Result:** Connected both platforms to `bushel-volunteer-20260925` with FlutterFire. Replaced the options placeholder, generated the Android service file and `firebase.json`, added the Google Services Gradle plugin, and selected Bushel in `.firebaserc`. Added an opt-in live authentication smoke test that cleans up its temporary accounts.

**Validation:** Dependency resolution, static analysis, all 23 local tests, and the Web release build pass. The live Auth check returns `CONFIGURATION_NOT_FOUND`; first-time console Authentication setup and Email/Password enablement are still needed. Console/UI automation has no connected browser. Android build/launch verification is blocked by the missing Android SDK and device/emulator. Updated README and plan with these precise remaining steps; no Firestore work was started.

### Documentation: Simpler Plan and Local Work While Firebase Is Blocked

**Prompt:** Simplify the plan and add one or two slices before further Firestore work while login is unavailable.

**Result:** Condensed `plan.md` into status and completion tables. Added Slice 14 (explicit local demo mode without Firebase login) and Slice 15 (a working mock shift calendar). Moved Firestore setup and migrations from 14-21 to 16-23, and updated YAML todos. Kept 12-13 incomplete with the school-account access restriction and Android verification gap recorded. This update changes documentation only.

### Documentation: Plan Proofreading

**Prompt:** Proofread the plan and make sure all steps are included.

**Result:** Checked slices 0-23 and their order. Clarified remaining Firebase setup/verification, demo launch documentation, database region selection, calendar migration, child shift participation, and kid badge persistence. Corrected README references to Firestore Slice 16 and profile Slice 17. Documentation only; no features implemented.

### Features: Slices 14-15 Local Demo and Shift Calendar

**Prompt:** Build slices 14 and 15.

**Result:** Added `BUSHEL_DEMO=true` startup without Firebase initialization, a persistent demo label, and a full mock-data/navigation reset. Replaced the placeholder date strip with month navigation, selectable days, shift markers, date-filtered Available/My Shifts, and empty-day guidance.

**Modifications:** Shift models now store real dates; mock shifts span three days starting at launch. Custom shifts accept a date picker or validated ISO date and remain visible when bank details reopen. Existing tests now isolate store state and scroll the calendar reliably. Updated README launch commands and marked 14-15 complete; Firebase 12-13 remains blocked and Firestore is untouched.

**Validation:** All 27 tests pass and the Web demo release build succeeds. Tests cover Firebase-free demo onboarding/reset, calendar signup and filtering, year/leap-day boundaries, invalid dates, and custom-shift visibility. Static analysis is clean. Android execution remains unverified because this machine lacks its SDK/device.

### Feature: Slice 16 Firestore in Texas (2026-09-26)

**Prompt:** Build step 16 with the database in Texas.

**Result:** Enabled the Firestore API and created the Standard Native `(default)` database in Dallas (`us-south1`) for `bushel-volunteer-20260925`. Added `cloud_firestore`, versioned rules/index configuration, and deployed owner-only rules for temporary test documents. All other app collections stay denied; no stores were migrated.

**Modifications:** Added a separate authenticated Flutter connection-check entry point and a Python emulator/live test using end-user tokens, not admin access. The test creates and cleans up temporary users/documents. Added loopback Auth/Firestore emulator configuration and used a checksum-verified portable Java 21 runtime without changing system Java.

**Validation:** 20 ownership/schema checks passed in the Emulator Suite and all 20 passed live, including write/read/delete and denial of signed-out/cross-user access. All 29 Flutter tests, static analysis, and the diagnostic Web build pass. Live Email/Password signup now works; earlier Authentication setup errors no longer block the backend test. Interactive Flutter auth verification and Android execution remain pending; Windows native plugin setup reports a Developer Mode/symlink requirement.

### Feature: Slice 17 adult profiles (2026-09-26)

**Prompt:** Set up Slice 17.

**Result:** Adult onboarding saves name, experience preference, and family setting to `profiles/{auth UID}` in the existing Dallas database. Sign-in restores the profile; missing profiles onboard, and read/write failures allow retry. Profile mode changes save before being applied. Account changes clear navigation and local data; stale responses cannot restore the old session. Demo and all other app areas remain local.

**Security and validation:** Deployed owner-only profile rules with an allowlisted schema. Coordinator preference grants no backend permissions. Static analysis is clean, the normal Web build succeeds, and all 35 Flutter tests and 45 emulator/45 live Firestore checks pass; temporary test users/documents were removed. Interactive Android/Web verification remains pending.

### Feature: Slices 18–19 food banks, shifts, and signup (2026-09-26)

**Prompt:** Build slices 18 and 19; continue.

**Result:** Normal adult mode streams banks into discovery, map, details, and recommendations, with loading/empty/retry states. Shifts use stable document IDs and date-only calendar mapping. Approved coordinators create shifts; adult signup/cancellation and My Shifts persist across sessions. Demo and kid shift data remain local. Live group/attendance actions wait for their slices; removed a stale group path that assumed a nonempty mock shift list.

**Security and setup:** Deployed bank-specific coordinator access rules separate from profile preferences. Atomic registration/count rules enforce capacity, prevent duplicate signup and count tampering, and isolate private registrations. Added administrator CLI helpers to import new bank records and grant/revoke access. No permanent access grants or sample bank data were added.

**Validation:** All 42 Flutter tests pass, analysis is clean, and the Web build succeeds. All 43 catalog/shift checks and 45 existing profile/connection checks pass in both emulator and live runs, including a simultaneous last-slot signup race. Admin import/grant/revoke payloads are exercised by the test fixtures. Temporary fixtures were cleaned up. Interactive Android/Web verification remains pending.

## Challenges & Solutions

### Challenge 1: Flutter SDK Cache Lock

**Problem:** The normal Flutter launcher stalled because an existing SDK process held Flutter’s cache lock.

**Solution:** Invoked Flutter’s cached tool snapshot directly to generate and verify the project without changing the SDK or repository Git state.

**Prompt used:** No additional user prompt; this occurred while implementing Slice 0.

### Challenge 2: Flutter Tool State Permissions

**Problem:** Flutter needed to update its per-user tool state outside the workspace sandbox.

**Solution:** Requested scoped permission for Flutter’s tool-state access, then generated the scaffold and ran analysis/tests normally.

**Prompt used:** No additional user prompt; this occurred while implementing Slice 0.

### Challenge 3: Onboarding CTA Below Test Viewport

**Problem:** The onboarding hero was taller than Flutter’s default 800×600 widget-test viewport, so automated taps initially missed controls below the fold.

**Solution:** Kept the production UI scrollable and updated tests to scroll controls into view before tapping.

**Prompt used:** The onboarding screen prompt listed above.

### Challenge 4: Hidden ListTile Material Effects

**Problem:** A decorated container around the family option obscured the `SwitchListTile` Material ink effects and triggered a framework assertion during tests.

**Solution:** Replaced the decorated container with a clipped `Material` surface using a rounded shape and border.

**Prompt used:** The onboarding screen prompt listed above.

### Challenge 5: Home Card Covered by Bottom Navigation in Tests

**Problem:** The fixed bottom navigation overlapped the lower portion of a food-bank card in the short widget-test viewport, causing navigation taps to miss.

**Solution:** Updated the interaction test to scroll the dashboard before tapping the bank card and to scroll the detail page until recommendations were built.

**Prompt used:** The Slice 2 food bank details prompt listed above.

## What I Learned

- Keep mock content in shared models and data files when multiple screens need the same information.
- Responsive production layouts should remain scrollable even when a reference design appears to fit a single device size.
- Widget tests need to account for fixed navigation and lazily built list content.
- Material controls should have their own appropriate Material surface so tap feedback remains visible.
- Each slice should stop at its intended boundary; bank detail can expose shifts without implementing signup state early.

## Future Improvements

- [ ] Persist custom shifts between app launches.
- [ ] Implement volunteer signup and cancellation for available shifts.
- [ ] Add a My Shifts screen using the selected mock shifts.
- [ ] Replace the mock map illustration with a real map provider and live coordinates.
- [ ] Persist onboarding choices locally between app launches.
- [ ] Add QR check-in simulation and volunteer points.
- [ ] Add rewards, badges, family challenges, and a leaderboard.
- [ ] Add Kid Mode and coordinator dashboard experiences.
- [ ] Replace mock data with Firebase-backed data in a later phase.
- [ ] Add real food bank photography or branded image assets.
- [ ] Continue recording each new prompt, result, modification, and bug fix in this file.
