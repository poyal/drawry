# Release preparation

## Build configuration

- Bundle ID / application ID: `com.poyal.drawry`; marketing version `2.0.0`, build/versionCode `2`. Increment for subsequent uploads.
- Minimum execution: iOS 17 and Android API 26. Build submission SDKs are independent of these minima.
- iOS: Xcode 26+ with iOS 26+ SDK, automatic signing after selecting the owner's Apple team. [Apple SDK requirement](https://developer.apple.com/news/upcoming-requirements/?id=04282026a).
- Android: compile/target SDK 36, JDK 17, Gradle 8.13; release signing from the four environment variables in README. [Google Play target API requirement](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
- SQLCipher is pinned to 4.14.0 on both platforms. Android 4.19.0 requires compile SDK 37, so it is not used in this SDK-36 project. Future dependency upgrades require build and 16KB device checks.
- Native library packaging must remain 16KB-compatible; validate final AAB/APK as well as execution. [Android page-size guidance](https://developer.android.com/guide/practices/page-sizes).

## Owner-provided release inputs

Apple Developer team and provisioning, Google Play upload keystore, store records, support/privacy-policy URLs, final app icon and store screenshots are required before publication. No credentials are committed and no store upload is performed by the build workflows. Existing app icon artwork is retained pending final release artwork.

App Store privacy / Play Data Safety declarations must describe the shipped app: device-local diaries and on-demand user sharing, no backend/accounts/analytics. Camera/microphone permissions are used only on capture. Photo library selection uses system pickers. The iOS privacy manifest declares used disk-space and uptime APIs. Confirm declarations against the final dependency inventory and store forms at submission time.

The iOS encryption declaration is explicitly present in Info.plist. Complete the App Store Connect export-compliance questionnaire for the actual distributed encryption implementation before submitting; do not treat the project flag alone as the completed submission process.

## Release gates

Brand/UI work is still open: final launcher icon, intro/onboarding, consistent buttons and in-screen icons, and screen-level visual polish. Track acceptance in [TODO.md](../TODO.md); do not treat existing icon concepts or local QA screenshots as final store assets.

`VALIDATION_STATUS.md` lists executed checks. In addition, complete `docs/acceptance.md` on physical devices, run iOS build/tests with full Xcode, archive with production signing, inspect signed bundles and submit to TestFlight / Play internal testing. Recheck store SDK policies at the actual submission date.

The `.toolchain/` directory is a git-ignored local verification environment, not a runtime dependency or part of release artifacts.
