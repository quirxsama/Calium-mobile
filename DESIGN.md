# Calium · Solid UI

Native Android/Flutter, task-oriented anime discovery and watching. Keep the existing
OLED charcoal, rose/crimson, amber rating and green completion palette. Retain
Plus Jakarta Sans headlines and Inter body text. Strength comes from hierarchy,
image scale, spacing and solid tonal surfaces; avoid extra glows and decorative blur.

- Compact window: bottom navigation. From 600 dp: scrollable navigation rail;
  extended labels from 1200 dp. Decisions use window constraints, not device models.
- Content width capped at 1400 dp; reading/settings/profile surfaces narrower.
- Home: image-led feature with a visible action, controlled title measure, accessible
  manual paging, readable poster titles and consistent section spacing.
- Detail: wide banner with larger poster/title; at expanded widths overview and
  episode browser sit side by side. Compact layouts stack and retain every action.
- Grids derive columns and card height from actual width and text scaling.
- Native buttons, chips and sheets; 48 dp touch targets, visible keyboard focus,
  safe areas, scrollable large-text content, system Remove animations respected.
- Verify at 360×800, 800×1280 and 1280×800; include 2× text and narrow split view.

Workspace: `.worktrees/solid-responsive`, branch `ui/solid-responsive`.
Pre-UI checkpoint: `ddabb1f4be118eec22d50ac3050400a3c7ea296c` (Git stash).
The original main workspace retains the pre-UI code and existing reliability work.
