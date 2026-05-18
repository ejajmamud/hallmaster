# HallMaster Enterprise
## Presentation Slide Content Draft

Date: 2026-04-19
Recommended duration: 8 to 12 minutes

## Slide 1: Title
- HallMaster Enterprise
- Mobile and Ubiquitous Computing Mini Project
- Team members + roles

Speaker note:
- Introduce project as an enterprise hall booking app with role-based operations.

## Slide 2: Problem Statement
- Manual hall booking causes conflicts and poor visibility.
- Users need faster booking.
- Admins need centralized control and reliable records.

Speaker note:
- Emphasize conflict prevention and operational governance.

## Slide 3: Solution Overview
- Flutter mobile app with Guest/User/Admin roles.
- Conflict-safe booking workflow.
- Admin dashboard for halls/bookings/users.
- Audit-ready operational actions.

## Slide 4: User Roles and Core Jobs
- Guest: discover halls, compare quickly.
- User: create/manage bookings.
- Admin: approve/update bookings, manage halls and users.

## Slide 5: System Architecture
- Flutter UI
- Riverpod state management
- go_router role-based routing
- SQLite local persistence
- Repository pattern for data logic

## Slide 6: Main User Flows
- Flow A: Guest -> Login -> User Home -> Create Booking -> My Bookings
- Flow B: My Bookings -> Reschedule/Edit -> Save
- Flow C: Admin Dashboard -> Booking Actions
- Flow D: Admin Dashboard -> Hall CRUD

## Slide 7: Key Business Rules
- Overlap protection for hall/date/time.
- Edit restrictions for cancelled/past bookings.
- Hall deletion blocked when active bookings exist.
- New booking status: pending approval.

## Slide 8: UI/UX Evolution (Phase 1)
- Design system and token consistency.
- Better form validation and feedback.
- Loading/empty/error state coverage.
- Cleaner role-specific navigation.

## Slide 9: Product Features (Phase 2)
- Pending workflow and status transitions.
- Booking filters and search.
- Admin analytics metrics.
- CSV export for bookings.

## Slide 10: Security and Quality (Phase 3)
- Strong password policy.
- Login rate limiting and lockout.
- Session inactivity timeout.
- Accessibility improvements.
- Security/validation test coverage.

## Slide 11: Demo Plan
- Guest browse and login.
- Create booking with pricing and pending state.
- User manages booking.
- Admin confirms and exports CSV.

## Slide 12: Verification and Deliverables
- APK/AAB generated.
- Emulator install verified.
- Tests passing.
- Wireframe and architecture docs prepared.

## Slide 13: Challenges and Solutions
- Android Java path issue workaround with Gradle + explicit JAVA_HOME.
- Reinstall strategy for stale runtime state.

## Slide 14: Future Enhancements
- Push notifications.
- Real backend and cloud sync.
- Approval matrix and role permissions expansion.

## Slide 15: Conclusion
- Enterprise-ready hall booking foundation completed.
- Reliable workflows + operations + security controls.
- Ready for iteration and team enhancement.
