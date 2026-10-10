package gui
{
   import collection.DenItemCollection;
   import den.DenItem;
   import den.DenXtCommManager;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import loader.MasterpieceDefHelper;

   // Looks up the masterpiece paintings a player owns. It sends the same "dmi"
   // request the Jammer Wall sends for someone else's wall (one per search),
   // and paintings load from the content CDN like they do everywhere else.
   public class MasterpiecesPopup
   {

      private static const PANEL_W:int = 720;

      private static const PANEL_H:int = 520;

      private static const GRID_X:int = -340;

      private static const GRID_Y:int = -136;

      private static const GRID_W:int = 680;

      private static const GRID_H:int = 384;

      private static const COLS:int = 5;

      private static const TILE_W:int = 124;

      private static const TILE_H:int = 140;

      private static const TILE_GAP:int = 12;

      private static const ROW_H:int = 152;

      private static const IMAGE_BOX:int = 112;

      private static const COLOR_NEUTRAL_BTN:uint = 3818070;

      private static const TICK_MS:int = 250;

      private static const REQUEST_TIMEOUT_MS:int = 10000;

      private static const MIN_REQUEST_GAP_MS:int = 1500;

      private static const CACHE_TTL_MS:int = 60000;

      private static const MAX_IMAGE_LOADS:int = 6;

      private static const IMAGE_TIMEOUT_MS:int = 15000;

      private static var _resultCache:Object = {};

      private static var _lastRequestAt:int = -100000;

      private static var _lastQuery:String = "";

      private var _popup:MovieClip;

      private var _panelBg:MovieClip;

      private var _closeCallback:Function;

      private var _isDestroyed:Boolean = false;

      private var _statusTxt:TextField;

      private var _closeBtn:MovieClip;

      private var _searchBtn:MovieClip;

      private var _mineBtn:MovieClip;

      private var _searchInput:TextField;

      private var _searchPlaceholder:TextField;

      private var _gridContent:Sprite;

      private var _gridMask:Shape;

      private var _scroller:ModMenuScroller;

      private var _emptyTitle:TextField;

      private var _emptyHint:TextField;

      private var _timer:Timer;

      // {name, key, sentAt} while a "dmi" reply is outstanding.
      private var _pending:Object;

      private var _owner:String = "";

      private var _ownerKey:String = "";

      private var _timedOut:Boolean = false;

      private var _entries:Array;

      private var _rowsByIndex:Object;

      private var _tilesById:Object;

      private var _images:Object;

      private var _failedImages:Object;

      private var _activeLoads:Object;

      private var _activeLoadCount:int = 0;

      private var _loadQueue:Array;

      public function MasterpiecesPopup(param1:Function)
      {
         super();
         _closeCallback = param1;
         _entries = [];
         _rowsByIndex = {};
         _tilesById = {};
         _images = {};
         _failedImages = {};
         _activeLoads = {};
         _loadQueue = [];
         createInterface();
         _timer = new Timer(TICK_MS);
         _timer.addEventListener(TimerEvent.TIMER,onTick,false,0,true);
         _timer.start();
         if(_lastQuery != "")
         {
            _searchInput.text = _lastQuery;
            _searchPlaceholder.visible = false;
            if(cachedResult(_lastQuery.toLowerCase()))
            {
               search(_lastQuery);
               return;
            }
         }
         updateStatus();
         updateEmptyState();
      }

      private function createInterface() : void
      {
         var title:TextField;
         var searchBox:MovieClip;
         var placeholderFormat:TextFormat;
         var divider:Shape;
         var track:MovieClip;
         var thumb:MovieClip;
         _popup = new MovieClip();
         _panelBg = ModMenuUIHelper.createPopupBackground(PANEL_W,PANEL_H);
         _panelBg.x = -PANEL_W / 2;
         _panelBg.y = -PANEL_H / 2;
         _popup.addChild(_panelBg);
         title = makeText("Masterpieces",20,ModMenuUIHelper.COLOR_TEXT,true);
         title.x = GRID_X;
         title.y = -246;
         title.width = 400;
         title.height = 30;
         _popup.addChild(title);
         _statusTxt = makeText("",12,ModMenuUIHelper.COLOR_TEXT_DIM,false);
         _statusTxt.x = GRID_X;
         _statusTxt.y = -216;
         _statusTxt.width = 640;
         _statusTxt.height = 18;
         _popup.addChild(_statusTxt);
         _closeBtn = ModMenuUIHelper.createCloseXButton();
         _closeBtn.x = 312;
         _closeBtn.y = -246;
         _closeBtn.addEventListener("mouseDown",onCloseDown,false,0,true);
         _popup.addChild(_closeBtn);
         searchBox = ModMenuUIHelper.createSearchField(290,30);
         searchBox.x = GRID_X;
         searchBox.y = -186;
         _popup.addChild(searchBox);
         _searchInput = searchBox["input"] as TextField;
         _searchInput.maxChars = 30;
         _searchPlaceholder = searchBox["placeholder"] as TextField;
         _searchPlaceholder.text = "Username…";
         placeholderFormat = new TextFormat();
         placeholderFormat.size = 12;
         placeholderFormat.italic = true;
         _searchPlaceholder.setTextFormat(placeholderFormat);
         _searchInput.addEventListener(Event.CHANGE,onSearchChanged,false,0,true);
         _searchInput.addEventListener(KeyboardEvent.KEY_DOWN,onSearchKeyDown,false,0,true);
         _searchBtn = ModMenuUIHelper.createButton("Search",ModMenuUIHelper.COLOR_BTN_PRIMARY,84,30);
         _searchBtn.x = GRID_X + 300;
         _searchBtn.y = -186;
         _searchBtn.addEventListener("mouseDown",onSearchDown,false,0,true);
         _popup.addChild(_searchBtn);
         _mineBtn = ModMenuUIHelper.createButton("Mine",COLOR_NEUTRAL_BTN,70,30);
         _mineBtn.x = GRID_X + 394;
         _mineBtn.y = -186;
         _mineBtn.addEventListener("mouseDown",onMineDown,false,0,true);
         _popup.addChild(_mineBtn);
         divider = ModMenuUIHelper.createHeaderDivider(GRID_W);
         divider.x = GRID_X;
         divider.y = -146;
         _popup.addChild(divider);
         _gridContent = new Sprite();
         _gridContent.x = GRID_X;
         _gridContent.y = GRID_Y;
         _popup.addChild(_gridContent);
         _gridMask = new Shape();
         _gridMask.graphics.beginFill(0,1);
         _gridMask.graphics.drawRect(GRID_X,GRID_Y,GRID_W,GRID_H);
         _gridMask.graphics.endFill();
         _popup.addChild(_gridMask);
         _gridContent.mask = _gridMask;
         track = ModMenuUIHelper.createScrollTrack(GRID_H);
         track.x = GRID_X + GRID_W - 8;
         track.y = GRID_Y;
         _popup.addChild(track);
         thumb = ModMenuUIHelper.createScrollThumb();
         _popup.addChild(thumb);
         _scroller = new ModMenuScroller(_gridContent,GRID_Y,GRID_H);
         _scroller.setScrollTrack(track,thumb,GRID_H);
         _scroller.setOnScrollChangeCallback(onGridScrolled);
         _emptyTitle = makeText("",15,ModMenuUIHelper.COLOR_TEXT,true,"center");
         _emptyTitle.x = GRID_X;
         _emptyTitle.y = GRID_Y + 130;
         _emptyTitle.width = GRID_W;
         _emptyTitle.height = 24;
         _popup.addChild(_emptyTitle);
         _emptyHint = makeText("",12,ModMenuUIHelper.COLOR_TEXT_DIM,false,"center");
         _emptyHint.x = GRID_X;
         _emptyHint.y = GRID_Y + 158;
         _emptyHint.width = GRID_W;
         _emptyHint.height = 20;
         _popup.addChild(_emptyHint);
         _popup.x = 450;
         _popup.y = 275;
         GuiManager.guiLayer.addChild(_popup);
         DarkenManager.darken(_popup);
         _popup.addEventListener("mouseDown",onPopupMouseDown,false,0,true);
         _popup.addEventListener("mouseWheel",onPopupWheel,false,0,true);
         try
         {
            gMainFrame.stage.addEventListener(KeyboardEvent.KEY_DOWN,onStageKeyDown,false,0,true);
            gMainFrame.stage.focus = _searchInput;
         }
         catch(e:Error)
         {
         }
      }

      private function makeText(text:String, size:int, color:uint, bold:Boolean, align:String = "left") : TextField
      {
         var tf:TextField = new TextField();
         var fmt:TextFormat = new TextFormat(null,size,color,bold);
         fmt.align = align;
         tf.defaultTextFormat = fmt;
         tf.text = text;
         tf.selectable = false;
         tf.mouseEnabled = false;
         return tf;
      }

      private static function myUserName() : String
      {
         try
         {
            return String(gMainFrame.userInfo.myUserName || "");
         }
         catch(e:Error)
         {
         }
         return "";
      }

      private static function cachedResult(key:String) : Object
      {
         var cached:Object = _resultCache[key];
         if(cached && getTimer() - cached.time < CACHE_TTL_MS)
         {
            return cached;
         }
         return null;
      }

      private function get canRequest() : Boolean
      {
         return _pending == null && getTimer() - _lastRequestAt >= MIN_REQUEST_GAP_MS;
      }

      private static function trim(text:String) : String
      {
         var start:int = 0;
         var end:int = text.length;
         while(start < end && text.charCodeAt(start) <= 32)
         {
            start++;
         }
         while(end > start && text.charCodeAt(end - 1) <= 32)
         {
            end--;
         }
         return text.substring(start,end);
      }

      private function search(rawName:String) : void
      {
         var name:String = trim(rawName || "");
         var key:String;
         var cached:Object;
         var mine:Array;
         if(_isDestroyed || name == "" || _pending != null)
         {
            return;
         }
         key = name.toLowerCase();
         _lastQuery = name;
         cached = cachedResult(key);
         if(cached)
         {
            showResult(cached.name,cached.items);
            return;
         }
         // Your own paintings are already in your den inventory.
         if(key == myUserName().toLowerCase())
         {
            mine = ownMasterpieces();
            if(mine.length > 0)
            {
               storeResult(myUserName(),mine);
               showResult(myUserName(),mine);
               return;
            }
         }
         if(!canRequest)
         {
            return;
         }
         _pending = {
            "name":name,
            "key":key,
            "sentAt":getTimer()
         };
         _lastRequestAt = getTimer();
         _timedOut = false;
         _owner = name;
         _ownerKey = key;
         _entries = [];
         layoutGrid(true);
         try
         {
            DenXtCommManager.requestDenMasterpieceItems(name,onItemsReceived);
         }
         catch(requestError:Error)
         {
            _pending = null;
            _timedOut = true;
         }
         updateStatus();
         updateEmptyState();
      }

      private static function ownMasterpieces() : Array
      {
         var out:Array = [];
         var list:DenItemCollection;
         var item:DenItem;
         var i:int;
         try
         {
            list = gMainFrame.userInfo.playerUserInfo.denItemsFull;
            i = 0;
            while(list && i < list.length)
            {
               item = list.getDenItem(i);
               if(item && item.isCustom)
               {
                  out.push(item);
               }
               i++;
            }
         }
         catch(e:Error)
         {
         }
         return out;
      }

      private static function storeResult(name:String, items:Array) : void
      {
         _resultCache[name.toLowerCase()] = {
            "name":name,
            "items":items,
            "time":getTimer()
         };
      }

      // DenXtCommManager keeps one "dmi" callback and the reply doesn't name the
      // player, so a reply with nothing pending (it came after the timeout) is
      // dropped.
      private function onItemsReceived(list:DenItemCollection) : void
      {
         var items:Array = [];
         var i:int;
         var pending:Object = _pending;
         if(_isDestroyed || pending == null)
         {
            return;
         }
         _pending = null;
         i = 0;
         while(list && i < list.length)
         {
            items.push(list.getDenItem(i));
            i++;
         }
         storeResult(pending.name,items);
         showResult(pending.name,items);
      }

      private function showResult(name:String, items:Array) : void
      {
         var byImage:Object = {};
         var item:DenItem;
         var entry:Object;
         _owner = name;
         _ownerKey = name.toLowerCase();
         _timedOut = false;
         _entries = [];
         for each(item in items)
         {
            if(!item || !item.isCustom || !item.isApproved || !item.uniqueImageId)
            {
               continue;
            }
            entry = byImage[item.uniqueImageId];
            if(entry)
            {
               entry.count++;
               continue;
            }
            entry = {
               "item":item,
               "imageId":item.uniqueImageId,
               "count":1
            };
            byImage[item.uniqueImageId] = entry;
            _entries.push(entry);
         }
         layoutGrid(true);
         updateStatus();
      }

      private function onTick(e:TimerEvent) : void
      {
         var now:int;
         var id:String;
         var load:Object;
         var expired:Array;
         if(_isDestroyed)
         {
            return;
         }
         now = getTimer();
         if(_pending != null && now - _pending.sentAt > REQUEST_TIMEOUT_MS)
         {
            _pending = null;
            _timedOut = true;
            updateEmptyState();
         }
         expired = [];
         for(id in _activeLoads)
         {
            load = _activeLoads[id];
            if(now - load.startedAt > IMAGE_TIMEOUT_MS)
            {
               expired.push(id);
            }
         }
         for each(id in expired)
         {
            _activeLoads[id].helper.destroy();
            delete _activeLoads[id];
            _activeLoadCount--;
            _failedImages[id] = true;
            showTileFailed(id);
         }
         pumpImageQueue();
         updateStatus();
      }

      private function updateStatus() : void
      {
         var msg:String;
         var copies:int = 0;
         var entry:Object;
         if(_pending != null)
         {
            msg = "Looking up " + _pending.name + "…";
         }
         else if(_timedOut)
         {
            msg = "No answer for " + _owner + ".";
         }
         else if(_owner == "")
         {
            msg = "Type a username to see the masterpieces they own.";
         }
         else
         {
            for each(entry in _entries)
            {
               copies += entry.count;
            }
            msg = _owner + " owns " + _entries.length + " painting" + (_entries.length == 1 ? "" : "s");
            if(copies > _entries.length)
            {
               msg += " (" + copies + " copies)";
            }
            if(_entries.length > 0)
            {
               msg += "  ·  click one to view it";
            }
         }
         _statusTxt.text = msg;
         setButtonEnabled(_searchBtn,canRequest);
         setButtonEnabled(_mineBtn,_pending == null);
      }

      private static function setButtonEnabled(btn:MovieClip, enabled:Boolean) : void
      {
         btn.alpha = enabled ? 1 : 0.45;
         btn.mouseEnabled = enabled;
      }

      private function updateEmptyState() : void
      {
         var title:String = "";
         var hint:String = "";
         if(_entries.length == 0)
         {
            if(_pending != null)
            {
               title = "Looking up " + _pending.name + "…";
            }
            else if(_timedOut)
            {
               title = "The server didn\'t answer for " + _owner + ".";
               hint = "Check the spelling and try again.";
            }
            else if(_owner == "")
            {
               title = "Search for a player.";
               hint = "Type their username and press Enter, or press Mine for your own.";
            }
            else
            {
               title = _owner + " doesn\'t own any masterpieces.";
               hint = "Check the spelling, or try someone else.";
            }
         }
         _emptyTitle.text = title;
         _emptyHint.text = hint;
         _emptyTitle.visible = title != "";
         _emptyHint.visible = hint != "";
      }

      private function layoutGrid(resetScroll:Boolean) : void
      {
         clearRows();
         _scroller.setMaxScrollForHeight(rowCount() * ROW_H);
         if(resetScroll)
         {
            _scroller.resetScroll();
         }
         renderVisibleRows();
         updateEmptyState();
      }

      private function rowCount() : int
      {
         return Math.ceil(_entries.length / COLS);
      }

      private function clearRows() : void
      {
         while(_gridContent.numChildren > 0)
         {
            _gridContent.removeChildAt(0);
         }
         _rowsByIndex = {};
         _tilesById = {};
         _loadQueue = [];
      }

      private function onGridScrolled(scrollY:int) : void
      {
         renderVisibleRows();
      }

      // Only the rows in view (plus one either side) exist, so a big collection
      // doesn't load every painting at once.
      private function renderVisibleRows() : void
      {
         var scrollY:int = _scroller.getScrollY();
         var first:int = Math.max(0,int(scrollY / ROW_H) - 1);
         var last:int = Math.min(rowCount() - 1,int((scrollY + GRID_H) / ROW_H) + 1);
         var stale:Array = [];
         var key:String;
         var idx:int;
         var row:MovieClip;
         var tile:MovieClip;
         for(key in _rowsByIndex)
         {
            idx = int(key);
            if(idx < first || idx > last)
            {
               stale.push(key);
            }
         }
         for each(key in stale)
         {
            row = _rowsByIndex[key];
            for each(tile in row.tiles)
            {
               if(_tilesById[tile.entry.imageId] == tile)
               {
                  delete _tilesById[tile.entry.imageId];
               }
            }
            if(row.parent)
            {
               row.parent.removeChild(row);
            }
            delete _rowsByIndex[key];
         }
         idx = first;
         while(idx <= last)
         {
            if(!_rowsByIndex[idx])
            {
               row = createRow(idx);
               row.y = idx * ROW_H;
               _gridContent.addChild(row);
               _rowsByIndex[idx] = row;
            }
            idx++;
         }
         pumpImageQueue();
      }

      private function createRow(rowIdx:int) : MovieClip
      {
         var row:MovieClip = new MovieClip();
         var tiles:Array = [];
         var col:int = 0;
         var entryIdx:int;
         var tile:MovieClip;
         while(col < COLS)
         {
            entryIdx = rowIdx * COLS + col;
            if(entryIdx >= _entries.length)
            {
               break;
            }
            tile = createTile(_entries[entryIdx]);
            tile.x = col * (TILE_W + TILE_GAP);
            row.addChild(tile);
            tiles.push(tile);
            col++;
         }
         row.tiles = tiles;
         return row;
      }

      private function createTile(entry:Object) : MovieClip
      {
         var tile:MovieClip = new MovieClip();
         var bg:MovieClip = new MovieClip();
         var holder:Sprite = new Sprite();
         var loadingTxt:TextField;
         var captionTxt:TextField;
         var countTxt:TextField;
         var countChip:Sprite;
         var creator:String = "";
         ModMenuUIHelper.drawRowBackground(bg,TILE_W,TILE_H,false);
         tile.addChild(bg);
         tile.bg = bg;
         holder.mouseEnabled = false;
         holder.mouseChildren = false;
         tile.addChild(holder);
         tile.holder = holder;
         loadingTxt = makeText("Loading…",11,ModMenuUIHelper.COLOR_TEXT_DIM,false,"center");
         loadingTxt.x = 6;
         loadingTxt.y = 6 + IMAGE_BOX / 2 - 9;
         loadingTxt.width = IMAGE_BOX;
         loadingTxt.height = 18;
         tile.addChild(loadingTxt);
         tile.loadingTxt = loadingTxt;
         try
         {
            creator = entry.item.uniqueImageCreator || "";
         }
         catch(e:Error)
         {
         }
         if(creator.charAt(0) == "#")
         {
            creator = "";
         }
         captionTxt = makeText(creator != "" ? "by " + creator : "",11,ModMenuUIHelper.COLOR_TEXT_DIM,false);
         captionTxt.x = 6;
         captionTxt.y = TILE_H - 22;
         captionTxt.width = entry.count > 1 ? TILE_W - 48 : TILE_W - 12;
         captionTxt.height = 18;
         tile.addChild(captionTxt);
         if(entry.count > 1)
         {
            countTxt = makeText("×" + entry.count,10,ModMenuUIHelper.COLOR_TEXT,true);
            countTxt.autoSize = "left";
            countTxt.x = 6;
            countTxt.y = 0;
            countChip = new Sprite();
            countChip.graphics.beginFill(ModMenuUIHelper.COLOR_ACCENT_BLUE,0.35);
            countChip.graphics.drawRoundRect(0,0,int(countTxt.textWidth) + 16,16,8,8);
            countChip.graphics.endFill();
            countChip.addChild(countTxt);
            countChip.x = TILE_W - 8 - (int(countTxt.textWidth) + 16);
            countChip.y = TILE_H - 21;
            countChip.mouseEnabled = false;
            countChip.mouseChildren = false;
            tile.addChild(countChip);
         }
         tile.entry = entry;
         tile.buttonMode = true;
         tile.mouseChildren = false;
         tile.addEventListener(MouseEvent.ROLL_OVER,onTileOver,false,0,true);
         tile.addEventListener(MouseEvent.ROLL_OUT,onTileOut,false,0,true);
         tile.addEventListener("mouseDown",onTileDown,false,0,true);
         _tilesById[entry.imageId] = tile;
         if(_images[entry.imageId])
         {
            fitPainting(tile,_images[entry.imageId]);
         }
         else if(_failedImages[entry.imageId])
         {
            loadingTxt.text = "Couldn\'t load";
         }
         else if(!_activeLoads[entry.imageId])
         {
            _loadQueue.push(entry.imageId);
         }
         return tile;
      }

      private function pumpImageQueue() : void
      {
         var id:String;
         while(_activeLoadCount < MAX_IMAGE_LOADS && _loadQueue.length > 0)
         {
            id = _loadQueue.shift();
            // Scrolled away before its turn, or already handled.
            if(!_tilesById[id] || _images[id] || _activeLoads[id] || _failedImages[id])
            {
               continue;
            }
            startImageLoad(id);
         }
      }

      private function startImageLoad(id:String) : void
      {
         var helper:MasterpieceDefHelper = new MasterpieceDefHelper();
         _activeLoads[id] = {
            "helper":helper,
            "startedAt":getTimer()
         };
         _activeLoadCount++;
         helper.init(id,function(image:Sprite):void
         {
            onImageLoaded(id,image);
         });
      }

      private function onImageLoaded(id:String, image:Sprite) : void
      {
         var load:Object;
         var tile:MovieClip;
         if(_isDestroyed)
         {
            return;
         }
         load = _activeLoads[id];
         if(!load)
         {
            return;
         }
         load.helper.destroy();
         delete _activeLoads[id];
         _activeLoadCount--;
         _images[id] = image;
         tile = _tilesById[id];
         if(tile)
         {
            fitPainting(tile,image);
         }
         pumpImageQueue();
      }

      private function showTileFailed(id:String) : void
      {
         var tile:MovieClip = _tilesById[id];
         if(tile)
         {
            tile.loadingTxt.text = "Couldn\'t load";
         }
      }

      private function fitPainting(tile:MovieClip, image:Sprite) : void
      {
         var holder:Sprite = tile.holder;
         var bounds:Rectangle;
         var scale:Number;
         image.scaleX = 1;
         image.scaleY = 1;
         image.x = 0;
         image.y = 0;
         holder.addChild(image);
         bounds = image.getBounds(holder);
         if(bounds.width < 1 || bounds.height < 1)
         {
            return;
         }
         scale = Math.min(IMAGE_BOX / bounds.width,IMAGE_BOX / bounds.height);
         image.scaleX = scale;
         image.scaleY = scale;
         image.x = 6 + (IMAGE_BOX - bounds.width * scale) / 2 - bounds.x * scale;
         image.y = 6 + (IMAGE_BOX - bounds.height * scale) / 2 - bounds.y * scale;
         tile.loadingTxt.visible = false;
      }

      private function onTileOver(e:MouseEvent) : void
      {
         ModMenuUIHelper.drawRowBackground(e.currentTarget.bg,TILE_W,TILE_H,true);
      }

      private function onTileOut(e:MouseEvent) : void
      {
         ModMenuUIHelper.drawRowBackground(e.currentTarget.bg,TILE_W,TILE_H,false);
      }

      // The game's own preview: frame, artist name (it looks the name up from
      // the owner), likes and report, the same as a buddy card's trade list.
      private function onTileDown(e:MouseEvent) : void
      {
         var entry:Object = e.currentTarget.entry;
         var item:DenItem;
         e.stopPropagation();
         item = entry ? entry.item as DenItem : null;
         if(!item)
         {
            return;
         }
         GuiManager.openMasterpiecePreview(item.uniqueImageId,item.uniqueImageCreator,item.uniqueImageCreatorDbId,item.uniqueImageCreatorUUID,item.version,_owner,item,onPreviewClosed);
      }

      // The preview writes the artist's name onto the item, so redraw the tiles
      // to show it.
      private function onPreviewClosed(bought:Boolean) : void
      {
         if(_isDestroyed)
         {
            return;
         }
         layoutGrid(false);
      }

      private function onSearchChanged(e:Event) : void
      {
         _searchPlaceholder.visible = _searchInput.text == "";
      }

      private function onSearchKeyDown(e:KeyboardEvent) : void
      {
         // Keep typing out of the game's own hotkeys (WASD, chat on Enter).
         e.stopPropagation();
         if(e.keyCode == 13)
         {
            search(_searchInput.text);
         }
         else if(e.keyCode == 27)
         {
            if(_searchInput.text != "")
            {
               _searchInput.text = "";
               onSearchChanged(null);
            }
            else
            {
               destroy();
            }
         }
      }

      private function onSearchDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         search(_searchInput.text);
      }

      private function onMineDown(e:MouseEvent) : void
      {
         var me:String = myUserName();
         e.stopPropagation();
         if(me == "" || _pending != null)
         {
            return;
         }
         _searchInput.text = me;
         onSearchChanged(null);
         search(me);
      }

      private function onStageKeyDown(e:KeyboardEvent) : void
      {
         if(e.keyCode == 27 && isTopPopup())
         {
            destroy();
         }
      }

      // DarkenManager keeps its dark backdrop in the topmost darkened popup, as
      // child 0. If it isn't in ours, the painting preview is open on top.
      private function isTopPopup() : Boolean
      {
         return _popup != null && _popup.numChildren > 0 && _popup.getChildAt(0) != _panelBg;
      }

      private function onPopupMouseDown(e:MouseEvent) : void
      {
         e.stopPropagation();
      }

      private function onPopupWheel(e:MouseEvent) : void
      {
         if(_scroller && _scroller.onMouseWheel(e))
         {
            e.stopPropagation();
         }
      }

      private function onCloseDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         destroy();
      }

      public function destroy() : void
      {
         var callback:Function;
         var id:String;
         if(_isDestroyed)
         {
            return;
         }
         _isDestroyed = true;
         callback = _closeCallback;
         _closeCallback = null;
         if(_timer)
         {
            _timer.stop();
            _timer.removeEventListener(TimerEvent.TIMER,onTick);
            _timer = null;
         }
         for(id in _activeLoads)
         {
            _activeLoads[id].helper.destroy();
         }
         _activeLoads = null;
         try
         {
            if(gMainFrame && gMainFrame.stage)
            {
               gMainFrame.stage.removeEventListener(KeyboardEvent.KEY_DOWN,onStageKeyDown);
            }
         }
         catch(e:Error)
         {
         }
         if(_scroller)
         {
            _scroller.destroy();
            _scroller = null;
         }
         if(_popup)
         {
            _popup.removeEventListener("mouseDown",onPopupMouseDown);
            _popup.removeEventListener("mouseWheel",onPopupWheel);
            try
            {
               DarkenManager.unDarken(_popup);
               if(_popup.parent)
               {
                  _popup.parent.removeChild(_popup);
               }
            }
            catch(removeError:Error)
            {
            }
         }
         _popup = null;
         _entries = null;
         _rowsByIndex = null;
         _tilesById = null;
         _images = null;
         _loadQueue = null;
         if(callback != null)
         {
            try
            {
               callback();
            }
            catch(callbackError:Error)
            {
            }
         }
      }
   }
}
