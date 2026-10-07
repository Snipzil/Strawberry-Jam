package gui
{
   import Enums.TradeItem;
   import avatar.Avatar;
   import avatar.AvatarManager;
   import buddy.BuddyManager;
   import collection.IitemCollection;
   import den.DenItem;
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
   import inventory.Iitem;
   import item.Item;
   import pet.PetItem;
   import quest.QuestManager;
   import trade.TradeXtCommManager;

   public class MarketplacePopup
   {

      private static const PANEL_W:int = 720;

      private static const PANEL_H:int = 520;

      private static const LIST_X:int = -340;

      private static const LIST_Y:int = -116;

      private static const LIST_W:int = 680;

      private static const LIST_H:int = 360;

      private static const ROW_W:int = 664;

      private static const ROW_H:int = 48;

      private static const ICON_BOX:int = 36;

      private static const COLOR_NEUTRAL_BTN:uint = 3818070;

      // Trade lists are asked for one player at a time, the way a player opening
      // buddy cards would, and reused for a minute so reopening doesn't resend.
      private static const REQUEST_INTERVAL_MS:int = 300;

      private static const REQUEST_TIMEOUT_MS:int = 8000;

      private static const CACHE_TTL_MS:int = 60000;

      private static const ICON_LOAD_GRACE_MS:int = 3000;

      private static const FILTER_ALL:int = -1;

      private static const SORT_ITEM:int = 0;

      private static const SORT_PLAYER:int = 1;

      private static const STATUS_QUEUED:int = 0;

      private static const STATUS_PENDING:int = 1;

      private static const STATUS_DONE:int = 2;

      private static const STATUS_TIMEOUT:int = 3;

      private static var _tradeListCache:Object = {};

      private static var _lastRequestAt:int = -100000;

      private var _popup:MovieClip;

      private var _panelBg:MovieClip;

      private var _closeCallback:Function;

      private var _isDestroyed:Boolean = false;

      private var _statusTxt:TextField;

      private var _refreshBtn:MovieClip;

      private var _closeBtn:MovieClip;

      private var _searchInput:TextField;

      private var _searchPlaceholder:TextField;

      private var _chips:Array;

      private var _headers:Array;

      private var _listContent:Sprite;

      private var _listMask:Shape;

      private var _scroller:ModMenuScroller;

      private var _emptyTitle:TextField;

      private var _emptyHint:TextField;

      private var _players:Array;

      private var _playerByKey:Object;

      private var _queue:Array;

      private var _queueTimer:Timer;

      private var _roomName:String;

      private var _roomChanged:Boolean = false;

      private var _entries:Array;

      private var _visible:Array;

      private var _filterType:int = -1;

      private var _sortMode:int = 0;

      private var _rowsByIndex:Object;

      private var _pendingIcons:Array;

      private var _fittingIcons:Boolean = false;

      public function MarketplacePopup(param1:Function)
      {
         super();
         _closeCallback = param1;
         _chips = [];
         _headers = [];
         _players = [];
         _playerByKey = {};
         _queue = [];
         _entries = [];
         _visible = [];
         _rowsByIndex = {};
         _pendingIcons = [];
         createInterface();
         loadRoom(false);
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
         title = makeText("Trade Marketplace",20,ModMenuUIHelper.COLOR_TEXT,true);
         title.x = LIST_X;
         title.y = -246;
         title.width = 400;
         title.height = 30;
         _popup.addChild(title);
         _statusTxt = makeText("",12,ModMenuUIHelper.COLOR_TEXT_DIM,false);
         _statusTxt.x = LIST_X;
         _statusTxt.y = -216;
         _statusTxt.width = 540;
         _statusTxt.height = 18;
         _popup.addChild(_statusTxt);
         _refreshBtn = ModMenuUIHelper.createButton("Refresh",COLOR_NEUTRAL_BTN,80,28);
         _refreshBtn.x = 224;
         _refreshBtn.y = -246;
         _refreshBtn.addEventListener("mouseDown",onRefreshDown,false,0,true);
         _popup.addChild(_refreshBtn);
         _closeBtn = ModMenuUIHelper.createCloseXButton();
         _closeBtn.x = 312;
         _closeBtn.y = -246;
         _closeBtn.addEventListener("mouseDown",onCloseDown,false,0,true);
         _popup.addChild(_closeBtn);
         searchBox = ModMenuUIHelper.createSearchField(290,30);
         searchBox.x = LIST_X;
         searchBox.y = -186;
         _popup.addChild(searchBox);
         _searchInput = searchBox["input"] as TextField;
         _searchPlaceholder = searchBox["placeholder"] as TextField;
         _searchPlaceholder.text = "Search items or players…";
         placeholderFormat = new TextFormat();
         placeholderFormat.size = 12;
         placeholderFormat.italic = true;
         _searchPlaceholder.setTextFormat(placeholderFormat);
         _searchInput.addEventListener(Event.CHANGE,onSearchChanged,false,0,true);
         _searchInput.addEventListener(KeyboardEvent.KEY_DOWN,onSearchKeyDown,false,0,true);
         addChip("All",FILTER_ALL,70,-40);
         addChip("Clothing",TradeItem.ITEM_TYPE_ACCESSORY_ITEM,100,36);
         addChip("Den",TradeItem.ITEM_TYPE_DEN_ITEM,84,142);
         addChip("Pets",TradeItem.ITEM_TYPE_PET_ITEM,76,232);
         divider = ModMenuUIHelper.createHeaderDivider(LIST_W);
         divider.x = LIST_X;
         divider.y = -146;
         _popup.addChild(divider);
         addHeader("ITEM",SORT_ITEM,LIST_X + 52);
         addHeader("PLAYER",SORT_PLAYER,LIST_X + 318);
         updateHeaders();
         _listContent = new Sprite();
         _listContent.x = LIST_X;
         _listContent.y = LIST_Y;
         _popup.addChild(_listContent);
         _listMask = new Shape();
         _listMask.graphics.beginFill(0,1);
         _listMask.graphics.drawRect(LIST_X,LIST_Y,LIST_W,LIST_H);
         _listMask.graphics.endFill();
         _popup.addChild(_listMask);
         _listContent.mask = _listMask;
         track = ModMenuUIHelper.createScrollTrack(LIST_H);
         track.x = LIST_X + LIST_W - 8;
         track.y = LIST_Y;
         _popup.addChild(track);
         thumb = ModMenuUIHelper.createScrollThumb();
         _popup.addChild(thumb);
         _scroller = new ModMenuScroller(_listContent,LIST_Y,LIST_H);
         _scroller.setScrollTrack(track,thumb,LIST_H);
         _scroller.setOnScrollChangeCallback(onListScrolled);
         _emptyTitle = makeText("",15,ModMenuUIHelper.COLOR_TEXT,true,"center");
         _emptyTitle.x = LIST_X;
         _emptyTitle.y = LIST_Y + 110;
         _emptyTitle.width = LIST_W;
         _emptyTitle.height = 24;
         _popup.addChild(_emptyTitle);
         _emptyHint = makeText("",12,ModMenuUIHelper.COLOR_TEXT_DIM,false,"center");
         _emptyHint.x = LIST_X;
         _emptyHint.y = LIST_Y + 138;
         _emptyHint.width = LIST_W;
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

      private function addChip(label:String, filterType:int, width:int, x:int) : void
      {
         var chip:MovieClip = ModMenuUIHelper.createToggleChip(label,width,filterType == _filterType);
         chip.x = x;
         chip.y = -186;
         chip.filterType = filterType;
         chip.baseLabel = label;
         chip.addEventListener("mouseDown",onChipDown,false,0,true);
         _popup.addChild(chip);
         _chips.push(chip);
      }

      private function setChipLabel(chip:MovieClip, label:String) : void
      {
         var lf:TextField = chip["labelField"] as TextField;
         var fmt:TextFormat;
         if(!lf || lf.text == label)
         {
            return;
         }
         lf.text = label;
         fmt = new TextFormat();
         fmt.size = 11;
         fmt.bold = true;
         fmt.align = "center";
         lf.setTextFormat(fmt);
         lf.textColor = chip["isOn"] ? ModMenuUIHelper.COLOR_TEXT : ModMenuUIHelper.COLOR_TEXT_DIM;
      }

      private function addHeader(label:String, sortMode:int, x:int) : void
      {
         var header:MovieClip = new MovieClip();
         var tf:TextField = makeText(label,11,ModMenuUIHelper.COLOR_TEXT_DIM,true);
         tf.width = 120;
         tf.height = 18;
         header.addChild(tf);
         header.graphics.beginFill(0,0);
         header.graphics.drawRect(0,0,90,18);
         header.graphics.endFill();
         header.x = x;
         header.y = -138;
         header.buttonMode = true;
         header.mouseChildren = false;
         header.labelField = tf;
         header.baseLabel = label;
         header.sortMode = sortMode;
         header.addEventListener("mouseDown",onHeaderDown,false,0,true);
         _popup.addChild(header);
         _headers.push(header);
      }

      private function updateHeaders() : void
      {
         var header:MovieClip;
         var active:Boolean;
         for each(header in _headers)
         {
            active = header.sortMode == _sortMode;
            header.labelField.text = header.baseLabel + (active ? "  ▼" : "");
            header.labelField.textColor = active ? ModMenuUIHelper.COLOR_TEXT : ModMenuUIHelper.COLOR_TEXT_DIM;
         }
      }

      private static function currentRoomName() : String
      {
         try
         {
            return gMainFrame.server.getCurrentRoomName();
         }
         catch(e:Error)
         {
         }
         return "";
      }

      private function loadRoom(force:Boolean) : void
      {
         var sfsUserId:*;
         var avatar:Avatar;
         var key:String;
         var myKey:String;
         var player:Object;
         var cached:Object;
         var now:int = getTimer();
         stopQueue();
         _players = [];
         _playerByKey = {};
         _queue = [];
         _roomChanged = false;
         _roomName = currentRoomName();
         myKey = String(gMainFrame.userInfo.myUserName).toLowerCase();
         for(sfsUserId in AvatarManager.avatarList)
         {
            avatar = AvatarManager.avatarList[sfsUserId];
            if(!avatar || !avatar.userName)
            {
               continue;
            }
            key = avatar.userName.toLowerCase();
            if(key == myKey || _playerByKey[key])
            {
               continue;
            }
            if(!gMainFrame.userInfo.getUserInfoByUserName(avatar.userName) || !gMainFrame.userInfo.getAvatarInfoByUserName(avatar.userName))
            {
               continue;
            }
            player = {
               "username":avatar.userName,
               "avatarName":avatar.avName || "",
               "key":key,
               "status":STATUS_QUEUED,
               "sentAt":0,
               "list":null,
               "itemCount":0
            };
            _players.push(player);
            _playerByKey[key] = player;
            cached = _tradeListCache[key];
            if(!force && cached && now - cached.time < CACHE_TTL_MS)
            {
               player.status = STATUS_DONE;
               player.list = cached.list;
            }
            else
            {
               _queue.push(player);
            }
         }
         if(_queue.length > 0)
         {
            _queueTimer = new Timer(100);
            _queueTimer.addEventListener(TimerEvent.TIMER,onQueueTick,false,0,true);
            _queueTimer.start();
         }
         rebuildEntries();
         applyFilter(true);
         onQueueTick(null);
      }

      private function onQueueTick(e:TimerEvent) : void
      {
         var now:int;
         var player:Object;
         var waiting:Boolean = false;
         if(_isDestroyed)
         {
            stopQueue();
            return;
         }
         if(_queueTimer == null)
         {
            updateStatus();
            return;
         }
         if(currentRoomName() != _roomName)
         {
            _roomChanged = true;
            stopQueue();
            updateStatus();
            updateEmptyState();
            return;
         }
         now = getTimer();
         for each(player in _players)
         {
            if(player.status == STATUS_PENDING)
            {
               if(now - player.sentAt > REQUEST_TIMEOUT_MS)
               {
                  player.status = STATUS_TIMEOUT;
               }
               else
               {
                  waiting = true;
               }
            }
         }
         if(_queue.length > 0 && now - _lastRequestAt >= REQUEST_INTERVAL_MS)
         {
            player = _queue.shift();
            if(player.status == STATUS_QUEUED)
            {
               player.status = STATUS_PENDING;
               player.sentAt = now;
               _lastRequestAt = now;
               waiting = true;
               try
               {
                  TradeXtCommManager.sendTradeListRequest(player.username);
               }
               catch(requestError:Error)
               {
                  player.status = STATUS_TIMEOUT;
               }
            }
         }
         if(_queue.length == 0 && !waiting)
         {
            stopQueue();
            updateEmptyState();
         }
         updateStatus();
      }

      private function stopQueue() : void
      {
         if(_queueTimer)
         {
            _queueTimer.stop();
            _queueTimer.removeEventListener(TimerEvent.TIMER,onQueueTick);
            _queueTimer = null;
         }
         if(_queue)
         {
            _queue.length = 0;
         }
      }

      private function get isLoading() : Boolean
      {
         return _queueTimer != null;
      }

      public function onTradeListReceived(username:String, tradeList:IitemCollection) : void
      {
         var key:String;
         var player:Object;
         if(_isDestroyed || !username)
         {
            return;
         }
         key = username.toLowerCase();
         _tradeListCache[key] = {
            "list":tradeList,
            "time":getTimer()
         };
         player = _playerByKey[key];
         if(!player)
         {
            return;
         }
         player.status = STATUS_DONE;
         player.list = tradeList;
         rebuildEntries();
         applyFilter(false);
         updateStatus();
      }

      private static function tradeTypeOf(item:Iitem) : int
      {
         if(item is Item)
         {
            return TradeItem.ITEM_TYPE_ACCESSORY_ITEM;
         }
         if(item is DenItem)
         {
            return TradeItem.ITEM_TYPE_DEN_ITEM;
         }
         if(item is PetItem)
         {
            return TradeItem.ITEM_TYPE_PET_ITEM;
         }
         return -1;
      }

      private static function typeLabelOf(tradeType:int) : String
      {
         if(tradeType == TradeItem.ITEM_TYPE_ACCESSORY_ITEM)
         {
            return "Clothing";
         }
         if(tradeType == TradeItem.ITEM_TYPE_DEN_ITEM)
         {
            return "Den Item";
         }
         return "Pet";
      }

      // Copies of the same item from the same player share a row. Colors,
      // masterpiece paintings and pets are told apart.
      private static function variantOf(item:Iitem) : String
      {
         if(item is Item)
         {
            return String((item as Item).color);
         }
         if(item is DenItem && item.isCustom)
         {
            return "custom" + (item as DenItem).uniqueImageId;
         }
         if(item is PetItem)
         {
            return "pet" + item.invIdx;
         }
         return "";
      }

      private function rebuildEntries() : void
      {
         var byKey:Object = {};
         var player:Object;
         var list:IitemCollection;
         var i:int;
         var item:Iitem;
         var tradeType:int;
         var groupKey:String;
         var entry:Object;
         var name:String;
         _entries = [];
         for each(player in _players)
         {
            player.itemCount = 0;
            list = player.list as IitemCollection;
            if(player.status != STATUS_DONE || !list)
            {
               continue;
            }
            i = 0;
            while(i < list.length)
            {
               item = list.getIitem(i);
               i++;
               if(!item || !item.isApproved)
               {
                  continue;
               }
               tradeType = tradeTypeOf(item);
               if(tradeType < 0)
               {
                  continue;
               }
               player.itemCount++;
               groupKey = player.key + "|" + tradeType + "|" + item.defId + "|" + variantOf(item);
               entry = byKey[groupKey];
               if(entry)
               {
                  entry.count++;
                  continue;
               }
               name = item.name || "Unknown item";
               entry = {
                  "item":item,
                  "tradeType":tradeType,
                  "typeLabel":typeLabelOf(tradeType),
                  "name":name,
                  "nameKey":name.toLowerCase(),
                  "owner":player.username,
                  "ownerKey":player.key,
                  "avatarName":player.avatarName,
                  "count":1,
                  "isRare":safeFlag(item,"isRare"),
                  "isDiamond":safeFlag(item,"isDiamond"),
                  "isOcean":safeFlag(item,"isOcean"),
                  "isMasterpiece":item is DenItem && safeFlag(item,"isCustom")
               };
               entry.search = (name + " " + player.username + " " + player.avatarName + " " + entry.typeLabel + (entry.isRare ? " rare" : "") + (entry.isDiamond ? " diamond" : "") + (entry.isOcean ? " ocean" : "")).toLowerCase();
               byKey[groupKey] = entry;
               _entries.push(entry);
            }
         }
      }

      private static function safeFlag(item:Iitem, flag:String) : Boolean
      {
         try
         {
            return Boolean(item[flag]);
         }
         catch(e:Error)
         {
         }
         return false;
      }

      private function queryWords() : Array
      {
         var raw:String = _searchInput ? _searchInput.text.toLowerCase() : "";
         var words:Array = raw.split(" ");
         var result:Array = [];
         var word:String;
         for each(word in words)
         {
            if(word.length > 0)
            {
               result.push(word);
            }
         }
         return result;
      }

      private function applyFilter(resetScroll:Boolean) : void
      {
         var words:Array = queryWords();
         var counts:Object = {};
         var total:int = 0;
         var entry:Object;
         var word:String;
         var matches:Boolean;
         var chip:MovieClip;
         var count:int;
         counts[TradeItem.ITEM_TYPE_ACCESSORY_ITEM] = 0;
         counts[TradeItem.ITEM_TYPE_DEN_ITEM] = 0;
         counts[TradeItem.ITEM_TYPE_PET_ITEM] = 0;
         _visible = [];
         for each(entry in _entries)
         {
            matches = true;
            for each(word in words)
            {
               if(entry.search.indexOf(word) < 0)
               {
                  matches = false;
                  break;
               }
            }
            if(!matches)
            {
               continue;
            }
            counts[entry.tradeType] += entry.count;
            total += entry.count;
            if(_filterType == FILTER_ALL || entry.tradeType == _filterType)
            {
               _visible.push(entry);
            }
         }
         _visible.sort(_sortMode == SORT_PLAYER ? comparePlayer : compareItem);
         for each(chip in _chips)
         {
            count = chip.filterType == FILTER_ALL ? total : int(counts[chip.filterType]);
            setChipLabel(chip,chip.baseLabel + "  " + count);
         }
         layoutList(resetScroll);
      }

      private function compareItem(a:Object, b:Object) : int
      {
         if(a.nameKey != b.nameKey)
         {
            return a.nameKey < b.nameKey ? -1 : 1;
         }
         if(a.ownerKey != b.ownerKey)
         {
            return a.ownerKey < b.ownerKey ? -1 : 1;
         }
         return 0;
      }

      private function comparePlayer(a:Object, b:Object) : int
      {
         if(a.ownerKey != b.ownerKey)
         {
            return a.ownerKey < b.ownerKey ? -1 : 1;
         }
         if(a.nameKey != b.nameKey)
         {
            return a.nameKey < b.nameKey ? -1 : 1;
         }
         return 0;
      }

      private function layoutList(resetScroll:Boolean) : void
      {
         clearRows();
         _scroller.setMaxScrollForHeight(_visible.length * ROW_H);
         if(resetScroll)
         {
            _scroller.resetScroll();
         }
         renderVisibleRows();
         updateEmptyState();
      }

      private function clearRows() : void
      {
         while(_listContent.numChildren > 0)
         {
            _listContent.removeChildAt(0);
         }
         _rowsByIndex = {};
         _pendingIcons = [];
      }

      private function onListScrolled(scrollY:int) : void
      {
         renderVisibleRows();
      }

      // Only the rows in view (plus one either side) exist, so a busy room
      // doesn't build hundreds of rows and icons on every keystroke.
      private function renderVisibleRows() : void
      {
         var scrollY:int = _scroller.getScrollY();
         var first:int = Math.max(0,int(scrollY / ROW_H) - 1);
         var last:int = Math.min(_visible.length - 1,int((scrollY + LIST_H) / ROW_H) + 1);
         var stale:Array = [];
         var key:String;
         var idx:int;
         var row:MovieClip;
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
            if(row && row.parent)
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
               row = createRow(_visible[idx]);
               row.y = idx * ROW_H;
               _listContent.addChild(row);
               _rowsByIndex[idx] = row;
            }
            idx++;
         }
      }

      private function createRow(entry:Object) : MovieClip
      {
         var row:MovieClip = new MovieClip();
         var bg:MovieClip = new MovieClip();
         var iconBox:Shape = new Shape();
         var holder:Sprite = new Sprite();
         var nameTxt:TextField;
         var countChip:Sprite;
         var countTxt:TextField;
         var nameRight:int;
         var subTxt:TextField;
         var link:MovieClip;
         var linkTxt:TextField;
         var linkFormat:TextFormat;
         var ownerTxt:TextField;
         var avatarTxt:TextField;
         var tradeBtn:MovieClip;
         var profileBtn:MovieClip;
         ModMenuUIHelper.drawRowBackground(bg,ROW_W,ROW_H - 4,false);
         row.addChild(bg);
         row.bg = bg;
         row.addEventListener(MouseEvent.ROLL_OVER,onRowOver,false,0,true);
         row.addEventListener(MouseEvent.ROLL_OUT,onRowOut,false,0,true);
         iconBox.graphics.beginFill(ModMenuUIHelper.COLOR_TEXT,0.05);
         iconBox.graphics.drawRoundRect(6,4,ICON_BOX,ICON_BOX,8,8);
         iconBox.graphics.endFill();
         row.addChild(iconBox);
         holder.mouseEnabled = false;
         holder.mouseChildren = false;
         row.addChild(holder);
         attachIcon(holder,entry.item);
         nameTxt = makeText(entry.name,13,ModMenuUIHelper.COLOR_TEXT,true);
         nameTxt.x = 52;
         nameTxt.y = 5;
         nameTxt.width = 250;
         nameTxt.height = 20;
         row.addChild(nameTxt);
         if(entry.count > 1)
         {
            nameRight = 52 + Math.min(int(nameTxt.textWidth) + 4,250);
            countTxt = makeText("×" + entry.count,10,ModMenuUIHelper.COLOR_TEXT,true);
            countTxt.autoSize = "left";
            countTxt.x = 6;
            countTxt.y = 0;
            countChip = new Sprite();
            countChip.graphics.beginFill(ModMenuUIHelper.COLOR_ACCENT_BLUE,0.35);
            countChip.graphics.drawRoundRect(0,0,int(countTxt.textWidth) + 16,16,8,8);
            countChip.graphics.endFill();
            countChip.addChild(countTxt);
            countChip.x = nameRight + 6;
            countChip.y = 7;
            countChip.mouseEnabled = false;
            countChip.mouseChildren = false;
            row.addChild(countChip);
         }
         subTxt = makeText("",11,ModMenuUIHelper.COLOR_TEXT_DIM,false);
         subTxt.htmlText = subLineHtml(entry);
         subTxt.x = 52;
         subTxt.y = 24;
         subTxt.width = 250;
         subTxt.height = 18;
         row.addChild(subTxt);
         if(entry.isMasterpiece)
         {
            link = new MovieClip();
            linkTxt = makeText("View painting",11,ModMenuUIHelper.COLOR_ACCENT_BLUE,false);
            linkFormat = linkTxt.defaultTextFormat;
            linkFormat.underline = true;
            linkTxt.setTextFormat(linkFormat);
            linkTxt.autoSize = "left";
            link.addChild(linkTxt);
            link.x = 52 + int(subTxt.textWidth) + 12;
            link.y = 24;
            link.buttonMode = true;
            link.mouseChildren = false;
            link.entry = entry;
            link.addEventListener("mouseDown",onPreviewDown,false,0,true);
            row.addChild(link);
         }
         ownerTxt = makeText(entry.owner,13,ModMenuUIHelper.COLOR_TEXT,false);
         ownerTxt.x = 318;
         ownerTxt.y = 5;
         ownerTxt.width = 180;
         ownerTxt.height = 20;
         row.addChild(ownerTxt);
         avatarTxt = makeText(entry.avatarName,11,ModMenuUIHelper.COLOR_TEXT_DIM,false);
         avatarTxt.x = 318;
         avatarTxt.y = 24;
         avatarTxt.width = 180;
         avatarTxt.height = 18;
         row.addChild(avatarTxt);
         tradeBtn = ModMenuUIHelper.createButton("Trade",ModMenuUIHelper.COLOR_BTN_PRIMARY,72,28);
         tradeBtn.x = 508;
         tradeBtn.y = 8;
         tradeBtn.entry = entry;
         tradeBtn.addEventListener("mouseDown",onTradeDown,false,0,true);
         row.addChild(tradeBtn);
         profileBtn = ModMenuUIHelper.createButton("Profile",COLOR_NEUTRAL_BTN,68,28);
         profileBtn.x = 588;
         profileBtn.y = 8;
         profileBtn.entry = entry;
         profileBtn.addEventListener("mouseDown",onProfileDown,false,0,true);
         row.addChild(profileBtn);
         return row;
      }

      private static function escapeHtml(text:String) : String
      {
         return text.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
      }

      private static function subLineHtml(entry:Object) : String
      {
         var html:String = escapeHtml(entry.typeLabel);
         if(entry.isRare)
         {
            html += "   <font color=\'#FFC94D\'><b>Rare</b></font>";
         }
         if(entry.isDiamond)
         {
            html += "   <font color=\'#6FD8FF\'><b>Diamond</b></font>";
         }
         if(entry.isOcean)
         {
            html += "   <font color=\'#5FB3FF\'>Ocean</font>";
         }
         return html;
      }

      // Item icons are one shared Sprite per item, drawn around their own
      // origin and loaded asynchronously, so each one is scaled to fit the box
      // once it has loaded (the holder carries the transform, not the icon).
      private function attachIcon(holder:Sprite, item:Iitem) : void
      {
         var icon:Sprite = null;
         try
         {
            icon = item.icon;
         }
         catch(e:Error)
         {
            icon = null;
         }
         if(!icon)
         {
            return;
         }
         holder.addChild(icon);
         holder.visible = false;
         _pendingIcons.push({
            "holder":holder,
            "icon":icon,
            "item":item,
            "since":getTimer()
         });
         fitPendingIcons();
         if(_pendingIcons.length > 0 && !_fittingIcons && _popup)
         {
            _fittingIcons = true;
            _popup.addEventListener(Event.ENTER_FRAME,onFitIconsFrame,false,0,true);
         }
      }

      private function onFitIconsFrame(e:Event) : void
      {
         fitPendingIcons();
         if(_pendingIcons.length == 0 && _popup)
         {
            _fittingIcons = false;
            _popup.removeEventListener(Event.ENTER_FRAME,onFitIconsFrame);
         }
      }

      private function fitPendingIcons() : void
      {
         var remaining:Array = [];
         var pending:Object;
         for each(pending in _pendingIcons)
         {
            if(!pending.holder.parent || pending.icon.parent != pending.holder)
            {
               continue;
            }
            if(!fitIcon(pending))
            {
               remaining.push(pending);
            }
         }
         _pendingIcons = remaining;
      }

      private function fitIcon(pending:Object) : Boolean
      {
         var loaded:Boolean = true;
         var bounds:Rectangle;
         var scale:Number;
         var holder:Sprite = pending.holder;
         try
         {
            loaded = pending.item.isIconLoaded;
         }
         catch(e:Error)
         {
         }
         if(!loaded && getTimer() - pending.since < ICON_LOAD_GRACE_MS)
         {
            return false;
         }
         holder.scaleX = 1;
         holder.scaleY = 1;
         bounds = pending.icon.getBounds(holder);
         if(bounds.width < 2 || bounds.height < 2)
         {
            return false;
         }
         scale = Math.min(ICON_BOX / bounds.width,ICON_BOX / bounds.height);
         holder.scaleX = scale;
         holder.scaleY = scale;
         holder.x = 6 + ICON_BOX / 2 - (bounds.x + bounds.width / 2) * scale;
         holder.y = 4 + ICON_BOX / 2 - (bounds.y + bounds.height / 2) * scale;
         holder.visible = true;
         return true;
      }

      private function updateEmptyState() : void
      {
         var title:String = "";
         var hint:String = "";
         if(_visible.length == 0)
         {
            if(_roomChanged && _entries.length == 0)
            {
               title = "You changed rooms.";
               hint = "Press Refresh to see what people here are trading.";
            }
            else if(_players.length == 0)
            {
               title = "Nobody else is in this room.";
               hint = "Open the marketplace somewhere busier to see what people are trading.";
            }
            else if(_entries.length == 0)
            {
               if(isLoading)
               {
                  title = "Loading trade lists…";
               }
               else
               {
                  title = "Nobody here has items up for trade.";
                  hint = "Press Refresh to check again.";
               }
            }
            else
            {
               title = "No items match your search.";
               hint = "Try another name, or pick a different filter.";
            }
         }
         _emptyTitle.text = title;
         _emptyHint.text = hint;
         _emptyTitle.visible = title != "";
         _emptyHint.visible = hint != "";
      }

      private function updateStatus() : void
      {
         var total:int = int(_players.length);
         var answered:int = 0;
         var silent:int = 0;
         var sellers:int = 0;
         var items:int = 0;
         var player:Object;
         var msg:String;
         for each(player in _players)
         {
            if(player.status == STATUS_DONE)
            {
               answered++;
               items += player.itemCount;
               if(player.itemCount > 0)
               {
                  sellers++;
               }
            }
            else if(player.status == STATUS_TIMEOUT)
            {
               answered++;
               silent++;
            }
         }
         if(_roomChanged)
         {
            msg = "You changed rooms. Press Refresh to load this one.";
         }
         else if(total == 0)
         {
            msg = "Nobody else is here.";
         }
         else if(isLoading)
         {
            msg = "Loading trade lists… " + answered + " of " + total + " players";
            if(items > 0)
            {
               msg += "  ·  " + items + " item" + (items == 1 ? "" : "s") + " so far";
            }
         }
         else
         {
            msg = items + " item" + (items == 1 ? "" : "s") + " from " + sellers + " player" + (sellers == 1 ? "" : "s");
            if(silent > 0)
            {
               msg += "  ·  " + silent + " didn\'t respond";
            }
         }
         _statusTxt.text = msg;
         _refreshBtn.alpha = isLoading ? 0.45 : 1;
         _refreshBtn.mouseEnabled = !isLoading;
      }

      private function onRowOver(e:MouseEvent) : void
      {
         ModMenuUIHelper.drawRowBackground(e.currentTarget.bg,ROW_W,ROW_H - 4,true);
      }

      private function onRowOut(e:MouseEvent) : void
      {
         ModMenuUIHelper.drawRowBackground(e.currentTarget.bg,ROW_W,ROW_H - 4,false);
      }

      private function onChipDown(e:MouseEvent) : void
      {
         var chip:MovieClip;
         e.stopPropagation();
         _filterType = int(e.currentTarget.filterType);
         for each(chip in _chips)
         {
            ModMenuUIHelper.setToggleChipState(chip,chip.filterType == _filterType);
         }
         applyFilter(true);
      }

      private function onHeaderDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         if(_sortMode == int(e.currentTarget.sortMode))
         {
            return;
         }
         _sortMode = int(e.currentTarget.sortMode);
         updateHeaders();
         applyFilter(true);
      }

      private function onSearchChanged(e:Event) : void
      {
         _searchPlaceholder.visible = _searchInput.text == "";
         applyFilter(true);
      }

      private function onSearchKeyDown(e:KeyboardEvent) : void
      {
         // Keep typing out of the game's own hotkeys (WASD, chat on Enter).
         e.stopPropagation();
         if(e.keyCode == 27)
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

      private function onStageKeyDown(e:KeyboardEvent) : void
      {
         if(e.keyCode == 27 && isTopPopup())
         {
            destroy();
         }
      }

      // DarkenManager keeps its dark backdrop in the topmost darkened popup, as
      // child 0. If it isn't in ours, a trade or buddy card is open on top.
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

      private function onRefreshDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         if(isLoading)
         {
            return;
         }
         loadRoom(true);
      }

      private function onCloseDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         destroy();
      }

      private function onTradeDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         if(e.currentTarget.entry)
         {
            startTrade(e.currentTarget.entry);
         }
      }

      // Same steps as clicking an item on a buddy card's trade tab. TradeManager
      // looks the item up in the buddy card's trade list, so lend it ours.
      private function startTrade(entry:Object) : void
      {
         var player:Object = _playerByKey ? _playerByKey[entry.ownerKey] : null;
         if(_isDestroyed || !player || !player.list)
         {
            return;
         }
         if(QuestManager.isInPrivateAdventureState)
         {
            QuestManager.showLeaveQuestLobbyPopup(startTrade,entry);
            return;
         }
         TradeXtCommManager.sendTradeBusyRequest(true);
         TradeManager.isCurrentlyTrading = true;
         BuddyManager.setTradeListOverride(player.list);
         try
         {
            TradeManager.displayRequestTrade({
               "currUsernameToTradeTo":entry.owner,
               "itemToTrade":new TradeItem(entry.item.invIdx,entry.tradeType)
            });
         }
         catch(tradeError:Error)
         {
            TradeManager.isCurrentlyTrading = false;
            TradeXtCommManager.sendTradeBusyRequest(false);
         }
         BuddyManager.setTradeListOverride(null);
      }

      private function onProfileDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         if(e.currentTarget.entry)
         {
            BuddyManager.showBuddyCard({
               "userName":e.currentTarget.entry.owner,
               "onlineStatus":1
            });
         }
      }

      private function onPreviewDown(e:MouseEvent) : void
      {
         var entry:Object = e.currentTarget.entry;
         var denItem:DenItem;
         e.stopPropagation();
         denItem = entry ? entry.item as DenItem : null;
         if(denItem)
         {
            GuiManager.openMasterpiecePreview(denItem.uniqueImageId,denItem.uniqueImageCreator,denItem.uniqueImageCreatorDbId,denItem.uniqueImageCreatorUUID,denItem.version,entry.owner,denItem);
         }
      }

      public function destroy() : void
      {
         var callback:Function;
         if(_isDestroyed)
         {
            return;
         }
         _isDestroyed = true;
         stopQueue();
         callback = _closeCallback;
         _closeCallback = null;
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
            _popup.removeEventListener(Event.ENTER_FRAME,onFitIconsFrame);
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
         _players = null;
         _playerByKey = null;
         _entries = null;
         _visible = null;
         _rowsByIndex = null;
         _pendingIcons = null;
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
