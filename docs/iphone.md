# Install Bushel on iPhone from Windows

## Build the unsigned IPA

After the workflow is on GitHub's default branch, open **Actions > iOS unsigned IPA > Run workflow** and select the branch to build. The workflow uses Flutter 3.50.0 and the checked-in dependency lockfile on `macos-latest`. It builds with Swift Package Manager and packages the device app as `Payload/Runner.app` inside `Runner-unsigned.ipa`.

Open the successful run and download the **Runner-unsigned** artifact. Extract the downloaded ZIP to get `Runner-unsigned.ipa`. Leave the IPA itself intact. Standard GitHub-hosted runner minutes are free for public repositories. Private repositories use the owner's Actions allowance. [GitHub Actions billing](https://docs.github.com/en/actions/concepts/billing-and-usage)

The local Xcode configuration targets iOS 15.0 for the locked Firebase Apple SDK. If GitHub Actions reports an iOS 13.0 deployment-target mismatch, run the workflow from a GitHub branch containing the iOS 15.0 setting. The Android, iOS, and Web configs use Firebase project `bushel-volunteer-20260925`. The iOS bundle ID is `com.bushel.bushel`, and its Firebase plist is included in Runner resources. The iOS app declares camera and foreground location usage.

## Sign and install over USB

1. Install Sideloadly for Windows and the desktop iTunes and iCloud installers linked on its download page. Use the web versions linked there. [Sideloadly downloads](https://sideloadly.io/#download)
2. Unlock the iPhone and connect it with a data-capable USB cable. Tap **Trust** if prompted and enter the device passcode. Confirm iTunes detects the phone.
3. Open Sideloadly, select the iPhone, drop in `Runner-unsigned.ipa`, enter your free Apple ID, and click **Start**. Complete the Apple password and two-factor prompts in Sideloadly. Use the same Apple ID and effective bundle ID on subsequent installs.
4. On the iPhone, trust the Apple ID's developer profile in **Settings > General > VPN & Device Management** if prompted. On iOS 16 and later, turn on **Settings > Privacy & Security > Developer Mode**, restart, and confirm **Turn On**. Then open Bushel.
5. Refresh the signature within **7 days**. Reconnect by USB and repeat the Sideloadly install over the existing app using the same Apple ID and effective bundle ID. You can also enable automatic refresh and keep the Sideloadly daemon running on a PC that can reach the phone by USB or configured Wi-Fi. Reuse the same IPA for a signature refresh. [Sideloadly FAQ](https://sideloadly.io/faq.html)
