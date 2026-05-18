# HallMaster Enterprise

Hall booking mini-project built with Flutter.

## Platform Compliance

- Primary target: Android app (submission target)
- iOS support: codebase includes `ios/`, but iOS build/signing must be done on macOS with Xcode

If your mini-project brief explicitly asks for Android, this repository is aligned with that requirement.
If your lecturer explicitly asks for iOS evidence as well, use the iOS checklist below on a Mac.

## Android Build and Run

Standard Flutter commands:

```powershell
flutter pub get
flutter run -d emulator-5554
flutter build apk --release
flutter build appbundle --release
```

If your machine has the Android Studio JBR path mismatch issue, use the verified Gradle workaround:

```powershell
Set-Location android
$env:JAVA_HOME='C:\Program Files\Android\Android Studio1\jbr'
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path
$env:GRADLE_USER_HOME='..\\.gradle_user_home'
.\gradlew.bat app:assembleRelease
.\gradlew.bat app:bundleRelease
.\gradlew.bat app:installDebug
```

## Android Output Artifacts

- `build/app/outputs/apk/release/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## iOS Checklist (Only If Required by Brief)

Run on macOS:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing team and bundle ID
3. Run `flutter build ios --release`
4. Archive and export IPA from Xcode Organizer
5. Capture iOS simulator/device screenshots as evidence

## Submission Evidence

- Final report: `FINAL_SUBMISSION_REPORT_2026-04-19.md`
- Screenshots: `submission_screenshots/`
