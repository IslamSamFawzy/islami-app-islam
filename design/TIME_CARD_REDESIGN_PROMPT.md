# Prompt for Claude Code — Redesign the Prayer-Times card to match Figma exactly

> Paste everything below the line into Claude Code. This is a **focused, single-screen** task —
> only the Time tab's gold "Pray Time" card. Do not touch other screens.

---

## Context

**Islami** — Flutter, `flutter_bloc` + `get_it`. The Time tab already works; this is a **visual
redesign** of the gold prayer card so it matches the Figma frame pixel-for-pixel.

Files in scope:
- `lib/features/time/presentation/widgets/prayer_times_card.dart` (the whole card + `_ScallopClipper` + `_PrayerPill`)
- `lib/features/time/presentation/pages/time_view.dart` (only if spacing/padding around the card needs to change)

**Do NOT** touch the bloc, the repository, the caching, or the Azkar cards. Data and behaviour stay
exactly as they are — this is layout/shape/styling only.

**Figma frame:** open `https://www.figma.com/design/rYIdiZRmbIhvvoGbLPQ9Al/Islami?node-id=34333-629`
(the "Time Screen" frame, 430×932). Keep it open on a second monitor as your visual target.

> Note: the Figma MCP will likely error with "no edit access" on this file — that's expected, the file
> is view-only. Work from the reference image and the spec below, and verify by screenshotting the
> running app against the Figma frame in the browser.

## The gold "Pray Time" card — exact spec

**Overall**
- Gold/amber fill `#E2BE7F` (already `AppColors.primaryColor`), ~92% opacity is fine.
- Horizontal margin: **16px** each side (card is nearly full width).
- Bottom corners rounded ~**26px**. Soft shadow beneath (`elevation ~6`, black45).

**The wavy top — this is the part that's wrong today, get it right**

The current `_ScallopClipper` draws three humps with two deep valleys and it reads wrong. In the Figma
the top edge is a **single smooth, shallow wave**, not a spiky triple-scallop:

- The **center** of the top edge (under "Pray Time / Tuesday") rises into ONE broad, gentle dome.
- The edge sweeps **smoothly down** toward each side and the two top corners sit **lower** than the
  center dome (the date labels "16 Jul 2024" / "09 Muh 1446" sit in those lower corner shoulders).
- The curve is **continuous and soft** — no sharp V-valleys, no equal triple bumps. Think of a wide,
  low arch across the top, symmetric left/right.
- Amplitude is subtle: the center dome rises only ~**24–32px** above the corner shoulders, over the
  full card width. It should look like a calm wave, not a crown.

Rebuild `_ScallopClipper` as a single symmetric arch: rounded top corners, then one smooth
`quadraticBezier`/`cubicTo` sweeping up to a center apex and back down, then straight sides and rounded
bottom corners. Expose the apex height and corner radius as named constants so it's easy to tune.
Iterate the numbers against the Figma frame until the silhouette matches.

**Top content row** (dark text `#202020`, Janna, all bold)
- Left column: `16 Jul,` / `2024` — two lines, ~13–14px, centered in its column.
- Center column: `Pray Time` (~20px) on top, weekday `Tuesday` (~18px) below, centered.
- Right column: `09 Muh,` / `1446` — mirrors the left.
- The three columns share the top band; the center sits slightly higher (it's on the dome).

**Prayer carousel** (keep the existing infinite `carousel_slider` + pop-out behaviour — it's close)
- Chips are **dark**, rounded ~20, subtle top-lighter→bottom-darker brown gradient, thin faint border.
- The centered chip is **taller and pops up**; side chips are shorter and sit lower.
- Chip content, centered white: prayer **name** (small, ~12) · **time** (large — ~24 on the center chip,
  ~16 on the sides) · **AM/PM** (small, ~11). Match the Figma type sizes.
- Center chip time is clearly the biggest element; side chips are dimmer (`white70`).

**Next-pray row**
- Centered: `Next Pray - HH:MM` (dark, bold) + a **muted speaker icon** to its right (slash icon when
  muted, matching the Figma which shows the muted state). Keep the existing mute toggle wiring.
- Comfortable padding below it before the card's bottom edge.

## Ground rules

- Colours from `AppColors`, text from `Theme.of(context).textTheme` where it fits; no stray hex, Janna
  everywhere.
- Keep `PrayerTimesCard`'s public API (its constructor params) unchanged so `time_view.dart` and the
  bloc keep working.
- `flutter analyze` clean. One commit: `refactor(time): rebuild prayer card scallop + layout to match Figma`.

## Verify

1. `flutter run` on the device, open the Time tab, screenshot it.
2. Put your screenshot next to the Figma frame (node 34333-629) and compare **specifically**:
   the top wave silhouette, the three-column header, the pop-out chip sizes, and the next-pray row.
3. Adjust the scallop constants and type sizes until they line up, then re-screenshot to confirm.
4. Report what you changed and show the before/after of the card.
