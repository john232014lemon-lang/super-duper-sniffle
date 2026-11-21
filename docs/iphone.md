# iOS sideload plan (Windows → free Apple ID)

Goal: build an unsigned Flutter iOS IPA with GitHub Actions (`macos-latest`), then install on student iPhones from Windows with **Sideloadly** and a free Apple ID (no $99 Developer Program).

## Precursors (done 2026-11-21)

- Firebase iOS app registered: bundle `com.bushel.bushel`, app id `1:375797641238:ios:a6c2225ffd10167cdb0537` on project `bushel-volunteer-20260925`.
- `lib/firebase_options.dart` includes iOS; `ios/Runner/GoogleService-Info.plist` is in the Runner resources.
- Flutter **3.50+ uses Swift Package Manager** for iOS plugins. This repo has **no CocoaPods `Podfile`**. CI should **not** run `pod install` unless a future plugin forces CocoaPods fallback.
- `Info.plist` includes camera (QR scan) and location-when-in-use usage descriptions.

## Workflow (added 2026-11-21)

`.github/workflows/ios-unsigned-build.yml` builds an unsigned IPA on `macos-latest` (Flutter 3.50.0, no CocoaPods). Trigger via Actions → **iOS unsigned IPA** → Run workflow, or push to `main`. Download the `Runner-unsigned` artifact (`Runner-unsigned.ipa`).

## Still todo

1. Make the GitHub repo **public** (or accept paid macOS Actions minutes if private).
2. Windows + Sideloadly class path:
   - Download artifact IPA
   - Install Sideloadly + Apple **non–Microsoft Store iTunes** (Apple no longer ships a current non-Store iCloud; try iTunes-only first)
   - USB install with each student’s free Apple ID
   - Trust profile under **Settings → General → VPN & Device Management**; enable **Developer Mode** on iOS 16+
   - Re-sign about every **7 days** with free Apple IDs

## Constraints

- Development OS: Windows (no local Mac).
- Signing: free Apple ID via Sideloadly; CI builds unsigned (`--no-codesign`).
- Repository should stay public for free `macos-latest` minutes.
