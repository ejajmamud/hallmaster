# HallMaster Enterprise — Phase A Baseline Critique + Phase B Redesign Strategy

**Author:** Principal product designer / senior Flutter UI engineer pass
**Date:** 2026-04-19
**Scope:** Flutter UI/UX redesign track (Prompt 1). No code changes in this phase.
**Preserves:** Business rules, role routing, booking conflict logic, admin CRUD, security/rate-limiting, test pass rate.

---

## 0. Skill Availability and Fallback Logic

The project brief asks for thirteen skills in sequence: frontend-design, critique, arrange, typeset, colorize, clarify, adapt, harden, normalize, animate, delight, polish, audit. None of those names are registered in this session. The `design:*` skills that are available (`design-critique`, `design-handoff`, `design-system`, `accessibility-review`, `user-research`, `research-synthesis`, `ux-copy`) are oriented around Figma URLs or screenshots and do not run over raw Flutter source.

Fallback applied: I am emulating each missing skill methodology inline in this document. Each section below is tagged with the skill it is emulating so the reviewer can trace coverage.

- `critique` → Section 2
- `arrange` → Section 3.2 layout hierarchy + per-screen composition notes
- `typeset` → Section 3.3 typography scale + Section 6 per-screen type calls
- `colorize` → Section 3.4 semantic color tokens + Section 2.3 palette-split finding
- `clarify` → Section 6 UX copy column
- `adapt` → Section 3.6 responsive rules
- `harden` → Section 2.5 + Section 6 edge-state column
- `normalize` → Section 3 token system
- `animate` → Section 3.5 motion tokens
- `delight` → Section 6 discipline column (what NOT to add)
- `polish` → Reserved for Phase E
- `audit` → Reserved for Phase F
- `frontend-design` → Section 3.1 visual direction (single north star)

---

## 1. Executive Summary

HallMaster Enterprise is functionally whole. All six mandatory routes exist, role-based redirects are active, the booking repository enforces conflict, start<end, past-immutability, cancellation-immutability, and hall-deletion guard correctly, the auth stack normalizes emails and rate-limits logins, and the test suite covers security + validation + rate limiter. The Android release pipeline is documented and working. That substrate is preserved as-is.

The UI layer is where value is leaking. It reads as "classroom-default Material 3 with enterprise cosplay" — three competing gradient accents, six differently-named chip variants for the same visual role, marketing-speak panel labels ("Smart booking planner", "Administration Control Center", "Operational Snapshot"), a decorative abstract circle bolted onto every page, and — most seriously — decorative quick-filter chips on Guest Home that look interactive but have no handler, plus a user cancel-booking action that bypasses confirmation entirely. These are not cosmetic defects; the first is a WCAG 4.1.2 name/role/value violation and the second violates a stated non-negotiable in `.impeccable.md` ("destructive action confirmation dialogs").

**Design health score: 18 / 40** — functional baseline with significant composition, token, and confidence-layer debt.

Phase B proposes a single disciplined visual direction (quiet municipal operations cockpit), a full token system (spacing, typography, color, radius, elevation, motion), and a surgical per-screen redesign plan that preserves every routing and business rule. The total Flutter code change is concentrated in `theme.dart` (replaced) + one new `tokens.dart` + screen-level rewrites. Repositories, security, models, and database are not touched.

---

## 2. Baseline UX Critique

### 2.1 Design Health Rubric (4 points each, 10 dimensions)

| Dimension | Score | Evidence |
|---|---|---|
| Visual direction & brand coherence | 2 / 4 | Light-first done, but mint-green accents in hero cards (`#F0F7F4`, `#EFF7F4`, `#F0F8F5`, `#EAF3F0`) fight the institutional-blue brand (`#0B4EA2`). Two different accent chromas across five hero blocks. |
| Typography hierarchy | 2 / 4 | Seven styles defined in `theme.dart` with good weight contrast, but built from `const TextTheme().copyWith(...)` (skips platform baseline), uses system default (Roboto/SF) which renders `FontWeight.w800` unevenly, no bundled font, no display tier, inconsistent caps/tracking for overlines. |
| Spacing rhythm | 1 / 4 | No spacing scale token. Raw literals 6, 8, 10, 11, 12, 14, 16, 18, 20, 22 scattered across six screens. No 4/8pt rhythm. Page padding, card padding, and inter-section gaps are eyeballed. |
| Color semantic system | 2 / 4 | `brand`, `danger`, `warning` tokens exist. `success` missing. Status chips in `my_bookings_page.dart:611-647` hardcode four pairs of hex without any token reference. Five "chip surface" greys invented ad-hoc (`#EAF0F9`, `#E9F0F8`, `#E8F1EE`, `#F3F7F5`, `#F3F7F6`). |
| Component consistency | 1 / 4 | Six chip variants (`_InfoPill`, `_QuickFilterChip`, `_HeroBadge`, `_StatPill`, `_DetailPill`, `_CountChip`) plus the Chip widget from ChipTheme — all doing the same visual job with slightly different paint recipes. |
| State transparency | 3 / 4 | `AppLoadingState`, `AppErrorState`, `AppEmptyState`, `AppInlineMessage` are well-built primitives. Used consistently. But loading is always a centered spinner — no skeletons, no progressive reveal. |
| Accessibility | 2 / 4 | Some `Semantics()` wraps in `app_shell_scaffold.dart`, most screens none. Guest quick-filter chips have no tap handler but look interactive (WCAG 4.1.2 failure). Input `fillColor: #F6F9FD` vs canvas `#F4F7FC` is ~1.01:1 — invisible field boundary without focus. No reduced-motion handling. |
| Responsive behavior | 2 / 4 | Login has a breakpoint at 980px. No other screen adapts beyond Wrap reflow. Admin dashboard metric cards are fixed-width (160/220) and look uneven on tablet. |
| Motion & delight | 1 / 4 | Zero motion tokens. All transitions are default Flutter. No durations, no curves, no reduced-motion respect, no purposeful micro-interactions. |
| Trust & confidence | 1 / 4 | User cancel booking has NO confirmation (`my_bookings_page.dart:459-488` — `cancelBooking()` fires on menu tap, success comes via snackbar). Hall delete confirmation text says "This cannot be undone" but never warns that active bookings will block the delete (that error appears only after confirm). Generic error messages (`'Failed to update booking: $e'` leaks raw exception text to user). |

**Total: 18 / 40.**

### 2.2 Defect Table (P0 → P3)

Severity key: P0 = ships a bug or violates a non-negotiable, P1 = credibility damage or task blocker, P2 = legibility/efficiency loss, P3 = polish gap.

| # | Severity | Location | Defect | Impact |
|---|---|---|---|---|
| D1 | **P0** | `my_bookings_page.dart:459-488` | User cancel booking fires immediately with no confirmation dialog. Only feedback is a success snackbar *after* the DB write. | Violates `.impeccable.md` "destructive action confirmation dialogs" and `MINIPROJECT_INSTRUCTION_DOCUMENT.md` "destructive action confirmation dialogs". Users lose a booking on a misclick. |
| D2 | **P0** | `guest_home_page.dart:62-77` | Quick filter chips ("Flexible dates", "Large capacity", "Near campus", "Best value") look interactive but have no `onTap`. | WCAG 4.1.2 name/role/value failure. Fakes functionality. |
| D3 | **P0** | `admin_dashboard_page.dart:278-324` | Hall delete confirmation fires `hasActiveBookings` check *after* the user clicks "Delete". Admin is told "cannot be undone", clicks confirm, gets an error snackbar. | Post-hoc blocking. Violates the project's own stated hall-deletion guard UX contract (should be a pre-flight warning, not an error). |
| D4 | P1 | `app_shell_scaffold.dart:178-190` | Abstract decorative circle (`AppTokens.brand.withOpacity(0.05)`, 240×240) rendered behind every route. | Violates `.impeccable.md` "no gimmicky effects" + `GROUP_WIREFRAME_BRIEF.md` "avoid overly decorative gradients/glassmorphism". |
| D5 | P1 | All hero panels | Three different greenish gradients (`#FDFEFE→#F0F7F4`, `#FEFFFE→#F0F8F5`, `#FDFEFE→#EFF7F4`) with no tokenization and no relationship to the institutional-blue brand. | Dual-chroma palette splits the brand. |
| D6 | P1 | `booking_flow_page.dart:298-368` | Conflict detection happens only on submit. No pre-flight indicator when the user changes hall/date/time. | Users confidently fill in a doomed slot. |
| D7 | P1 | `guest_home_page.dart:203-208` + `:221-236` | Two "sign in" primary actions on the same screen (View rates button + Sign In To Request Booking sticky), plus a third nav bar entry. | Violates `.impeccable.md` "one clear primary action per section". |
| D8 | P1 | `admin_dashboard_page.dart:67-113` | CSV export writes to `getApplicationDocumentsDirectory()` and announces file path via snackbar. User has no way to actually open the file on Android. | Feature appears broken in practice. |
| D9 | P1 | `booking_flow_page.dart:316-319` | Date validation uses `selectedDate.isBefore(DateTime.now())` — compares date+time, so booking "today" at 10:00 when it's currently 14:00 rejects with "Cannot book for past dates". | Rejects legitimate same-day bookings. |
| D10 | P2 | `my_bookings_page.dart:498-527` | Custom "Actions" pill (green container with gear icon) wraps a PopupMenuButton. Not a standard menu affordance. Screen readers may not announce correctly. | Affordance ambiguity + a11y regression. |
| D11 | P2 | `admin_dashboard_page.dart:599-674` | Three nested `AsyncValue.when` for halls → bookings → users. Each level blocks the next. If bookings load slow, users tab shows "Loading bookings" instead of users. | Cascading loading states misrepresent what's actually loading. |
| D12 | P2 | `booking_flow_page.dart` + `my_bookings_page.dart` edit dialog | Start hour 8-20, end hour 9-22, but no validator prevents picking start 20 + end 9 (caught later by `startHour >= endHour`). | Jarring double-correction. |
| D13 | P2 | `user_home_page.dart:259-306` | Metric tiles sized by `((width-52)/3).clamp(102, 160)` — on a 320-wide device they render at 102 wide with headline large value text, overflowing. | Overflow risk on compact screens. |
| D14 | P2 | `theme.dart:113-124` | `MaterialStateProperty` / `MaterialState` — M2 APIs in an M3 theme. Deprecated in Flutter 3.16+. | Future-Flutter breakage. |
| D15 | P2 | All screens | Generic error banners show raw exception strings (`'Failed to update booking: $e'`). | Leaks stack language to end users. |
| D16 | P2 | `my_bookings_page.dart` & admin dialog | Edit dialog does not call `isHallAvailableExcluding` before offering Save — user has to submit to learn there's a conflict, same as create. | Inconsistent with create flow. Wasted effort. |
| D17 | P2 | `user_home_page.dart:228-252` | Recent bookings row formats date as `${day}/${month}/${year}` with no `DateFormat`, no leading zero — looks different from the rest of the app which uses `DateFormat('dd MMM yyyy')`. | Inconsistent date rendering. |
| D18 | P3 | Everywhere | Tooltip saturation — every filled button with a visible text label also has a tooltip that restates the same text. | Noise, accessibility noise via duplicate announcements. |
| D19 | P3 | `app_shell_scaffold.dart:220-245` | NavigationBar for admin role has only two destinations ("Dashboard", "Public"). Two-item bottom nav is unusual and visually stranded. | Shell navigation affordance weak for admins. |
| D20 | P3 | Every marketing block | "Smart booking planner", "Administration Control Center", "Operational Snapshot", "Operations Workspace", "Your booking portfolio" — decorative business-speak titles without operational payload. | Violates `GROUP_WIREFRAME_BRIEF.md` "short operational labels". |
| D21 | P3 | `login_page.dart:380-444` | Split-view marketing panel at ≥980px lists "Role-aware access", "CSV export ready", "Audit logging" as feature pills. Filler that adds width without informing the sign-in decision. | Viewport waste on tablet/desktop. |
| D22 | P3 | `app_shell_scaffold.dart:86-103` | Eyebrow label ("Admin Workspace" / "User Workspace" / "Public Workspace") stacked above every app bar title. Constant, never changes per screen. | Visual competition with the actual screen title. |
| D23 | P3 | `booking_flow_page.dart:172-200` | Start/End hour as two separate DropdownButtonFormFields. No single time-range UI. | Below enterprise-cockpit expectations; inefficient. |
| D24 | P3 | `admin_dashboard_page.dart:625-653` | Metric cards use fixed widths (160 default, 220 for revenue) — on a 900-wide desktop the wrap is uneven. | Misaligned grid. |
| D25 | P3 | `login_page.dart:335-353` | "Sign In As Demo User" uses FilledButton (primary-weight), "Sign In As Demo Admin" uses OutlinedButton (secondary-weight). Arbitrary hierarchy between two demo role paths. | Implied preference between demo roles not earned. |

### 2.3 Anti-Pattern Detection

1. **Chromatically split palette.** Two accent families (institutional blue in the theme, mint-green in hero panels) never reconcile. Enterprise brand intent is "Trustworthy, Operational, Premium" — this reads "draft-mood-board".
2. **Six chip primitives.** `_InfoPill`, `_QuickFilterChip`, `_HeroBadge`, `_StatPill`, `_DetailPill`, `_CountChip` plus `Chip` plus `_StatusChip` — one design problem, seven solutions.
3. **Decorative circle.** 240×240 soft-blue circle bolted onto every page, breaks on small screens.
4. **Tooltip saturation.** Tooltip on every button including ones whose label is the same text. Accessibility noise.
5. **Generic AI-marketing phrasing.** "Smart", "Enterprise", "Operational", "Control Center", "Workspace" sprinkled without content.
6. **Role-based nav bar with 2 items** (Admin: Dashboard, Public) — bottom nav requires ≥3 to earn its position.
7. **Hard-coded hex literals** inside feature files — at least 22 unique hex values outside `theme.dart`.
8. **Non-functional affordances** (Guest quick-filter chips).
9. **Snackbar-only destructive feedback** (user cancel booking).
10. **Post-hoc validation** (admin hall delete confirms first, validates after).

### 2.4 Cognitive Load Findings

| Screen | Touchpoints in first viewport | Rating |
|---|---|---|
| Guest Home | Hero (HallMaster label + 2 badges + title + description + search + 1 CTA) + 4 filter chips + list header + n hall cards + sticky CTA = ~13 before scroll | **High, misleading** (4 fake filter chips amplify) |
| Login | Marketing panel (5 pills + 3 feature rows) + form title + subtitle + 2–3 fields + feedback + 2 buttons + mode switch + demo section (3 buttons) = ~17 | **High** |
| User Home | Hero + Operational Snapshot card + 3 metric tiles + 3 recent bookings + 2 action cards = ~14 | **Medium-high** |
| Create Booking | Hero + 3 cards (property/services/pricing) each with 3–5 controls + CTA = ~16 controls | **High, no progression affordance** |
| My Bookings | Portfolio header + 3 count chips + search + filter + clear + n booking cards = ~9+ per card | **Medium** |
| Admin Dashboard | 5 metric cards + Control Center bar + 3 tabs + per-tab filter stack (search + status + clear + export) + list = ~13 before data | **High** |

### 2.5 Accessibility Risks (WCAG 2.1 AA preview)

| # | Risk | Criterion |
|---|---|---|
| A1 | Guest quick-filter chips have no role and no handler. | 4.1.2 Name, Role, Value |
| A2 | Input field fillColor `#F6F9FD` on canvas `#F4F7FC` — contrast ratio ~1.02:1. | 1.4.11 Non-text Contrast (focusable UI boundary) |
| A3 | Custom "Actions" pill wrapping PopupMenuButton — not announced as menu trigger. | 4.1.2 Name, Role, Value |
| A4 | Status chip pending text `#9A5A00` on `#FFF3E5` — 4.87:1 — passes AA for ≥24px but chip text is 11px label, needs re-check under AAA if intended. | 1.4.3 Contrast (Minimum) |
| A5 | No `MediaQuery.disableAnimations` respect anywhere. | 2.3.3 Animation from Interactions |
| A6 | Tooltip duplicates label — screen readers announce twice. | 3.3.2 Labels or Instructions |
| A7 | NavigationBar label size 12 w500 — close to minimum. | 1.4.4 Resize text |
| A8 | Metric tiles have no `Semantics(label: '...')` — SR reads value and label separately with no relationship. | 1.3.1 Info and Relationships |
| A9 | Date picker inherits Flutter default — OK. |  |
| A10 | Color-only status not an issue — text is always present alongside color. |  |

---

## 3. Phase B — Redesign Strategy

### 3.1 Visual Direction (single north star)

**"Municipal operations cockpit."**

Think the booking cockpit of a well-run civic venue or a mid-market hotel property-management system. Calm neutral-stone canvas, a single disciplined institutional blue, one accent family per status, precision typography at a 4pt rhythm, shadows used sparingly to signal elevation, not depth theatre. No gradients on content surfaces. No mint-green. No abstract decorative shapes. No marketing phrases on operational cards.

Mood words: **controlled, deliberate, quietly expensive, audit-ready**.

What this replaces: the current "enterprise cosplay" look — three gradients, six chip variants, and decorative copy — which reads classroom-default despite real functional depth.

### 3.2 Layout Hierarchy Rules (skill: arrange)

1. **One primary action per section.** Section = hero, form group, or list header. Secondary actions use outlined or text variant.
2. **Page grid.** Mobile: 16px margins. Tablet ≥720px: 24px. Desktop ≥1024px: 40px with max content width 1200.
3. **Vertical rhythm.** 4pt base. Section stacks use 24px between section titles and content, 16px between cards, 12px intra-card. Never 6, 10, 11, 18, 22.
4. **Card radius discipline.** One radius per surface role: content cards `radius-md` (14), modals `radius-lg` (20), pills `radius-pill` (999), buttons `radius-md`. No ad-hoc `9`, `12`.
5. **Eyebrow discipline.** No eyebrow ("Admin Workspace" / "Operations Workspace") above screen titles. Role is already visible via the user chip in the app bar.

### 3.3 Typography Scale (skill: typeset)

Bundled font: **Inter** (OFL, bundle locally in `pubspec.yaml`). Tabular number feature on prices. Fallback: platform default.

| Token | Size / Line | Weight | Tracking | Use |
|---|---|---|---|---|
| display-lg | 32 / 40 | 700 | -0.5 | Hero numeric metrics |
| display-md | 28 / 36 | 700 | -0.4 | Dashboard overview |
| title-xl | 22 / 30 | 700 | -0.3 | Page title (app bar) |
| title-lg | 20 / 28 | 600 | -0.2 | Card section title |
| title-md | 16 / 22 | 600 | -0.1 | Card title |
| body-lg | 16 / 24 | 450 | 0 | Primary body |
| body-md | 14 / 22 | 450 | 0 | Secondary body |
| body-sm | 13 / 20 | 450 | 0 | Meta, captions |
| label-md | 13 / 16 | 600 | 0.1 | Buttons, chips |
| label-sm | 11 / 14 | 700 | 0.6 | Overline, status chip |
| mono-sm | 13 / 20 | 500 | 0 | Booking IDs, amounts (tabular) |

Drop `headlineLarge` at 34pt / w800 — too aggressive, hurts readability on small screens, reads "marketing banner" not "enterprise".

### 3.4 Color Semantic Tokens (skill: colorize)

Single brand chroma: institutional blue. One accent per status. Neutral-stone canvas. No greens in hero panels.

**Canvas & surface:**

| Token | Light |
|---|---|
| surface-canvas | `#F6F8FB` |
| surface-card | `#FFFFFF` |
| surface-raised | `#FFFFFF` (+shadow-sm) |
| surface-muted | `#EEF2F7` |
| surface-inverse | `#0F172A` |

**Border:**

| Token | Light |
|---|---|
| border-subtle | `#E5EAF2` |
| border-default | `#CFD6E2` |
| border-strong | `#9AA3B4` |

**Text:**

| Token | Light |
|---|---|
| text-primary | `#0F172A` |
| text-secondary | `#475569` |
| text-tertiary | `#64748B` |
| text-inverse | `#F8FAFC` |
| text-disabled | `#94A3B8` |

**Brand (institutional blue):**

| Token | Light |
|---|---|
| brand-50 | `#EEF4FF` |
| brand-100 | `#D9E4FC` |
| brand-200 | `#B8CBF8` |
| brand-300 | `#8CA9F0` |
| brand-400 | `#5D82E3` |
| brand-500 | `#355CD1` |
| brand-600 | `#1E40AF` ← primary |
| brand-700 | `#1A3790` |
| brand-800 | `#172D72` |

**Status families** (used for booking status chips, banners, inline messages):

| Status | Surface | Text / Icon | Usage |
|---|---|---|---|
| info | `#EEF4FF` | `#1E40AF` | informational banner, brand neutral |
| pending | `#FEF9E7` | `#B45309` | booking pending |
| success | `#ECFDF5` | `#047857` | booking confirmed |
| neutral | `#F1F5F9` | `#475569` | booking completed (past, archived tone) |
| danger | `#FEF2F2` | `#B91C1C` | booking cancelled, destructive |

All four booking statuses mapped to one family each. `BookingStatus.confirmed → success`, `pending → pending`, `cancelled → danger`, `completed → neutral`. Token-indexed, no hex literals in feature code.

### 3.5 Motion Tokens (skill: animate)

| Token | Value | Use |
|---|---|---|
| duration-xxs | 80 ms | micro state flips (hover, press) |
| duration-xs | 120 ms | chip toggle, check |
| duration-sm | 180 ms | button press, snackbar in/out |
| duration-md | 240 ms | route transitions, dialog enter |
| duration-lg | 360 ms | sheet slide, emphasized transitions |
| ease-standard | `Curves.easeInOutCubicEmphasized` | default |
| ease-decelerate | `Curves.easeOutCubic` | enter |
| ease-accelerate | `Curves.easeInCubic` | exit |

**Reduced-motion rule:** when `MediaQuery.disableAnimations` is true, all durations collapse to 0ms, fades replace slides. Implemented via a single `AppMotion.of(context).duration(...)` helper.

No other motion than: list item fade-in on first load, snackbar slide, dialog scale-fade, status chip color tween on change, progress indicators. Never decorative pulses.

### 3.6 Spacing Scale

4pt base. `space-1 = 4, space-2 = 8, space-3 = 12, space-4 = 16, space-5 = 20, space-6 = 24, space-7 = 28, space-8 = 32, space-10 = 40, space-12 = 48, space-16 = 64`. Only these values in layout code. All existing literals get mapped or rounded.

### 3.7 Radius Scale

`radius-xs = 6, radius-sm = 10, radius-md = 14, radius-lg = 20, radius-xl = 28, radius-pill = 999`. Buttons = `radius-md`. Cards = `radius-md`. Dialogs = `radius-lg`. Chips/pills = `radius-pill`.

### 3.8 Elevation / Shadow System

| Token | Recipe | Use |
|---|---|---|
| shadow-0 | none | resting cards on canvas |
| shadow-sm | `BoxShadow(blurRadius: 4, offset: (0,1), color: #0F172A @ 5%)` + `BoxShadow(blurRadius: 2, offset: (0,1), color: #0F172A @ 4%)` | raised card (focused/selected) |
| shadow-md | `blur: 12 offset: (0,4) 6% + blur: 4 offset: (0,2) 4%` | menus, dropdowns |
| shadow-lg | `blur: 32 offset: (0,16) 8% + blur: 12 offset: (0,4) 4%` | dialogs, sheets |

Cards on canvas use `shadow-0 + border-subtle`, not shadow. Only dialogs and menus get shadow.

### 3.9 Responsive Breakpoints (skill: adapt)

- **Compact** 0–599: single column, 16 margin, bottom nav, full-width primary CTAs.
- **Medium** 600–899: tablets, 24 margin, card grid 2-up where applicable, bottom nav retained.
- **Expanded** 900+: desktop/tablet landscape, 40 margin, nav rail or drawer, max content width 1200, admin dashboard reveals a right-side detail pane when a booking card is selected.

### 3.10 Component Tokens (derived)

| Component | Height | Radius | Notes |
|---|---|---|---|
| Button (default) | 44 | radius-md | min-tap target 48 via padding |
| Button (compact) | 36 | radius-md | chips, inline actions |
| Input | 52 | radius-md | bigger than current 48, more confident |
| Chip | 28 | radius-pill | single variant: `<Icon?> + Label + <Trailing?>` |
| Card | auto | radius-md | border, no shadow on canvas |
| Dialog | auto | radius-lg | shadow-lg, max-width 560 |

---

## 4. Before/After Rationale, Per Screen

### 4.1 Guest Home

**Before:** Hero with 3 CTAs competing for the one "sign in" intent, 4 decorative non-functional filter chips, hall card CTA that dead-ends at `/login`, sticky bottom button repeats the same CTA.

**After:**
- One primary CTA per section. Hero: "Sign In To Book" (primary). Each hall card: one tap surface that goes to `/login` + a clear "Sign in to view rates" inline affordance, not two buttons.
- Replace fake quick-filter chips with real working filters: capacity range, price ceiling, location — or remove them entirely for the mini-project scope (recommended: remove for MVP, annotate as backlog).
- Remove "Recommended" pseudo-badge (first-item-only).
- Hall card shows: name, location, capacity chip, price tier, amenity count (not amenity list which overflows).
- Skeleton loader replacing spinner for the hall list.

**Preserves:** `hallsProvider`, `searchHallsProvider`, guest role restriction, all navigation targets.

### 4.2 Login/Register

**Before:** Split ≥980px layout with a marketing panel that doesn't help the sign-in decision. Five competing actions (Sign In / Register toggle, Demo User primary, Demo Admin outlined, Continue As Guest text) plus implicit preference between demo roles.

**After:**
- Single column up to desktop. On desktop, keep 2-column but replace marketing filler with a lightweight helper: "What you get after sign in" (3 short bullets, no marketing pills).
- Primary action = Sign In / Register (one at a time based on mode).
- Collapse demo access to a single "Try a demo" card with two equal-weight links ("Sign in as demo user", "Sign in as demo admin"). No primary/secondary hierarchy between roles — both are equally demos.
- Add live rate-limit countdown (timer ticks each second) via `StreamBuilder`.
- Password strength indicator below the field while typing (emulates real auth forms).
- Error messaging: replace `e.toString()` leak with mapped messages ("We couldn't reach the account store. Try again.", etc.).

**Preserves:** `LoginRateLimiter`, `UserRepository.authenticate`, `emailExists`, `createUser`, validation.

### 4.3 User Home

**Before:** Two heroes of information (branded hero + "Operational Snapshot" card), three metric tiles that can overflow on tiny screens, three recent bookings duplicating the My Bookings page, two action cards that duplicate the hero CTAs, plus two bottom nav entries for the same actions = ~5 paths to "Create New Booking".

**After:**
- One hero with the user's first name, two equal-weight CTAs (Create Booking primary, Open My Bookings secondary).
- One metric row with four tiles (Upcoming, Pending, Confirmed, Completed). Tile sizing via `Wrap` with min width 140 and flexible growth — no overflow below 320px.
- One "Next booking" card showing the single upcoming booking with date, time, hall, status chip, and an inline reschedule/cancel menu.
- Remove "Operational Snapshot / Live" decorative band.
- Remove the duplicate action cards at the bottom.

**Preserves:** `currentUserProvider`, `userBookingsProvider`, role-based nav entries.

### 4.4 Create Booking

**Before:** Single long scroll, decorative hero titled "Smart booking planner", no step affordance, conflict detection only on submit, two separate start/end dropdowns, date comparison bug on same-day.

**After:**
- Three visually distinct steps on one page: **Venue** · **Schedule** · **Summary** — numbered, each with a clear accent border when active, muted when complete.
- Real-time conflict check via the existing `checkDoubleBookingProvider` (already defined in `app_state.dart:76-81`). Shows a pending banner "Checking availability…" during debounce, then green "Available" or red "Conflict: another event is booked from X to Y" — with the user seeing the result *before* submitting.
- Start/End time as one inline range control, with a chip-set of common blocks ("4-hour morning", "4-hour evening") + custom.
- Date comparison normalized to `DateUtils.dateOnly(selected).isBefore(DateUtils.dateOnly(now))` — same-day bookings allowed. Still checks that the start-hour-of-today is in the future.
- Sticky submit bar at the bottom showing the computed grand total + "Confirm Booking" primary action.
- Replace decorative hero with a thin bar: "New booking · pending on submit · can be rescheduled until event starts".

**Preserves:** `BookingRepository.createBooking`, `isHallAvailable`, service selection, 6% tax, pending default status, `logAudit`.

### 4.5 My Bookings

**Before:** Search + status + clear + count chips + portfolio hero + cards with a custom "Actions" pill, no confirmation on cancel, no grouping.

**After:**
- Group bookings into **Upcoming** (pending+confirmed, date ≥ today), **Past** (completed, date < today), **Cancelled** — three segmented groups, each collapsible. Matches how users mentally model their list.
- Standard menu affordance: `IconButton(Icons.more_vert)` — not a custom pill.
- **Cancel confirmation dialog** with three elements: booking summary, "This cannot be undone", and typed-or-toggle confirmation. Success snackbar comes after DB write, as today.
- Edit dialog adds a live conflict preview (same machinery as create) + shows only fields that matter.
- Single search bar + single status filter dropdown. Remove count chips (stats live on User Home now).
- Each card: hall name + date/time + status chip (token-indexed) + price + menu — in a consistent row layout with 3-column breakpoint on tablet.

**Preserves:** `cancelBooking`, `updateBooking`, all edit-constraint logic (cancelled+past immutability is enforced in repository layer regardless of UI).

### 4.6 Admin Dashboard

**Before:** Triple-nested AsyncValue pyramid, 5 metric cards of uneven widths, "Administration Control Center" label, post-hoc hall delete validation, CSV export to an inaccessible path, status change menu mixes destructive with non-destructive items.

**After:**
- Flatten AsyncValue pyramid into a single `ref.watch` combinator that returns `(halls, bookings, users)` — each section renders its own loading/error state independently.
- Metric strip: 5 tiles, `Wrap` with flexible grow, each 200px min width, uniform height 108. No "Revenue" getting special width.
- Replace "Administration Control Center" with a neutral section header: "Overview" (body-md secondary) + a right-aligned last-refreshed timestamp + Refresh button.
- Tabs keep the 3-tab structure (Bookings · Halls · Users). Bookings tab: search + status + clear + export arranged as a filter shelf pinned below the tab bar.
- **Hall delete:** do the `hasActiveBookings` check BEFORE showing the confirmation dialog. If active bookings exist, show a different dialog: "Cannot delete · 3 active bookings" with a link "Review bookings" that filters the bookings tab by that hall.
- **Booking menu:** split the PopupMenuItem list into two groups with a PopupMenuDivider — "Status" (Pending, Confirmed, Completed) at the top, "Risk" (Cancel, Delete) at the bottom with danger-600 text color.
- **CSV export:** after write, show a persistent banner (not just snackbar) with "Export complete · Open folder · Share" actions. If the sandboxed path can't be opened (Android scoped storage), include a copy-path chip.
- **Users tab:** keep thin for MVP but add a role filter dropdown and a "Promote/demote" action menu per row — gated behind the admin role by the existing router guard.

**Preserves:** `hallRepositoryProvider.hasActiveBookings`, `bookingRepositoryProvider.setBookingStatus`, `deleteBooking`, `deleteHall`, all admin audit logs, role-based routing, CSV export path logic (we wrap, don't remove).

---

## 5. Proposed Phase C Execution Order (pending approval)

One screen at a time, each with a diff preview, each passing `flutter analyze` and the existing tests locally.

1. **Foundation** — introduce `lib/src/app/tokens.dart` (spacing, radius, elevation, motion, breakpoints), rebuild `theme.dart` around it, bundle Inter in `pubspec.yaml` + `assets/fonts/Inter-*.ttf`. Update `app_shell_scaffold.dart` to remove the decorative circle and the gradient; introduce `AppMotion` and `AppBreakpoints` helpers. Migrate `AppLoadingState` / `AppErrorState` / `AppEmptyState` / `AppInlineMessage` to token references.
2. **Guest Home** — restructure, remove fake filter chips, unify hall card, skeleton loader.
3. **Login/Register** — consolidate demo access, live rate-limit countdown, strength indicator, cleaner two-column at wide.
4. **User Home** — collapse duplication, single hero + metric row + next-booking card.
5. **Create Booking** — step-structured, real-time conflict check via existing provider, sticky submit bar, same-day bug fix.
6. **My Bookings** — grouped list, standard menu, cancel-confirmation dialog, live edit conflict preview.
7. **Admin Dashboard** — flatten AsyncValue, pre-flight hall delete check, split menu, export banner, responsive metric strip.
8. **Polish & motion pass** — status chip color tween, list enter fade (respect reduced-motion), dialog scale-fade.
9. **Verification** — `flutter analyze`, all existing tests, run `flutter test` on widget_test scaffold, take screenshots into `submission_screenshots/` for the final submission report.

Each step is independent and revertable.

---

## 6. Regression Guardrails

Before merging any Phase C screen:

1. `BookingRepository.isHallAvailable` and `isHallAvailableExcluding` signatures and behaviors untouched.
2. `GoRouter.redirect` rules in `router.dart` preserve: `/admin` → `/login` if not admin, `/user` | `/booking/new` | `/booking/my` → `/login` if guest.
3. `cancelBooking`, `setBookingStatus`, `deleteBooking`, `deleteHall`, `hasActiveBookings` not modified — only UI wrappers are changed.
4. `logAudit` is called at the same call sites with the same action strings (`CREATED`, `RESCHEDULED_BY_USER`, `RESCHEDULED_BY_ADMIN`, `STATUS_*`).
5. `SecurityService` + `ValidationService` + `LoginRateLimiter` not modified — only UI timer display is added.
6. `pubspec.yaml` changes: add Inter asset entries. No new runtime packages except (optional) `flutter_animate` if we want polished list fades — I recommend doing motion with `AnimatedSwitcher` + `AnimatedOpacity` to keep dependencies lean. To be decided during Phase E.
7. Existing tests (`security_service_test.dart`, `login_rate_limiter_test.dart`, `widget_test.dart`) pass unchanged.
8. No new provider names; existing providers keep their `FutureProvider.family` contracts.
9. Android release build command unchanged.

---

## 7. Clarifying Questions Before Phase C Starts

1. **Quick filter chips on Guest Home** — delete for MVP, or wire to real filters (capacity/price/location)? Recommended: delete (annotate as backlog P1).
2. **Decorative abstract circle** behind every page — confirm removal?
3. **Dark mode** — in scope for this submission or defer? Recommended: defer. Token system is dark-mode-ready.
4. **Font family** — Inter bundled confirmed. Also acceptable: Manrope, IBM Plex Sans, or Geist. Inter has the widest neutral readability.
5. **"Operational Snapshot / Live" card on User Home** — delete or re-purpose? Recommended: delete; it carries zero operational payload.
6. **Custom "Actions" pill** on My Bookings — replace with standard `IconButton(Icons.more_vert)` — confirm?
7. **User cancel booking confirmation** — plain AlertDialog with "Cancel" / "Keep booking", or stronger (type-to-confirm)? Recommended: plain dialog, danger-600 on the destructive button.
8. **CSV export** — keep current behavior and just improve feedback, or invest in a `share_plus` dependency to trigger the Android share sheet? Recommended: share sheet (single-package win, better UX).
9. **Admin "Users" tab** — thin for MVP or add promote/demote? Recommended: thin now, promote/demote is a follow-up.

---

## 8. What This Document Is Not Yet

- Not Phase C code. No Flutter files have been edited.
- Not a Figma wireframe pack. That's Prompt 2, a separate track.
- Not a dark-mode spec. Dark mode is opt-in future work.
- Not a full accessibility audit against every WCAG criterion. The audit in §2.5 is the targeted preview; the full audit runs in Phase F against the implemented redesign.

---

## 9. Awaiting Approval To Proceed

Once you confirm:
- Phase A critique accuracy (score, defect severity, anti-pattern list).
- Phase B token system (visual direction, scales, semantics).
- Clarifying-question answers (§7).
- Green light on the Phase C execution order (§5).

…I will start at step 1 (Foundation — tokens + theme rebuild + shell cleanup), deliver the diff, and pause again before moving to Guest Home.

— end of Phase A + B deliverable —
