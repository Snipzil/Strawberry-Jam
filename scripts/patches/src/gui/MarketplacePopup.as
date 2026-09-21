package gui
{
   import avatar.Avatar;
   import avatar.AvatarInfo;
   import avatar.AvatarManager;
   import avatar.UserInfo;
   import buddy.BuddyManager;
   import collection.IitemCollection;
   import com.sbi.popup.SBOkPopup;
   import den.DenItem;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import inventory.Iitem;
   import item.Item;
   import pet.PetItem;
   import trade.TradeXtCommManager;
   
   public class MarketplacePopup
   {
      
      private var _marketplacePopup:MovieClip;
      
      private var _closeCallback:Function;
      
      private var _allTradeItems:Array;
      
      private var _filteredTradeItems:Array;
      
      private var _itemListContainer:MovieClip;
      
      private var _itemListMask:Sprite;
      
      private var _scrollUpBtn:MovieClip;
      
      private var _scrollDownBtn:MovieClip;
      
      private var _scrollPosition:int = 0;
      
      private var _maxVisibleEntries:int = 10;
      
      private var _entryHeight:int = 40;
      
      private var _searchField:TextField;
      
      private var _usersInRoom:Array;
      
      private var _pendingTradeRequests:Object;
      
      private var _receivedTradeLists:Object;
      
      private var _requestsCompleted:int = 0;
      
      private var _totalRequests:int = 0;
      
      public function MarketplacePopup(param1:Function)
      {
         super();
         _closeCallback = param1;
         _allTradeItems = [];
         _filteredTradeItems = [];
         _usersInRoom = [];
         _pendingTradeRequests = {};
         _receivedTradeLists = {};
         DarkenManager.showLoadingSpiral(true);
         scanUsersAndRequestTradeLists();
         createMarketplaceInterface();
      }
      
      private function scanUsersAndRequestTradeLists() : void
      {
         for(var sfsUserId in AvatarManager.avatarList)
         {
            var avatar:Avatar = AvatarManager.avatarList[sfsUserId];
            if(avatar.userName != gMainFrame.userInfo.myUserName)
            {
               var userInfo:UserInfo = gMainFrame.userInfo.getUserInfoByUserName(avatar.userName);
               var avatarInfo:AvatarInfo = gMainFrame.userInfo.getAvatarInfoByUserName(avatar.userName);
               if(userInfo && avatarInfo)
               {
                  _usersInRoom.push({
                     "username":avatar.userName,
                     "avatarName":avatar.avName,
                     "userInfo":userInfo,
                     "avatarInfo":avatarInfo,
                     "sfsUserId":sfsUserId
                  });
               }
            }
         }
         _totalRequests = _usersInRoom.length;
         if(_totalRequests > 0)
         {
            for each(var userData in _usersInRoom)
            {
               _pendingTradeRequests[userData.username] = true;
               TradeXtCommManager.sendTradeListRequest(userData.username);
            }
         }
         else
         {
            _requestsCompleted = 0;
            _totalRequests = 0;
         }
      }
      
      public function onTradeListReceived(username:String, tradeList:IitemCollection) : void
      {
         if(_pendingTradeRequests[username])
         {
            _pendingTradeRequests[username] = false;
            _receivedTradeLists[username] = tradeList;
            ++_requestsCompleted;
            addUserTradeItems(username,tradeList);
            updateDisplayWithNewItems();
            updateLoadingStatus();
         }
      }
      
      private function addUserTradeItems(username:String, tradeList:IitemCollection) : void
      {
         if(!tradeList || tradeList.length == 0)
         {
            return;
         }
         var userData:Object = null;
         for each(var user in _usersInRoom)
         {
            if(user.username == username)
            {
               userData = user;
               break;
            }
         }
         if(!userData)
         {
            return;
         }
         var i:int = 0;
         while(i < tradeList.length)
         {
            var item:Iitem = tradeList.getIitem(i);
            if(item && item.isApproved)
            {
               var itemType:String = "Unknown";
               var itemRarity:String = "Common";
               if(item is Item)
               {
                  itemType = "Clothing";
                  itemRarity = determineItemRarity(item as Item);
               }
               else if(item is DenItem)
               {
                  itemType = "Den Item";
                  itemRarity = determineItemRarity(item as DenItem);
               }
               else if(item is PetItem)
               {
                  itemType = "Pet";
                  itemRarity = determineItemRarity(item as PetItem);
               }
               _allTradeItems.push({
                  "itemName":item.name || "Unknown Item",
                  "itemType":itemType,
                  "itemRarity":itemRarity,
                  "ownerUsername":username,
                  "ownerAvatarName":userData.avatarName,
                  "ownerAvatarInfo":userData.avatarInfo,
                  "actualItem":item
               });
            }
            i++;
         }
      }
      
      private function determineItemRarity(item:Iitem) : String
      {
         if(item.defId)
         {
            return "Rare";
         }
         return "Common";
      }
      
      private function updateDisplayWithNewItems() : void
      {
         if(_searchField && _searchField.text.length > 0)
         {
            performSearch();
         }
         else
         {
            _filteredTradeItems = _allTradeItems.concat();
            populateItemList();
         }
      }
      
      private function updateLoadingStatus() : void
      {
         if(_marketplacePopup && _marketplacePopup.countTxt)
         {
            if(_requestsCompleted < _totalRequests)
            {
               _marketplacePopup.countTxt.text = "Loading trade lists... (" + _requestsCompleted + "/" + _totalRequests + ")";
            }
            else
            {
               _marketplacePopup.countTxt.text = "Found " + _allTradeItems.length + " items for trade";
               DarkenManager.showLoadingSpiral(false);
            }
         }
      }
      
      private function createMarketplaceInterface() : void
      {
         var titleTxt:TextField;
         var titleFormat:TextFormat;
         var descTxt:TextField;
         var descFormat:TextFormat;
         var countTxt:TextField;
         var countFormat:TextFormat;
         var searchLabel:TextField;
         var searchFormat:TextFormat;
         var searchBtn:MovieClip;
         var clearBtn:MovieClip;
         var closeBtn:MovieClip;
         _marketplacePopup = new MovieClip();
         var bg:MovieClip = ModMenuUIHelper.createPopupBackground(700,550,0.9);
         bg.x = -350;
         bg.y = -275;
         _marketplacePopup.addChild(bg);
         titleTxt = new TextField();
         titleTxt.text = "Room Marketplace";
         titleTxt.textColor = 16777215;
         titleTxt.x = -270;
         titleTxt.y = -255;
         titleTxt.width = 540;
         titleTxt.height = 40;
         titleTxt.selectable = false;
         titleFormat = new TextFormat();
         titleFormat.size = 24;
         titleFormat.bold = true;
         titleFormat.align = "center";
         titleTxt.setTextFormat(titleFormat);
         _marketplacePopup.addChild(titleTxt);
         descTxt = new TextField();
         descTxt.text = "Browse all items available for trade in this room!";
         descTxt.textColor = ModMenuUIHelper.COLOR_TEXT_DIM;
         descTxt.x = -300;
         descTxt.y = -215;
         descTxt.width = 600;
         descTxt.height = 25;
         descTxt.selectable = false;
         descFormat = new TextFormat();
         descFormat.size = 14;
         descFormat.align = "center";
         descTxt.setTextFormat(descFormat);
         _marketplacePopup.addChild(descTxt);
         countTxt = new TextField();
         countTxt.text = _totalRequests > 0 ? "Loading trade lists... (0/" + _totalRequests + ")" : "No other players in room";
         countTxt.textColor = 15267304;
         countTxt.x = -250;
         countTxt.y = -195;
         countTxt.width = 500;
         countTxt.height = 20;
         countTxt.selectable = false;
         countFormat = new TextFormat();
         countFormat.size = 12;
         countFormat.align = "center";
         countTxt.setTextFormat(countFormat);
         _marketplacePopup.addChild(countTxt);
         _marketplacePopup.countTxt = countTxt;
         _searchField = new TextField();
         _searchField.type = "input";
         _searchField.border = true;
         _searchField.borderColor = ModMenuUIHelper.COLOR_BORDER;
         _searchField.background = true;
         _searchField.backgroundColor = 1118481;
         _searchField.textColor = ModMenuUIHelper.COLOR_TEXT;
         _searchField.x = -200;
         _searchField.y = -165;
         _searchField.width = 300;
         _searchField.height = 25;
         _searchField.maxChars = 50;
         _searchField.text = "";
         _marketplacePopup.addChild(_searchField);
         searchLabel = new TextField();
         searchLabel.text = "Search for items (e.g., \'Headdress\', \'Spike\', \'Beta\')";
         searchLabel.textColor = 16777215;
         searchLabel.x = -200;
         searchLabel.y = -185;
         searchLabel.width = 300;
         searchLabel.height = 20;
         searchLabel.selectable = false;
         searchFormat = new TextFormat();
         searchFormat.size = 11;
         searchFormat.align = "left";
         searchLabel.setTextFormat(searchFormat);
         _marketplacePopup.addChild(searchLabel);
         searchBtn = ModMenuUIHelper.createButton("Search",5025616,80);
         searchBtn.x = 110;
         searchBtn.y = -165;
         searchBtn.addEventListener("mouseDown",onSearchBtn,false,0,true);
         _marketplacePopup.addChild(searchBtn);
         _marketplacePopup.searchBtn = searchBtn;
         clearBtn = ModMenuUIHelper.createButton("Clear",16750592,70);
         clearBtn.x = 200;
         clearBtn.y = -165;
         clearBtn.addEventListener("mouseDown",onClearSearch,false,0,true);
         _marketplacePopup.addChild(clearBtn);
         _marketplacePopup.clearBtn = clearBtn;
         createScrollableItemList();
         try
         {
            closeBtn = ModMenuUIHelper.createCloseXButton();
            closeBtn.x = 315;
            closeBtn.y = -255;
            closeBtn.addEventListener("mouseDown",onCloseBtn,false,0,true);
            closeBtn.addEventListener("click",onCloseBtn,false,0,true);
            _marketplacePopup.closeBtn = closeBtn;
            _marketplacePopup.addChild(closeBtn);
         }
         catch(closeBtnError:Error)
         {
         }
         _marketplacePopup.x = 450;
         _marketplacePopup.y = 275;
         GuiManager.guiLayer.addChild(_marketplacePopup);
         DarkenManager.darken(_marketplacePopup);
         try
         {
            gMainFrame.stage.focus = _searchField;
         }
         catch(e:Error)
         {
         }
         addEventListeners();
         populateItemList();
         if(_totalRequests == 0)
         {
            DarkenManager.showLoadingSpiral(false);
         }
      }
      
      private function createScrollableItemList() : void
      {
         _itemListContainer = new MovieClip();
         _itemListContainer.x = -330;
         _itemListContainer.y = -130;
         _marketplacePopup.addChild(_itemListContainer);
         _itemListMask = new Sprite();
         _itemListMask.graphics.beginFill(16711680,0);
         _itemListMask.graphics.drawRect(-330,-130,660,_maxVisibleEntries * _entryHeight);
         _itemListMask.graphics.endFill();
         _marketplacePopup.addChild(_itemListMask);
         _itemListContainer.mask = _itemListMask;
         _scrollUpBtn = ModMenuUIHelper.createButton("▲",6710886,30);
         _scrollUpBtn.x = 300;
         _scrollUpBtn.y = -130;
         _scrollUpBtn.addEventListener("mouseDown",onScrollUp,false,0,true);
         _marketplacePopup.addChild(_scrollUpBtn);
         _scrollDownBtn = ModMenuUIHelper.createButton("▼",6710886,30);
         _scrollDownBtn.x = 300;
         _scrollDownBtn.y = 220;
         _scrollDownBtn.addEventListener("mouseDown",onScrollDown,false,0,true);
         _marketplacePopup.addChild(_scrollDownBtn);
         updateScrollButtons();
      }
      
      private function populateItemList() : void
      {
         while(_itemListContainer.numChildren > 0)
         {
            _itemListContainer.removeChildAt(0);
         }
         var yPos:int = 0;
         var entryCount:int = 0;
         createItemListHeader(yPos);
         yPos += 30;
         if(_filteredTradeItems.length == 0)
         {
            var noResultsTxt:TextField = new TextField();
            if(_totalRequests == 0)
            {
               noResultsTxt.text = "No other players in this room.";
            }
            else if(_requestsCompleted < _totalRequests)
            {
               noResultsTxt.text = "Loading trade lists from " + _totalRequests + " players...";
            }
            else if(_allTradeItems.length == 0)
            {
               noResultsTxt.text = "No items for trade found in this room.";
            }
            else
            {
               noResultsTxt.text = "No items match your search.";
            }
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
            for each(var itemData in _filteredTradeItems)
            {
               createItemEntry(itemData,yPos);
               yPos += _entryHeight;
               entryCount++;
            }
         }
         if(_requestsCompleted >= _totalRequests)
         {
            _marketplacePopup.countTxt.text = "Showing " + _filteredTradeItems.length + " of " + _allTradeItems.length + " items";
         }
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
         headerTxt.text = "Item Name               Type        Rarity     Owner                    Actions";
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
      
      private function createItemEntry(itemData:Object, yPos:int) : void
      {
         var entryBg:MovieClip = new MovieClip();
         var bgColor:uint = Math.floor(yPos / _entryHeight) % 2 == 0 ? ModMenuUIHelper.COLOR_ROW_EVEN : ModMenuUIHelper.COLOR_ROW_ODD;
         entryBg.graphics.beginFill(bgColor,0.5);
         entryBg.graphics.drawRoundRect(0,0,660,_entryHeight - 3,ModMenuUIHelper.CORNER_RADIUS_SM,ModMenuUIHelper.CORNER_RADIUS_SM);
         entryBg.graphics.endFill();
         entryBg.graphics.lineStyle(1,ModMenuUIHelper.COLOR_BORDER,0.2);
         entryBg.graphics.drawRoundRect(0,0,660,_entryHeight - 3,ModMenuUIHelper.CORNER_RADIUS_SM,ModMenuUIHelper.CORNER_RADIUS_SM);
         entryBg.y = yPos;
         _itemListContainer.addChild(entryBg);
         var itemNameTxt:TextField = new TextField();
         itemNameTxt.text = itemData.itemName;
         itemNameTxt.textColor = 16777215;
         itemNameTxt.x = 10;
         itemNameTxt.y = yPos + 3;
         itemNameTxt.width = 140;
         itemNameTxt.height = 20;
         itemNameTxt.selectable = false;
         var itemNameFormat:TextFormat = new TextFormat();
         itemNameFormat.size = 11;
         itemNameFormat.bold = true;
         itemNameTxt.setTextFormat(itemNameFormat);
         _itemListContainer.addChild(itemNameTxt);
         var typeTxt:TextField = new TextField();
         typeTxt.text = itemData.itemType;
         typeTxt.textColor = 15267304;
         typeTxt.x = 160;
         typeTxt.y = yPos + 3;
         typeTxt.width = 80;
         typeTxt.height = 20;
         typeTxt.selectable = false;
         var typeFormat:TextFormat = new TextFormat();
         typeFormat.size = 10;
         typeTxt.setTextFormat(typeFormat);
         _itemListContainer.addChild(typeTxt);
         var rarityTxt:TextField = new TextField();
         rarityTxt.text = itemData.itemRarity;
         var rarityColor:uint = getRarityColor(itemData.itemRarity);
         rarityTxt.textColor = rarityColor;
         rarityTxt.x = 250;
         rarityTxt.y = yPos + 3;
         rarityTxt.width = 70;
         rarityTxt.height = 20;
         rarityTxt.selectable = false;
         var rarityFormat:TextFormat = new TextFormat();
         rarityFormat.size = 10;
         rarityFormat.bold = true;
         rarityTxt.setTextFormat(rarityFormat);
         _itemListContainer.addChild(rarityTxt);
         var ownerTxt:TextField = new TextField();
         ownerTxt.text = itemData.ownerUsername;
         ownerTxt.textColor = 16777215;
         ownerTxt.x = 330;
         ownerTxt.y = yPos + 3;
         ownerTxt.width = 120;
         ownerTxt.height = 20;
         ownerTxt.selectable = false;
         var ownerFormat:TextFormat = new TextFormat();
         ownerFormat.size = 11;
         ownerTxt.setTextFormat(ownerFormat);
         _itemListContainer.addChild(ownerTxt);
         var avatarTxt:TextField = new TextField();
         avatarTxt.text = "(" + itemData.ownerAvatarName + ")";
         avatarTxt.textColor = 13428172;
         avatarTxt.x = 330;
         avatarTxt.y = yPos + 18;
         avatarTxt.width = 120;
         avatarTxt.height = 16;
         avatarTxt.selectable = false;
         var avatarFormat:TextFormat = new TextFormat();
         avatarFormat.size = 9;
         avatarTxt.setTextFormat(avatarFormat);
         _itemListContainer.addChild(avatarTxt);
         var tradeBtn:MovieClip = ModMenuUIHelper.createButton("Trade For",2201331,80);
         tradeBtn.x = 460;
         tradeBtn.y = yPos + 5;
         tradeBtn.userData = itemData;
         tradeBtn.addEventListener("mouseDown",onTradeForItem,false,0,true);
         _itemListContainer.addChild(tradeBtn);
         var viewUserBtn:MovieClip = ModMenuUIHelper.createButton("View User",16750592,75);
         viewUserBtn.x = 550;
         viewUserBtn.y = yPos + 5;
         viewUserBtn.userData = itemData;
         viewUserBtn.addEventListener("mouseDown",onViewUser,false,0,true);
         _itemListContainer.addChild(viewUserBtn);
      }
      
      private function getRarityColor(rarity:String) : uint
      {
         switch(rarity.toLowerCase())
         {
            case "common":
               return 15263976;
            case "uncommon":
               return 9498256;
            case "rare":
               return 8900331;
            case "beta":
               return 14315734;
            case "legendary":
               return 16766720;
            default:
               return 16777215;
         }
      }
      
      private function addEventListeners() : void
      {
         _marketplacePopup.addEventListener("mouseDown",onPopup,false,0,true);
         _marketplacePopup.closeBtn.addEventListener("mouseDown",onCloseBtn,false,0,true);
         _searchField.addEventListener("keyDown",onSearchKeyDown,false,0,true);
      }
      
      private function removeEventListeners() : void
      {
         if(_marketplacePopup)
         {
            _marketplacePopup.removeEventListener("mouseDown",onPopup);
            if(_marketplacePopup.closeBtn)
            {
               _marketplacePopup.closeBtn.removeEventListener("mouseDown",onCloseBtn);
               _marketplacePopup.closeBtn.removeEventListener("click",onCloseBtn);
            }
            if(_marketplacePopup.searchBtn)
            {
               _marketplacePopup.searchBtn.removeEventListener("mouseDown",onSearchBtn);
            }
            if(_marketplacePopup.clearBtn)
            {
               _marketplacePopup.clearBtn.removeEventListener("mouseDown",onClearSearch);
            }
            if(_searchField)
            {
               _searchField.removeEventListener("keyDown",onSearchKeyDown);
            }
            if(_scrollUpBtn)
            {
               _scrollUpBtn.removeEventListener("mouseDown",onScrollUp);
            }
            if(_scrollDownBtn)
            {
               _scrollDownBtn.removeEventListener("mouseDown",onScrollDown);
            }
            if(_itemListContainer)
            {
               var i:int = 0;
               while(i < _itemListContainer.numChildren)
               {
                  var child:* = _itemListContainer.getChildAt(i);
                  if(child && child.hasEventListener && child.hasEventListener("mouseDown"))
                  {
                     child.removeEventListener("mouseDown",onTradeForItem);
                     child.removeEventListener("mouseDown",onViewUser);
                  }
                  i++;
               }
            }
         }
      }
      
      private function onPopup(param1:MouseEvent) : void
      {
         param1.stopPropagation();
      }
      
      private function onCloseBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         destroy();
      }
      
      private function onSearchKeyDown(param1:KeyboardEvent) : void
      {
         param1.stopPropagation();
         if(param1.keyCode == 13)
         {
            performSearch();
         }
         else if(param1.keyCode == 27)
         {
            destroy();
         }
      }
      
      private function onSearchBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         performSearch();
      }
      
      private function onClearSearch(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         _searchField.text = "";
         performSearch();
      }
      
      private function performSearch() : void
      {
         var searchTerm:String = _searchField.text;
         while(searchTerm.length > 0 && (searchTerm.charAt(0) == " " || searchTerm.charAt(0) == "\t"))
         {
            searchTerm = searchTerm.substring(1);
         }
         while(searchTerm.length > 0 && (searchTerm.charAt(searchTerm.length - 1) == " " || searchTerm.charAt(searchTerm.length - 1) == "\t"))
         {
            searchTerm = searchTerm.substring(0,searchTerm.length - 1);
         }
         if(searchTerm.length == 0)
         {
            _filteredTradeItems = _allTradeItems.concat();
         }
         else
         {
            _filteredTradeItems = [];
            for each(var itemData in _allTradeItems)
            {
               if(itemData.itemName.toLowerCase().indexOf(searchTerm.toLowerCase()) >= 0 || itemData.itemType.toLowerCase().indexOf(searchTerm.toLowerCase()) >= 0 || itemData.itemRarity.toLowerCase().indexOf(searchTerm.toLowerCase()) >= 0)
               {
                  _filteredTradeItems.push(itemData);
               }
            }
         }
         _scrollPosition = 0;
         populateItemList();
      }
      
      private function scrollUp() : void
      {
         if(_scrollPosition > 0)
         {
            --_scrollPosition;
            _itemListContainer.y = -130 - _scrollPosition * _entryHeight;
            updateScrollButtons();
         }
      }
      
      private function scrollDown() : void
      {
         var maxScroll:int = Math.max(0,_filteredTradeItems.length - _maxVisibleEntries + 1);
         if(_scrollPosition < maxScroll)
         {
            ++_scrollPosition;
            _itemListContainer.y = -130 - _scrollPosition * _entryHeight;
            updateScrollButtons();
         }
      }
      
      private function updateScrollButtons() : void
      {
         if(_scrollUpBtn)
         {
            _scrollUpBtn.alpha = _scrollPosition > 0 ? 1 : 0.5;
         }
         if(_scrollDownBtn)
         {
            var maxScroll:int = Math.max(0,_filteredTradeItems.length - _maxVisibleEntries + 1);
            _scrollDownBtn.alpha = _scrollPosition < maxScroll ? 1 : 0.5;
         }
      }
      
      private function onScrollUp(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         scrollUp();
      }
      
      private function onScrollDown(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         scrollDown();
      }
      
      private function onTradeForItem(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         var itemData:Object = param1.currentTarget.userData;
         if(itemData && itemData.ownerUsername)
         {
            new SBOkPopup(gMainFrame.stage,"To trade for \'" + itemData.itemName + "\' from " + itemData.ownerUsername + ", you\'ll need to open their buddy card and view their trade list to initiate a trade for this specific item.",false);
            BuddyManager.showBuddyCard({
               "userName":itemData.ownerUsername,
               "onlineStatus":1
            });
         }
      }
      
      private function onViewUser(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         var itemData:Object = param1.currentTarget.userData;
         if(itemData && itemData.ownerUsername)
         {
            BuddyManager.showBuddyCard({
               "userName":itemData.ownerUsername,
               "onlineStatus":1
            });
         }
      }
      
      public function destroy() : void
      {
         var tempCallback:Function;
         try
         {
            removeEventListeners();
            if(_marketplacePopup && _marketplacePopup.parent)
            {
               DarkenManager.unDarken(_marketplacePopup);
               _marketplacePopup.parent.removeChild(_marketplacePopup);
            }
            _marketplacePopup = null;
            _allTradeItems = null;
            _filteredTradeItems = null;
            _usersInRoom = null;
            _pendingTradeRequests = null;
            _receivedTradeLists = null;
            if(_closeCallback != null)
            {
               tempCallback = _closeCallback;
               _closeCallback = null;
               tempCallback();
            }
         }
         catch(error:Error)
         {
         }
      }
   }
}

