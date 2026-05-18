# HallMaster Enterprise
## Flutter Folder Structure and Responsibility Breakdown

Date: 2026-04-19

## 1. Current High-Level Structure
- lib/main.dart
- lib/src/app
- lib/src/core
- lib/src/features
- lib/src/data/repositories

## 2. App Layer
Path: lib/src/app

- app.dart
  - MaterialApp.router setup
  - global theme registration
- router.dart
  - route table
  - role-based redirect logic
- theme.dart
  - design tokens + component theming

## 3. Core Layer
Path: lib/src/core

- models.dart
  - domain models and enums
- app_state.dart
  - providers and shared state
- database.dart
  - SQLite setup and seed data
- security.dart
  - hash/validation/lockout/session policy
- widgets/
  - app_shell_scaffold.dart (shared shell/navigation/session timeout)
  - async_state_views.dart (loading/empty/error/inline messages)

## 4. Feature Layer
Path: lib/src/features

- guest/guest_home_page.dart
  - hall browse and search
- auth/login_page.dart
  - sign in/register/demo access
- user/user_home_page.dart
  - user command center
- booking/booking_flow_page.dart
  - booking creation and price breakdown
- booking/my_bookings_page.dart
  - user booking list and actions
- admin/admin_dashboard_page.dart
  - admin metrics, tabs, booking/hall/user management

## 5. Data Layer
Path: lib/src/data/repositories

- user_repository.dart
  - user CRUD and authentication
- hall_repository.dart
  - hall CRUD and search
- service_repository.dart
  - add-on services retrieval
- booking_repository.dart
  - booking CRUD, status transitions, overlap checks, audit log

## 6. Suggested Componentization for Team Work
Create reusable widgets under lib/src/features/shared/widgets:
- metric_card.dart
- booking_card.dart
- hall_card.dart
- status_chip.dart
- filter_panel.dart
- section_header.dart
- confirm_dialog.dart

## 7. Suggested Optional Refactor for Scaling
Introduce feature-first modules:
- lib/src/features/auth
- lib/src/features/booking
- lib/src/features/admin
- lib/src/features/guest

Inside each:
- presentation/
- widgets/
- controller/ (if needed)

## 8. Team Task Mapping
Teammate A:
- guest + auth features
- validation copy and edge states

Teammate B:
- booking feature screens and dialogs
- price breakdown and conflict UX

Teammate C:
- admin dashboard and analytics panels
- filter/export UX

Project lead:
- shared components
- routing/state integration
- consistency and final QA

## 9. Test Placement Plan
- test/security_service_test.dart
- test/login_rate_limiter_test.dart
- test/widget_test.dart

Recommended next test files:
- test/booking_repository_test.dart
- test/hall_repository_test.dart
- test/router_access_test.dart
- test/admin_dashboard_widget_test.dart
