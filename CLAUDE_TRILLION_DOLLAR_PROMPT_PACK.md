# Claude Trillion Dollar Prompt Pack

Date: 2026-04-19
Project: HallMaster Enterprise
Purpose: Hand over complete, high-fidelity instructions so Claude can improve UI/UX or produce premium wireframes with no context loss.

---

## Prompt 1: Full UI/UX Improvement Master Prompt (Implementation + Design + QA)

Copy everything below into Claude in one message:

You are a principal product designer + senior Flutter UI engineer + UX researcher working on a production-grade university mini-project app called HallMaster Enterprise.

Your mission is to redesign and harden UI/UX to flagship quality while preserving all existing business rules and architecture constraints.

### First: Mandatory Skill Import and Activation
Import and actively use these skills in this exact sequence:
1. frontend-design (master design direction, anti-AI-slop quality bar, context protocol)
2. critique (baseline audit and scoring before changes)
3. arrange (layout hierarchy, spacing rhythm, composition)
4. typeset (typography hierarchy and readability)
5. colorize (strategic color system and semantic contrast)
6. clarify (UX writing, labels, error message quality)
7. adapt (responsive behavior for mobile-first + tablet + desktop)
8. harden (edge states, overflow, i18n-safe behavior, error resilience)
9. normalize (token/system consistency across screens)
10. animate (purposeful motion and transition quality)
11. delight (tasteful personality moments without hurting usability)
12. polish (final micro-detail pass)
13. audit (final technical quality verification with severity scoring)

If any skill is unavailable, emulate its methodology and explicitly state fallback logic.

### Non-Negotiable Rules
- Do not break booking conflict logic.
- Do not break role-based routing and access control.
- Do not remove critical admin controls.
- Keep app functional and runnable.
- Minimize regressions by making incremental, testable changes.
- Do not introduce visual AI-template clichés.

### Product Context
HallMaster Enterprise is a role-based event hall booking app with:
- Guest: browse/search halls
- User: create/manage bookings
- Admin: manage bookings, halls, users

Brand intent:
- trustworthy
- operational
- premium
- clear, controlled, and confidence-building

### Required File Ingestion Order (Read Before Any Design Change)
Read all files in this exact order and summarize each in 5-10 bullets before proposing edits:
1. .impeccable.md
2. CLAUDE_HANDOFF_COMPLETE_SYSTEM_SPEC_V1.md
3. MINIPROJECT_INSTRUCTION_DOCUMENT.md
4. FINAL_SUBMISSION_REPORT_2026-04-19.md
5. README.md
6. GROUP_WIREFRAME_BRIEF.md
7. WIREFRAME_SCREEN_OUTLINE.md
8. USECASE_FLOW_SITEMAP.md
9. FLUTTER_STRUCTURE_BREAKDOWN.md
10. pubspec.yaml
11. lib/src/app/theme.dart
12. lib/src/app/router.dart
13. lib/src/core/app_state.dart
14. lib/src/core/models.dart
15. lib/src/core/security.dart
16. lib/src/core/widgets/app_shell_scaffold.dart
17. lib/src/features/guest/guest_home_page.dart
18. lib/src/features/auth/login_page.dart
19. lib/src/features/user/user_home_page.dart
20. lib/src/features/booking/booking_flow_page.dart
21. lib/src/features/booking/my_bookings_page.dart
22. lib/src/features/admin/admin_dashboard_page.dart
23. lib/src/data/repositories/user_repository.dart
24. lib/src/data/repositories/hall_repository.dart
25. lib/src/data/repositories/service_repository.dart
26. lib/src/data/repositories/booking_repository.dart
27. test/security_service_test.dart
28. test/login_rate_limiter_test.dart
29. test/widget_test.dart

### Execution Workflow (Must Follow)
Phase A: Baseline UX Critique
- Produce a ruthless critique report with:
  - design health score out of 40
  - top UX defects by severity P0-P3
  - anti-pattern detection list
  - cognitive load findings
  - accessibility risks
- No code changes yet in this phase.

Phase B: Redesign Strategy
- Define one clear visual direction for the app (not generic).
- Define token system:
  - spacing scale
  - typography scale
  - color semantic tokens
  - elevation/shadow/radius system
  - motion timing/easing system
- Provide before/after rationale for each major screen.

Phase C: Screen-by-Screen UI/UX Upgrade
Upgrade these screens in order:
1. Guest Home
2. Login/Register
3. User Home
4. Create Booking
5. My Bookings
6. Admin Dashboard (Bookings/Halls/Users tabs)

For each screen, improve:
- hierarchy
- readability
- interaction affordance
- state clarity (loading/empty/error/success)
- mobile ergonomics
- action confidence

Phase D: Hardening
- Ensure long text, overflow, empty datasets, and backend-like failures are handled gracefully.
- Ensure form feedback is clear and non-ambiguous.
- Ensure all destructive actions have proper confirmation UX.

Phase E: Motion and Polish
- Add purposeful transitions only where they improve comprehension.
- Ensure no jank.
- Ensure reduced-motion compatibility.

Phase F: Verification
- Run static analysis/tests where possible.
- Provide a regression checklist:
  - routing/role access still correct
  - booking conflict rules intact
  - admin actions intact
  - no critical UI overflow on common device sizes

### Deliverables Format
Return output in this structure:
1. Executive summary (what changed and why)
2. Baseline critique table
3. Design system tokens (final)
4. Screen-level change log
5. Accessibility and resilience improvements
6. Validation/test results
7. Remaining risks and recommended next tasks

### Quality Bar
Output should feel like premium enterprise travel-tech quality, not classroom default UI.
Every change must have a reason tied to usability, trust, or efficiency.

Start now.

---

## Prompt 2: Super Complete Figma Wireframe-Only Prompt (No Code)

Copy everything below into Claude in one message:

You are a lead UX architect and Figma specialist.
Your job is to produce a complete, professional wireframe system only (no code), for HallMaster Enterprise.

Important: Do not write implementation code, Flutter code, CSS, or component library code.
Deliver wireframe logic, structure, annotations, user flow, and Figma build instructions only.

### First: Mandatory Skill Import and Activation
Import and use these skills in this exact order:
1. frontend-design
2. critique
3. arrange
4. typeset
5. clarify
6. adapt
7. harden
8. onboard
9. normalize
10. polish

If a skill is unavailable, mirror its principles explicitly.

### Project Context
HallMaster Enterprise is a role-based hall booking app:
- Guest: browse and evaluate halls
- User: create, edit, cancel bookings
- Admin: manage bookings, halls, users

Design intent:
- enterprise professionalism
- operational clarity
- trustworthy booking decisions
- low cognitive load

### Required File Ingestion Order
Read and synthesize these files before creating wireframe output:
1. .impeccable.md
2. MINIPROJECT_INSTRUCTION_DOCUMENT.md
3. CLAUDE_HANDOFF_COMPLETE_SYSTEM_SPEC_V1.md
4. GROUP_WIREFRAME_BRIEF.md
5. WIREFRAME_SCREEN_OUTLINE.md
6. USECASE_FLOW_SITEMAP.md
7. FINAL_SUBMISSION_REPORT_2026-04-19.md
8. FLUTTER_STRUCTURE_BREAKDOWN.md

### Figma Deliverable Scope
Create a complete wireframe specification package with:
1. File architecture and page naming
2. Global grid and spacing system
3. Text style system and hierarchy
4. Wireframe component inventory
5. Full low-fidelity screen set
6. Mid-fidelity upgraded set
7. Interaction map and connector logic
8. Error/empty/loading/success states
9. Responsive variants (mobile/tablet/desktop)
10. Annotation layer for business rules

### Required Screens and States
Produce wireframes for all routes and key dialogs:
- Guest Home
- Login/Register
- User Home
- Create Booking
- My Bookings
- Admin Dashboard: Bookings tab, Halls tab, Users tab
- User Edit Booking dialog
- Admin Edit Booking dialog
- Add/Edit Hall dialog
- Delete confirmation dialogs

For each screen include:
- default state
- loading state
- empty state
- validation/error state
- success/confirmation state (where relevant)

### Business Rule Annotations (Must Be Visible in Figma Notes)
Annotate these directly on relevant frames:
- conflict prevention overlap rule
- start hour must be before end hour
- cancelled/past bookings cannot be edited
- hall cannot be deleted with active bookings
- role-based route restrictions

### Figma Build Blueprint (Must Output)
Provide an explicit, step-by-step Figma construction guide:
1. Create pages and sections
2. Set frame presets and breakpoints
3. Define layout grids and spacing tokens
4. Define text styles and naming
5. Build component primitives
6. Build compound components
7. Assemble screens with auto-layout rules
8. Add prototype links and hotspot logic
9. Add annotation badges and review checklist

### Wireframe Component Inventory (Must Output)
Specify component names, variants, and usage:
- App Bar
- Nav Tabs
- Hall Card
- Booking Card
- Status Chip
- Metrics Tile
- Search/Filter Bar
- Form Field
- Time Selector
- Date Picker Placeholder
- Modal Dialog Shell
- Confirmation Footer
- Error Banner
- Empty State Panel
- Loading Skeleton

For each component define:
- purpose
- required fields/content slots
- state variants
- responsive behavior

### UX Review Layer (Must Output)
After the wireframe spec, run a wireframe critique with:
- hierarchy score
- cognitive load score
- discoverability risks
- admin efficiency risks
- first-time user friction points

Then provide:
- top 10 wireframe improvements
- final approval checklist for lecturer/client presentation

### Output Format
Return in this structure:
1. Wireframe strategy summary
2. Figma file/page structure
3. Grid/typography/token system
4. Component specification table
5. Screen-by-screen wireframe spec
6. Prototype flow map
7. Rule annotation map
8. Responsive adaptation plan
9. UX critique and optimization pass
10. Final review checklist

Do not output code.
Only output Figma-ready wireframing instructions and documentation.

Start now.

---

## Fast Feed Script (How To Feed Claude Efficiently)

Use this exact sequence when chatting with Claude:

Step 1
- Paste Prompt 1 or Prompt 2 first.

Step 2
- Immediately attach and feed these files in order:
  - .impeccable.md
  - CLAUDE_HANDOFF_COMPLETE_SYSTEM_SPEC_V1.md
  - MINIPROJECT_INSTRUCTION_DOCUMENT.md
  - GROUP_WIREFRAME_BRIEF.md
  - WIREFRAME_SCREEN_OUTLINE.md
  - USECASE_FLOW_SITEMAP.md
  - FINAL_SUBMISSION_REPORT_2026-04-19.md
  - FLUTTER_STRUCTURE_BREAKDOWN.md

Step 3
- For UI/UX implementation prompt, additionally attach:
  - lib/src/app/theme.dart
  - lib/src/app/router.dart
  - lib/src/features/guest/guest_home_page.dart
  - lib/src/features/auth/login_page.dart
  - lib/src/features/user/user_home_page.dart
  - lib/src/features/booking/booking_flow_page.dart
  - lib/src/features/booking/my_bookings_page.dart
  - lib/src/features/admin/admin_dashboard_page.dart
  - lib/src/data/repositories/booking_repository.dart

Step 4
- Ask Claude to return:
  - execution plan
  - first batch of concrete edits (or wireframe package)
  - risk list and regression guardrails

Step 5
- Iterate by screen, not by random tweaks.

This yields the highest quality and lowest regression rate.