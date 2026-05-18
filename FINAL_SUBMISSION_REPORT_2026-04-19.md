# HallMaster Enterprise - Final Submission Report

Date: 2026-04-19
Project: hallmaster_enterprise
Platform target: Flutter Android app (plus desktop/web dev targets)

## 0. Platform Requirement Clarification

- Mini-project implementation is prepared and validated as an Android app.
- iOS source scaffolding exists in this Flutter project (`ios/` folder), but iOS compilation and signing require macOS + Xcode.
- In this Windows environment, Android deliverables were fully produced and verified (APK + AAB + emulator install).
- If lecturer requires iOS output explicitly, a macOS build/signing pass is required as a separate final packaging step.

## 1. Executive Summary

This submission finalizes the enterprise hall-booking mini-project with:

- Persistent SQLite data layer and repository architecture
- Authentication and role-based access (guest/user/admin)
- Full hall CRUD (admin)
- Full booking controls (admin + user)
- Booking reschedule/edit flow from both admin and user sides
- Double-booking prevention on booking create and update
- Audit logging for booking state transitions and edits
- Android release artifacts (APK + AAB) generated
- Emulator deployment and UI evidence captured

## 2. Major Features Implemented

### 2.1 User-side Booking Features

- Create booking with date/time/services and total price calculation
- View my bookings
- Cancel my booking
- Reschedule/edit my booking (hall/date/time/price recompute)

Primary files:

- lib/src/features/booking/booking_flow_page.dart
- lib/src/features/booking/my_bookings_page.dart
- lib/src/data/repositories/booking_repository.dart

### 2.2 Admin-side Hall CRUD

- Add hall (validated form)
- Edit hall
- Delete hall (with active-booking safety guard)

Primary files:

- lib/src/features/admin/admin_dashboard_page.dart
- lib/src/data/repositories/hall_repository.dart

### 2.3 Admin-side Booking Controls

- Mark confirmed/completed/cancelled
- Hard-delete booking records
- Reschedule/edit booking from admin dashboard
- Audit log entries for admin status/modify actions

Primary files:

- lib/src/features/admin/admin_dashboard_page.dart
- lib/src/data/repositories/booking_repository.dart

## 3. Booking Reschedule/Edit Design

### 3.1 Shared Rules Enforced

- Cannot update cancelled bookings
- Cannot update past bookings
- Start hour must be before end hour
- Conflict detection checks hall/date/time overlap
- Edit operation excludes current booking ID from conflict query
- Final price recalculated from selected hall + duration + services + tax

### 3.2 Repository Enhancements

Implemented methods:

- isHallAvailableExcluding(..., excludeBookingId)
- updateBooking(... hallId/date/time/finalPrice ...)
- setBookingStatus(...)
- deleteBooking(...)

### 3.3 User-side Edit UX

- My Bookings page popup action includes Reschedule / Edit
- Dialog allows hall/date/time changes
- Validation and conflict-safe save
- Provider invalidation refreshes booking lists after save

### 3.4 Admin-side Edit UX

- Admin Bookings tab popup includes Reschedule / Edit
- Dialog allows hall/date/time changes
- Save writes update + audit log
- Dashboard refreshes immediately

## 4. Android Build and Verification

### 4.1 Environment Findings

- Android SDK and emulator available
- Default Flutter Android build path used a broken JBR executable location:
  - C:\Program Files\Android\Android Studio\jbr\bin\java.exe

### 4.2 Build Workaround Applied

Used Gradle directly with:

- JAVA_HOME = C:\Program Files\Android\Android Studio1\jbr
- Isolated GRADLE_USER_HOME in project folder

This bypassed the broken global Java resolution path.

### 4.3 Generated Artifacts

Located at:

- build/app/outputs/apk/release/app-release.apk
- build/app/outputs/flutter-apk/app-release.apk
- build/app/outputs/bundle/release/app-release.aab
- build/app/outputs/apk/debug/app-debug.apk

### 4.4 Emulator Deployment

- AVD connected: emulator-5554 (Android API 36)
- Installed debug build with Gradle:
  - gradlew app:installDebug
- Install confirmed successful on emulator

## 5. Screenshot Evidence

All screenshots saved under:

- submission_screenshots/

Key evidence files:

- submission_screenshots/01_guest_home.png
- submission_screenshots/12_login_page_manual.png
- submission_screenshots/13_user_home_manual.png
- submission_screenshots/14_new_booking_manual.png
- submission_screenshots/15_my_bookings_manual.png
- submission_screenshots/16_admin_dashboard_manual.png
- submission_screenshots/17_admin_halls_tab_manual.png
- submission_screenshots/18_admin_add_hall_dialog_manual.png
- submission_screenshots/19_admin_edit_booking_dialog_manual.png
- submission_screenshots/22_user_my_bookings.png

## 6. Validation Results

### 6.1 Static Analysis

- flutter analyze completed with no compile/blocking errors
- Remaining outputs are lint/info suggestions only

### 6.2 Functional Verification

Verified via code + emulator execution path:

- User booking edit/reschedule flow available
- Admin booking edit/reschedule flow available
- Admin hall CRUD actions available
- Booking controls (status + delete) available
- Data refresh behavior after actions available

## 7. Known Environment Caveat

Flutter CLI android build/run currently resolves an invalid Java path in this machine setup. Project-level Gradle build and emulator installation still work using explicit JAVA_HOME and isolated GRADLE_USER_HOME.

For local machine permanent fix:

1. Repair/reinstall Android Studio installation at C:\Program Files\Android\Android Studio (restore jbr\\bin\\java.exe)
2. Keep JAVA_HOME pointing to a valid JBR/JDK
3. Re-run flutter doctor and flutter build apk/appbundle

## 8. Conclusion

The project now meets production-grade functional expectations for:

- Admin management (halls + bookings)
- User booking lifecycle (create, view, cancel, edit/reschedule)
- Data integrity protections (double-booking prevention + update constraints)
- Android deliverables (APK/AAB) and emulator execution evidence

This report plus source changes and screenshot folder form the complete submission package.
