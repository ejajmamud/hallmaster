# HallMaster Enterprise
## Wireframe Screen-by-Screen Outline

Date: 2026-04-19

## 1. Guest Home
Purpose:
- Help new users discover halls and convert to login/register.

Layout blocks:
- App bar: title + role indicator (Guest)
- Search input with clear icon
- Hall cards list
- Bottom sticky CTA: Login or Register to Book

Card content:
- Hall name
- Location
- Capacity
- Base rate per 4 hours
- Arrow/CTA affordance

States:
- Loading
- Empty search result
- Error with retry

## 2. Login/Register
Purpose:
- Fast, low-friction authentication and onboarding.

Layout blocks:
- Auth mode title (Sign In/Register)
- Name field (register mode only)
- Email field
- Password field + show/hide toggle
- Inline validation/error block
- Primary submit button
- Mode-switch text button
- Demo access section:
  - Demo User
  - Demo Admin
  - Continue as Guest

States:
- Idle
- Submitting
- Validation error
- Success feedback
- Rate-limit/lockout message

## 3. User Home
Purpose:
- Act as user command center.

Layout blocks:
- Welcome/context card
- Quick action card: Create New Booking
- Quick action card: Manage Existing Bookings

States:
- Standard
- Optional empty/maintenance state card

## 4. Create Booking
Purpose:
- Complete booking creation with pricing transparency.

Layout blocks:
- Booking details card:
  - Hall selector
  - Date picker
  - Start/End hour selectors
- Add-on services card (checkbox list)
- Pricing summary card:
  - Subtotal
  - Services
  - Tax 6%
  - Grand Total
- Primary action button: Confirm Booking

Rule hints (annotate in wireframe):
- No overlapping confirmed/pending slot
- Start hour < End hour
- Booking submission enters pending approval

States:
- Loading dependencies
- Empty halls
- Validation error
- Conflict error
- Success snackbar + redirect

## 5. My Bookings
Purpose:
- Allow users to review and act on their bookings.

Layout blocks:
- Search + status filter panel
- Booking list cards:
  - Hall name
  - Date/time
  - Status chip
  - Price
  - Action menu for active booking

Action menu (active booking):
- Reschedule / Edit
- Cancel Booking

States:
- Loading
- Empty bookings with CTA
- Filtered empty
- Error with retry

## 6. Admin Dashboard
Purpose:
- Centralized operational management.

Top section:
- Metrics cards:
  - Halls
  - Users
  - Bookings
  - Pending Approval
  - Confirmed Revenue

Main section:
- Tab bar: Bookings, Halls, Users

### 6A. Admin Tab: Bookings
Blocks:
- Search + status filter panel
- Clear filter button
- Export CSV button
- Booking cards list with action menu

Action menu:
- Reschedule / Edit
- Mark Pending
- Mark Confirmed
- Mark Completed
- Cancel Booking
- Delete Record

### 6B. Admin Tab: Halls
Blocks:
- Add Hall button
- Hall cards list
- Edit/Delete hall actions

### 6C. Admin Tab: Users
Blocks:
- User cards list
- Name, email, role

States (per tab):
- Loading
- Empty
- Error with retry

## 7. Required Dialogs
1. User Edit Booking
- Hall, date, start/end, services summary, updated total
- Cancel / Save Changes

2. Admin Edit Booking
- Same structure as user edit with admin action context

3. Add/Edit Hall
- Hall name, location, capacity, base price, amenities
- Cancel / Create or Update

4. Delete Confirmation
- Delete Hall
- Delete Booking
- Clear warning + safe cancel + confirm action

## 8. Visual Priority Notes
- One primary action per screen
- Use semantic chips for status
- Keep destructive actions visually distinct
- Ensure touch targets are mobile-safe
- Keep labels short and operational
