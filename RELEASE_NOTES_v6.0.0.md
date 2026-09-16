# Strawberry Jam v6.0.0

A visual and usability overhaul across the whole app: the main window, the game launcher, and the in-game Mod Menu. Updated with ❤ by Snipz, built on glvckoma's Strawberry Jam.

Download: `strawberry-jam-Setup-6.0.0.exe` from the Releases page.

## Highlights

- **Mod Menu (F10) rebuilt.** Wider two-column layout so Mods and Popups fit without scrolling, click anywhere on a row to toggle it, switch-style toggles, hotkey chips only where a hotkey exists, live search with an "Enabled only" filter, per-tab counts, hover tooltips for long descriptions, a draggable scrollbar, and your search, filter, and last tab are remembered between sessions.
- **Launcher redesign.** New login card with a theme accent, redesigned inputs and buttons, a cleaner account rail, and a settings panel with segmented tabs, keyboard-chip shortcuts, and a fixed height so tabs stop jumping. Full dark and light token system that follows your theme color. The 2-step verification, forgot-password, message, and rename modals now match.
- **Plugins tab refresh.** New plugin cards with accent icons, type badges, and an open chevron; a toolbar with search (Ctrl+F, Esc to clear); a Recent row of your last five opened plugins; keyboard navigation with a visible focus ring.
- **Header.** Segmented Network/Plugins tabs and a PLAY button that spins while patching and turns into a green RUNNING state while the game is open.
- **2FA fix for UUID Spoofing.** The spoofed device ID is now persistent, so Animal Jam remembers the device and stops asking for a code on every login. A "New ID" button regenerates it on demand.
- **In-game controls.** Settings, debug log, version, and a new "Open · F10" Mod Menu row stay visible and clickable over the game. The mod menu button is a glass pill that reveals its shortcut on hover.

## Fixes

- Login form no longer renders over the 2-step verification and other modals.
- Utility buttons were nearly invisible over the game; they now sit above the game screen.
- Removed stale play-button text references.

## Under the hood

- The Mod Menu's ActionScript sources and a rebuild tool now live in `scripts/modmenu`, so it can be changed without decompiling the client.
- The previous client (v5.2.0) stays selectable in Settings as a fallback next to the new v6.0.0 client.
- Repository, update feed, installer, and About links now point to https://github.com/Snipzil/Strawberry-Jam.

## Notes

- After updating, the first login will ask for a 2FA code once (new device ID). It should not ask again after that.
- Anti-AFK reviewed: with the toggle on, keep-alive packets are sent every 3 minutes regardless of input, plus randomized activity packets every 2 to 3 minutes, and the idle-kick warning can no longer fire.
