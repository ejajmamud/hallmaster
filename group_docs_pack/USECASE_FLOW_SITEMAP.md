# HallMaster Enterprise
## Use Cases, Flowchart, and Sitemap

Date: 2026-04-19

## 1. Use Case Overview
Actors:
- Guest
- Registered User
- Admin

Guest use cases:
- Browse halls
- Search halls
- Go to login/register

User use cases:
- Register/login
- Create booking
- View my bookings
- Edit/reschedule booking
- Cancel booking

Admin use cases:
- View dashboard metrics
- Manage booking statuses
- Edit/delete booking
- Manage halls (add/edit/delete)
- View users
- Export bookings CSV

## 2. Use Case Diagram (Mermaid)
```mermaid
flowchart LR
  Guest((Guest))
  User((User))
  Admin((Admin))

  UC1[Browse/Search Halls]
  UC2[Login/Register]
  UC3[Create Booking]
  UC4[View My Bookings]
  UC5[Reschedule/Cancel Booking]
  UC6[Manage Booking Status]
  UC7[Manage Halls]
  UC8[View Users]
  UC9[Export Bookings CSV]

  Guest --> UC1
  Guest --> UC2
  User --> UC2
  User --> UC3
  User --> UC4
  User --> UC5
  Admin --> UC6
  Admin --> UC7
  Admin --> UC8
  Admin --> UC9
```

## 3. Main Flowchart (Mermaid)
```mermaid
flowchart TD
  A[Open App] --> B{Role}
  B -->|Guest| C[Guest Home]
  B -->|User| D[User Home]
  B -->|Admin| E[Admin Dashboard]

  C --> F[Search and View Halls]
  F --> G[Go to Login/Register]
  G --> H[Authenticate]
  H --> D

  D --> I[Create Booking]
  I --> J{Conflict Check}
  J -->|Conflict| K[Show Conflict Error]
  J -->|No Conflict| L[Save as Pending]
  L --> M[My Bookings]

  M --> N[Reschedule or Cancel]
  N --> M

  E --> O[Bookings Tab]
  E --> P[Halls Tab]
  E --> Q[Users Tab]

  O --> R[Update Status/Edit/Delete]
  O --> S[Filter/Search/Export CSV]
  P --> T[Add/Edit/Delete Hall]
  Q --> U[View User List]
```

## 4. Sitemap (Mermaid)
```mermaid
flowchart LR
  Root[App Root]

  Root --> Guest[/guest]
  Root --> Login[/login]
  Root --> UserHome[/user]
  Root --> BookNew[/booking/new]
  Root --> MyBookings[/booking/my]
  Root --> Admin[/admin]

  Admin --> AdminBookings[Tab: Bookings]
  Admin --> AdminHalls[Tab: Halls]
  Admin --> AdminUsers[Tab: Users]

  MyBookings --> EditDialog[Dialog: Reschedule/Edit]
  AdminBookings --> AdminEditDialog[Dialog: Edit Booking]
  AdminHalls --> HallDialog[Dialog: Add/Edit Hall]
  AdminBookings --> DeleteDialog[Dialog: Delete Confirm]
  AdminHalls --> DeleteHallDialog[Dialog: Delete Confirm]
```

## 5. Rule Annotations for Diagrams
- New booking status = pending.
- Overlap protection checks pending + confirmed statuses.
- Hall deletion blocked if active bookings exist.
- Guest cannot access /user, /booking/new, /booking/my, or /admin.
