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
  `onNameClick` is mod-added (vanilla NameBar has no click handler), and it
  also ran on name-only namebars: the jag inbox sender, buddy list rows,
  trade popups. Those call `setAvName(String)`, so `_avatarUserName` stays
  null, `isMyAvatar()` treats a null name as you, and the handler ate the
  click with `stopImmediatePropagation`. As a result, clicking a jag sender
  opened your own card when "own nametag click" was on and did nothing
  when it was off. It now returns without stopping the event when the
  namebar has no username, so the container's own handler (for example
  `ECardInbox.onUsernameClick`) runs.
- `src/gui/MarketplacePopup.as` (mod-added popup, not vanilla) — the "Trade
  For" and "View User" row buttons called a bare `createButton(...)` instead
  of `ModMenuUIHelper.createButton(...)` (every other button in the file
  calls it qualified). Confirmed via pcode: those two calls compile to
  `findpropstrict`/`callproperty` with no resolvable target, i.e. a
  `ReferenceError` at runtime. Since this only fires while rendering an
  actual trade item row, the popup looked "broken" only once there was
  something to show — it silently threw instead of listing the item. Fixed
  by qualifying both calls.
  The popup has since been rebuilt for usability. Copies of an item from one
  player share a row (`×4`); colours, masterpiece paintings and pets stay
  separate. Rows show the item icon (scaled to fit once it loads), the type,
  real tags (`isRare`, `isDiamond`, `isOcean`; the old "Rarity" column said
  "Rare" for everything because it only tested `defId`) and the owner. Search
  is live and matches item, username, avatar name, type and tags, and every
  word has to match. All/Clothing/Den/Pets chips show counts, the ITEM and
  PLAYER headers sort, and the list scrolls by wheel or scrollbar
  (`ModMenuScroller`). Items are cards, three across in an 860px panel: the
  icon (with a `×4` badge for copies) on the left, then the name, the owner
  with their avatar's name in grey, and the tags or link next to small Trade
  and Profile buttons. About 20 show at once where the old two-line rows
  showed 7. Long names end in "…". The status sits beside the title and the
  sort (ITEM / PLAYER) at the end of the filter row, since a grid has no
  columns to head. Only the rows of cards in view are built. Masterpieces get a
  "View painting" link (`GuiManager.openMasterpiecePreview`, as on the buddy
  card). Trade lists are requested one player at a time, 300ms apart, instead
  of all at once. A player who doesn't answer within 8s is shown as "didn't
  respond", where the old popup left a blocking loading spiral up forever.
  Lists are cached for 60s, so reopening doesn't resend, and Refresh forces a
  reload. **Trade** now opens the trade request for that exact item, the way
  clicking it on a buddy card's trade tab does. Before, it showed an OK
  popup telling you to go and find the item yourself.
- `src/buddy/BuddyManager.as` — `TradeManager.findItem` looks the requested
  item up only in `getTradeListFromBuddyCard()`, i.e. an open buddy card. The
  marketplace now lends it the owner's trade list for the duration of
  `TradeManager.displayRequestTrade` through `setTradeListOverride(list)` /
  `setTradeListOverride(null)`. `TradeManager` itself is left alone: the mod
  already changed it heavily and it is 2700 lines, while `BuddyManager`
  is near-vanilla. Diffed against the current client after a round trip: the
  hook is the only change.
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
  Scrolling the picker left rows blank for about a second. `SBDynamicScrollbar`
  only shows and loads windows 100ms after scrolling *stops*, and
  `ItemWindowOriginal.setStatesForVisibility(false)` destroys the icon of
  every window that leaves the view, so scrolling back rebuilds it from
  scratch. The picker now passes `keepIconLoaded:true`; with it, a hidden
  window keeps its icon and only pauses its animations
  (`src/gui/itemWindows/ItemWindowOriginal.as`, opt-in, so other lists are
  unchanged). An `enterFrame` prefetch in the picker also watches the scroll
  target and, when it changes, shows and loads the windows from one screen
  above it to two below, before the scroll tween reaches them.
  `SBDynamicScrollbar` itself is not patched: its decompile has broken
  expressions (`null.width` in `doInsert`) and would not recompile
  faithfully.
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
  Future AJ updates are ported by `npm run aj:update` (see
  `scripts/aj-update/README.md`), which also writes the merged classes back
  into this folder. Note `options/unmodded-ajclient.swf` is not pure vanilla:
  its `SmartFoxClient` is hooked to the local proxy, so diff against AJ's own
  SWF from `ajcontent.akamaized.net/<deploy>/ajclient.swf` instead.
- `src/gui/ShopExplorerPopup.as` (mod-added popup, not vanilla) and
  `src/den/DenXtCommManager.as` — Shop Explorer was getting accounts
  banned. It sent a burst of `dsi` (den store info) requests no vanilla
  client sends: every one of *your own* shop IDs (`ShopManager.myShopItems`)
  paired with the current den owner's name, shop IDs left over from the
  previous den, your own username when you weren't in a den at all, and a
  fresh burst on every reopen (and on every den join while it was open).
  Now it only runs inside a den; it asks only for shops placed in that den
  (den-state IDs, which `DenXtCommManager` now tags with the room they came
  from via `getLastDenStateRoomName()`, plus the room's own den items); your
  own shops come from the local cache like the vanilla shop does; and
  requests go out one at a time, 2.5s apart, paused while a shop is open,
  stopped if you leave the den or a reply doesn't come back in 10s, with
  results cached for 60s so reopening doesn't resend. `DenXtCommManager` no
  longer calls into the popup on den state.
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
- HTML mod menu bridge: `src/gui/ModMenuFeatures.as`, `src/MainFrame.as`,
  `src/gui/GuiManager.as`. The F10 menu is now drawn by the client in HTML
  (`assets/client/gui/components/screens/ModMenuPanel.js`). `MainFrame` calls
  `ModMenuFeatures.initBridge()` next to the `mec` setup, which registers
  ExternalInterface callbacks `sjModMenuGetState`, `sjModMenuSetToggle`,
  `sjModMenuSetScope`, `sjModMenuSetDenLogin` and `sjModMenuOpenPopup`. They
  are thin wrappers over the existing `ModMenuFeatures`/`GuiManager` calls, so
  persistence and scopes are unchanged. `sjModMenuGetState` returns a JSON
  string: ExternalInterface marshals objects through XML, and the ~45-entry
  state as an object took about 105ms per call, freezing the game. GameScreen calls them with
  `webview.executeJavaScript` on the Flash `<embed>`. `GuiManager.toggleModMenu()`
  first asks `ModMenuFeatures.toggleHtmlMenu()`, which calls
  `sjModMenu.toggle` (exposed by `gamePreload.js`). That returns false when the
  "Classic Mod Menu" client setting is on or the host isn't ready, and the
  Flash menu opens as before.

- Mod settings survive AJ updates: `src/gui/GuiManager.as`,
  `src/avatar/AvatarManager.as`, `scripts/modmenu/src/ModMenu.as`. Mod data used
  `SharedObject.getLocal(name)`, which Flash scopes to the SWF's path
  (`/<deploy>/ajclient.swf`), so each AJ deploy started with an empty
  `aj_global_mod_settings` and every mod setting reset (one `.sol` per deploy
  under `#SharedObjects/*/#localhost/<deploy>/`). They now go through
  `GuiManager.getPersistentSO(name)`, which uses localPath `"/"` (as AJ's own
  `com/sbi/login` does) and, the first time, copies over the current deploy's
  old file. `CustomAvatarNames`, `CustomNametagColors` and
  `PhantomModeVisibility` still use the per-deploy path (not patched here).
- Stage quality: `src/gui/GuiManager.as`, `src/MainFrame.as`,
  `src/gamePlayFlow/GamePlay.as`. `MainFrame.handleResize` forced quality to
  `medium` (`low` on any high-DPI screen) on every resize, and `GamePlay` init
  and headless exit forced `medium`. That undid Performance Mode's `low` even
  though the toggle stayed on. All of them now call
  `GuiManager.applyStageQuality()`: Performance Mode gives `low`; otherwise the
  HD Graphics enhancement (`hdGraphics`, opt-in) gives `high`; with it off, the
  original medium / low-on-HiDPI behaviour. It briefly shipped default-on as
  `hdGraphicsEnabled` and made startup lag badly (Flash rasterizes on the CPU,
  and `high` is 4x4 anti-aliasing), so that key is ignored now. It also sets
  `gMainFrame.currStageQuality`, which minigames restore on exit.
  `applyLoadedModSettings` no longer clears `_performanceMode` before four
  setters that each save to disk. The game runs at 24 fps with a fixed 33ms
  step per frame (`roomMgr.heartbeat(33, ...)`), so movement and timeline
  animations are frame-locked and the frame rate is deliberately left alone.
- `src/avatar/AvatarWorldView.as` (mod-added tint, not vanilla): the private
  chat balloon (`_privBalloon`) is tinted with a `ColorTransform`. It used
  half red/green with +128 red/blue offsets, which made the bubble pink and
  its outline purple. It is now light blue (red x0.65, green x0.82, blue x1,
  no offsets), so the white fill becomes about `#A6D1FF` and the black outline
  stays black.
- `src/com/sbi/graphics/LayerAnim.as` — animations got choppier the longer
  a session ran. Every avatar animation sits in a global pool
  (`_activePool`), and `LayerAnim.heartbeat()` advances at most 8 of them per
  tick, round-robin. Vanilla AJ often drops an `AvatarView` without calling
  `destroy()`: `ShopWithPreview.purchaseComplete` (every clothing purchase),
  `AvatarSwitcher`, `ItemWindowCustPlayers` (adventure lobbies), the
  `PVP_*` games, `MinigameManager`, `AdventureJoin`, `StartupPopups` and
  others. Those animations stayed in the pool for good. Each tick still
  bounds-checked them, and `trimAnims()` kept their painted frames and source
  images in memory, so the per-frame work and Flash's heap (and its GC
  pauses) grew all session. Now, every 48 ticks (~2s), an animation whose
  bitmap is off the stage, with no load, preload or callback pending, gets
  a strike. After 3 strikes it is *parked*: removed from the pool, with an
  `addedToStage` listener on its own bitmap. Nothing global references it
  then, so a leaked one is garbage-collected along with its frames. One that
  is reused rejoins the pool when it is added to the stage or when
  `playAnim`/`preload`/`layers`/`avDefId` start a new load.
  `LayerAnim.destroy()` also destroys parked animations.
  Two decompile notes: `_isOnscreen`/`_hasSequence` are function-valued
  static *vars* (the setters replace them), but FFDec prints them as static
  methods. Recompiling that form would break `LayerAnim.isOnscreen = ...` in
  `Utility`, so the source restores the var form. Also, `pruneOrphans()`
  (used only by Performance Mode) reads `anim.parent`, which `LayerAnim`
  doesn't have. It throws, which aborts the rest of
  `PerformanceManager.performPerformanceCleanup()`. It is deliberately left
  as is: the steps it skips (`cleanChatBubbles`, `cleanDisplayLists`) destroy
  live chat balloons and room foreground art, and need fixing first.
- `src/avatar/AvatarManager.as` heartbeat: the mod wrapped the whole
  per-avatar `heartbeat` loop in one `try`. So an avatar that threw stopped
  every avatar after it from moving for as long as it kept throwing. The
  `try` is now inside the loop.
- Masterpieces popup: `src/gui/MasterpiecesPopup.as` (new class, mod-added),
  plus `showMasterpiecesPopup()` in `src/gui/GuiManager.as` and a
  "Masterpieces" entry in `ModMenuFeatures.getPopupFeatures()` (both menus
  list popups from there). It replaces the old Masterpieces Viewer plugin,
  which searched jam.exposed; that site is gone. You type a username (or press
  Mine) and it shows the approved paintings that player owns. Copies of one
  painting share a tile (`×3`). Clicking a tile opens the game's own preview
  (`GuiManager.openMasterpiecePreview`, as the buddy card and marketplace do),
  which looks up the artist's name from the owner and writes it back onto the
  item, so the tile shows "by" and the artist's name after that.
  A search sends one `dmi` request, the one the Jammer Wall sends to show
  someone else's masterpieces. At most one is in flight, they are at least
  1.5s apart, a reply that hasn't come in 10s counts as no answer, and results
  are cached for 60s. Your own name reads your den inventory instead of
  asking. `DenXtCommManager` keeps a single `dmi` callback and the reply
  doesn't name the player, so a reply that arrives with nothing pending is
  dropped. Paintings come from the content CDN through `MasterpieceDefHelper`,
  for the rows in view only and at most 6 at a time. A painting that hasn't
  loaded in 15s shows "Couldn't load".
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
java -Xmx1600m PatchTool replace mid.swf new-raw.swf ..\src,..\src\avatar,..\src\gui,..\src\buddy,..\src\room,..\src\gamePlayFlow,..\src\pet,..\src\den,..\src\gui\itemWindows,..\src\com\sbi\graphics com.sbi.graphics.LayerAnim,avatar.NameBar,avatar.AvatarManager,avatar.AvatarViewExt_Splash,pet.PetBase,pet.PetManager,den.DenXtCommManager,gui.ShopExplorerPopup,gui.MarketplacePopup,gui.TeleportPopup,gui.ModMenuFeatures,gui.GuiManager,buddy.BuddyCard,buddy.BuddyManager,gui.DenAndClothesItemSelect,gui.itemWindows.ItemWindowOriginal,gui.ChatHistory,MainFrame,room.RoomManagerWorld,gamePlayFlow.GamePlay,avatar.AvatarWorldView,gui.MasterpiecesPopup
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

A listed class with a source file but no script in the SWF (a brand-new mod
class, like `gui.MasterpiecesPopup` the first time) is added before the
replace: `PatchTool` compiles an empty `package x { public class Y { } }` into
the ABC that holds the other targets, which is what FFDec's "Add class" does,
and prints `added new class ...`. New classes compile first, so the classes
that use them see the real class. Once a client contains the class, later
builds just replace it like any other.
