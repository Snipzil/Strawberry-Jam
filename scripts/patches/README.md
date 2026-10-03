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
- `src/gui/DenAndClothesItemSelect.as` — the multi-select item picker
  capped how many items you could select via `getSelectionLimit()`, which
  for both your own trade list (`TYPE_TRADE`) and a trade request
  (`TYPE_TRADE_INITIATION`) used `TradeManager.currentTradeListLength`, the
  length of the *trade-request* list. That list is only cleared when the next
  trade request opens, so after sending a request with N items you could
  only select 20−N items for your own trade list, and none at all after a
  full 20-item request. `TYPE_TRADE` now counts your own trade list (the list
  passed to `init`, or `userInfo.getMyTradeList()`), and both branches clamp
  to 0.
  Separately, selection was tracked by grid window index (`_selectedItems`),
  which went stale whenever the grid was rebuilt (search, tab switch). The
  rebuild re-marks selected items green by item identity, but toggling still
  checked the stale index list, so clicking a green item could add it twice
  and clicking an unselected item in a previously used slot did nothing.
  `toggleItemSelection` now decides by item identity, and `onListLoaded`
  rebuilds `_selectedItems` from the items it re-marks.
- `src/MainFrame.as`, `src/room/RoomManagerWorld.as`,
  `src/gamePlayFlow/GamePlay.as` — zoom hotkeys and WASD chat focus.
  - Zoom: the Shift+Plus/Minus hotkeys stepped from
    `MainFrame.electronManagedZoomLevel`, not from what was on screen. Rooms
    clamp to a minimum "fill" zoom and window resizes apply an auto zoom, so
    presses could jump, go the wrong way, or do nothing for several presses.
    Joining a room also capped the scale to the room's own zoom, which threw
    away your zoom in some rooms. Hotkeys now step from
    `RoomManagerWorld.currentZoom` and record the result with
    `MainFrame.setUserZoom()`, which sets an explicit `userZoomSet` flag
    (exactly 100% used to count as "not set"). `onRoomLoaded` and
    `handleResize` re-apply that zoom when the flag is set (except in
    side-scroll quests). `updateRoomZoom` no longer throws before a room's
    layers exist.
  - WASD: with WASD movement on, the game puts focus back in the chat box
    (for example after you send a message) and W/A/S/D then type there. A
    capture-phase stage `mouseDown` in `MainFrame` now clears focus from the
    text field whenever you click anything that isn't a text field, so
    clicking the room to walk frees the keys. It only runs while WASD
    movement is on, so vanilla chat focus is unchanged.
- AJ deploy 1830 port: `src/avatar/AvatarManager.as`,
  `src/avatar/AvatarViewExt_Splash.as`, `src/pet/PetBase.as`,
  `src/pet/PetManager.as`, `src/den/DenXtCommManager.as`. AJ's client update
  (deploy 1830, the Proto-Phantom candy adventure) added eight coloured
  splash liquids (red, orange, yellow, green, cyan, blue, purple, pink) and
  pets 120-123 (axolotl, countfabulous, countfabulousbat, tut). Our base
  predates it, so in that adventure the splash view treated the colours as a
  real splash volume and players couldn't move. `AvatarViewExt_Splash` is
  AJ's 1830 file as-is (our mods don't touch it). The other four are our
  modded versions plus only AJ's additions. AJ's `SmartFoxClient`/`SFClient`
  changes were deliberately not ported, because they are connection plumbing
  and renames, and our base forces the local proxy connection.
  To check for future AJ updates: `GET https://www.animaljam.com/flashvars`
  → `deploy_version`, download
  `https://ajcontent.akamaized.net/<deploy_version>/ajclient.swf`, export both
  it and `options/unmodded-ajclient.swf` with FFDec (one export at a time;
  parallel exports came out truncated) and diff the scripts.
- `src/room/RoomManagerWorld.as` heartbeat: an earlier decompile/recompile
  of this class moved `heartbeat_movePlayer` into an `else` after the
  avatar-volume test, so the player only moved while standing outside every
  avatar volume. Spawning inside one (the Proto-Phantom party adventure,
  `room_adventure_12a_party`) froze movement with no error. Restored to
  vanilla: it runs every frame. Decompiled control flow can come back
  restructured, so diff any whole-class patch against
  `options/unmodded-ajclient.swf` for changed `if`/`else`/`continue` before
  shipping it.
- `src/gui/ChatHistory.as` + `src/MainFrame.as`: vanilla re-focuses chat on
  its own (`setFocusOnMsgText` on room mouse-up, after sending, on room
  entry). With WASD movement on, that trapped W/A/S/D in chat. With WASD on,
  `setFocusOnMsgText` now leaves focus alone (and releases chat if it had it).
  `focusMsgTextForTyping()` keeps the old behaviour for explicit requests,
  Enter outside a text field opens chat, and Enter on an empty chat releases
  it.
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
java -Xmx1600m PatchTool replace mid.swf new-raw.swf ..\src,..\src\avatar,..\src\gui,..\src\buddy,..\src\room,..\src\gamePlayFlow,..\src\pet,..\src\den avatar.NameBar,avatar.AvatarManager,avatar.AvatarViewExt_Splash,pet.PetBase,pet.PetManager,den.DenXtCommManager,gui.MarketplacePopup,gui.TeleportPopup,gui.ModMenuFeatures,gui.GuiManager,buddy.BuddyCard,gui.DenAndClothesItemSelect,gui.ChatHistory,MainFrame,room.RoomManagerWorld,gamePlayFlow.GamePlay
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
