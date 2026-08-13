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
9. Local shift signup and cancellation - **Status: Not Started**
10. Real map, QR check-in, rewards, Kid Mode, and coordinator dashboard - **Status: Not Started**

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

- [ ] Implement local shift signup and cancellation.
- [ ] Add a My Shifts screen using the selected mock shifts.
- [ ] Add a simple map view for the three mock food banks.
- [ ] Persist onboarding choices locally between app launches.
- [ ] Add QR check-in simulation and volunteer points.
- [ ] Add rewards, badges, family challenges, and a leaderboard.
- [ ] Add Kid Mode and coordinator dashboard experiences.
- [ ] Replace mock data with Firebase-backed data in a later phase.
- [ ] Add real food bank photography or branded image assets.
- [ ] Continue recording each new prompt, result, modification, and bug fix in this file.
