# Bushel Development Log

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
