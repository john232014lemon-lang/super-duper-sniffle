I need your help setting up a free CI/CD pipeline to build our Flutter iOS app using GitHub Actions on a macOS runner, and then sideloading it onto our iPhones from Windows PCs using a free Apple ID (no $99 Apple Developer Program membership).

### Context & Constraints
- **Repository:** Public GitHub repository (so `macos-latest` GitHub-hosted runner minutes are free).
- **Development OS:** Windows PCs (we do not have local Macs).
- **Signing:** Free Apple ID only. The GitHub Actions runner must build an unsigned `.ipa` (`--no-codesign`) and package `Runner.app` into a `Payload` directory zipped as `app.ipa`.
- **Sideloading Tool:** We will use **Sideloadly** (free Windows desktop app) to sign the `.ipa` with our free Apple ID and install it over USB onto our iPhones.

### Your Tasks
1. **Inspect the Repository:**
   - Check our `pubspec.yaml` (Flutter/Dart SDK versions and dependencies, especially any iOS-specific packages like Firebase or plugins requiring CocoaPods).
   - Check the `ios/` directory (`ios/Podfile`, `ios/Runner/Info.plist`, and deployment target versions) to ensure there are no configuration blockers for an automated headless macOS build.
2. **Create the GitHub Actions Workflow:**
   - Create `.github/workflows/ios-unsigned-build.yml`.
   - Configure it to trigger on `workflow_dispatch` (manual trigger) and/or pushes to `main`.
   - Use `runs-on: macos-latest`.
   - Include steps to:
     - Checkout the code (`actions/checkout@v4`).
     - Set up Flutter (`subosito/flutter-action@v2`) matching our project's SDK version.
     - Run `flutter pub get`.
     - Run `pod install` inside `ios/` if needed.
     - Build the unsigned iOS release app: `flutter build ios --release --no-codesign`.
     - Package `build/ios/iphoneos/Runner.app` into a `Payload/` folder and zip it into `Runner-unsigned.ipa`.
     - Upload `Runner-unsigned.ipa` using `actions/upload-artifact@v4`.
3. **Provide a Windows + Sideloadly Walkthrough:**
   - After generating the workflow file, give us clear, step-by-step instructions on how to:
     1. Trigger the workflow on GitHub and download `Runner-unsigned.ipa`.
     2. Install Sideloadly (plus Apple's non-Microsoft-Store versions of iTunes and iCloud required by Sideloadly on Windows).
     3. Connect an iPhone via USB, load `Runner-unsigned.ipa` into Sideloadly, enter our free Apple ID, and install the app.
     4. Trust the developer profile in iOS **Settings > General > VPN & Device Management** and enable **Developer Mode** (iOS 16+), plus explain the 7-day re-signing refresh process.

Start by inspecting `pubspec.yaml` and the `ios/` directory in this repository, tell me if any fixes are needed first, and then generate the `.github/workflows/ios-unsigned-build.yml` file.
