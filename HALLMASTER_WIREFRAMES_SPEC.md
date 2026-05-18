# HallMaster Enterprise — Wireframe Specification
**Version:** 1.0
**Date:** 19 April 2026
**Scope:** Full wireframe system for a role-based hall booking app (Guest / User / Admin).
**Companion file:** `HALLMASTER_WIREFRAMES_VISUAL.html` — open in any browser to view every frame and state.

---

## 1 · Wireframe Strategy Summary

HallMaster Enterprise serves three audiences with one calm, enterprise-grade language. The design intent is operational, trustworthy, and low-friction. Wireframes are delivered at two fidelities: low-fi (structure only) for scanning hierarchy, and mid-fi (realistic content + spacing + status color) for reviewing interaction logic and business rules.

Guiding principles:
1. Role-correct routing is non-negotiable — every frame shows the correct permissions.
2. Conflict and permission rules surface inline — never silent.
3. Every screen ships with four states: default, loading, empty, error. Critical flows add a success state.
4. Mobile first, tablet parity, desktop efficiency (nav rail, inline actions).

---

## 2 · Figma File & Page Structure

| Page | Purpose |
| --- | --- |
| 00 · Cover & Guidelines | Title frame, change log, reviewer notes |
| 01 · Tokens & Styles | Color, type, spacing, radius, motion tokens |
| 02 · Components | Primitives and compounds with variants |
| 03 · Low-fi Wireframes | Boxes-only flow for structure review |
| 04 · Mid-fi Wireframes | Realistic content + status color |
| 05 · States | Loading, empty, error, success for every screen |
| 06 · Responsive | Tablet (768) and desktop (1280) variants |
| 07 · Flows & Prototype | Connectors and hotspots |
| 08 · Annotations | Sticky notes for business rules R1–R5 |

---

## 3 · Grid, Typography, and Tokens

**Spacing scale (4pt rhythm):** `s1 4 / s2 8 / s3 12 / s4 16 / s5 20 / s6 24 / s7 32 / s8 40 / s9 56`.

**Grid presets:**
- Compact (mobile, 360 px): 4 columns · 16 gutter · 16 margin.
- Medium (tablet, 768 px): 8 columns · 20 gutter · 24 margin.
- Expanded (desktop, 1280 px): 12 columns · 24 gutter · 32 margin.

**Typography (Inter):**
- Display 28 / 32 / 600
- Title 20 / 26 / 600
- Subtitle 16 / 22 / 600
- Body 14 / 20 / 400
- Label 12 / 16 / 600, +0.4 tracking, UPPERCASE
- Meta 11 / 14 / 500

**Color tokens:** brand `#0B4EA2`, brand-ink `#0C2753`, brand-surface `#E7EEF8`; status — success `#196B3D`, warning `#9A5A00`, danger `#B42318`, info `#254F91`; each paired with its tinted surface for WCAG AA contrast.

**Radius:** `xs 6 / sm 10 / md 14 / lg 20 / pill 999`.
**Motion:** `fast 120 / base 200 / slow 280 ms`, ease standard `cubic(0.4,0.0,0.2,1)`, ease emphasized `cubic(0.2,0,0,1)`.

---

## 4 · Component Specification

| Component | Purpose | Required slots | Variants / states | Responsive |
| --- | --- | --- | --- | --- |
| AppBar | Top-level identity + actions | title, leading, trailing actions | Default, with subtitle, with role pill | Collapses to compact on scroll |
| BottomNav | Primary routes on mobile | 3–4 items | Active / inactive / badge | Replaced by NavRail ≥ medium |
| NavRail | Persistent nav (tablet+) | logo, sections, account | Collapsed (72 px) / expanded (240 px) | Desktop only |
| HallCard | Hall summary row | thumb, name, meta, CTA | Default, selected, inactive, skeleton | Stacks on compact, 2-col on medium |
| BookingCard | Booking summary row | hall, date/time, status chip, actions | Per status, skeleton, disabled | 1-col compact, 2-col medium |
| StatusChip | Communicate state | icon, label | success / warning / danger / info / neutral / brand · sizes sm/md | Same across breakpoints |
| MetricTile | KPI summary | icon, number, label, intent | intents per status | Wrap grid 2→3 cols |
| Form TextField | Labeled input | label, value, helper, error | default / focus / error / disabled | Full-width |
| TimeSlot / Timeline | Slot picker | hour label, bar | free / selected / busy | Horizontal on mobile, grid on desktop |
| ConfirmDialog | Destructive or guarded confirm | title, body, primary, secondary | neutral / destructive / blocked | Fullscreen sheet ≤ 360 |
| Toast | Ephemeral feedback | icon, message, undo action | success / error / info | 6 s auto-dismiss |
| EmptyState | Zero-data placeholder | icon, title, body, CTA | default / first-time / filtered | Centered always |
| ErrorState | Data-load failure | icon, title, body, retry | offline / server / permission | Centered always |
| LoadingState | Skeleton set | header, cards ×3 | per surface | Matches real layout |

---

## 5 · Screen-by-Screen Specification

### 5.1 Guest Home (`/guest`)
- Structure: hero (CTA to sign in) → search → filter chips → halls list.
- Primary action: “View details” per card (mid-fi shows brand chip).
- Gate: any booking action redirects to `/login` via `router.dart` redirect.
- States: default, typing search with suggestions, filtered empty result.

### 5.2 Login / Register (`/login`)
- Segmented control toggles between Login and Register in one frame.
- Fields: email, password (eye toggle), register adds name, confirm, strength meter.
- States: default, field-level errors with inline text, banner for rate-limit (countdown visible), success routes by role.

### 5.3 User Home (`/user`)
- Hero greeting + two CTAs (New booking, My bookings).
- Metric tiles: Total, Pending, Approved — counts from `userBookingsProvider`.
- Recent bookings (top 3) with status chips + “View all”.
- States: default, loading skeletons, first-time empty, tablet nav-rail variant.

### 5.4 Create Booking (`/booking/new`)
Three steps with a progress bar and dot indicator.
- **Step 1 — Pick hall:** search + type filters; selected state has brand border and chip.
- **Step 2 — Date & time:** date picker + hour timeline with busy blocks; inline conflict banner with suggested free slots; invalid-range error when start ≥ end.
- **Step 3 — Review:** summary card + optional purpose + information banner (“Pending until admin approves”).
- Success screen: confetti-free, check illus + reference #, two CTAs.

### 5.5 My Bookings (`/booking/my`)
- Tabbed list: All, Pending, Past (counts live).
- Row: hall, date/time, status chip. Tap opens detail with Edit + Cancel.
- Edit is hidden for cancelled and past-completed (R3).
- States: default, empty, offline error, success toast with Undo.

### 5.6 Admin Dashboard (`/admin`)
Three tabs. State is persisted per tab.
- **Bookings:** queue with inline Approve / Reject; filter chips; KPI strip (Pending, Today, Conflicts).
- **Halls:** search + list with Active / Inactive pill; add via + icon; Delete is guarded (R4).
- **Users:** filter chips (All / Admins / Users / Inactive); per-row role badge; actions in overflow menu.
- Tablet/desktop variant promotes a NavRail and widens columns.

### 5.7 Dialogs (cross-cutting)
- User edit booking: reopens Step 2 controls inside a modal with a warning banner — edits reset status to Pending.
- Admin edit booking: shows user identity, decision dropdown, optional admin note; inline conflict result.
- Add / edit hall: name, capacity, type, amenities, status toggle.
- Delete booking: danger modal with named primary “Cancel booking”.
- Delete hall (blocked): warning modal with alternative “Deactivate hall”.

---

## 6 · Responsive Adaptation Plan

| Breakpoint | Navigation | Layout | Notable changes |
| --- | --- | --- | --- |
| Compact (<600) | Bottom nav + FAB | Single column, card stack | Timeline scrolls horizontally |
| Medium (600–839) | Collapsed NavRail (72) | 2-col booking / hall cards | Dialogs grow to 480 px |
| Expanded (840–1199) | Expanded NavRail (240) | 2-col + detail panel on booking list | Admin uses split view (list + detail) |
| Large (≥1200) | NavRail + toolbar | 12-col admin dashboard with charts zone | Keyboard shortcuts overlay available |

---

## 7 · State Matrix (Checklist)

| Screen | Default | Loading | Empty | Error | Success |
| --- | --- | --- | --- | --- | --- |
| Guest Home | ✓ | ✓ | ✓ (no results) | ✓ retry | n/a |
| Login / Register | ✓ | spinner on submit | n/a | field errors + rate-limit banner | route by role |
| User Home | ✓ | skeletons | first-time | data-load error card | n/a |
| Booking Step 1 | ✓ | skeletons | no halls | load error | selection chip |
| Booking Step 2 | ✓ | timeline shimmer | no busy | conflict + invalid-range | valid chip |
| Booking Step 3 | ✓ | submit spinner | n/a | submit failed | confirmation screen |
| My Bookings | ✓ | skeletons | no bookings | offline | cancel toast |
| Admin Bookings | ✓ | skeletons | queue clear | load error | approve / reject toast |
| Admin Halls | ✓ | skeletons | no halls | load error | saved toast |
| Admin Users | ✓ | skeletons | no users | load error | role-change toast |

---

## 8 · Business Rule Annotation Map (R1–R5)

| Rule | Where to annotate |
| --- | --- |
| R1 Conflict prevention (overlap) | Step 2 timeline + Step 3 review + Admin edit dialog |
| R2 Valid time range (start < end, ≥ 1h) | Step 2 fields |
| R3 Edit permissions (pending / approved-future only) | My Bookings detail + User edit dialog |
| R4 Hall deletion (blocked if active bookings) | Admin Halls list + Delete dialog |
| R5 Role-based routing | Cover page + every gated CTA |

Annotation format (Figma sticky): **`[RULE-ID] Short name`** then one-sentence behavior, then source (e.g. `router.dart:28`, `booking_repository.dart:hasConflict`).

---

## 9 · Figma Build Blueprint (Step-by-Step)

1. **Create pages** in order listed in §2.
2. **Set frame presets** for 360 / 768 / 1280. Apply the matching layout grid.
3. **Create color styles** from the token list. Name them `Brand/Primary`, `Status/Success/Surface`, `Text/Primary`, etc.
4. **Create text styles** from §3. Tighten letter-spacing on labels only.
5. **Build primitives** in `02 · Components` with Auto Layout. Use variants for state (default/focus/error/disabled) and intent (success/warning/danger/info/neutral/brand).
6. **Build compound components** (AppBar, BookingCard, ConfirmDialog, etc.) using the primitives — never bare shapes.
7. **Assemble screens** on pages 03 / 04. Use Auto Layout on all cards and sections. Bind text to styles and color to variables.
8. **Generate states** on page 05: duplicate default, apply skeleton / empty / error / success variant.
9. **Produce responsive set** on page 06 by resizing frames and swapping NavRail / BottomNav.
10. **Prototype** flows per §11. Connect hotspots, set transitions (`easeEmphasized`, 280 ms for sheets, 200 ms for tabs).
11. **Annotate** rules on page 08 sticky notes, linking to frames.

---

## 10 · Prototype Flow Map

- **Guest path:** Guest Home → Hall detail → Sign-in gate → Auth → User Home.
- **Booking path:** User Home → Step 1 → Step 2 → Step 3 → Success → My Bookings.
- **Cancel path:** My Bookings → Detail → Cancel confirm → Toast with Undo.
- **Admin queue:** Admin Bookings → Review modal → Approve/Reject → Toast.
- **Hall management:** Admin Halls → Add/Edit modal; Delete → blocked modal when active bookings exist → Deactivate alternative.

---

## 11 · UX Critique Layer

| Dimension | Score /10 | Notes |
| --- | --- | --- |
| Hierarchy | 9 | Hero + metric row dominant; cards calm and scannable. |
| Cognitive load | 8 | Max three primary actions per screen. Filters collapse to chips. |
| Discoverability | 8 | FAB on key screens, bottom nav for top-level routes. |
| Admin efficiency | 8 | Inline approve/reject avoids modal-per-row. |
| First-time friction | 8 | Guest path unblocked; conversion moment explicit. |

**Top 10 improvements (backlog):**
1. Calendar grid view on Step 2 for visual conflict scanning.
2. Saved searches for admin queue.
3. Batch-approve on tablet / desktop.
4. Export / print on Admin Bookings.
5. Hall photo gallery in guest view.
6. Notification center (badge on bell).
7. Tooltip on status chips explaining meaning.
8. Audit log tab inside admin edit dialog.
9. Keyboard shortcuts overlay (desktop).
10. Reduced-motion toggle in profile.

---

## 12 · Accessibility & Resilience Notes

- All interactive elements ≥ 44 × 44 px touch target.
- Status is conveyed with icon + text + color — never color alone.
- Focus rings: 2 px brand at 12 % opacity, 3 px halo.
- Dynamic type tested at 125 % — cards must not clip.
- Long strings truncate with trailing ellipsis + tooltip on hover (desktop).
- Error copy is plain and actionable (no “Oops!”).

---

## 13 · Final Approval Checklist

- [ ] All 6 routes covered with default + loading + empty + error states.
- [ ] All 5 dialogs covered with explicitly named primary / secondary actions.
- [ ] Business rules R1–R5 visible as sticky notes on relevant frames.
- [ ] Tokens applied (no raw hex in components).
- [ ] Mobile + tablet + desktop breakpoints produced.
- [ ] Prototype flows connected end-to-end.
- [ ] Accessibility: ≥ 44 px targets, status chips have icon + text, focus states visible.
- [ ] UX copy reviewed (no `Oops!`, no jargon, named destructive actions).
- [ ] Lecturer/client walk-through rehearsed against §10 flow map.
