# HallMaster Enterprise
## Group Wireframe and Project Brief

Date: 2026-04-19
Prepared for: Group wireframe and UI planning
Project type: Mobile app mini project (Flutter)
Primary delivery target: Android

## 1. Project Summary
HallMaster Enterprise is an event hall booking application with three user roles:
- Guest: browse halls and search basic information
- User: create and manage own bookings
- Admin: manage halls, bookings, and users

The app is implemented with Flutter + Riverpod + go_router + SQLite.
The project emphasizes realistic business rules:
- conflict-safe booking
- role-based access control
- hall CRUD with booking constraints
- booking lifecycle status and audit logging

## 2. Vision and Goal
Build a reliable hall reservation system that is simple for users and operationally strong for admins.

Primary goals:
- reduce booking conflicts
- allow easy schedule changes
- provide admin control for operations
- keep clear booking and status records

## 3. Target Users and Core Jobs
### 3.1 Guest
Needs to:
- discover halls quickly
- compare location, capacity, and base pricing
- decide whether to register/login

### 3.2 Registered User
Needs to:
- create booking with selected hall, date, time, and add-on services
- view current bookings
- reschedule/edit bookings safely
- cancel own bookings

### 3.3 Admin
Needs to:
- view overall operations in one dashboard
- add/edit/delete halls
- update booking status
- reschedule/edit bookings
- delete booking records
- monitor registered users

## 4. Information Architecture
### Main routes
- /guest
- /login
- /user
- /admin
- /booking/new
- /booking/my

### Navigation by role
Guest:
- Browse
- Login

User:
- Home
- New Booking
- My Bookings

Admin:
- Dashboard
- Public

## 5. Functional Scope (Current Build)
### 5.1 Authentication and Access
- login and register
- demo login for user/admin
- guest mode
- route guards by role (guest cannot access user/admin pages)

### 5.2 Hall Catalog
- list halls with:
  - hall name
  - location
  - capacity
  - base price (RM per 4 hours)
- search by hall name or location

### 5.3 Booking Creation
- choose hall
- choose event date
- choose start and end hour
- choose add-on services
- auto price calculation:
  - hall subtotal by duration
  - service total
  - 6% tax
  - grand total
- conflict check before save

### 5.4 My Bookings (User)
- list user bookings
- see status and pricing
- actions on active booking:
  - reschedule/edit
  - cancel booking

### 5.5 Admin Dashboard
Tab 1: Bookings
- list all bookings
- mark confirmed/completed/cancelled
- reschedule/edit
- delete record

Tab 2: Halls
- add hall
- edit hall
- delete hall (blocked when active bookings exist)

Tab 3: Users
- list all users and roles

### 5.6 Data and Audit
- SQLite local database
- audit log events for booking actions (create/status/reschedule)

## 6. Core Business Rules
### Booking conflict prevention
A hall is unavailable if another confirmed booking overlaps on same date and time.

Overlap logic:
NOT (existing_end <= new_start OR existing_start >= new_end)

### Booking edit constraints
- cancelled booking cannot be edited
- past booking cannot be edited
- start hour must be before end hour
- edit conflict checks must exclude the current booking id

### Hall deletion rule
Hall cannot be deleted when active (non-cancelled) bookings exist.

## 7. Data Model Overview
### AppUser
- id
- name
- email
- role (guest/user/admin)
- phone

### Hall
- id
- name
- location
- capacity
- basePrice
- amenities

### AddOnService
- id
- name
- unitPrice

### Booking
- id
- userId
- hall
- date
- startHour
- endHour
- services
- status (pending/confirmed/cancelled/completed)
- finalPrice

## 8. Wireframe Requirements by Screen
Use this section directly for wireframe tasks.

### 8.1 Guest Home (/guest)
Goal:
- hall discovery and conversion to login

Required blocks:
- top app bar (title + role identity if available)
- search field with clear action
- hall card list
- hall card content:
  - name
  - location
  - capacity
  - base rate
  - CTA behavior: tap routes to login
- bottom CTA button: Login or Register to Book

States:
- loading halls
- empty search result
- data error + retry

### 8.2 Login/Register (/login)
Goal:
- fast access and low-friction onboarding

Required blocks:
- mode switch: sign in / register
- fields:
  - full name (register only)
  - email
  - password with show/hide
- inline validation and feedback messages
- primary action button
- secondary text action for mode switch
- demo access section:
  - Demo User
  - Demo Admin
  - Continue as Guest

States:
- submit loading
- validation error
- success feedback (registration)

### 8.3 User Home (/user)
Goal:
- clear command center for user actions

Required blocks:
- welcome + context card
- quick action card: Create New Booking
- quick action card: Manage Existing Bookings

### 8.4 Create Booking (/booking/new)
Goal:
- complete booking in one guided flow

Required blocks:
- booking details card:
  - hall selector
  - date selector
  - time range selectors
- services card:
  - add-on checkbox list
- pricing card:
  - subtotal
  - service total
  - tax
  - grand total
- final primary button: Confirm Booking

States:
- loading halls/services
- empty halls
- validation error
- conflict error
- success snackbar then redirect

### 8.5 My Bookings (/booking/my)
Goal:
- review and manage own bookings

Required blocks:
- booking list cards with:
  - hall name
  - date and time
  - status chip
  - final price
- action menu for active booking:
  - Reschedule/Edit
  - Cancel Booking

States:
- loading
- empty with CTA to create booking
- error + retry

### 8.6 Admin Dashboard (/admin)
Goal:
- operational control center

Required blocks:
- metrics row:
  - Halls count
  - Users count
  - Bookings count
- tab bar with 3 tabs

Tab Bookings:
- booking list cards
- action menu:
  - Reschedule/Edit
  - Mark Confirmed
  - Mark Completed
  - Cancel Booking
  - Delete Record

Tab Halls:
- add hall button
- hall list cards
- edit/delete actions

Tab Users:
- user list cards
- avatar, name, email, role

States for each tab:
- loading
- empty
- error + retry

## 9. Dialogs to Wireframe
### 9.1 User Edit Booking Dialog
Fields:
- Hall dropdown
- Date picker
- Start Hour
- End Hour
- Services summary text
- Updated total text
Actions:
- Cancel
- Save Changes

### 9.2 Admin Edit Booking Dialog
Same as user dialog, but triggered from admin booking actions.

### 9.3 Add/Edit Hall Dialog
Fields:
- Hall Name
- Location
- Capacity
- Base Price
- Amenities (comma separated)
Actions:
- Cancel
- Create/Update

### 9.4 Delete Confirm Dialogs
- Delete Hall
- Delete Booking
Simple risk warning + Cancel + Confirm

## 10. Key User Flows for Wireframe Mapping
### Flow A: Guest to User Booking
Guest Home -> Login/Register -> User Home -> Create Booking -> My Bookings

### Flow B: User Reschedule
My Bookings -> Reschedule/Edit Dialog -> Save -> Updated list

### Flow C: Admin Booking Control
Admin Dashboard -> Bookings Tab -> Action Menu -> Status update or Reschedule -> Refresh list

### Flow D: Admin Hall Management
Admin Dashboard -> Halls Tab -> Add/Edit/Delete Hall -> Refresh list

## 11. UX Quality Expectations for Wireframes
The wireframes should explicitly show:
- clear primary action per screen
- visible loading/empty/error states
- concise helper text for forms
- hierarchy between primary and secondary actions
- mobile-first spacing and touch targets
- role clarity (guest/user/admin)

## 12. Suggested Team Split
Teammate A:
- Guest + Login/Register wireframes
- auth states and microcopy

Teammate B:
- User Home + Create Booking + My Bookings
- user edit dialog and pricing view

Teammate C:
- Admin dashboard tabs + hall CRUD dialogs + booking action menu
- admin edit dialog and destructive confirms

You:
- unify component system
- review consistency across all wireframes
- finalize flow map and presentation storyboard

## 13. Submission Storyboard (for presentation)
1. Problem and objective
2. User roles and journey map
3. Wireframes per role
4. Business-rule overlays (conflict prevention, role guards)
5. Final UI highlights and demo sequence
6. Technical architecture summary

## 14. Technical Reference Files
- Routing and role redirects: lib/src/app/router.dart
- Domain models: lib/src/core/models.dart
- App state providers: lib/src/core/app_state.dart
- Booking business rules: lib/src/data/repositories/booking_repository.dart
- Hall business rules: lib/src/data/repositories/hall_repository.dart
- User/auth logic: lib/src/data/repositories/user_repository.dart
- Final implementation report: FINAL_SUBMISSION_REPORT_2026-04-19.md

## 15. Quick Wireframe Checklist
- All 6 primary screens drafted
- All 4 important dialogs drafted
- Loading/empty/error states drafted for each screen
- Primary user flows linked by arrows
- Role-specific navigation visible
- Form fields and validation hints included
- Status chips and action menus represented

This brief is intended to be directly usable in Figma/Miro for low to mid fidelity wireframe production.

## 16. AI-Ready Handoff Pack
Use this section when feeding AI design tools (ChatGPT, Claude, Gemini, Uizard, Galileo, Visily, Figma AI).

### 16.1 One-shot Product Context (paste as-is)
Project: HallMaster Enterprise
Type: Mobile-first Flutter app
Primary target: Android
Users: Guest, Registered User, Admin
Core domain: Event hall booking and operational management
Key value: Prevent booking conflicts while enabling fast booking and admin control

Must-have capabilities:
- Guest browse with search
- Login/register and role-based navigation
- User booking creation with pricing breakdown and conflict checks
- User booking management (reschedule/cancel)
- Admin dashboard with booking controls, hall CRUD, and user listing
- Loading, empty, error states on every major screen

Critical rules:
- No overlapping confirmed bookings for same hall/date/time
- Booking edit: not allowed for cancelled or past bookings
- Start hour must be earlier than end hour
- Hall deletion blocked when active bookings exist

### 16.2 Design Direction for AI
Visual style:
- Enterprise, clean, trustworthy, operational
- Light-first UI
- Material-3-aligned card layout
- Strong hierarchy and clear primary CTA per screen

Avoid:
- Gaming/neon style
- Overly decorative gradients/glassmorphism
- Dark-heavy visual language
- Ambiguous button hierarchy

### 16.3 Platform and Layout Constraints
- Mobile-first frame width: 360 to 412
- Also provide tablet adaptation notes (optional)
- Touch targets: minimum 44x44
- Keep bottom navigation role-aware
- Dialogs should be mobile modal sheets or centered dialogs depending on context

### 16.4 Required Deliverables from AI
AI output must include:
1. Low-fidelity wireframes for all 6 primary screens
2. Wireframes for 4 required dialogs
3. State variants (loading/empty/error/success) for each major screen
4. Flow map connecting all key journeys (A to D)
5. Component inventory list
6. Annotation notes for business-rule driven behavior

### 16.5 Screen Inventory (authoritative)
Primary screens:
1. Guest Home (/guest)
2. Login/Register (/login)
3. User Home (/user)
4. Create Booking (/booking/new)
5. My Bookings (/booking/my)
6. Admin Dashboard (/admin)

Dialogs:
1. User Edit Booking
2. Admin Edit Booking
3. Add/Edit Hall
4. Delete Confirm

### 16.6 Reusable Component Inventory
Core components AI should design once and reuse:
- App top bar
- Bottom navigation bar (role variants)
- Search field with clear action
- Info/metric card
- Booking card
- Hall card
- User card
- Status chip (pending/confirmed/cancelled/completed)
- Primary/secondary/destructive buttons
- Inline validation/error message
- Empty state panel
- Error state with retry action
- Loading indicator block
- Action menu (kebab or chip-triggered)

### 16.7 Suggested Token Baseline for Wireframes
Spacing scale: 4, 8, 12, 16, 20, 24
Corner radii: 10, 14, 20
Type hierarchy:
- H1 page title
- H2 section title
- Body regular
- Body small
- Label/button

Semantic colors (wireframe labels acceptable):
- Primary
- Surface
- Surface variant
- Success
- Warning
- Error

### 16.8 Content and Microcopy Pack
Use or adapt these labels in wireframes:

Global:
- Login or Register to Book
- Retry
- Save Changes
- Cancel
- Delete

Booking:
- Create Booking
- Select Hall
- Event Date
- Start Hour
- End Hour
- Add-on Services
- Subtotal
- Tax (6%)
- Grand Total
- Confirm Booking

Admin:
- Admin Dashboard
- Bookings
- Halls
- Users
- Add Hall
- Mark Confirmed
- Mark Completed
- Cancel Booking
- Delete Record

Validation and feedback examples:
- Start hour must be before end hour
- This time slot is already booked. Please select another time.
- Booking updated successfully
- No booking records yet

### 16.9 User Stories and Acceptance Criteria (for AI annotations)
US-01 Guest Browse:
- As a guest, I can search halls by name/location.
- AC: Search updates hall list and supports empty result state.

US-02 Auth and Access:
- As a user/admin, I can sign in and see role-specific pages.
- AC: Guest cannot directly access user/admin routes.

US-03 Create Booking:
- As a user, I can create booking with hall/date/time/services.
- AC: Final price breakdown is visible before confirmation.
- AC: Conflict check blocks overlapping confirmed bookings.

US-04 Manage My Booking:
- As a user, I can reschedule or cancel active bookings.
- AC: Cancelled/completed bookings show status and restricted actions.

US-05 Admin Booking Control:
- As admin, I can update status, reschedule, or delete booking records.
- AC: Booking list refreshes after each action.

US-06 Admin Hall CRUD:
- As admin, I can create/edit/delete halls.
- AC: Hall deletion is blocked when active bookings exist.

### 16.10 Screen State Matrix (AI must generate variants)
Guest Home:
- Loading, Data, Empty Search, Error

Login/Register:
- Idle, Submitting, Validation Error, Success Message

Create Booking:
- Loading Dependencies, Form Ready, Validation Error, Conflict Error, Success Redirect

My Bookings:
- Loading, Populated List, Empty, Error

Admin Dashboard Tabs:
- Loading, Populated, Empty, Error for each tab

Dialogs:
- Default, Validation Error, Submitting, Success Close

### 16.11 AI Prompt Template (copy and fill)
Prompt title: HallMaster Enterprise Wireframe Generation

Prompt body:
Design a mobile-first wireframe set for HallMaster Enterprise, an Android-first Flutter app with Guest, User, and Admin roles.

Use this functional scope:
- Guest: browse and search halls, then login/register CTA.
- User: login/register, user home, create booking, my bookings, edit/cancel booking.
- Admin: dashboard with Bookings/Halls/Users tabs, hall CRUD, booking status actions, booking edit dialog.

Enforce these rules:
- No overlapping confirmed bookings.
- Booking edit blocked for past/cancelled bookings.
- Hall deletion blocked when active bookings exist.

Generate:
1) Wireframes for all primary screens and required dialogs.
2) Loading/empty/error/success variants.
3) User flow map with labeled transitions.
4) Component library list reused across screens.
5) Notes/annotations where business rules affect UI behavior.

Style requirements:
- Enterprise, clear hierarchy, light-first, practical, not decorative.
- One obvious primary action per screen.
- Mobile spacing and touch-safe controls.

Output format:
- Section A: Screen list
- Section B: Wireframes by role
- Section C: State variants
- Section D: Flow map
- Section E: Component inventory
- Section F: Rule annotations

### 16.12 AI Quality Checklist
Before accepting AI output, verify:
- All 6 screens and 4 dialogs are present
- Role-specific navigation is correct
- Every screen includes state variants
- Pricing breakdown appears in booking flow
- Conflict and validation messaging is represented
- Admin actions include status changes and destructive confirmations
- Wireframes are consistent with mobile constraints

### 16.13 Ambiguities and Assumptions (declare in AI run)
If not specified by lecturer/group, AI should assume:
- Currency = RM
- Tax = 6%
- Booking duration uses hour blocks
- Default status on creation = pending (admin approval flow)
- Guest cannot create bookings

If team later changes assumptions, regenerate wireframes with updated rules.
