# HallMaster Enterprise - Complete System Specification for Claude

Date: 2026-04-19
Project: hallmaster_enterprise
Current package baseline: V1.0

## 1. Purpose of This Document

This document is a full technical handoff for another AI agent (Claude) to continue improving the HallMaster Enterprise mini-project without losing context.

It consolidates:
- product scope
- architecture
- database schema
- business rules
- feature behavior
- repository APIs
- build and run instructions
- known environment caveats
- evidence and artifacts
- prioritized next steps

Companion instruction document:
- MINIPROJECT_INSTRUCTION_DOCUMENT.md

Primary source files used to compile this handoff:
- README.md
- FINAL_SUBMISSION_REPORT_2026-04-19.md
- GROUP_WIREFRAME_BRIEF.md
- WIREFRAME_SCREEN_OUTLINE.md
- USECASE_FLOW_SITEMAP.md
- FLUTTER_STRUCTURE_BREAKDOWN.md
- .impeccable.md
- lib/src/core/*.dart
- lib/src/data/repositories/*.dart

## 2. Project Summary

HallMaster Enterprise is a Flutter-based hall booking app with role-aware experience:
- Guest: browse and search halls
- User: create and manage own bookings
- Admin: manage bookings, halls, users

Primary target for submission is Android.
The codebase is multi-platform (android/ios/web/windows/linux/macos), but validated deliverables in this environment are Android artifacts.

## 3. Tech Stack and Runtime

- Flutter SDK
- Dart SDK >= 3.0.0 < 4.0.0
- State management: flutter_riverpod
- Navigation: go_router
- Persistence: sqflite (local SQLite)
- Storage path helpers: path_provider + path
- Security hashing: crypto (SHA-256)
- Equality helpers: equatable
- IDs/util: uuid
- Localization utility used for formatting: intl

Dependencies are in pubspec.yaml.

## 4. Canonical Folder Structure

Top-level app structure:
- lib/main.dart
- lib/src/app
- lib/src/core
- lib/src/features
- lib/src/data/repositories
- test

Layer responsibilities:

### 4.1 App Layer (lib/src/app)
- app.dart: MaterialApp.router setup and global app shell integration
- router.dart: route table and role-based redirects
- theme.dart: design tokens and component theme config

### 4.2 Core Layer (lib/src/core)
- models.dart: domain entities and enums
- app_state.dart: Riverpod providers (repositories, user/session state, data fetch providers)
- database.dart: SQLite creation + seed data
- security.dart: input normalization, hashing, validation, login rate limiter
- widgets/app_shell_scaffold.dart: shared shell/navigation/session controls
- widgets/async_state_views.dart: loading/error/empty views

### 4.3 Feature Layer (lib/src/features)
- guest/guest_home_page.dart
- auth/login_page.dart
- user/user_home_page.dart
- booking/booking_flow_page.dart
- booking/my_bookings_page.dart
- admin/admin_dashboard_page.dart

### 4.4 Data Layer (lib/src/data/repositories)
- user_repository.dart
- hall_repository.dart
- service_repository.dart
- booking_repository.dart

## 5. Roles and Access Model

Enums:
- UserRole: guest, user, admin
- BookingStatus: pending, confirmed, cancelled, completed

Routing behavior (router.dart):
- Initial route: /guest
- Routes:
  - /guest
  - /login
  - /user
  - /admin
  - /booking/new
  - /booking/my
- Redirect rules:
  - non-admin trying /admin -> /login
  - guest trying /user, /booking/new, /booking/my -> /login

Current user state provider default:
- guest user object is preloaded until auth action updates state.

## 6. Data Model (Domain)

### 6.1 AppUser
Fields:
- id
- name
- email
- role
- phone (optional)

### 6.2 Hall
Fields:
- id
- name
- location
- capacity
- basePrice
- amenities (list of strings)

### 6.3 AddOnService
Fields:
- id
- name
- unitPrice

### 6.4 Booking
Fields:
- id
- userId
- hall (embedded Hall object on read)
- date
- startHour
- endHour
- services (list of AddOnService)
- status
- finalPrice

## 7. SQLite Schema

Database file:
- application documents path + hallmaster_enterprise.db

Tables created in database.dart:

1) users
- id TEXT PRIMARY KEY
- name TEXT NOT NULL
- email TEXT UNIQUE NOT NULL
- password_hash TEXT NOT NULL
- phone TEXT
- role TEXT NOT NULL
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL

2) halls
- id TEXT PRIMARY KEY
- name TEXT NOT NULL
- location TEXT NOT NULL
- capacity INTEGER NOT NULL
- base_price REAL NOT NULL
- amenities TEXT NOT NULL (comma-separated in DB)
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL

3) add_on_services
- id TEXT PRIMARY KEY
- name TEXT NOT NULL
- unit_price REAL NOT NULL
- created_at TEXT NOT NULL

4) bookings
- id TEXT PRIMARY KEY
- user_id TEXT NOT NULL
- hall_id TEXT NOT NULL
- booking_date TEXT NOT NULL (YYYY-MM-DD)
- start_hour INTEGER NOT NULL
- end_hour INTEGER NOT NULL
- status TEXT NOT NULL
- final_price REAL NOT NULL
- created_at TEXT NOT NULL
- updated_at TEXT NOT NULL
- cancelled_at TEXT
- cancellation_reason TEXT
- FK user_id -> users.id
- FK hall_id -> halls.id

5) booking_services
- booking_id TEXT NOT NULL
- service_id TEXT NOT NULL
- composite PK (booking_id, service_id)

6) audit_logs
- id TEXT PRIMARY KEY
- entity_type TEXT NOT NULL
- entity_id TEXT NOT NULL
- action TEXT NOT NULL
- actor_id TEXT NOT NULL
- changes TEXT
- created_at TEXT NOT NULL

## 8. Seed Data

Seeded on first DB create:

Halls:
- h1 Prime Ballroom, Kuala Lumpur, capacity 350, base_price 1200.0
- h2 Orchid Conference Hall, Cyberjaya, capacity 120, base_price 680.0
- h3 Zenith Boardroom, Putrajaya, capacity 40, base_price 320.0

Services:
- s1 AV Equipment, 180.0
- s2 Catering Package, 350.0
- s3 Decor Setup, 220.0

## 9. Repository API Contract

## 9.1 UserRepository
Core methods:
- getUserById(id)
- getUserByEmail(email)
- emailExists(email)
- createUser(id, name, email, password, role, phone?)
- authenticate(email, password)
- getAllUsers()
- updateUser(id, name?, phone?)
- deleteUser(id)

Behavior notes:
- email and name are normalized before save
- password stored as SHA-256 hash

## 9.2 HallRepository
Core methods:
- getHallById(id)
- getAllHalls()
- searchHalls(query?, minCapacity?, maxPrice?)
- createHall(...)
- updateHall(...)
- deleteHall(id)
- hasActiveBookings(hallId)

Behavior notes:
- active booking check excludes only cancelled status

## 9.3 ServiceRepository
Core methods:
- getServiceById(id)
- getAllServices()
- createService(...)
- updateService(...)
- deleteService(id)

## 9.4 BookingRepository
Core methods:
- getBookingById(id)
- getBookingsByUser(userId)
- getAllBookings()
- isHallAvailable(hallId, date, startHour, endHour)
- isHallAvailableExcluding(..., excludeBookingId?)
- getConflictingBookings(...)
- createBooking(...)
- updateBooking(bookingId, hallId?, date?, startHour?, endHour?, serviceIds?, finalPrice?)
- cancelBooking(bookingId, reason?)
- setBookingStatus(bookingId, status, reason?)
- deleteBooking(bookingId)
- logAudit(entityType, entityId, action, actorId, changes?)

Behavior notes:
- getBookingsByUser currently excludes cancelled bookings
- overlap checks consider pending + confirmed statuses
- updateBooking rejects cancelled booking updates
- updateBooking rejects past booking updates
- updateBooking enforces startHour < endHour

## 10. Business Rules (Must Preserve)

1) Conflict prevention:
- same hall + same date + overlapping time cannot coexist for pending/confirmed bookings
- overlap expression:
  NOT (existing_end <= new_start OR existing_start >= new_end)

2) Booking edit constraints:
- cannot edit cancelled bookings
- cannot edit past bookings
- start hour must be strictly less than end hour
- when editing, conflict checks must exclude current booking id

3) Hall deletion rule:
- hall cannot be deleted while non-cancelled bookings exist for that hall

4) Lifecycle states:
- new booking starts as pending
- admin/user actions can move status to confirmed/completed/cancelled under current UI logic

5) Audit intent:
- booking state changes and edits are intended to be logged in audit_logs

## 11. Security and Validation Layer

SecurityService:
- normalizeEmail: trim + lowercase
- normalizeName: trim + collapse internal spaces
- hashPassword: SHA-256
- verifyPassword
- isValidEmail regex check
- isStrongPassword policy:
  - length >= 8
  - uppercase + lowercase + digit + symbol

ValidationService includes validators for:
- email
- password
- name
- phone
- hall name
- capacity
- price

LoginRateLimiter:
- max attempts: 5
- lock duration: 5 minutes
- state held in-memory maps

SessionPolicy:
- inactivity timeout: 15 minutes

## 12. Implemented User Experience Scope

### 12.1 Guest
- browse/search halls
- go to login/register

### 12.2 Auth
- sign in/register mode
- demo user and demo admin access
- continue as guest
- validation and lockout behavior

### 12.3 User
- user home command center
- create booking flow with price breakdown
- view own bookings
- reschedule/edit own booking
- cancel own booking

### 12.4 Admin
- dashboard with metrics and tabs
- bookings tab:
  - mark pending/confirmed/completed/cancelled
  - edit/reschedule
  - delete record
  - search/filter/export capabilities are documented in flow docs
- halls tab:
  - add/edit/delete with active booking guard
- users tab:
  - view list of users and roles

## 13. State Management and Providers

Defined in app_state.dart:
- databaseServiceProvider
- userRepositoryProvider
- hallRepositoryProvider
- bookingRepositoryProvider
- serviceRepositoryProvider
- currentUserProvider
- hallsProvider
- servicesProvider
- searchHallsProvider(query)
- userBookingsProvider(userId)
- allBookingsProvider
- allUsersProvider
- checkDoubleBookingProvider((hallId, date, startHour, endHour))

## 14. Testing Status

Existing tests:
- test/security_service_test.dart
- test/login_rate_limiter_test.dart
- test/widget_test.dart

What is currently covered:
- password hashing/verification
- normalization behavior
- validation checks
- rate limiter lock/unlock behavior
- basic test harness boot

Gaps (high priority):
- booking_repository tests (conflicts, updates, cancellation)
- hall_repository tests (search filters, active booking guard)
- router access tests (role redirects)
- admin dashboard/widget flow tests

## 15. Build, Run, and Artifact Instructions

## 15.1 Standard Flutter commands
- flutter pub get
- flutter run -d emulator-5554
- flutter build apk --release
- flutter build appbundle --release

## 15.2 Verified Android workaround for this machine
From project android/ folder:
- set JAVA_HOME to C:\Program Files\Android\Android Studio1\jbr
- prepend JAVA_HOME\bin to PATH
- set GRADLE_USER_HOME to ..\\.gradle_user_home
- run gradlew app:assembleRelease / app:bundleRelease / app:installDebug

## 15.3 Output artifacts
- build/app/outputs/apk/release/app-release.apk
- build/app/outputs/flutter-apk/app-release.apk
- build/app/outputs/bundle/release/app-release.aab
- build/app/outputs/apk/debug/app-debug.apk

## 15.4 Portable backup package
- hallmaster_enterprise_V1.0.zip
- staging folder: _backup_v1_0
- zip includes release APK copy under releases/hallmaster_v1.0_android_release.apk

## 16. Evidence and Supporting Docs

Submission evidence:
- submission_screenshots/ (manual + generated screenshots)

Core docs:
- FINAL_SUBMISSION_REPORT_2026-04-19.md
- GROUP_WIREFRAME_BRIEF.md
- WIREFRAME_SCREEN_OUTLINE.md
- USECASE_FLOW_SITEMAP.md
- FLUTTER_STRUCTURE_BREAKDOWN.md
- PRESENTATION_SLIDES_DRAFT.md
- .impeccable.md

## 17. Known Caveats and Risk Notes

1) Android Java path mismatch on this Windows machine:
- Flutter path resolution points to an invalid jbr location
- Workaround is stable with explicit JAVA_HOME + Gradle wrapper

2) iOS build not validated in this environment:
- ios/ exists but requires macOS + Xcode for signing and IPA output

3) DB migration strategy:
- schema is version 1 with onCreate only
- no migration path implemented yet

4) Some documented capabilities may need verification in current UI code snapshot:
- for example CSV export visibility may depend on latest admin screen revision

## 18. Mini-Project Instruction Mapping

The implementation is aligned to mini-project style requirements:
- role-based mobile workflow
- full CRUD/service operations
- local persistent storage
- validation and security controls
- demonstrable evidence (screenshots and build outputs)
- report and architecture documentation

For explicit instruction content to hand over, use:
- MINIPROJECT_INSTRUCTION_DOCUMENT.md

## 19. Improvement Backlog for Claude (Prioritized)

P0 (stability + correctness)
- add repository unit tests for booking conflicts and update edge cases
- add migration scaffolding for schema version upgrades
- ensure all admin booking actions consistently write audit logs

P1 (product quality)
- implement or hard-verify CSV export in admin bookings tab
- improve empty/error states consistency across all tabs/screens
- add stronger date/time input constraints in booking dialogs

P2 (architecture)
- split feature modules into presentation/controllers/widgets for scale
- centralize pricing calculation in a dedicated service shared by user/admin edit flows
- formalize domain exceptions instead of generic Exception strings

P3 (UX and future scope)
- notifications and reminders
- backend API sync and multi-device data
- richer admin analytics and filtering presets

## 20. Handoff Execution Checklist for Claude

1. Read this file first.
2. Read MINIPROJECT_INSTRUCTION_DOCUMENT.md.
3. Read FINAL_SUBMISSION_REPORT_2026-04-19.md for baseline claims.
4. Verify route guards and booking conflict logic before any refactor.
5. Add automated tests for booking and routing paths.
6. Keep Android build workaround available until Java path is fixed.
7. Maintain submission evidence integrity (screenshots + report + artifacts).

---

If additional grading rubric files are later provided by lecturer, append them as a new section and map each rubric item to concrete code/screens/tests.
