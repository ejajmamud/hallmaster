# Hallmaster Enterprise: Complete User Journey & Workflows

This diagram visualizes all 20 user journey steps from SECTION B of the submission report.

```mermaid
graph TD
    Start([App Launch]) --> Guest["🔓 GUEST JOURNEY"]
    
    Guest --> S1["Step 1: Launch App<br/>/guest route<br/>Hero: 'Find a hall that fits your event'<br/>Search bar, filter chips, hall cards"]
    S1 --> S2["Step 2: Search Halls<br/>Tap search bar → keyboard opens<br/>Chips collapse, live suggestions"]
    S2 --> S3["Step 3: Sign In Redirect<br/>Tap 'Sign in to book'<br/>Route to /login"]
    
    S3 --> Auth["🔐 REGISTRATION & LOGIN"]
    Auth --> S4["Step 4: Register<br/>Full name, Email, Password<br/>Strength meter, Confirm password<br/>Tap Create account"]
    S4 --> S5["Step 5: Login<br/>Email + Password<br/>Route to /user or /admin"]
    S5 --> S6["Step 6: Rate-Limit Protection<br/>5 failed attempts in 5 min<br/>Login button disabled<br/>Countdown banner"]
    
    S5 -->|User Role| User["👤 USER BOOKING FLOW"]
    S5 -->|Admin Role| Admin["🛠️ ADMIN WORKFLOW"]
    
    User --> S7["Step 7: User Home /user<br/>Greeting, CTAs<br/>New booking, My bookings<br/>Metric tiles, Recent bookings"]
    S7 --> S8["Step 8: Create Booking - Step 1<br/>Filterable hall list<br/>Tap to select, SELECTED ✓ chip<br/>Continue button"]
    S8 --> S9["Step 9: Create Booking - Step 2<br/>Date picker (no past dates)<br/>Time range selection<br/>Day timeline with busy blocks<br/>Conflict detection, invalid range check"]
    S9 --> S10["Step 10: Create Booking - Step 3<br/>Review summary card<br/>Optional purpose field<br/>Submit request<br/>Success screen with reference #B-2093"]
    
    S10 --> S11["Step 11: My Bookings<br/>Tabs: All, Pending, Past<br/>Live counts per tab<br/>Tap row for detail panel"]
    S11 --> S12["Step 12: Edit Booking<br/>Pre-filled modal<br/>Modifying time re-runs conflict check<br/>Save resets status to Pending"]
    S11 --> S13["Step 13: Cancel Booking<br/>Destructive confirmation dialog<br/>Success toast with Undo (6 sec)"]
    
    Admin --> S14["Step 14: Admin Dashboard /admin<br/>Three tabs: Bookings, Halls, Users<br/>KPI strip: Pending, Today, Conflicts"]
    S14 --> S15["Step 15: Approve or Reject<br/>Pending bookings with inline buttons<br/>Tap → show toast confirmation"]
    S14 --> S16["Step 16: Manage Halls<br/>Halls tab, Add hall modal<br/>Name, capacity, type, amenities, active toggle<br/>Edit or delete existing"]
    S16 --> S17["Step 17: Blocked Deletion<br/>Delete with active bookings<br/>Guarded modal, Deactivate alternative"]
    S14 --> S18["Step 18: Manage Users<br/>Users tab with role badges<br/>Promote/demote, deactivate users"]
    
    User --> Edge["⚠️ ACCESSIBILITY & EDGE CASES"]
    Admin --> Edge
    
    Edge --> S19["Step 19: Offline Handling<br/>Network disabled<br/>Centred error card<br/>Try again button"]
    Edge --> S20["Step 20: Empty State<br/>Fresh user account<br/>First-time empty hero<br/>CTA to create first booking"]
    
    style Start fill:#FF1565D8,stroke:#000,color:#fff
    style Guest fill:#1565D8,stroke:#000,color:#fff
    style Auth fill:#0B4DB5,stroke:#000,color:#fff
    style User fill:#2E7D32,stroke:#000,color:#fff
    style Admin fill:#F57C00,stroke:#000,color:#fff
    style Edge fill:#7B1FA2,stroke:#000,color:#fff
```

## How to Use This Diagram

1. **View in VS Code**: The `.md` file displays the diagram directly in the preview panel
2. **Export to PNG/SVG**: 
   - Use [Mermaid Live Editor](https://mermaid.live) - copy/paste the code
   - VS Code Mermaid extension can export directly
3. **Share**: Include this file in your documentation or presentation

## Diagram Structure

| Section | Color | Steps | Purpose |
|---------|-------|-------|---------|
| Guest Journey | Blue | 1-3 | Public browsing & sign-in |
| Registration & Login | Dark Blue | 4-6 | Account creation & security |
| User Booking Flow | Green | 7-13 | Full booking lifecycle |
| Admin Workflow | Orange | 14-18 | Administrative controls |
| Accessibility & Edge Cases | Purple | 19-20 | Error & empty states |
