package gui
{
   import den.DenStateItem;
   import den.DenXtCommManager;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import inventory.Iitem;
   import loader.DenItemHelper;
   import room.DenItemHolder;
   import room.RoomManagerWorld;
   import shop.MyShopData;
   import shop.MyShopItem;
   import shop.ShopManager;
   import shop.ShopToSellXtCommManager;
   
   public class ShopExplorerPopup
   {

      // The server bans for "dsi" (den store info) traffic a normal client never
      // sends. Only ask for shops placed in the den we are standing in, one
      // request at a time, spaced out like a player clicking shops.
      private static const REQUEST_INTERVAL_MS:int = 2500;

      private static const REQUEST_TIMEOUT_MS:int = 10000;

      private static const CACHE_TTL_MS:int = 60000;

      private static var _activeInstance:ShopExplorerPopup;

      private static var _requestInFlight:Boolean = false;

      private static var _requestSentAt:int = 0;

      private static var _lastRequestAt:int = -100000;

      private static var _shopCache:Object = {};

      private var _popup:MovieClip;

      private var _closeCallback:Function;

      private var _itemListContainer:MovieClip;

      private var _itemListMask:Sprite;

      private var _scrollUpBtn:MovieClip;

      private var _scrollDownBtn:MovieClip;

      private var _scrollPosition:int = 0;

      private var _maxVisibleEntries:int = 12;

      private var _entryHeight:int = 45;

      private var _headerHeight:int = 30;

      private var _searchField:TextField;

      private var _statusTxt:TextField;

      private var _shopDataMap:Dictionary;

      private var _allItems:Array;

      private var _filteredItems:Array;

      private var _loadingShopsCount:int = 0;

      private var _loadedShopsCount:int = 0;

      private var _isDestroyed:Boolean = false;

      private var _requestQueue:Array;

      private var _requestOwner:String = "";

      private var _queueTimer:Timer;

      public function ShopExplorerPopup(param1:Function)
      {
         super();
         try
         {
            if(!GuiManager || !GuiManager.guiLayer)
            {
               throw new Error("GuiManager.guiLayer is not initialized. Cannot create ShopExplorerPopup.");
            }
            if(_activeInstance && _activeInstance != this)
            {
               _activeInstance.destroy();
            }
            _activeInstance = this;
            _closeCallback = param1;
            _shopDataMap = new Dictionary();
            _allItems = [];
            _filteredItems = [];
            _isDestroyed = false;
            _requestQueue = [];
            createShopExplorerInterface();
            discoverAndLoadShops();
         }
         catch(error:Error)
         {
            stopQueue();
            if(DarkenManager && _popup)
            {
               DarkenManager.unDarken(_popup);
            }
            if(_popup && _popup.parent && GuiManager && GuiManager.guiLayer)
            {
               GuiManager.guiLayer.removeChild(_popup);
            }
            throw error;
         }
      }

      // Kept for SWFs whose DenXtCommManager still calls it; shops are only
      // requested when the popup is opened.
      public static function onDenStateShopsDiscovered(shopIds:Array) : void
      {
      }

      private function createShopExplorerInterface() : void
      {
         var titleTxt:TextField;
         var titleFormat:TextFormat;
         var searchLabel:TextField;
         var searchLabelFormat:TextFormat;
         var clearBtn:MovieClip;
         var closeXBtn:MovieClip;
         _popup = new MovieClip();
         var bg:MovieClip = ModMenuUIHelper.createPopupBackground(700,530);
         bg.x = -350;
         bg.y = -310;
         _popup.addChild(bg);
         titleTxt = new TextField();
         titleTxt.text = "Shop Explorer";
         titleTxt.textColor = 16777215;
         titleFormat = new TextFormat();
         titleFormat.size = 24;
         titleFormat.bold = true;
         titleTxt.setTextFormat(titleFormat);
         titleTxt.x = -100;
         titleTxt.y = -280;
         titleTxt.width = 200;
         titleTxt.height = 40;
         titleTxt.selectable = false;
         titleTxt.mouseEnabled = false;
         _popup.addChild(titleTxt);
         _statusTxt = new TextField();
         _statusTxt.defaultTextFormat = new TextFormat(null,11);
         _statusTxt.textColor = 13421772;
         _statusTxt.x = -330;
         _statusTxt.y = -272;
         _statusTxt.width = 220;
         _statusTxt.height = 20;
         _statusTxt.selectable = false;
         _statusTxt.mouseEnabled = false;
         _popup.addChild(_statusTxt);
         searchLabel = new TextField();
         searchLabel.text = "Search:";
         searchLabel.textColor = 13421772;
         searchLabelFormat = new TextFormat();
         searchLabelFormat.size = 12;
         searchLabelFormat.align = "left";
         searchLabel.setTextFormat(searchLabelFormat);
         searchLabel.x = -330;
         searchLabel.y = -240;
         searchLabel.width = 80;
         searchLabel.height = 20;
         searchLabel.selectable = false;
         searchLabel.mouseEnabled = false;
         _popup.addChild(searchLabel);
         _searchField = new TextField();
         _searchField.type = "input";
         _searchField.border = true;
         _searchField.borderColor = ModMenuUIHelper.COLOR_BORDER;
         _searchField.background = true;
         _searchField.backgroundColor = 1118481;
         _searchField.textColor = ModMenuUIHelper.COLOR_TEXT;
         _searchField.x = -240;
         _searchField.y = -240;
         _searchField.width = 400;
         _searchField.height = 25;
         _searchField.maxChars = 50;
         _searchField.text = "";
         _searchField.addEventListener(Event.CHANGE,onSearchTextChanged,false,0,true);
         _popup.addChild(_searchField);
         try
         {
            clearBtn = createButton("Clear",16744448,70);
            clearBtn.x = 180;
            clearBtn.y = -240;
            clearBtn.addEventListener("mouseDown",onClearSearch,false,0,true);
            _popup.addChild(clearBtn);
         }
         catch(clearBtnError:Error)
         {
         }
         try
         {
            createScrollableItemList();
         }
         catch(scrollError:Error)
         {
         }
         try
         {
            closeXBtn = createCloseXButton();
            closeXBtn.x = 300;
            closeXBtn.y = -280;
            _popup.closeBtn = closeXBtn;
            _popup.addChild(closeXBtn);
         }
         catch(closeBtnError:Error)
         {
         }
         _popup.x = 450;
         _popup.y = 305;
         if(!GuiManager || !GuiManager.guiLayer)
         {
            throw new Error("GuiManager.guiLayer is not initialized");
         }
         GuiManager.guiLayer.addChild(_popup);
         if(DarkenManager)
         {
            DarkenManager.darken(_popup);
         }
         addEventListeners();
      }
      
      private function createScrollableItemList() : void
      {
         _itemListContainer = new MovieClip();
         _itemListContainer.x = -330;
         _itemListContainer.y = -210;
         _itemListContainer.mouseEnabled = true;
         _itemListContainer.mouseChildren = true;
         _popup.addChild(_itemListContainer);
         _itemListMask = new Sprite();
         _itemListMask.graphics.beginFill(16711680,0);
         var maskHeight:int = 210 - -210;
         _itemListMask.graphics.drawRect(-330,-210,660,maskHeight);
         _itemListMask.graphics.endFill();
         _popup.addChild(_itemListMask);
         _itemListContainer.mask = _itemListMask;
         _scrollUpBtn = createButton("▲",6710886,30);
         _scrollUpBtn.x = 300;
         _scrollUpBtn.y = -185;
         _scrollUpBtn.addEventListener("mouseDown",onScrollUp,false,0,true);
         _scrollUpBtn.alpha = 0.5;
         _scrollUpBtn.mouseEnabled = false;
         _popup.addChild(_scrollUpBtn);
         _scrollDownBtn = createButton("▼",6710886,30);
         _scrollDownBtn.x = 300;
         _scrollDownBtn.y = 185;
         _scrollDownBtn.addEventListener("mouseDown",onScrollDown,false,0,true);
         _scrollDownBtn.alpha = 0.5;
         _scrollDownBtn.mouseEnabled = false;
         _popup.addChild(_scrollDownBtn);
      }
      
      private static function currentDenOwner() : String
      {
         try
         {
            if(RoomManagerWorld.instance && RoomManagerWorld.instance.denOwnerName)
            {
               return RoomManagerWorld.instance.denOwnerName;
            }
         }
         catch(e:Error)
         {
         }
         return "";
      }

      private static function isCurrentRoom(roomName:String) : Boolean
      {
         var owner:String = currentDenOwner();
         if(!roomName || owner == "")
         {
            return false;
         }
         try
         {
            if(roomName != gMainFrame.server.getCurrentRoomName())
            {
               return false;
            }
         }
         catch(e:Error)
         {
            return false;
         }
         return roomName.toLowerCase() == ("den" + owner).toLowerCase();
      }

      private function addShopId(shopId:int, shopIdSet:Dictionary, shopIds:Array) : void
      {
         if(shopId > 0 && shopIdSet[shopId] == null)
         {
            shopIdSet[shopId] = true;
            shopIds.push(shopId);
         }
      }

      // Shop IDs placed in the room we are in, read from the room's own den items.
      private function collectRoomShopIds(shopIdSet:Dictionary, shopIds:Array) : void
      {
         var layerMgr:Object;
         var roomAvatarsLayer:Object;
         var numChildren:int;
         var childIdx:int;
         var child:Object;
         var helper:DenItemHelper;
         var denStateItem:DenStateItem;
         var denItemDef:Object;
         try
         {
            if(!RoomManagerWorld.instance || !RoomManagerWorld.instance.layerManager)
            {
               return;
            }
            layerMgr = RoomManagerWorld.instance.layerManager;
            if(!layerMgr.hasOwnProperty("room_avatars") || !layerMgr.room_avatars)
            {
               return;
            }
            roomAvatarsLayer = layerMgr.room_avatars;
            numChildren = int(roomAvatarsLayer.numChildren);
            childIdx = 0;
            while(childIdx < numChildren)
            {
               try
               {
                  child = roomAvatarsLayer.getChildAt(childIdx);
                  helper = null;
                  if(child && child.hasOwnProperty("denItemHelper"))
                  {
                     helper = child.denItemHelper as DenItemHelper;
                  }
                  else if(child && child.hasOwnProperty("_denItemHelper"))
                  {
                     helper = child._denItemHelper as DenItemHelper;
                  }
                  denStateItem = helper ? helper.denStateItem as DenStateItem : null;
                  if(denStateItem)
                  {
                     if(denStateItem.specialType == 5 || denStateItem.denItemHelper && denStateItem.denItemHelper.isDenStore)
                     {
                        addShopId(denStateItem.invIdx,shopIdSet,shopIds);
                     }
                     else
                     {
                        denItemDef = DenXtCommManager.getDenItemDef(denStateItem.defId);
                        if(denItemDef && int(denItemDef.specialType) == 5)
                        {
                           addShopId(denStateItem.invIdx,shopIdSet,shopIds);
                        }
                     }
                  }
               }
               catch(childError:Error)
               {
               }
               childIdx++;
            }
         }
         catch(e:Error)
         {
         }
      }

      private function discoverAndLoadShops() : void
      {
         var shopIdSet:Dictionary = new Dictionary();
         var shopIds:Array = [];
         var denShopId:int;
         var cachedShopId:Object;
         var shopIdToLoad:int;
         var ownShop:MyShopData;
         var isMyDen:Boolean = false;
         _requestOwner = currentDenOwner();
         if(_requestOwner == "")
         {
            setStatus("");
            showMessage("Shop Explorer only works inside a den.");
            return;
         }
         try
         {
            isMyDen = RoomManagerWorld.instance.isMyDen;
         }
         catch(e:Error)
         {
         }
         try
         {
            if(isCurrentRoom(DenXtCommManager.getLastDenStateRoomName()))
            {
               for each(denShopId in DenXtCommManager.getLastDenStateShopIds())
               {
                  addShopId(denShopId,shopIdSet,shopIds);
               }
            }
         }
         catch(denStateError:Error)
         {
         }
         collectRoomShopIds(shopIdSet,shopIds);
         if(isMyDen && ShopManager.myShopItems)
         {
            // Our own shop contents are cached locally, the same way the vanilla
            // shop skips the server for the owner.
            for(cachedShopId in ShopManager.myShopItems)
            {
               addShopId(int(cachedShopId),shopIdSet,shopIds);
            }
         }
         if(shopIds.length == 0)
         {
            setStatus("");
            showMessage("No shops found in this den.");
            return;
         }
         _loadingShopsCount = shopIds.length;
         _loadedShopsCount = 0;
         for each(shopIdToLoad in shopIds)
         {
            ownShop = isMyDen && ShopManager.myShopItems ? ShopManager.myShopItems[shopIdToLoad] as MyShopData : null;
            if(!ownShop)
            {
               ownShop = getCachedShop(_requestOwner,shopIdToLoad);
            }
            if(ownShop)
            {
               addShopData(shopIdToLoad,ownShop);
            }
            else
            {
               _requestQueue.push(shopIdToLoad);
            }
         }
         if(_requestQueue.length > 0)
         {
            _queueTimer = new Timer(250);
            _queueTimer.addEventListener(TimerEvent.TIMER,onQueueTick,false,0,true);
            _queueTimer.start();
         }
         combineAndSortItems();
         updateStatus();
         if(_queueTimer)
         {
            onQueueTick(null);
         }
      }

      private static function getCachedShop(owner:String, shopId:int) : MyShopData
      {
         var entry:Object = _shopCache[owner.toLowerCase() + ":" + shopId];
         if(entry && getTimer() - entry.time < CACHE_TTL_MS)
         {
            return entry.data as MyShopData;
         }
         return null;
      }

      private function onQueueTick(e:TimerEvent) : void
      {
         var shopId:int;
         var cached:MyShopData;
         if(_isDestroyed)
         {
            stopQueue();
            return;
         }
         if(currentDenOwner() != _requestOwner)
         {
            stopQueue();
            updateStatus();
            return;
         }
         if(_requestInFlight)
         {
            if(getTimer() - _requestSentAt > REQUEST_TIMEOUT_MS)
            {
               // No reply: stop rather than keep sending.
               _requestInFlight = false;
               stopQueue();
               setStatus("Stopped: a shop did not respond.");
            }
            return;
         }
         if(ShopManager.isWorldShopOpen() || getTimer() - _lastRequestAt < REQUEST_INTERVAL_MS)
         {
            return;
         }
         while(_requestQueue.length > 0)
         {
            shopId = int(_requestQueue.shift());
            cached = getCachedShop(_requestOwner,shopId);
            if(cached)
            {
               addShopData(shopId,cached);
               combineAndSortItems();
               updateStatus();
               continue;
            }
            _requestInFlight = true;
            _requestSentAt = _lastRequestAt = getTimer();
            try
            {
               ShopToSellXtCommManager.requestStoreInfo(_requestOwner,shopId,onShopDataLoaded,{
                  "shopId":shopId,
                  "owner":_requestOwner
               });
            }
            catch(requestError:Error)
            {
               _requestInFlight = false;
               stopQueue();
               setStatus("Stopped: request failed.");
            }
            return;
         }
         stopQueue();
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
         if(_requestQueue)
         {
            _requestQueue.length = 0;
         }
      }

      private function onShopDataLoaded(shopData:MyShopData, passback:Object) : void
      {
         _requestInFlight = false;
         if(passback && passback.shopId && passback.owner && shopData)
         {
            _shopCache[String(passback.owner).toLowerCase() + ":" + int(passback.shopId)] = {
               "data":shopData,
               "time":getTimer()
            };
         }
         if(_isDestroyed || !passback || !passback.shopId)
         {
            return;
         }
         try
         {
            addShopData(int(passback.shopId),shopData);
            combineAndSortItems();
            updateStatus();
         }
         catch(error:Error)
         {
         }
      }

      private function addShopData(shopId:int, shopData:MyShopData) : void
      {
         var i:int;
         var shopItem:MyShopItem;
         ++_loadedShopsCount;
         if(!shopData || !shopData.shopItems || _shopDataMap[shopId])
         {
            return;
         }
         _shopDataMap[shopId] = shopData;
         i = 0;
         while(i < shopData.shopItems.length)
         {
            shopItem = shopData.shopItems[i];
            if(shopItem && shopItem.currItem)
            {
               _allItems.push({
                  "item":shopItem.currItem,
                  "shopId":shopId,
                  "cost":shopItem.cost,
                  "currencyType":shopItem.currencyType,
                  "shopItem":shopItem
               });
            }
            i++;
         }
      }

      private function updateStatus() : void
      {
         if(_loadedShopsCount < _loadingShopsCount && _queueTimer)
         {
            setStatus("Loading shops " + _loadedShopsCount + "/" + _loadingShopsCount + "...");
         }
         else if(_loadedShopsCount < _loadingShopsCount)
         {
            setStatus("Loaded " + _loadedShopsCount + "/" + _loadingShopsCount + " shops");
         }
         else
         {
            setStatus(_loadingShopsCount + " shop" + (_loadingShopsCount == 1 ? "" : "s"));
         }
      }

      private function setStatus(message:String) : void
      {
         if(_statusTxt)
         {
            _statusTxt.text = message;
         }
      }

      private function combineAndSortItems() : void
      {
         _allItems.sort(function(a:Object, b:Object):int
         {
            var nameA:String = a.item.name ? a.item.name.toLowerCase() : "";
            var nameB:String = b.item.name ? b.item.name.toLowerCase() : "";
            if(nameA < nameB)
            {
               return -1;
            }
            if(nameA > nameB)
            {
               return 1;
            }
            return 0;
         });
         filterItems(_searchField ? _searchField.text : "");
      }
      
      private function filterItems(searchText:String) : void
      {
         _filteredItems = [];
         var searchLower:String = searchText ? searchText.toLowerCase() : "";
         for each(var itemEntry in _allItems)
         {
            if(!searchLower || !itemEntry.item.name || itemEntry.item.name.toLowerCase().indexOf(searchLower) != -1)
            {
               _filteredItems.push(itemEntry);
            }
         }
         updateDisplay();
      }
      
      private function updateDisplay() : void
      {
         while(_itemListContainer.numChildren > 0)
         {
            _itemListContainer.removeChildAt(0);
         }
         var yPos:int = 0;
         createItemListHeader(yPos);
         yPos += _headerHeight;
         if(_filteredItems.length == 0)
         {
            var noResultsTxt:TextField = new TextField();
            noResultsTxt.text = _allItems.length == 0 ? (_queueTimer ? "Loading shops..." : "No items found in any shops.") : "No items match your search.";
            noResultsTxt.textColor = 16777215;
            noResultsTxt.x = 50;
            noResultsTxt.y = yPos + 20;
            noResultsTxt.width = 500;
            noResultsTxt.height = 25;
            noResultsTxt.selectable = false;
            var noResultsFormat:TextFormat = new TextFormat();
            noResultsFormat.size = 14;
            noResultsFormat.align = "center";
            noResultsTxt.setTextFormat(noResultsFormat);
            _itemListContainer.addChild(noResultsTxt);
         }
         else
         {
            for each(var itemEntry in _filteredItems)
            {
               createItemEntry(itemEntry,yPos);
               yPos += _entryHeight;
            }
         }
         _itemListContainer.y = -210 - _scrollPosition * _entryHeight;
         updateScrollButtons();
      }
      
      private function createItemListHeader(yPos:int) : void
      {
         var headerBg:MovieClip = new MovieClip();
         headerBg.graphics.beginFill(ModMenuUIHelper.COLOR_ROW_EVEN,0.9);
         headerBg.graphics.drawRoundRect(0,0,660,25,ModMenuUIHelper.CORNER_RADIUS_SM,ModMenuUIHelper.CORNER_RADIUS_SM);
         headerBg.graphics.endFill();
         headerBg.y = yPos;
         _itemListContainer.addChild(headerBg);
         var headerTxt:TextField = new TextField();
         headerTxt.text = "Item Name                                    Cost              Shop";
         headerTxt.textColor = 16777215;
         headerTxt.x = 10;
         headerTxt.y = yPos + 3;
         headerTxt.width = 640;
         headerTxt.height = 20;
         headerTxt.selectable = false;
         var headerFormat:TextFormat = new TextFormat();
         headerFormat.size = 12;
         headerFormat.bold = true;
         headerTxt.setTextFormat(headerFormat);
         _itemListContainer.addChild(headerTxt);
      }
      
      private function createItemEntry(itemEntry:Object, yPos:int) : void
      {
         var item:Iitem;
         var shopId:int;
         var cost:int;
         var currencyType:int;
         var itemIcon:Sprite;
         var iconSprite:Sprite;
         var nameTxt:TextField;
         var nameFormat:TextFormat;
         var costTxt:TextField;
         var costColor:uint;
         var currencyName:String;
         var costFormat:TextFormat;
         var openShopBtn:MovieClip;
         var entryBg:MovieClip = new MovieClip();
         entryBg.graphics.beginFill(3355443,0.7);
         entryBg.graphics.drawRoundRect(0,0,660,_entryHeight - 2,3,3);
         entryBg.graphics.endFill();
         entryBg.y = yPos;
         entryBg.buttonMode = true;
         entryBg.mouseChildren = true;
         _itemListContainer.addChild(entryBg);
         item = itemEntry.item;
         shopId = int(itemEntry.shopId);
         cost = int(itemEntry.cost);
         currencyType = int(itemEntry.currencyType);
         if(item)
         {
            try
            {
               // An item's icon is one shared Sprite that stays parented to the
               // previous render's row, so always re-add it (addChild moves it).
               // Icons are drawn around their own origin, so place by center.
               itemIcon = item.icon;
               if(itemIcon)
               {
                  iconSprite = new Sprite();
                  iconSprite.addChild(itemIcon);
                  iconSprite.x = 25;
                  iconSprite.y = yPos + (_entryHeight - 2) / 2;
                  iconSprite.scaleX = 0.4;
                  iconSprite.scaleY = 0.4;
                  iconSprite.mouseEnabled = false;
                  iconSprite.mouseChildren = false;
                  _itemListContainer.addChild(iconSprite);
               }
            }
            catch(iconError:Error)
            {
            }
         }
         nameTxt = new TextField();
         nameTxt.text = item ? item.name : "Unknown Item";
         nameTxt.textColor = 16777215;
         nameTxt.x = 50;
         nameTxt.y = yPos + 12;
         nameTxt.width = 350;
         nameTxt.height = 20;
         nameTxt.selectable = false;
         nameTxt.mouseEnabled = false;
         nameFormat = new TextFormat();
         nameFormat.size = 12;
         nameTxt.setTextFormat(nameFormat);
         _itemListContainer.addChild(nameTxt);
         costTxt = new TextField();
         costColor = uint(currencyType == 3 ? 65535 : 16776960);
         currencyName = currencyType == 3 ? "Diamonds" : "Gems";
         costTxt.text = currencyName + ": " + Utility.convertNumberToString(cost);
         costTxt.textColor = costColor;
         costTxt.x = 410;
         costTxt.y = yPos + 12;
         costTxt.width = 120;
         costTxt.height = 20;
         costTxt.selectable = false;
         costTxt.mouseEnabled = false;
         costFormat = new TextFormat();
         costFormat.size = 11;
         costFormat.bold = true;
         costTxt.setTextFormat(costFormat);
         _itemListContainer.addChild(costTxt);
         openShopBtn = createButton("Open Shop",5025616,100);
         openShopBtn.x = 540;
         openShopBtn.y = yPos + 8;
         openShopBtn["shopId"] = shopId;
         openShopBtn.addEventListener("mouseDown",onOpenShopClick,false,0,true);
         _itemListContainer.addChild(openShopBtn);
      }
      
      private function onOpenShopClick(event:MouseEvent) : void
      {
         var button:MovieClip;
         var shopId:int;
         var wasShopOpen:Boolean;
         event.stopPropagation();
         button = event.currentTarget as MovieClip;
         if(button && button["shopId"])
         {
            shopId = int(button["shopId"]);
            try
            {
               wasShopOpen = ShopManager.isWorldShopOpen();
               ShopManager.launchDenShopStore(shopId);
               if(!wasShopOpen)
               {
                  _popup.addEventListener(Event.ENTER_FRAME,checkShopClosed,false,0,true);
               }
            }
            catch(error:Error)
            {
               showMessage("Error opening shop: " + error.message);
            }
         }
      }
      
      private function checkShopClosed(e:Event) : void
      {
         if(_isDestroyed || !_popup)
         {
            if(_popup)
            {
               _popup.removeEventListener(Event.ENTER_FRAME,checkShopClosed);
            }
            return;
         }
         if(!ShopManager.isWorldShopOpen())
         {
            _popup.removeEventListener(Event.ENTER_FRAME,checkShopClosed);
            GuiManager.refreshShopExplorerPopup();
         }
      }
      
      public function refreshAndActivate() : void
      {
         var closeBtnChildren:int;
         var i:int;
         var child:*;
         var self:ShopExplorerPopup;
         try
         {
            if(_popup && _popup.parent && !_isDestroyed)
            {
               GuiManager.guiLayer.setChildIndex(_popup,GuiManager.guiLayer.numChildren - 1);
               DarkenManager.unDarken(_popup);
               DarkenManager.darken(_popup);
               _popup.mouseEnabled = true;
               _popup.mouseChildren = true;
               _popup.visible = true;
               if(_popup.closeBtn)
               {
                  _popup.closeBtn.mouseEnabled = true;
                  _popup.closeBtn.mouseChildren = true;
                  _popup.closeBtn.buttonMode = true;
                  _popup.closeBtn.visible = true;
                  _popup.closeBtn.tabEnabled = false;
                  closeBtnChildren = int(_popup.closeBtn.numChildren);
                  i = 0;
                  while(i < closeBtnChildren)
                  {
                     child = _popup.closeBtn.getChildAt(i);
                     if(child)
                     {
                        child.mouseEnabled = false;
                     }
                     i++;
                  }
                  _popup.closeBtn.removeEventListener("mouseDown",onCloseButtonClick);
                  _popup.closeBtn.removeEventListener("click",onCloseButtonClick);
                  self = this;
                  _popup.closeBtn.addEventListener("mouseDown",onCloseButtonClick,false,0,true);
                  _popup.closeBtn.addEventListener("click",onCloseButtonClick,false,0,true);
               }
               if(_itemListContainer)
               {
                  _itemListContainer.mouseEnabled = true;
                  _itemListContainer.mouseChildren = true;
               }
               if(_scrollUpBtn)
               {
                  _scrollUpBtn.mouseEnabled = true;
               }
               if(_scrollDownBtn)
               {
                  _scrollDownBtn.mouseEnabled = true;
               }
            }
         }
         catch(e:Error)
         {
         }
      }
      
      private function onCloseButtonClick(e:MouseEvent) : void
      {
         e.stopPropagation();
         destroy();
      }
      
      private function createCloseXButton() : MovieClip
      {
         var xTxt:TextField;
         var xFormat:TextFormat;
         var self:ShopExplorerPopup;
         var btn:MovieClip = new MovieClip();
         var bgShape:Shape = new Shape();
         bgShape.graphics.beginFill(16007990,0.8);
         bgShape.graphics.drawRoundRect(0,0,30,30,5,5);
         bgShape.graphics.endFill();
         bgShape.graphics.lineStyle(2,16777215,1);
         bgShape.graphics.drawRoundRect(0,0,30,30,5,5);
         btn.addChild(bgShape);
         xTxt = new TextField();
         xTxt.text = "×";
         xTxt.textColor = 16777215;
         xFormat = new TextFormat();
         xFormat.size = 24;
         xFormat.bold = true;
         xFormat.align = "center";
         xTxt.setTextFormat(xFormat);
         xTxt.x = 0;
         xTxt.y = 2;
         xTxt.width = 30;
         xTxt.height = 30;
         xTxt.selectable = false;
         xTxt.mouseEnabled = false;
         btn.addChild(xTxt);
         btn.buttonMode = true;
         btn.mouseChildren = true;
         btn.mouseEnabled = true;
         xTxt.mouseEnabled = false;
         self = this;
         btn.addEventListener("mouseDown",self.onCloseButtonClick,false,0,true);
         btn.addEventListener("click",self.onCloseButtonClick,false,0,true);
         btn.addEventListener("mouseOver",function(e:MouseEvent):void
         {
            bgShape.graphics.clear();
            bgShape.graphics.beginFill(16007990,1);
            bgShape.graphics.drawRoundRect(0,0,30,30,5,5);
            bgShape.graphics.endFill();
            bgShape.graphics.lineStyle(2,16777215,1);
            bgShape.graphics.drawRoundRect(0,0,30,30,5,5);
         },false,0,true);
         btn.addEventListener("mouseOut",function(e:MouseEvent):void
         {
            bgShape.graphics.clear();
            bgShape.graphics.beginFill(16007990,0.8);
            bgShape.graphics.drawRoundRect(0,0,30,30,5,5);
            bgShape.graphics.endFill();
            bgShape.graphics.lineStyle(2,16777215,1);
            bgShape.graphics.drawRoundRect(0,0,30,30,5,5);
         },false,0,true);
         return btn;
      }
      
      private function onSearchTextChanged(event:Event) : void
      {
         filterItems(_searchField.text);
         _scrollPosition = 0;
         updateDisplay();
      }
      
      private function onClearSearch(event:MouseEvent) : void
      {
         event.stopPropagation();
         _searchField.text = "";
         filterItems("");
         _scrollPosition = 0;
         updateDisplay();
      }
      
      private function scrollUp() : void
      {
         if(_scrollPosition > 0)
         {
            --_scrollPosition;
            _itemListContainer.y = -210 - _scrollPosition * _entryHeight;
            updateScrollButtons();
         }
      }
      
      private function scrollDown() : void
      {
         var maxScroll:int = Math.max(0,_filteredItems.length - _maxVisibleEntries + 1);
         if(_scrollPosition < maxScroll)
         {
            ++_scrollPosition;
            _itemListContainer.y = -210 - _scrollPosition * _entryHeight;
            updateScrollButtons();
         }
      }
      
      private function onMouseWheel(e:MouseEvent) : void
      {
         if(!_popup || !_popup.visible || !_popup.parent)
         {
            return;
         }
         e.stopPropagation();
         var delta:int = e.delta > 0 ? -1 : 1;
         if(delta < 0)
         {
            scrollUp();
         }
         else
         {
            scrollDown();
         }
      }
      
      private function onScrollUp(event:MouseEvent) : void
      {
         event.stopPropagation();
         scrollUp();
      }
      
      private function onScrollDown(event:MouseEvent) : void
      {
         event.stopPropagation();
         scrollDown();
      }
      
      private function updateScrollButtons() : void
      {
         var maxScroll:int = Math.max(0,_filteredItems.length - _maxVisibleEntries + 1);
         if(_scrollUpBtn)
         {
            _scrollUpBtn.alpha = _scrollPosition > 0 ? 1 : 0.5;
            _scrollUpBtn.mouseEnabled = _scrollPosition > 0;
         }
         if(_scrollDownBtn)
         {
            _scrollDownBtn.alpha = _scrollPosition < maxScroll ? 1 : 0.5;
            _scrollDownBtn.mouseEnabled = _scrollPosition < maxScroll;
         }
      }
      
      private function createButton(label:String, color:uint, width:int) : MovieClip
      {
         var btn:MovieClip = new MovieClip();
         btn.graphics.beginFill(color,0.9);
         btn.graphics.drawRoundRect(0,0,width,28,5,5);
         btn.graphics.endFill();
         btn.graphics.lineStyle(2,16777215,0.5);
         btn.graphics.drawRoundRect(0,0,width,28,5,5);
         var btnTxt:TextField = new TextField();
         btnTxt.text = label;
         btnTxt.textColor = 16777215;
         var btnFormat:TextFormat = new TextFormat();
         btnFormat.size = 12;
         btnFormat.bold = true;
         btnFormat.align = "center";
         btnTxt.setTextFormat(btnFormat);
         btnTxt.x = 5;
         btnTxt.y = 6;
         btnTxt.width = width - 10;
         btnTxt.height = 20;
         btnTxt.selectable = false;
         btnTxt.mouseEnabled = false;
         btn.addChild(btnTxt);
         btn.buttonMode = true;
         btn.mouseChildren = false;
         btn.mouseEnabled = true;
         return btn;
      }
      
      private function showMessage(message:String) : void
      {
         if(!_itemListContainer)
         {
            return;
         }
         var msgTxt:TextField = new TextField();
         msgTxt.text = message;
         msgTxt.textColor = 16777215;
         msgTxt.x = -300;
         msgTxt.y = -50;
         msgTxt.width = 600;
         msgTxt.height = 100;
         msgTxt.selectable = false;
         msgTxt.multiline = true;
         msgTxt.wordWrap = true;
         var msgFormat:TextFormat = new TextFormat();
         msgFormat.size = 14;
         msgFormat.align = "center";
         msgTxt.setTextFormat(msgFormat);
         _itemListContainer.addChild(msgTxt);
      }
      
      private function addEventListeners() : void
      {
         _popup.addEventListener("mouseDown",onPopupClick,false,0,true);
         if(_itemListContainer)
         {
            _itemListContainer.addEventListener("mouseWheel",onMouseWheel,false,0,true);
         }
         if(_popup)
         {
            _popup.addEventListener("mouseWheel",onMouseWheel,false,0,true);
         }
         if(gMainFrame && gMainFrame.stage)
         {
            gMainFrame.stage.addEventListener("keyDown",onKeyDown,false,0,true);
         }
      }
      
      private function removeEventListeners() : void
      {
         try
         {
            if(_popup)
            {
               try
               {
                  _popup.removeEventListener("mouseDown",onPopupClick);
                  _popup.removeEventListener("mouseWheel",onMouseWheel);
               }
               catch(e1:Error)
               {
               }
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            if(_itemListContainer)
            {
               try
               {
                  _itemListContainer.removeEventListener("mouseWheel",onMouseWheel);
               }
               catch(e3:Error)
               {
               }
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            if(gMainFrame && gMainFrame.stage)
            {
               try
               {
                  gMainFrame.stage.removeEventListener("keyDown",onKeyDown);
               }
               catch(e2:Error)
               {
               }
            }
         }
         catch(e:Error)
         {
         }
      }
      
      private function onPopupClick(event:MouseEvent) : void
      {
         var target:* = event.target;
         var bg:* = null;
         if(_popup && _popup.numChildren > 0)
         {
            bg = _popup.getChildAt(0);
         }
         if(target == _popup || target == bg)
         {
            event.stopPropagation();
         }
      }
      
      private function onKeyDown(event:KeyboardEvent) : void
      {
         if(event.keyCode == 27)
         {
            destroy();
         }
      }
      
      public function destroy() : void
      {
         var tempCallback:Function;
         if(_isDestroyed)
         {
            return;
         }
         _isDestroyed = true;
         if(_activeInstance == this)
         {
            _activeInstance = null;
         }
         stopQueue();
         try
         {
            if(_popup)
            {
               _popup.removeEventListener(Event.ENTER_FRAME,checkShopClosed);
            }
         }
         catch(e:Error)
         {
         }
         tempCallback = null;
         try
         {
            if(_closeCallback != null)
            {
               tempCallback = _closeCallback;
               _closeCallback = null;
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            removeEventListeners();
         }
         catch(e:Error)
         {
         }
         try
         {
            if(_popup)
            {
               try
               {
                  if(DarkenManager)
                  {
                     DarkenManager.unDarken(_popup);
                  }
               }
               catch(darkenError:Error)
               {
               }
               try
               {
                  if(_popup.parent)
                  {
                     _popup.parent.removeChild(_popup);
                  }
               }
               catch(removeError:Error)
               {
               }
            }
         }
         catch(e:Error)
         {
         }
         _popup = null;
         _shopDataMap = null;
         _allItems = null;
         _filteredItems = null;
         if(tempCallback != null)
         {
            try
            {
               tempCallback();
            }
            catch(callbackError:Error)
            {
            }
         }
      }
   }
}

