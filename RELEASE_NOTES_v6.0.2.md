# Strawberry Jam v6.0.2

Fixes the 6.0.1 game client not loading after an update, and makes app updates easier to see and more reliable.

Download: `strawberry-jam-Setup-6.0.2.exe` from the Releases page, or let the app update itself.

## Fix

- **6.0.1 client now loads.** Updating from 6.0.0 kept the old game client selected in Settings, so it replaced the new one every time the app started. The 6.0.1 fixes never showed up in game. Your selection now moves to the v6.0.1 client automatically on first launch. You can still pick an older client in Settings and it will stay picked.

## Installer

- **One-click install.** The installer is now a single progress window that opens Strawberry Jam when it finishes. It closes Strawberry Jam and the game on its own instead of asking, with no extra popups or console windows. It installs to the same place as before, so your settings carry over.
- Windows may still show a "Windows protected your PC" warning on a fresh download because the installer isn't code-signed yet. Click **More info → Run anyway**. Updates through the app don't show it.

## Updates

These take effect from the next update after this one.

- **Update button in the header.** When an update is out, a button appears next to Settings. It shows download progress, then turns green: click **Restart to update**, or it installs the next time you close the app. You also get a console message at each step, and a desktop notice if the window is in the background.
- **Quiet installs.** Updates install without opening the installer window, then reopen Strawberry Jam. If the game is open, you're asked before it closes.
- **Automatic retries.** A failed download retries on its own after 2, 5, then 15 minutes. Click the update button to retry right away, or download from the Releases page.
- **Notices with auto-updates off.** Turning off Automatic Updates now only stops background downloads. You still see when an update is out and can download it with one click.

## What you get now (from 6.0.1)

- **Retry Follow Buddy (Room Full)**, a new toggle in the Mod Menu's Enhancements tab. **Go to room** on a buddy card keeps retrying until you get into a full room, with a **Stop** button.
- Clicking another player's nametag opens their buddy card.
- The marketplace **Trade For** and **View User** buttons work again.
- Teleporting keeps retrying until you arrive.

You don't need to uninstall or reinstall.
