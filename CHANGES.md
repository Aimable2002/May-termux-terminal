# CHANGES.md — Exactly What Was Modified vs. Original Termux

This file exists so there's zero ambiguity about what's stock Termux and
what was written/changed. Every line below was confirmed by diffing this
project against a fresh, untouched clone of
`termux-play-store/termux-apps` — nothing here is guessed or approximate.

## Files modified inside `android/termux-apps/` (forked repo)

Only **4 files** were touched in the entire forked Android repo (which
contains 1,470+ files total). Everything else is 100% untouched, stock
upstream code.

### 1. `termux-app/src/main/res/values/strings.xml`
- Changed `application_name` from `"Termux"` to `"MAY"`
- This is the app's display name shown under the icon and in the app list

### 2. `termux-app/src/main/res/values/colors.xml`
- Added two new color resources (nothing existing was removed or changed):
  - `may_icon_background` = `#0B1220` (dark navy)
  - `may_accent` = `#34D399` (mint/emerald green)

### 3. `termux-app/src/main/res/drawable/ic_foreground.xml`
- This is the actual launcher icon shape — a vector drawable (not a raster
  image), so it's real, editable code, not a placeholder
- Original: a white `>_` terminal-prompt mark
- Changed: same exact shape/geometry, recolored from white to the new
  `may_accent` green
- **Because Termux's own repo uses symlinks**, this same file is shared by
  `termux-style/` and `termux-tasker/` — those two companion apps'
  icons updated automatically as a result, not because they were
  separately edited (confirmed via `stat`/inode check, not assumed)

### 4. `termux-app/src/main/res/drawable/ic_shortcut_icon.xml`
- The circular badge icon variant (used for shortcuts)
- Original: black circle background, white `>_` mark
- Changed: background recolored to `may_icon_background`, mark recolored
  to `may_accent` — same shape, new brand colors

### Also updated automatically via symlink (not separately edited):
- `termux-app/src/main/res/mipmap-anydpi/ic_launcher.xml` — background
  color reference changed from `@android:color/black` to
  `@color/may_icon_background`
- `termux-app/src/main/res/mipmap-anydpi/ic_launcher_round.xml` — same
  background color change

**Everything else** — every Kotlin/Java source file, every layout, every
build script, every other resource — is untouched, original Termux code.

## What was NOT changed (deliberately)

- **Package name / applicationId** (`com.termux`) — left as-is. Termux
  hardcodes this path (`/data/data/com.termux/files/usr`) in many places
  across the codebase; a full rename is a known, invasive job that risks
  breaking the app if done blind, without a real build to verify each step.
  Flagged as a deliberate follow-up task, not an oversight.
- **Splash screen, about dialog, any other branding surface** — not yet
  located/changed. Worth a follow-up pass once you have a real build
  environment to verify changes visually.
- **App icon shape** — kept Termux's existing `>_` geometry and only
  recolored it, rather than replacing it with a different shape. This was
  a deliberate choice (lower risk, proven-legible shape) — a full custom
  icon shape (see `android/art-may/may-logo.svg` for one concept) is a
  separate, optional next step.

## New files written from scratch (not from Termux at all)

None of these existed before — they're the actual product logic:

```
bin/may            — menu dispatcher / entrypoint
bin/may-chat        — chat mode
bin/may-agent       — launches OpenCode with the user's key
bin/may-models      — lists free/paid models
bin/may-config      — API key / provider setup
lib/common.sh       — shared config read/write helpers
install.sh          — universal installer (Termux + PC)
android/art-may/may-logo.svg          — original logo concept (unused by the
                                          actual app icon, which reuses
                                          Termux's proven shape — see above)
android/art-may/may-icon-preview.png  — rendered preview of that concept
```

## How to verify this yourself

If you want to confirm this independently rather than take the list on
faith:
```bash
git clone --depth 1 https://github.com/termux-play-store/termux-apps.git original
diff -rq original/ android/termux-apps/
```
This will show you exactly the same 4 files listed above (plus the two
symlink-propagated mipmap files), nothing more.
