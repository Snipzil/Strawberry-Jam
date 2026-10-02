# Native class patches

Unlike `scripts/modmenu` (which owns five UI classes wholesale), this folder
keeps small, targeted patches to native `ajclient.swf` classes that ship with
bugs affecting the mod. Each file under `src/` is a full decompiled copy of
the native class with a minimal, documented fix applied — treat the rest of
the file as vanilla and untouched.

- `src/avatar/NameBar.as` — `onNameClick()` stopped the click on another
  player's in-room nametag but never called `BuddyManager.showBuddyCard(...)`
  for anyone except yourself (and only then behind the `allowOwnNametagClick`
  mod toggle). Clicking someone else's nametag did nothing, which is why
  their trade list could never be opened this way. Fixed to open the buddy
  card (with `onlineStatus:1`, since they're visibly present) for other
  players too, mirroring the existing own-nametag branch.
- `src/gui/MarketplacePopup.as` (mod-added popup, not vanilla) — the "Trade
  For" and "View User" row buttons called a bare `createButton(...)` instead
  of `ModMenuUIHelper.createButton(...)` (every other button in the file
  calls it qualified). Confirmed via pcode: those two calls compile to
  `findpropstrict`/`callproperty` with no resolvable target, i.e. a
  `ReferenceError` at runtime. Since this only fires while rendering an
  actual trade item row, the popup looked "broken" only once there was
  something to show — it silently threw instead of listing the item. Fixed
  by qualifying both calls.
- `src/gui/GuiManager.as` (glue class — see below for how much of it this
  patch touches) — `onMarketplacePopupClose()` called
  `_marketplacePopup.destroy()` a second time inside the callback that
  `MarketplacePopup.destroy()` itself invokes after already tearing itself
  down; harmless (everything inside is null-guarded) but pointless. Now just
  clears the reference. Also adds a small generic retry helper —
  `beginRoomJoinRetry(targetRoomWithNode, seekUsername)` /
  `cancelRoomJoinRetry()` — that resends a same-node room-join request every
  2s (`ROOM_JOIN_RETRY_INTERVAL_MS`) until `gMainFrame.server.getCurrentRoomName()`
  matches the target, instead of giving up after one `HALT_ON_FAILURE`
  attempt. While a retry loop is running it shows a small non-blocking
  banner on `guiLayer` ("Trying to join &lt;user&gt;'s room...") with a Stop
  button that calls `cancelRoomJoinRetry()`, so it never runs forever with no
  way to cancel it. Used by:
  - `src/gui/TeleportPopup.as` — teleporting across rooms now always retries
    via `GuiManager.beginRoomJoinRetry(...)` instead of firing one join
    request and immediately closing the popup with no way to know if it
    failed.
  - `src/buddy/BuddyCard.as` — the buddy card's "Go to room" button
    (`gotoDownHandler`) now uses the same retry helper when the new
    `followBuddyRetryEnabled` mod toggle is on; otherwise it keeps the
    original one-shot behavior.
- `src/gui/ModMenuFeatures.as` — registers the new `followBuddyRetryEnabled`
  enhancement toggle ("Retry Follow Buddy (Room Full)") so it shows up in the
  mod menu's Enhancements tab and persists like every other toggle.

Because `GuiManager` is the single glue class behind every mod toggle
(6000+ lines, not something this project maintains in full elsewhere), this
patch carries the *entire* decompiled file with the above changes applied —
treat everything else in it as vanilla-plus-existing-mods, unchanged.

## Rebuild (Windows, JDK + JPEXS Free Flash Decompiler installed)

Combine with the ModMenu rebuild (see `scripts/modmenu/README.md`) by running
`ModMenuTool replace` and `PatchTool replace` back-to-back on the same
decompressed SWF before the final `SwfCompress` pass:

```bat
set CLASSPATH=C:\Program Files (x86)\FFDec\lib\*;C:\Program Files (x86)\FFDec\ffdec.jar;.
cd scripts\modmenu\tool
javac ModMenuTool.java SwfCompress.java
cd ..\..\patches\tool
javac PatchTool.java
"C:\Program Files (x86)\FFDec\ffdec-cli.exe" -decompress ..\..\..\assets\flash\ajclient.swf raw.swf
java -Xmx1600m ModMenuTool replace raw.swf mid.swf ..\..\modmenu\src
java -Xmx1600m PatchTool replace mid.swf new-raw.swf ..\src\avatar,..\src\gui,..\src\buddy avatar.NameBar,gui.MarketplacePopup,gui.TeleportPopup,gui.ModMenuFeatures,gui.GuiManager,buddy.BuddyCard
cd ..\..\modmenu\tool
java -Xmx1600m SwfCompress ..\..\patches\tool\new-raw.swf ..\..\..\assets\flash\ajclient.swf
```

The app copies the client selected in Settings (`assets/flash/options/<file>`)
over `ajclient.swf` on launch, so a rebuilt client also has to go into
`options/`. For a release, copy it to `options/vX.Y.Z.swf`, set
`LATEST_SWF_FILE` in `src/api/controllers/FilesController.js` to that file,
and add the old latest to `PREVIOUS_LATEST_SWF_FILES` so existing installs
switch to the new client. Otherwise the selected old client overwrites the
rebuilt one.

`PatchTool` takes a comma-separated list of source directories and a
comma-separated list of fully-qualified class names, so more patched classes
can be added later without a new tool.
