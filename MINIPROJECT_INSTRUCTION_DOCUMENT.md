# HallMaster Enterprise - Mini-Project Instruction Document

Date: 2026-04-19
Project: hallmaster_enterprise
Target: Mobile and Ubiquitous Computing mini-project
Primary delivery target: Android

## 1. Instruction Intent

Build a production-style hall booking mobile app that demonstrates:
- multi-role workflow
- strong CRUD and transaction handling
- conflict-safe scheduling
- persistent storage
- clear UX for core business operations

This instruction document is consolidated from the in-project planning artifacts:
- GROUP_WIREFRAME_BRIEF.md
- WIREFRAME_SCREEN_OUTLINE.md
- USECASE_FLOW_SITEMAP.md
- FLUTTER_STRUCTURE_BREAKDOWN.md
- PRESENTATION_SLIDES_DRAFT.md

## 2. Required Role Scope

Implement three role perspectives:

1) Guest
- browse halls
- search halls
- navigate to authentication

2) Registered User
- register/login
- create booking (hall/date/time/services)
- view own bookings
- reschedule/edit own bookings
- cancel own bookings

3) Admin
- view dashboard metrics
- manage booking statuses
- edit/delete bookings
- manage halls (add/edit/delete with safeguards)
- view users

## 3. Mandatory Screens

Core routes:
- /guest
- /login
- /user
- /booking/new
- /booking/my
- /admin

Screen requirements:

### 3.1 Guest Home
- searchable hall list
- hall card with name/location/capacity/base rate
- login/register CTA
- loading/empty/error states

### 3.2 Login/Register
- mode toggle
- register fields (name/email/password)
- login fields (email/password)
- inline validation
- feedback for success/error
- demo entry paths (user/admin/guest)

### 3.3 User Home
- command-center style landing
- action to create new booking
- action to manage existing bookings

### 3.4 Create Booking
- hall selector
- date picker
- start/end time selectors
- add-on service selection
- transparent pricing summary
- confirm action
- conflict and validation error handling

### 3.5 My Bookings
- list own bookings with status and price
- action menu for active bookings:
  - Reschedule/Edit
  - Cancel
- empty and error state handling

### 3.6 Admin Dashboard
- metrics strip/cards
- tabs: Bookings, Halls, Users

Bookings tab:
- status controls (pending/confirmed/completed/cancelled)
- edit/reschedule
- delete record
- search/filter/export support (as planned scope)

Halls tab:
- add hall
- edit hall
- delete hall with active-booking guard

Users tab:
- list users with role visibility

## 4. Business Rules (Non-Negotiable)

1) Overlap protection:
- prevent booking collision for same hall/date/time when overlapping pending/confirmed booking exists

2) Time validity:
- start hour must be before end hour

3) Edit restrictions:
- cancelled booking cannot be edited
- past booking cannot be edited
- edit conflict check must exclude the current booking id

4) Hall deletion safeguard:
- hall deletion blocked when non-cancelled bookings exist

5) Booking lifecycle:
- new booking enters pending status first

## 5. Data and Persistence Requirements

Use local SQLite database with at least these entities:
- users
- halls
- add_on_services
- bookings
- booking_services (junction)
- audit_logs

Minimum domain coverage:
- user profile and role
- hall pricing and capacity data
- booking date/time/status/price
- selected add-on services
- audit trail for booking operations

## 6. Architecture Requirements

Use layered architecture:
- App layer: routing and app shell
- Core layer: models, state providers, security, DB service
- Feature layer: role-specific screens
- Repository layer: data access and business constraints

Recommended patterns:
- Riverpod for state management
- go_router for role-guarded navigation
- repository pattern for data operations

## 7. Security and Validation Requirements

Include:
- password hashing before persistence
- email normalization and validation
- name/phone validation
- strong password policy
- login rate limiting / temporary lockout
- session inactivity policy (if applicable)

## 8. UX Quality Requirements

Must provide:
- clear action hierarchy on each screen
- explicit loading/empty/error/success states
- meaningful status chips for booking state
- destructive action confirmation dialogs
- mobile-safe tap targets

## 9. Testing and Quality Requirements

Minimum:
- security and validation tests
- login rate-limiter tests
- app boot/widget smoke test

Recommended additions:
- booking conflict tests
- hall deletion guard tests
- route access tests for roles
- admin flow widget tests

## 10. Submission Evidence Requirements

Deliverables should include:
- source code project
- final report
- screenshots of major flows
- release build artifact(s)

Expected evidence set:
- guest screen
- login/register
- user home
- create booking
- my bookings
- admin dashboard + tabs + dialogs

## 11. Build and Delivery Instructions

Android commands:
- flutter pub get
- flutter run -d emulator-5554
- flutter build apk --release
- flutter build appbundle --release

If Java path issue exists, use Gradle wrapper from android/ with explicit JAVA_HOME and isolated GRADLE_USER_HOME.

## 12. Wireframe and Flow Deliverables

Provide and keep updated:
- use case mapping (Guest/User/Admin)
- main flowchart from app entry to booking/admin actions
- sitemap matching route map
- screen-by-screen wireframe outline
- dialog wireframes for edit/delete/add flows

## 13. Presentation Requirements

Prepare concise project presentation covering:
- problem statement
- solution overview
- architecture
- business rules
- demo plan
- verification evidence
- challenges and future enhancements

## 14. Current Implementation Status Against Instructions

Implemented:
- role-based routes and access guard
- hall browse/search
- auth and role switching
- booking create/view/cancel/edit
- admin booking controls
- admin hall CRUD with guard
- user list view
- SQLite persistence and seed data
- security helpers and basic tests

Partially implemented or needs reconfirmation in latest UI snapshot:
- booking CSV export behavior in admin screen
- full regression pass across all edge states after latest UI redesign

## 15. Agent Handoff Guidance

For another AI agent:
1. Treat Sections 2-13 as project requirements.
2. Validate current code against each requirement before adding features.
3. Prioritize test coverage and booking correctness over visual refinements.
4. Keep role access and conflict logic unchanged unless requirement update is explicit.
5. Preserve submission evidence and artifact generation workflow.
