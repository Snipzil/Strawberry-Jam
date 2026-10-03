package gui
{
   import Enums.TradeItem;
   import collection.AccItemCollection;
   import collection.DenItemCollection;
   import collection.IitemCollection;
   import collection.PetItemCollection;
   import collection.TradeItemCollection;
   import com.sbi.debug.DebugUtility;
   import com.sbi.popup.SBOkPopup;
   import com.sbi.popup.SBYesNoPopup;
   import den.DenItem;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import gui.itemWindows.ItemWindowOriginal;
   import inventory.Iitem;
   import item.Item;
   import loader.MediaHelper;
   import localization.LocalizationManager;
   import pet.GuiPet;
   import pet.PetItem;
   import pet.PetManager;
   import shop.MyShopData;
   import shop.MyShopItem;
   import shop.ShopManager;
   import shop.ShopToSellXtCommManager;
   
   public class DenAndClothesItemSelect
   {
      
      public static const TYPE_TRADE:int = 0;
      
      public static const TYPE_ECARD:int = 1;
      
      public static const TYPE_DEN_SHOP:int = 2;
      
      public static const TYPE_TRADE_INITIATION:int = 3;
      
      private static var LAST_VIEWED_TYPE:int = 0;
      
      private const POPUP_MEDIA_ID:int = 4616;
      
      private const WIN_DOWN_STATE:int = 3;
      
      private const NUM_X_WIN:int = 3;
      
      private const NUM_Y_WIN:int = 4;
      
      private const X_WIN_OFFSET:Number = 2;
      
      private const Y_WIN_OFFSET:Number = 2;
      
      private const X_WIN_START:Number = 0;
      
      private const SCROLLBAR_GAP:int = 2;
      
      private const CLOTHING_VIEW_TYPE:int = 0;
      
      private const DEN_VIEW_TYPE:int = 1;
      
      private const PET_VIEW_TYPE:int = 2;
      
      private var _normalClothesScrollValue:Number = 0;
      
      private var _normalDenScrollValue:Number = 0;
      
      private var _normalPetScrollValue:Number = 0;
      
      private var _eCardClothesScrollValue:Number = 0;
      
      private var _eCardDenScrollValue:Number = 0;
      
      private var _tradeClothesScrollValue:Number = 0;
      
      private var _tradeDenScrollvalue:Number = 0;
      
      private var _tradePetScrollValue:Number = 0;
      
      private var _normalListViewType:int = 0;
      
      private var _eCardListViewType:int = 0;
      
      private var _tradeListViewType:int = 1;
      
      private var _normalDenListSortType:int = 2;
      
      private var _normalClothingListSortType:int = 2;
      
      private var _eCardDenListSortType:int = 2;
      
      private var _eCardClothingListSortType:int = 2;
      
      private var _tradeDenListSortType:int = 2;
      
      private var _tradeClothingListSortType:int = 2;
      
      private var _normalClothingSearchText:String = "";
      
      private var _normalDenSearchText:String = "";
      
      private var _normalPetSearchText:String = "";
      
      private var _eCardClothesSearchText:String = "";
      
      private var _eCardDenSearchText:String = "";
      
      private var _tradeClothesSearchText:String = "";
      
      private var _tradeDenSearchText:String = "";
      
      private var _tradePetSearchText:String = "";
      
      private var _popup:MovieClip;
      
      private var _mediaHelper:MediaHelper;
      
      private var _guiLayer:DisplayLayer;
      
      private var _onCloseCallback:Function;
      
      private var _onGiftBtnCallback:Function;
      
      private var _giftItemIdx:int = -1;
      
      private var _giftDownIdx:int;
      
      private var _type:int;
      
      private var _showPetBtns:Boolean;
      
      private var _itemClothingWindows:WindowAndScrollbarGenerator;
      
      private var _itemDenWindows:WindowAndScrollbarGenerator;
      
      private var _currItemWindow:WindowAndScrollbarGenerator;
      
      private var _itemPetWindows:WindowAndScrollbarGenerator;
      
      private var _headItems:AccItemCollection;
      
      private var _neckItems:AccItemCollection;
      
      private var _backItems:AccItemCollection;
      
      private var _legItems:AccItemCollection;
      
      private var _tailItems:AccItemCollection;
      
      private var _allNewestItems:AccItemCollection;
      
      private var _allOldestItems:AccItemCollection;
      
      private var _currClothesArray:IitemCollection;
      
      private var _currDenItemsArray:IitemCollection;
      
      private var _allOldestDenItems:DenItemCollection;
      
      private var _allNewestDenItems:DenItemCollection;
      
      private var _denItemsGemLow:DenItemCollection;
      
      private var _denItemsGemHigh:DenItemCollection;
      
      private var _denItemsNameLow:DenItemCollection;
      
      private var _denItemsNameHigh:DenItemCollection;
      
      private var _currPetsArray:PetItemCollection;
      
      private var _allPetItems:PetItemCollection;
      
      private var _customInitiationTradeList:TradeItemCollection;
      
      private var _initCustomDenList:IitemCollection;
      
      private var _currDownMC:ItemWindowOriginal = null;
      
      private var _currGiftMC:ItemWindowOriginal = null;
      
      private var _shortTextWidth:Number = 0;
      
      private var _wideTextWidth:Number = 0;
      
      private var _open:Boolean = false;
      
      private var _yesNoPopup:SBYesNoPopup;
      
      private var _lastSelectedIndex:int = -1;
      
      private var _selectedItems:Array = [];
      
      private var _selectedItemsCollection:IitemCollection;
      
      private var _filteredClothesArray:IitemCollection;
      
      private var _filteredDenItemsArray:IitemCollection;
      
      private var _filteredPetsArray:PetItemCollection;
      
      public function DenAndClothesItemSelect()
      {
         super();
      }
      
      private function isItemInOtherShops(item:Iitem) : Boolean
      {
         if(!ShopManager.myShopItems || _type != TYPE_DEN_SHOP)
         {
            return false;
         }
         var currentShopId:int = ShopManager.currentOpenShopId;
         for each(var shopData in ShopManager.myShopItems)
         {
            if(shopData.storeInvId != currentShopId)
            {
               var shopItems:Vector.<MyShopItem> = shopData.shopItems;
               var i:int = 0;
               while(i < shopItems.length)
               {
                  var shopItem:MyShopItem = shopItems[i];
                  if(shopItem.currItem.itemType == item.itemType && shopItem.currItem.defId == item.defId && shopItem.currItem.invIdx == item.invIdx)
                  {
                     return true;
                  }
                  i++;
               }
            }
         }
         return false;
      }
      
      public function init(param1:AccItemCollection, param2:DenItemCollection, param3:PetItemCollection, param4:DisplayLayer, param5:Function, param6:Function, param7:int = 0, param8:TradeItemCollection = null, param9:IitemCollection = null) : void
      {
         DarkenManager.showLoadingSpiral(true);
         _onGiftBtnCallback = param5;
         _onCloseCallback = param6;
         _type = param7;
         _guiLayer = param4;
         _customInitiationTradeList = param8;
         _showPetBtns = _customInitiationTradeList != null || _type == 0 || _type == 2 || _type == 3;
         _selectedItems = [];
         _selectedItemsCollection = new IitemCollection();
         _lastSelectedIndex = -1;
         _currClothesArray = _allNewestItems = param1;
         _currDenItemsArray = _allNewestDenItems = Utility.discardDefaultAudioItem(param2);
         if(_showPetBtns)
         {
            _currPetsArray = param3;
         }
         _initCustomDenList = param9;
         _mediaHelper = new MediaHelper();
         _mediaHelper.init(4616,onPopupLoaded);
      }
      
      public function destroy() : void
      {
         setCachingOptions();
         if(_type == 0 || _type == 3)
         {
            clearSelection();
         }
         if(_popup)
         {
            removeListeners();
            DarkenManager.unDarken(_popup);
            _guiLayer.removeChild(_popup);
            _popup = null;
         }
         if(_itemClothingWindows)
         {
            _itemClothingWindows.destroy();
            _itemClothingWindows = null;
         }
         if(_itemDenWindows)
         {
            _itemDenWindows.destroy();
            _itemDenWindows = null;
         }
         if(_currItemWindow)
         {
            _currItemWindow.destroy();
            _currItemWindow = null;
         }
         if(_yesNoPopup)
         {
            _yesNoPopup.destroy();
            _yesNoPopup = null;
         }
         _onCloseCallback = null;
         _selectedItems = null;
         _selectedItemsCollection = null;
         _filteredClothesArray = null;
         _filteredDenItemsArray = null;
         _filteredPetsArray = null;
      }
      
      public function removeGift() : void
      {
         _giftItemIdx = -1;
         _giftDownIdx = -1;
         if(_currDownMC)
         {
            _currDownMC.resetDownGift();
         }
         if(_currGiftMC)
         {
            _currGiftMC.gift.visible = false;
            _currGiftMC = null;
         }
      }
      
      private function onPopupLoaded(param1:MovieClip) : void
      {
         DarkenManager.showLoadingSpiral(false);
         _popup = param1.getChildAt(0) as MovieClip;
         _popup.x = 900 * 0.5;
         _popup.y = 550 * 0.5;
         _guiLayer.addChild(_popup);
         DarkenManager.darken(_popup);
         setInitialStatesAndVisibility();
         addListeners();
         if(_type == 0 || _type == 3)
         {
            if(_tradeListViewType == 0)
            {
               buildItemWindows(_currClothesArray = convertIntToListClothing(_tradeClothingListSortType));
            }
            else if(_tradeListViewType == 2)
            {
               buildItemWindows((_currPetsArray = PetManager.myPetListAsIitem) as IitemCollection);
            }
            else
            {
               buildItemWindows(_currDenItemsArray = convertIntToListDen(_tradeDenListSortType));
            }
         }
         else if(_type == 1)
         {
            if(_eCardListViewType == 0)
            {
               buildItemWindows(_currClothesArray = convertIntToListClothing(_eCardClothingListSortType));
            }
            else
            {
               buildItemWindows(_currDenItemsArray = convertIntToListDen(_eCardDenListSortType));
            }
         }
         else if(_showPetBtns && _normalListViewType == 2)
         {
            buildItemWindows(_currPetsArray = PetManager.myPetListAsIitem);
         }
         else if(_normalListViewType == 0)
         {
            buildItemWindows(_currClothesArray = convertIntToListClothing(_normalClothingListSortType));
         }
         else
         {
            buildItemWindows(_currDenItemsArray = convertIntToListDen(_normalDenListSortType));
         }
      }
      
      private function setInitialStatesAndVisibility() : void
      {
         var _loc1_:int = 0;
         _popup.denBtnUp.visible = true;
         _popup.denBtnDown.visible = false;
         _popup.clothesBtnUp.visible = false;
         _popup.clothesBtnDown.visible = true;
         _popup.gotoAndStop(_type == 1 ? "addItem" : "selectItem");
         _popup.petsBtnUp.visible = false;
         _popup.petsBtnDown.visible = _showPetBtns;
         _headItems = Utility.sortItemsAll(_currClothesArray,0,8,9,10) as AccItemCollection;
         _neckItems = Utility.sortItemsAll(_currClothesArray,0,7) as AccItemCollection;
         _backItems = Utility.sortItemsAll(_currClothesArray,0,6) as AccItemCollection;
         _legItems = Utility.sortItemsAll(_currClothesArray,0,5) as AccItemCollection;
         _tailItems = Utility.sortItemsAll(_currClothesArray,0,4) as AccItemCollection;
         _allOldestItems = new AccItemCollection();
         _allOldestItems.setCoreArray(_allNewestItems.getCoreArray().concat().reverse());
         if(_type == 0 || _type == 3)
         {
            _loc1_ = _tradeListViewType = LAST_VIEWED_TYPE;
         }
         else if(_type == 1)
         {
            _loc1_ = _eCardListViewType = LAST_VIEWED_TYPE;
         }
         else
         {
            _loc1_ = _normalListViewType = LAST_VIEWED_TYPE;
         }
         if(_type == 0 || _type == 3)
         {
            LocalizationManager.translateId(_popup.clothesTxt,11260);
         }
         else if(_type == 2)
         {
            LocalizationManager.translateId(_popup.clothesTxt,33913);
         }
         if(_loc1_ == 0)
         {
            _popup.denBtnUp.visible = false;
            _popup.denBtnDown.visible = true;
            _popup.clothesBtnUp.visible = true;
            _popup.clothesBtnDown.visible = false;
            if(_showPetBtns)
            {
               _popup.petsBtnUp.visible = false;
               _popup.petsBtnDown.visible = true;
            }
            _popup.sortBtnAccessories.visible = true;
            _popup.sortBtn.visible = false;
            _popup.sortPopupAccessories.sort1.activateSpecifiedItem(true,"time","sort1Dn");
         }
         else if(_showPetBtns && _loc1_ == 2)
         {
            _popup.denBtnUp.visible = false;
            _popup.denBtnDown.visible = true;
            _popup.clothesBtnUp.visible = false;
            _popup.clothesBtnDown.visible = true;
            _popup.petsBtnUp.visible = true;
            _popup.petsBtnDown.visible = false;
            _popup.sortBtnAccessories.visible = false;
            _popup.sortBtn.visible = true;
         }
         else
         {
            _popup.denBtnUp.visible = true;
            _popup.denBtnDown.visible = false;
            _popup.clothesBtnUp.visible = false;
            _popup.clothesBtnDown.visible = true;
            if(_showPetBtns)
            {
               _popup.petsBtnUp.visible = false;
               _popup.petsBtnDown.visible = true;
            }
            _popup.sortBtn.gotoAndStop("timeBtnDn");
            _popup.sortBtnAccessories.visible = false;
            _popup.sortBtn.visible = true;
         }
         _allOldestDenItems = new DenItemCollection();
         _allOldestDenItems.setCoreArray(_allNewestDenItems.getCoreArray().concat().reverse());
         _denItemsGemLow = new DenItemCollection(_allNewestDenItems.getCoreArray().concat().sortOn("value",16));
         _denItemsGemHigh = new DenItemCollection(_denItemsGemLow.getCoreArray().concat().reverse());
         _denItemsNameLow = new DenItemCollection(_allNewestDenItems.getCoreArray().concat().sortOn("name",2));
         _denItemsNameHigh = new DenItemCollection(_denItemsNameLow.getCoreArray().concat().reverse());
         if(_showPetBtns)
         {
            _allPetItems = PetManager.myPetListAsIitem;
         }
         _popup.searchBar.mouse.searchTxt.visible = false;
         _shortTextWidth = _popup.searchBar.mouse.txt.width + 10;
         _wideTextWidth = _popup.searchBar.mouse.searchTxt.width + 10;
         _popup.searchBar.mouse.b.xBtn.visible = false;
         _popup.sortingPopup.visible = false;
         _popup.sortPopupAccessories.visible = false;
      }
      
      private function buildItemWindows(param1:IitemCollection, param2:Boolean = false) : void
      {
         var _loc14_:String;
         var itemAtIndex:Iitem;
         var itemFoundInTrade:Boolean;
         var tradeIdx:int;
         var tradeItem:Iitem;
         var myTradeIdx:int;
         var myTradeItem:TradeItem;
         var itemTypesMatch:Boolean;
         var customDenItem:Iitem;
         var filterIdx:int;
         var filterPetIdx:int;
         var filterDenIdx:int;
         var isAlreadySelected:Boolean;
         var k:int;
         var selectedItem:Iitem;
         var numCols:int;
         var numRows:int;
         var initialWindowCount:int;
         var itemScale:Number;
         var _loc11_:Number = NaN;
         var _loc4_:IitemCollection = null;
         var _loc12_:TradeItemCollection = null;
         var _loc15_:int = 0;
         var _loc3_:Array = null;
         var _loc5_:Array = null;
         var _loc16_:Iitem = null;
         var _loc8_:int = 0;
         var _loc10_:int = 0;
         var _loc13_:Boolean = false;
         var _loc6_:int = 0;
         var _loc9_:int = 0;
         var _loc7_:int = 0;
         while(_popup.itemBlock.numChildren > 1)
         {
            _popup.itemBlock.removeChildAt(_popup.itemBlock.numChildren - 1);
         }
         _loc14_ = "";
         if(_type == 3)
         {
            _loc4_ = gui.TradeManager.initiationTradeList;
            _loc15_ = int(_loc4_.length);
         }
         else if(_type == 0)
         {
            _loc12_ = _customInitiationTradeList ? _customInitiationTradeList : gMainFrame.userInfo.getMyTradeList();
            _loc15_ = int(_loc12_.length);
         }
         if(_type == 1)
         {
            if(_eCardListViewType == 0)
            {
               _loc11_ = _eCardClothesScrollValue;
               _loc14_ = _eCardClothesSearchText;
               _currItemWindow = _itemClothingWindows;
            }
            else
            {
               _loc11_ = _eCardDenScrollValue;
               _loc14_ = _eCardDenSearchText;
               _currItemWindow = _itemDenWindows;
            }
            LAST_VIEWED_TYPE = _eCardListViewType;
         }
         else if(param1 == _currClothesArray)
         {
            if(_type == 0 || _type == 3)
            {
               _loc11_ = _tradeClothesScrollValue;
               _loc14_ = _tradeClothesSearchText;
            }
            else
            {
               _loc11_ = _normalClothesScrollValue;
               _loc14_ = _normalClothingSearchText;
            }
            _currItemWindow = _itemClothingWindows;
            LAST_VIEWED_TYPE = 0;
         }
         else if(param1 == _currDenItemsArray)
         {
            if(_type == 0 || _type == 3)
            {
               _loc11_ = _tradeDenScrollvalue;
               _loc14_ = _tradeDenSearchText;
            }
            else
            {
               _loc11_ = _normalDenScrollValue;
               _loc14_ = _normalDenSearchText;
            }
            _currItemWindow = _itemDenWindows;
            LAST_VIEWED_TYPE = 1;
         }
         else
         {
            if(param1 != _currPetsArray)
            {
               throw new Error("None of our lists match given items list");
            }
            if(_type == 0 || _type == 3)
            {
               _loc11_ = _tradePetScrollValue;
               _loc14_ = _tradePetSearchText;
            }
            else
            {
               _loc11_ = _normalPetScrollValue;
               _loc14_ = _normalPetSearchText;
            }
            _currItemWindow = _itemPetWindows;
            LAST_VIEWED_TYPE = 2;
         }
         if(_loc14_ != "")
         {
            _open = true;
         }
         else
         {
            _open = false;
         }
         if(_currItemWindow == null || param2)
         {
            _loc3_ = [];
            _loc5_ = [];
            _loc16_ = null;
            _loc8_ = 0;
            _loc10_ = int(param1.length);
            _loc6_ = 0;
            _loc7_ = 0;
            for(; _loc7_ < _loc10_; _loc7_++)
            {
               if(_loc7_ < _loc10_)
               {
                  try
                  {
                     itemAtIndex = param1.getIitem(_loc7_);
                     if(itemAtIndex == null)
                     {
                        _loc8_++;
                        continue;
                     }
                     _loc16_ = itemAtIndex.clone();
                     if(_loc16_ == null)
                     {
                        _loc8_++;
                        continue;
                     }
                  }
                  catch(e:Error)
                  {
                     _loc8_++;
                     continue;
                  }
                  if(_type != 1)
                  {
                     if(_type == 0 || _type == 3)
                     {
                        itemFoundInTrade = false;
                        if(_type == 3 && _loc4_)
                        {
                           tradeIdx = 0;
                           while(tradeIdx < _loc4_.length && !itemFoundInTrade)
                           {
                              tradeItem = _loc4_.getIitem(tradeIdx);
                              if(tradeItem && _loc16_ && tradeItem.invIdx == _loc16_.invIdx && tradeItem.itemType == _loc16_.itemType && (_loc16_ is Item && tradeItem is Item || _loc16_ is DenItem && tradeItem is DenItem || _loc16_ is PetItem && tradeItem is PetItem))
                              {
                                 itemFoundInTrade = true;
                              }
                              tradeIdx++;
                           }
                        }
                        else if(_type == 0 && _loc12_)
                        {
                           myTradeIdx = 0;
                           while(myTradeIdx < _loc12_.length)
                           {
                              myTradeItem = _loc12_.getTradeItem(myTradeIdx);
                              if(myTradeItem && _loc16_)
                              {
                                 itemTypesMatch = false;
                                 if(myTradeItem.itemType == 0 && _loc16_ is Item)
                                 {
                                    itemTypesMatch = true;
                                 }
                                 else if(myTradeItem.itemType == 1 && _loc16_ is DenItem)
                                 {
                                    itemTypesMatch = true;
                                 }
                                 else if(myTradeItem.itemType == 3 && _loc16_ is PetItem)
                                 {
                                    itemTypesMatch = true;
                                 }
                                 if(itemTypesMatch && myTradeItem.invIdx == _loc16_.invIdx)
                                 {
                                    itemFoundInTrade = true;
                                    break;
                                 }
                              }
                              myTradeIdx++;
                           }
                        }
                        if(itemFoundInTrade || _loc16_.itemType == 0 && _loc16_ is DenItem && (_loc16_ as DenItem).specialType == 5)
                        {
                           _loc13_ = true;
                        }
                     }
                     else if(_type == 2)
                     {
                        if(_loc16_.itemType == 0 && _loc16_ is DenItem && ((_loc16_ as DenItem).specialType == 5 || (_loc16_ as DenItem).specialType == 4))
                        {
                           _loc13_ = true;
                        }
                        else if(_initCustomDenList)
                        {
                           _loc9_ = 0;
                           while(_loc9_ < _initCustomDenList.length)
                           {
                              customDenItem = _initCustomDenList.getIitem(_loc9_);
                              if(customDenItem && _loc16_ && _loc16_.itemType == customDenItem.itemType && _loc16_.defId == customDenItem.defId && _loc16_.invIdx == customDenItem.invIdx)
                              {
                                 _loc13_ = true;
                                 break;
                              }
                              _loc9_++;
                           }
                        }
                        if(!_loc13_ && isItemInOtherShops(_loc16_))
                        {
                           _loc13_ = true;
                        }
                     }
                  }
                  else if(_loc16_.itemType == 0 && _loc16_ is DenItem && (_loc16_ as DenItem).specialType == 5)
                  {
                     _loc13_ = true;
                  }
                  if(_loc13_)
                  {
                     _loc13_ = false;
                     _loc6_++;
                     continue;
                  }
                  if(_giftItemIdx == _loc16_.invIdx)
                  {
                     _giftDownIdx = _loc8_ + _loc6_;
                  }
                  isAlreadySelected = false;
                  k = 0;
                  while(k < _selectedItemsCollection.length)
                  {
                     selectedItem = _selectedItemsCollection.getIitem(k);
                     if(selectedItem.invIdx == _loc16_.invIdx && selectedItem.itemType == _loc16_.itemType)
                     {
                        isAlreadySelected = true;
                        break;
                     }
                     k++;
                  }
                  if(isAlreadySelected)
                  {
                     _loc16_.isAlreadySelected = true;
                  }
                  _loc5_.push(_loc8_ + _loc6_);
                  if(_loc16_)
                  {
                     _loc3_.push(_loc16_);
                  }
               }
               _loc8_++;
            }
            if(LAST_VIEWED_TYPE == 0)
            {
               _filteredClothesArray = new IitemCollection();
               filterIdx = 0;
               while(filterIdx < _loc3_.length)
               {
                  _filteredClothesArray.pushIitem(_loc3_[filterIdx]);
                  filterIdx++;
               }
            }
            else if(LAST_VIEWED_TYPE == 2)
            {
               _filteredPetsArray = new PetItemCollection();
               filterPetIdx = 0;
               while(filterPetIdx < _loc3_.length)
               {
                  _filteredPetsArray.pushPetItem(_loc3_[filterPetIdx] as PetItem);
                  filterPetIdx++;
               }
            }
            else
            {
               _filteredDenItemsArray = new IitemCollection();
               filterDenIdx = 0;
               while(filterDenIdx < _loc3_.length)
               {
                  _filteredDenItemsArray.pushIitem(_loc3_[filterDenIdx]);
                  filterDenIdx++;
               }
            }
            _currItemWindow = new WindowAndScrollbarGenerator();
            if(LAST_VIEWED_TYPE == 0)
            {
               _itemClothingWindows = _currItemWindow;
            }
            else if(LAST_VIEWED_TYPE == 2)
            {
               _itemPetWindows = _currItemWindow;
            }
            else
            {
               _itemDenWindows = _currItemWindow;
            }
            _popup.searchBar.mouse.searchTxt.text = "";
            numCols = GuiManager.getExpandedInventoryEnabled() ? GuiManager.getInventoryLayoutCols() : 3;
            numRows = GuiManager.getExpandedInventoryEnabled() ? GuiManager.getInventoryLayoutRows() : 4;
            initialWindowCount = numCols * numRows;
            itemScale = GuiManager.getExpandedInventoryEnabled() ? 3 / numCols : 1;
            _currItemWindow.init(_popup.itemBlock.width,_popup.itemBlock.height,2,_loc11_,numCols,numRows,initialWindowCount,2,2,0,2 * 0.5,ItemWindowOriginal,_loc3_,"icon",0,{
               "mouseDown":winMouseDown,
               "mouseOver":winMouseOver,
               "mouseOut":winMouseOut
            },{
               "giftItemIdx":_giftItemIdx,
               "isECard":_type == 1,
               "isChoosingForTradeList":_type == 0 || _type == 3,
               "indexArray":_loc5_,
               "itemScale":itemScale
            },onListLoaded);
         }
         else
         {
            _popup.searchBar.mouse.searchTxt.text = _loc14_;
            _currItemWindow.customStartScrollYValue = _loc11_;
            onListLoaded();
         }
         _popup.itemBlock.addChild(_currItemWindow);
      }
      
      private function onListLoaded() : void
      {
         onSearchTextInput(null);
         if(_giftDownIdx != -1)
         {
            if(_itemClothingWindows)
            {
               (_itemClothingWindows.bg.getChildAt(_giftDownIdx) as ItemWindowOriginal).resetDownGift();
            }
            if(_itemDenWindows)
            {
               (_itemDenWindows.bg.getChildAt(_giftDownIdx) as ItemWindowOriginal).resetDownGift();
            }
            if(_itemPetWindows)
            {
               (_itemPetWindows.bg.getChildAt(_giftDownIdx) as ItemWindowOriginal).resetDownGift();
            }
            if(LAST_VIEWED_TYPE == 0)
            {
               _currDownMC = _itemClothingWindows.bg.getChildAt(_giftDownIdx) as ItemWindowOriginal;
            }
            else if(LAST_VIEWED_TYPE == 2)
            {
               _currDownMC = _itemPetWindows.bg.getChildAt(_giftDownIdx) as ItemWindowOriginal;
            }
            else
            {
               _currDownMC = _itemDenWindows.bg.getChildAt(_giftDownIdx) as ItemWindowOriginal;
            }
         }
         // grid was rebuilt (search / tab switch): window indexes changed, so rebuild them from the selected items
         _selectedItems = [];
         var i:int = 0;
         while(i < _currItemWindow.mediaWindows.length)
         {
            var itemWindow:ItemWindowOriginal = _currItemWindow.mediaWindows[i] as ItemWindowOriginal;
            if(itemWindow != null && itemWindow.currItem != null)
            {
               var j:int = 0;
               while(j < _selectedItemsCollection.length)
               {
                  var selectedItem:Iitem = _selectedItemsCollection.getIitem(j);
                  if(selectedItem.invIdx == itemWindow.currItem.invIdx && selectedItem.itemType == itemWindow.currItem.itemType)
                  {
                     itemWindow.cir.gotoAndStop("green");
                     _selectedItems.push(itemWindow.index);
                     break;
                  }
                  j++;
               }
            }
            i++;
         }
      }
      
      private function winMouseOver(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(param1.currentTarget.numChildren >= 2 && param1.currentTarget.cir.currentFrameLabel != "gray")
         {
            if(param1.currentTarget.cir.currentFrameLabel == "down")
            {
               param1.currentTarget.cir.gotoAndStop("downMouse");
            }
            else if(param1.currentTarget.cir.currentFrameLabel == "green")
            {
               param1.currentTarget.cir.gotoAndStop("greenMouse");
            }
            else if(param1.currentTarget.cir.currentFrameLabel != "downMouse" && param1.currentTarget.cir.currentFrameLabel != "greenMouse")
            {
               param1.currentTarget.cir.gotoAndStop("over");
            }
         }
         AJAudio.playSubMenuBtnRollover();
      }
      
      private function winMouseOut(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(param1.currentTarget.numChildren >= 2 && param1.currentTarget.cir.currentFrameLabel != "gray")
         {
            if(param1.currentTarget.cir.currentFrameLabel == "downMouse")
            {
               param1.currentTarget.cir.gotoAndStop("down");
            }
            else if(param1.currentTarget.cir.currentFrameLabel == "greenMouse")
            {
               param1.currentTarget.cir.gotoAndStop("green");
            }
            else if(param1.currentTarget.cir.currentFrameLabel != "down" && param1.currentTarget.cir.currentFrameLabel != "green")
            {
               param1.currentTarget.cir.gotoAndStop("up");
            }
         }
      }
      
      private function winMouseDown(param1:MouseEvent) : void
      {
         var _loc3_:Iitem = null;
         var _loc4_:TradeItem = null;
         var _loc2_:* = null;
         param1.stopPropagation();
         if(param1.currentTarget.name == "previewBtn")
         {
            _loc3_ = param1.currentTarget.parent.parent.currItem;
            GuiManager.openMasterpiecePreview((_loc3_ as DenItem).uniqueImageId,(_loc3_ as DenItem).uniqueImageCreator,(_loc3_ as DenItem).uniqueImageCreatorDbId,(_loc3_ as DenItem).uniqueImageCreatorUUID,(_loc3_ as DenItem).version,gMainFrame.userInfo.myUserName,_loc3_ as DenItem);
         }
         else if(param1.currentTarget.name == "certBtn")
         {
            _loc3_ = param1.currentTarget.parent.parent.currItem;
            if(_loc3_ is PetItem)
            {
               GuiManager.openPetCertificatePopup((_loc3_ as PetItem).largeIcon as GuiPet,null);
            }
         }
         else
         {
            var windowItem:Iitem = param1.currentTarget.currItem as Iitem;
            _loc3_ = windowItem;
            if(!_loc3_)
            {
               if(_popup.denBtnUp.visible)
               {
                  _loc3_ = _filteredDenItemsArray ? _filteredDenItemsArray.getIitem(param1.currentTarget.index) : _currDenItemsArray.getIitem(param1.currentTarget.index);
               }
               else if(_popup.petsBtnUp.visible)
               {
                  _loc3_ = _filteredPetsArray ? _filteredPetsArray.getPetItem(param1.currentTarget.index) as Iitem : _currPetsArray.getPetItem(param1.currentTarget.index) as Iitem;
               }
               else
               {
                  _loc3_ = _filteredClothesArray ? _filteredClothesArray.getIitem(param1.currentTarget.index) : _currClothesArray.getIitem(param1.currentTarget.index);
               }
            }
            if(_loc3_)
            {
               if(_loc3_.isApproved)
               {
                  if(_loc3_.isInDenShop && _loc3_.denStoreInvId != ShopManager.currentOpenShopId)
                  {
                     if(_type == 0 || _type == 3)
                     {
                        _yesNoPopup = new SBYesNoPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(_popup.petsBtnUp.visible ? 33970 : 33969),true,onItemRemoveFromShopConfirmation,{
                           "evt":param1,
                           "currItem":_loc3_
                        });
                        return;
                     }
                     if(_type == 1)
                     {
                        _yesNoPopup = new SBYesNoPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(_popup.petsBtnUp.visible ? 33937 : 33936),true,onItemRemoveFromShopConfirmation,{
                           "evt":param1,
                           "currItem":_loc3_
                        });
                        return;
                     }
                     if(_type == 2)
                     {
                        _yesNoPopup = new SBYesNoPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(_popup.petsBtnUp.visible ? 33981 : 33980),true,onItemRemoveFromShopConfirmation,{
                           "evt":param1,
                           "currItem":_loc3_
                        });
                        return;
                     }
                  }
                  if(_type == 2)
                  {
                     _loc4_ = gui.TradeManager.getTradeItemInTradeList(_loc3_);
                     if(_loc4_)
                     {
                        _loc2_ = new TradeItemCollection();
                        _loc2_.pushTradeItem(_loc4_);
                        _yesNoPopup = new SBYesNoPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(_popup.petsBtnUp.visible ? 34028 : 34027),true,onTradeItemsRemoveFromShopConfirmation,{
                           "evt":param1,
                           "tradeItemsToRemove":_loc2_
                        });
                        return;
                     }
                  }
                  if(_type == 1)
                  {
                     if(param1.currentTarget.gift.visible && _loc3_.invIdx == _giftItemIdx)
                     {
                        _giftItemIdx = -1;
                        _giftDownIdx = -1;
                        param1.currentTarget.gift.visible = false;
                     }
                     else if(!param1.currentTarget.gift.visible && _loc3_.invIdx != _giftItemIdx)
                     {
                        if(_currDownMC)
                        {
                           _currDownMC.resetDownGift();
                        }
                        _currDownMC = param1.currentTarget.currDownGift = param1.currentTarget;
                        _giftItemIdx = _loc3_.invIdx;
                        _giftDownIdx = param1.currentTarget.index;
                        if(_giftItemIdx <= 0)
                        {
                           return;
                        }
                     }
                     else
                     {
                        DebugUtility.debugTrace("WARNING: Huuuuuuuuh");
                     }
                  }
                  else
                  {
                     if(_type == 0 || _type == 2 || _type == 3)
                     {
                        _loc2_ = param1.currentTarget as ItemWindowOriginal;
                        if(param1.shiftKey && _lastSelectedIndex != -1 && _lastSelectedIndex != _loc2_.index)
                        {
                           selectItemRange(_lastSelectedIndex,_loc2_.index);
                        }
                        else
                        {
                           toggleItemSelection(_loc3_,_loc2_);
                        }
                        updateSelectionUI();
                        return;
                     }
                     if(_type == 3)
                     {
                        if(_loc3_ is Item)
                        {
                           gui.TradeManager.adjustByOnNumClothingItemsInInitiateTradeList(1);
                        }
                        else if(_loc3_ is DenItem)
                        {
                           gui.TradeManager.adjustByOnNumDenItemsInInitiateTradeList(1);
                        }
                        else if(_loc3_ is PetItem)
                        {
                           gui.TradeManager.adjustByOnNumPetItemsInInitiateTradeList(1);
                        }
                     }
                     if(_onCloseCallback != null)
                     {
                        _onCloseCallback(_loc3_);
                     }
                     else
                     {
                        destroy();
                     }
                  }
               }
               else
               {
                  new SBOkPopup(_guiLayer,LocalizationManager.translateIdOnly(25199));
               }
            }
         }
      }
      
      private function getSelectionLimit() : int
      {
         var currentTradeItems:int;
         var currentCount:int;
         var remainingSlots:int;
         var myTradeList:TradeItemCollection;
         if(_type == TYPE_TRADE_INITIATION)
         {
            currentTradeItems = gui.TradeManager.currentTradeListLength;
            return Math.max(0,20 - currentTradeItems);
         }
         if(_type == TYPE_TRADE)
         {
            // Count the player's own trade list, not TradeManager's initiation list
            // (that one is stale until the next trade request and blocked selection).
            myTradeList = _customInitiationTradeList ? _customInitiationTradeList : gMainFrame.userInfo.getMyTradeList();
            currentTradeItems = myTradeList ? int(myTradeList.length) : 0;
            return Math.max(0,20 - currentTradeItems);
         }
         if(_type == TYPE_DEN_SHOP)
         {
            currentCount = 0;
            if(_initCustomDenList)
            {
               if(_initCustomDenList.hasOwnProperty("numItems"))
               {
                  currentCount = int(_initCustomDenList["numItems"]);
               }
               else if(_initCustomDenList.hasOwnProperty("items") && _initCustomDenList["items"])
               {
                  currentCount = int(_initCustomDenList["items"].length);
               }
               else if(_initCustomDenList.hasOwnProperty("length"))
               {
                  currentCount = int(_initCustomDenList["length"]);
               }
               else
               {
                  try
                  {
                     currentCount = int(_initCustomDenList["getNumItems"]());
                  }
                  catch(e:Error)
                  {
                     currentCount = 0;
                  }
               }
            }
            remainingSlots = ShopManager.MAX_STORE_ITEMS - currentCount;
            if(remainingSlots < 0)
            {
               remainingSlots = 0;
            }
            return remainingSlots;
         }
         if(_type == TYPE_ECARD)
         {
            return 1;
         }
         return ShopManager.MAX_STORE_ITEMS;
      }
      
      private function selectItemRange(startIndex:int, endIndex:int) : void
      {
         var minIndex:int = Math.min(startIndex,endIndex);
         var maxIndex:int = Math.max(startIndex,endIndex);
         var mediaWindows:Array = _currItemWindow.mediaWindows;
         var availableSlots:int = getSelectionLimit();
         var itemsToSelect:int = 0;
         var i:int = 0;
         while(i < mediaWindows.length)
         {
            if(mediaWindows[i] != null)
            {
               var itemWindow:ItemWindowOriginal = mediaWindows[i] as ItemWindowOriginal;
               if(itemWindow != null && itemWindow.visible && itemWindow.alpha > 0)
               {
                  var item:Iitem = itemWindow.currItem as Iitem;
                  if(item != null && item.isApproved)
                  {
                     if(itemWindow.index >= minIndex && itemWindow.index <= maxIndex)
                     {
                        if(itemWindow.cir.currentFrameLabel != "green" && itemWindow.cir.currentFrameLabel != "greenMouse")
                        {
                           if(_selectedItemsCollection.length + itemsToSelect >= availableSlots)
                           {
                              break;
                           }
                           itemWindow.cir.gotoAndStop("green");
                           _selectedItems.push(itemWindow.index);
                           _selectedItemsCollection.pushIitem(item.clone());
                           itemsToSelect++;
                        }
                     }
                  }
               }
            }
            i++;
         }
         _lastSelectedIndex = endIndex;
      }
      
      private function toggleItemSelection(item:Iitem, itemWindow:ItemWindowOriginal) : void
      {
         if(itemWindow == null || !itemWindow.visible || itemWindow.alpha <= 0)
         {
            return;
         }
         // decide by item identity, not window index (indexes go stale when the grid is rebuilt)
         var selectedPos:int = -1;
         var i:int = 0;
         while(i < _selectedItemsCollection.length)
         {
            if(_selectedItemsCollection.getIitem(i).invIdx == item.invIdx && _selectedItemsCollection.getIitem(i).itemType == item.itemType)
            {
               selectedPos = i;
               break;
            }
            i++;
         }
         if(selectedPos != -1)
         {
            if(itemWindow.isInUse)
            {
               itemWindow.cir.gotoAndStop("down");
            }
            else
            {
               itemWindow.cir.gotoAndStop("up");
            }
            _selectedItemsCollection.getCoreArray().splice(selectedPos,1);
            var existingIndex:int = int(_selectedItems.indexOf(itemWindow.index));
            if(existingIndex != -1)
            {
               _selectedItems.splice(existingIndex,1);
            }
         }
         else
         {
            var availableSlots:int = getSelectionLimit();
            if(_selectedItemsCollection.length >= availableSlots)
            {
               return;
            }
            itemWindow.cir.gotoAndStop("green");
            _selectedItems.push(itemWindow.index);
            _selectedItemsCollection.pushIitem(item.clone());
         }
         _lastSelectedIndex = itemWindow.index;
      }
      
      private function updateSelectionUI() : void
      {
         if(_selectedItems.length > 0)
         {
         }
      }
      
      private function addSelectedItemsToTrade() : void
      {
         if(_selectedItemsCollection.length == 0)
         {
            return;
         }
         var availableSlots:int = getSelectionLimit();
         if(availableSlots <= 0)
         {
            clearSelection();
            destroy();
            return;
         }
         if(_selectedItemsCollection.length > availableSlots)
         {
            var truncatedCollection:IitemCollection = new IitemCollection();
            var i:int = 0;
            while(i < availableSlots)
            {
               truncatedCollection.pushIitem(_selectedItemsCollection.getIitem(i));
               i++;
            }
            _selectedItemsCollection = truncatedCollection;
         }
         if(_type == 0 || _type == 2)
         {
            var isMultiSelect:Boolean = _selectedItemsCollection.length > 1;
            if(isMultiSelect && _onCloseCallback != null)
            {
               _onCloseCallback("MULTISELECT_START");
            }
            var j:int = 0;
            while(j < _selectedItemsCollection.length)
            {
               var item:Iitem = _selectedItemsCollection.getIitem(j);
               if(_onCloseCallback != null)
               {
                  _onCloseCallback(item);
               }
               j++;
            }
            if(_onCloseCallback != null)
            {
               _onCloseCallback(null);
            }
            clearSelection();
            destroy();
         }
         else if(_type == 3)
         {
            gui.TradeManager.addMultipleItemsToTrade(_selectedItemsCollection);
            clearSelection();
            destroy();
         }
         else
         {
            clearSelection();
         }
      }
      
      private function clearSelection() : void
      {
         var i:int;
         var index:int;
         var itemWindow:ItemWindowOriginal;
         if(_currItemWindow && _currItemWindow.mediaWindows && _selectedItems)
         {
            i = 0;
            for(; i < _selectedItems.length; i++)
            {
               index = int(_selectedItems[i]);
               if(index >= 0 && index < _currItemWindow.mediaWindows.length)
               {
                  itemWindow = _currItemWindow.mediaWindows[index] as ItemWindowOriginal;
                  if(itemWindow != null && itemWindow.cir)
                  {
                     try
                     {
                        if(itemWindow.isInUse)
                        {
                           itemWindow.cir.gotoAndStop("down");
                        }
                        else
                        {
                           itemWindow.cir.gotoAndStop("up");
                        }
                     }
                     catch(e:Error)
                     {
                        continue;
                     }
                  }
               }
            }
         }
         _selectedItems = [];
         _selectedItemsCollection = new IitemCollection();
         _lastSelectedIndex = -1;
      }
      
      private function onItemRemoveFromShopConfirmation(param1:Object, param2:Boolean = false) : void
      {
         var _loc5_:Iitem = null;
         var _loc3_:MyShopData = null;
         var _loc4_:* = undefined;
         _yesNoPopup = null;
         if(param1.status)
         {
            _loc5_ = param1.passback.currItem;
            _loc3_ = ShopManager.myShopItems[_loc5_.denStoreInvId];
            if(_loc3_ == null)
            {
               if(!param2)
               {
                  DarkenManager.showLoadingSpiral(true);
                  ShopToSellXtCommManager.requestStoreInfo(gMainFrame.userInfo.myUserName,_loc5_.denStoreInvId,onDenStoreDataLoaded,param1);
                  return;
               }
               DarkenManager.showLoadingSpiral(false);
               if(_onCloseCallback != null)
               {
                  _onCloseCallback(null);
               }
               else
               {
                  destroy();
               }
               new SBOkPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(33933));
               return;
            }
            DarkenManager.showLoadingSpiral(true);
            _loc4_ = new Vector.<MyShopItem>();
            _loc4_.push(new MyShopItem(_loc5_,0,0,_loc5_.denStoreInvId));
            ShopToSellXtCommManager.requestStoreUpdateItems(_loc3_.storeInvId,_loc3_.state,null,_loc4_,null,onStoreUpdate,param1.passback);
         }
      }
      
      private function onTradeItemsRemoveFromShopConfirmation(param1:Object) : void
      {
         if(param1.status)
         {
            gui.TradeManager.changeTradeList(null,param1.passback.tradeItemsToRemove);
            winMouseDown(param1.passback.evt);
         }
      }
      
      private function onDenStoreDataLoaded(param1:MyShopData, param2:Object) : void
      {
         _yesNoPopup = null;
         DarkenManager.showLoadingSpiral(false);
         if(param1 && param1.shopItems.length > 0)
         {
            onItemRemoveFromShopConfirmation(param2,true);
         }
         else
         {
            if(_onCloseCallback != null)
            {
               _onCloseCallback(null);
            }
            else
            {
               destroy();
            }
            new SBOkPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(33933));
         }
      }
      
      private function onStoreUpdate(param1:Boolean, param2:Object) : void
      {
         DarkenManager.showLoadingSpiral(false);
         if(param1)
         {
            (param2.currItem as Iitem).denStoreInvId = 0;
            winMouseDown(param2.evt);
         }
         else
         {
            if(_onCloseCallback != null)
            {
               _onCloseCallback(null);
            }
            else
            {
               destroy();
            }
            new SBOkPopup(_guiLayer,LocalizationManager.translateIdOnly(33933));
         }
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(_currDownMC)
         {
            _currDownMC.resetDownGift();
            _giftItemIdx = -1;
            _giftDownIdx = -1;
         }
         if((_type == 0 || _type == 2 || _type == 3) && _selectedItems.length > 0)
         {
            addSelectedItemsToTrade();
            return;
         }
         if(_onCloseCallback != null)
         {
            _onCloseCallback(null);
         }
         destroy();
      }
      
      private function onAddGiftBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(_giftItemIdx > 0)
         {
            _currGiftMC = _currDownMC;
            if(_popup.denBtnUp.visible)
            {
               _onGiftBtnCallback(_giftItemIdx,false);
            }
            else
            {
               _onGiftBtnCallback(_giftItemIdx);
            }
         }
         else if(_giftItemIdx == 0)
         {
            return;
         }
      }
      
      private function onSortByBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(param1.currentTarget == _popup.sortBtnAccessories)
         {
            _popup.sortPopupAccessories.visible = !_popup.sortPopupAccessories.visible;
         }
         else if(param1.currentTarget == _popup.sortBtn)
         {
            _popup.sortingPopup.visible = !_popup.sortingPopup.visible;
         }
      }
      
      private function onDenSortBtns(param1:MouseEvent) : void
      {
         var _loc5_:String = null;
         var _loc3_:IitemCollection = null;
         var _loc2_:int = 0;
         var _loc4_:* = false;
         param1.stopPropagation();
         if(param1.currentTarget.name == "timeBtn")
         {
            if(_currDenItemsArray == _allNewestDenItems)
            {
               _loc2_ = 1;
               _loc4_ = _currDenItemsArray != _allOldestDenItems;
               _loc3_ = _currDenItemsArray = _allOldestDenItems;
               _loc5_ = "Up";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"time",param1.currentTarget.name + "Dn");
            }
            else
            {
               _loc2_ = 2;
               _loc4_ = _currDenItemsArray != _allNewestDenItems;
               _loc3_ = _currDenItemsArray = _allNewestDenItems;
               _loc5_ = "Dn";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"time",param1.currentTarget.name + "Up");
            }
         }
         else if(param1.currentTarget.name == "gemBtn")
         {
            if(_currDenItemsArray == _denItemsGemLow)
            {
               _loc2_ = 3;
               _loc4_ = _currDenItemsArray != _denItemsGemHigh;
               _loc3_ = _currDenItemsArray = _denItemsGemHigh;
               _loc5_ = "Up";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"gemIcon",param1.currentTarget.name + "Up");
            }
            else
            {
               _loc2_ = 4;
               _loc4_ = _currDenItemsArray != _denItemsGemLow;
               _loc3_ = _currDenItemsArray = _denItemsGemLow;
               _loc5_ = "Dn";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"gemIcon",param1.currentTarget.name + "Dn");
            }
         }
         else if(param1.currentTarget.name == "abcBtn")
         {
            if(_currDenItemsArray == _denItemsNameHigh)
            {
               _loc2_ = 5;
               _loc4_ = _currDenItemsArray != _denItemsNameLow;
               _loc3_ = _currDenItemsArray = _denItemsNameLow;
               _loc5_ = "Up";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"abc",param1.currentTarget.name + "Dn");
            }
            else
            {
               _loc2_ = 6;
               _loc4_ = _currDenItemsArray != _denItemsNameHigh;
               _loc3_ = _currDenItemsArray = _denItemsNameHigh;
               _loc5_ = "Dn";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"abc",param1.currentTarget.name + "Up");
            }
         }
         _popup.sortBtn.gotoAndStop(param1.currentTarget.name + _loc5_);
         _popup.sortingPopup.visible = false;
         setCachingOptions(1,_loc2_,true);
         buildItemWindows(_loc3_,_loc4_);
         _popup.sortingPopup.visible = !_popup.sortingPopup.visible;
      }
      
      private function onAccessorySortBtns(param1:MouseEvent) : void
      {
         var _loc3_:AccItemCollection = null;
         var _loc2_:int = 0;
         var _loc4_:* = false;
         param1.stopPropagation();
         var _loc5_:String = "";
         if(param1.currentTarget.name == _popup.sortPopupAccessories.sort6.name)
         {
            _loc2_ = 7;
            _loc4_ = _currClothesArray != _headItems;
            _loc3_ = _currClothesArray = _headItems;
         }
         else if(param1.currentTarget.name == _popup.sortPopupAccessories.sort5.name)
         {
            _loc2_ = 6;
            _loc4_ = _currClothesArray != _neckItems;
            _loc3_ = _currClothesArray = _neckItems;
         }
         else if(param1.currentTarget.name == _popup.sortPopupAccessories.sort4.name)
         {
            _loc2_ = 5;
            _loc4_ = _currClothesArray != _backItems;
            _loc3_ = _currClothesArray = _backItems;
         }
         else if(param1.currentTarget.name == _popup.sortPopupAccessories.sort3.name)
         {
            _loc2_ = 4;
            _loc4_ = _currClothesArray != _legItems;
            _loc3_ = _currClothesArray = _legItems;
         }
         else if(param1.currentTarget.name == _popup.sortPopupAccessories.sort2.name)
         {
            _loc2_ = 3;
            _loc4_ = _currClothesArray != _tailItems;
            _loc3_ = _currClothesArray = _tailItems;
         }
         else if(param1.currentTarget.name == _popup.sortPopupAccessories.sort1.name)
         {
            if(_currClothesArray == _allOldestItems)
            {
               _loc2_ = 2;
               _loc4_ = _currClothesArray != _allNewestItems;
               _loc3_ = _currClothesArray = _allNewestItems;
               _loc5_ = "Dn";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"time",param1.currentTarget.name + "Up");
            }
            else
            {
               _loc2_ = 1;
               _loc4_ = _currClothesArray != _allOldestItems;
               _loc3_ = _currClothesArray = _allOldestItems;
               _loc5_ = "Up";
               (param1.currentTarget as GuiSoundButton).activateSpecifiedItem(true,"time",param1.currentTarget.name + "Dn");
            }
         }
         _popup.sortBtnAccessories.gotoAndStop(param1.currentTarget.name + _loc5_);
         if(_loc3_)
         {
            setCachingOptions(0,_loc2_,true);
            buildItemWindows(_loc3_,_loc4_);
            _popup.sortPopupAccessories.visible = !_popup.sortPopupAccessories.visible;
         }
      }
      
      private function tabBtnHandler(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         param1.stopPropagation();
         _open = false;
         if(param1.currentTarget.name == _popup.denBtnDown.name)
         {
            _loc2_ = 1;
            _popup.denBtnUp.visible = true;
            _popup.denBtnDown.visible = false;
            _popup.clothesBtnUp.visible = false;
            _popup.clothesBtnDown.visible = true;
            if(_showPetBtns)
            {
               _popup.petsBtnUp.visible = false;
               _popup.petsBtnDown.visible = true;
            }
            _popup.sortBtn.visible = true;
            _popup.sortBtnAccessories.visible = false;
            setCachingOptions(_loc2_,-1,false,false,true);
            buildItemWindows(_currDenItemsArray);
         }
         else if(param1.currentTarget.name == _popup.clothesBtnDown.name)
         {
            _loc2_ = 0;
            _popup.denBtnUp.visible = false;
            _popup.denBtnDown.visible = true;
            _popup.clothesBtnUp.visible = true;
            _popup.clothesBtnDown.visible = false;
            if(_showPetBtns)
            {
               _popup.petsBtnUp.visible = false;
               _popup.petsBtnDown.visible = true;
            }
            _popup.sortBtn.visible = false;
            _popup.sortBtnAccessories.visible = true;
            setCachingOptions(_loc2_,-1,false,true);
            buildItemWindows(_currClothesArray);
         }
         else if(param1.currentTarget.name == _popup.petsBtnDown.name)
         {
            _loc2_ = 2;
            _popup.denBtnUp.visible = false;
            _popup.denBtnDown.visible = true;
            _popup.clothesBtnUp.visible = false;
            _popup.clothesBtnDown.visible = true;
            _popup.petsBtnUp.visible = true;
            _popup.petsBtnDown.visible = false;
            _popup.sortBtn.visible = false;
            _popup.sortBtnAccessories.visible = false;
            setCachingOptions(_loc2_,-1,false,false,false,true);
            buildItemWindows(_currPetsArray);
         }
         _popup.sortingPopup.visible = false;
         _popup.sortPopupAccessories.visible = false;
      }
      
      private function setCachingOptions(param1:int = -1, param2:int = -1, param3:Boolean = false, param4:Boolean = false, param5:Boolean = false, param6:Boolean = false) : void
      {
         if(_currItemWindow)
         {
            if(_type == 0 || _type == 3)
            {
               if(_tradeListViewType == 0)
               {
                  if(param3)
                  {
                     _tradeClothesScrollValue = 0;
                     _tradeClothesSearchText = "";
                  }
                  else
                  {
                     _tradeClothesScrollValue = _currItemWindow.scrollYValue;
                     _tradeClothesSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
                  if(param2 != -1)
                  {
                     _tradeClothingListSortType = param2;
                  }
               }
               else if(_tradeListViewType == 2)
               {
                  if(param3)
                  {
                     _tradePetScrollValue = 0;
                     _tradePetSearchText = "";
                  }
                  else
                  {
                     _tradePetScrollValue = _currItemWindow.scrollYValue;
                     _tradePetSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
               }
               else
               {
                  if(param3)
                  {
                     _tradeDenScrollvalue = 0;
                     _tradeDenSearchText = "";
                  }
                  else
                  {
                     _tradeDenScrollvalue = _currItemWindow.scrollYValue;
                     _tradeDenSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
                  if(param2 != -1)
                  {
                     _tradeDenListSortType = param2;
                  }
               }
               if(param1 != -1)
               {
                  _tradeListViewType = param1;
               }
               if(param4)
               {
                  _currClothesArray = convertIntToListClothing(_tradeClothingListSortType);
               }
               if(param5)
               {
                  _currDenItemsArray = convertIntToListDen(_tradeDenListSortType);
               }
               if(param6)
               {
                  _currPetsArray = PetManager.myPetListAsIitem;
               }
            }
            else if(_type == 1)
            {
               if(_eCardListViewType == 0)
               {
                  if(param3)
                  {
                     _eCardClothesScrollValue = 0;
                     _eCardClothesSearchText = "";
                     if(_itemClothingWindows)
                     {
                        _itemClothingWindows.destroy();
                        _itemClothingWindows = null;
                     }
                  }
                  else
                  {
                     _eCardClothesScrollValue = _currItemWindow.scrollYValue;
                     _eCardClothesSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
                  if(param2 != -1)
                  {
                     _eCardClothingListSortType = param2;
                  }
               }
               else
               {
                  if(param3)
                  {
                     _eCardDenScrollValue = 0;
                     _eCardDenSearchText = "";
                     if(_itemDenWindows)
                     {
                        _itemDenWindows.destroy();
                        _itemDenWindows = null;
                     }
                  }
                  else
                  {
                     _eCardDenScrollValue = _currItemWindow.scrollYValue;
                     _eCardDenSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
                  if(param2 != -1)
                  {
                     _eCardDenListSortType = param2;
                  }
               }
               if(param1 != -1)
               {
                  _eCardListViewType = param1;
               }
               if(param4)
               {
                  _currClothesArray = convertIntToListClothing(_eCardClothingListSortType);
               }
               if(param5)
               {
                  _currDenItemsArray = convertIntToListDen(_eCardDenListSortType);
               }
            }
            else
            {
               if(_normalListViewType == 0)
               {
                  if(param3)
                  {
                     _normalClothesScrollValue = 0;
                     _normalClothingSearchText = "";
                  }
                  else
                  {
                     _normalClothesScrollValue = _currItemWindow.scrollYValue;
                     _normalClothingSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
                  if(param2 != -1)
                  {
                     _normalClothingListSortType = param2;
                  }
               }
               else if(_showPetBtns && _normalListViewType == 2)
               {
                  if(param3)
                  {
                     _normalPetScrollValue = 0;
                     _normalPetSearchText = "";
                  }
                  else
                  {
                     _normalPetScrollValue = _currItemWindow.scrollYValue;
                     _normalPetSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
               }
               else
               {
                  if(param3)
                  {
                     _normalDenScrollValue = 0;
                     _normalDenSearchText = "";
                  }
                  else
                  {
                     _normalDenScrollValue = _currItemWindow.scrollYValue;
                     _normalDenSearchText = _popup.searchBar.mouse.searchTxt.text;
                  }
                  if(param2 != -1)
                  {
                     _normalDenListSortType = param2;
                  }
               }
               if(param1 != -1)
               {
                  _normalListViewType = param1;
               }
               if(param4)
               {
                  _currClothesArray = convertIntToListClothing(_normalClothingListSortType);
               }
               if(param5)
               {
                  _currDenItemsArray = convertIntToListDen(_normalDenListSortType);
               }
               if(param6)
               {
                  _currPetsArray = PetManager.myPetListAsIitem;
               }
            }
         }
      }
      
      private function convertIntToListClothing(param1:int) : AccItemCollection
      {
         var _loc2_:AccItemCollection = null;
         switch(param1 - 1)
         {
            case 0:
               _loc2_ = _allOldestItems;
               break;
            case 1:
               _loc2_ = _allNewestItems;
               break;
            case 2:
               _loc2_ = _tailItems;
               break;
            case 3:
               _loc2_ = _legItems;
               break;
            case 4:
               _loc2_ = _backItems;
               break;
            case 5:
               _loc2_ = _neckItems;
               break;
            case 6:
               _loc2_ = _headItems;
         }
         return _loc2_;
      }
      
      private function convertIntToListDen(param1:int) : DenItemCollection
      {
         var _loc2_:DenItemCollection = null;
         switch(param1 - 1)
         {
            case 0:
               _loc2_ = _allNewestDenItems;
               break;
            case 1:
               _loc2_ = _allOldestDenItems;
               break;
            case 2:
               _loc2_ = _denItemsGemLow;
               break;
            case 3:
               _loc2_ = _denItemsGemHigh;
               break;
            case 4:
               _loc2_ = _denItemsNameLow;
               break;
            case 5:
               _loc2_ = _denItemsNameHigh;
         }
         return _loc2_;
      }
      
      private function clearCurrentSearchText() : void
      {
         if(_type == 0 || _type == 3)
         {
            if(_tradeListViewType == 0)
            {
               _tradeClothesSearchText = "";
            }
            else if(_tradeListViewType == 2)
            {
               _tradePetSearchText = "";
            }
            else
            {
               _tradeDenSearchText = "";
            }
         }
         else if(_type == 1)
         {
            if(_eCardListViewType == 0)
            {
               _eCardClothesSearchText = "";
            }
            else
            {
               _eCardDenSearchText = "";
            }
         }
         else if(_normalListViewType == 0)
         {
            _normalClothingSearchText = "";
         }
         else if(_showPetBtns && _normalListViewType == 2)
         {
            _normalPetSearchText = "";
         }
         else
         {
            _normalDenSearchText = "";
         }
      }
      
      private function onSearchTextInput(param1:Event) : void
      {
         if(_currItemWindow)
         {
            _currItemWindow.handleSearchInput(_popup.searchBar.mouse.searchTxt.text);
            resizeSearchBtn(_popup.searchBar.mouse,_popup.searchBar.mouse.searchTxt.text.length > 0);
         }
      }
      
      private function resizeSearchBtn(param1:MovieClip, param2:Boolean) : void
      {
         if(gMainFrame.stage.focus == _popup.searchBar.mouse.searchTxt)
         {
            param2 = true;
         }
         param1.m.width = param2 ? _wideTextWidth : _shortTextWidth;
         param1.b.x = param1.m.x + param1.m.width;
         param1.open = param2;
         param1.b.xBtn.visible = param1.open;
         param1.txt.visible = !param1.open;
         param1.txt.visible = !param1.open;
         param1.searchTxt.visible = param1.open;
         if(param2)
         {
            _popup.sortingPopup.visible = false;
            _popup.sortBtn.visible = false;
            _popup.sortPopupAccessories.visible = false;
            _popup.sortBtnAccessories.visible = false;
         }
         else if(_type == 0 || _type == 3)
         {
            if(_tradeListViewType == 0)
            {
               _popup.sortBtnAccessories.visible = true;
            }
            else if(_tradeListViewType == 2)
            {
               _popup.sortBtnAccessories.visible = false;
               _popup.sortBtn.visible = false;
            }
            else
            {
               _popup.sortBtn.visible = true;
            }
         }
         else if(_type == 1)
         {
            if(_eCardListViewType == 0)
            {
               _popup.sortBtnAccessories.visible = true;
            }
            else
            {
               _popup.sortBtn.visible = true;
            }
         }
         else if(_normalListViewType == 0)
         {
            _popup.sortBtnAccessories.visible = true;
         }
         else if(_normalListViewType == 2)
         {
            _popup.sortBtnAccessories.visible = false;
            _popup.sortBtn.visible = false;
         }
         else
         {
            _popup.sortBtn.visible = true;
         }
      }
      
      private function onSearchBarDown(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = _popup.searchBar.mouse;
         AJAudio.playHudBtnClick();
         if(param1)
         {
            param1.stopPropagation();
            if(_open)
            {
               if(!_loc2_.b.hitTestPoint(param1.stageX,param1.stageY,false))
               {
                  return;
               }
               _open = false;
               _loc2_.searchTxt.text = "";
               clearCurrentSearchText();
               onSearchTextInput(null);
            }
            else
            {
               _open = true;
               gMainFrame.stage.focus = _loc2_.searchTxt;
            }
         }
         else
         {
            _open = false;
            _loc2_.searchTxt.text = "";
            clearCurrentSearchText();
            onSearchTextInput(null);
         }
         resizeSearchBtn(_loc2_,_open);
      }
      
      private function onSearchBarOver(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         AJAudio.playHudBtnRollover();
      }
      
      private function onSearchBarOut(param1:MouseEvent) : void
      {
         param1.stopPropagation();
      }
      
      private function addListeners() : void
      {
         _popup.bx.addEventListener("mouseDown",onClose,false,0,true);
         if(_popup.addBtn)
         {
            _popup.addBtn.addEventListener("mouseDown",onAddGiftBtn,false,0,true);
         }
         _popup.sortBtn.addEventListener("mouseDown",onSortByBtn,false,0,true);
         _popup.sortBtnAccessories.addEventListener("mouseDown",onSortByBtn,false,0,true);
         _popup.sortPopupAccessories.sort6.addEventListener("mouseDown",onAccessorySortBtns,false,0,true);
         _popup.sortPopupAccessories.sort5.addEventListener("mouseDown",onAccessorySortBtns,false,0,true);
         _popup.sortPopupAccessories.sort4.addEventListener("mouseDown",onAccessorySortBtns,false,0,true);
         _popup.sortPopupAccessories.sort3.addEventListener("mouseDown",onAccessorySortBtns,false,0,true);
         _popup.sortPopupAccessories.sort2.addEventListener("mouseDown",onAccessorySortBtns,false,0,true);
         _popup.sortPopupAccessories.sort1.addEventListener("mouseDown",onAccessorySortBtns,false,0,true);
         _popup.sortingPopup.timeBtn.addEventListener("mouseDown",onDenSortBtns,false,0,true);
         _popup.sortingPopup.gemBtn.addEventListener("mouseDown",onDenSortBtns,false,0,true);
         _popup.sortingPopup.abcBtn.addEventListener("mouseDown",onDenSortBtns,false,0,true);
         _popup.denBtnUp.addEventListener("mouseDown",tabBtnHandler,false,0,true);
         _popup.denBtnDown.addEventListener("mouseDown",tabBtnHandler,false,0,true);
         _popup.clothesBtnUp.addEventListener("mouseDown",tabBtnHandler,false,0,true);
         _popup.clothesBtnDown.addEventListener("mouseDown",tabBtnHandler,false,0,true);
         _popup.petsBtnUp.addEventListener("mouseDown",tabBtnHandler,false,0,true);
         _popup.petsBtnDown.addEventListener("mouseDown",tabBtnHandler,false,0,true);
         _popup.searchBar.addEventListener("change",onSearchTextInput,false,0,true);
         _popup.searchBar.addEventListener("mouseDown",onSearchBarDown,false,0,true);
         _popup.searchBar.addEventListener("mouseOver",onSearchBarOver,false,0,true);
         _popup.searchBar.addEventListener("mouseOut",onSearchBarOut,false,0,true);
      }
      
      private function removeListeners() : void
      {
         _popup.bx.removeEventListener("mouseDown",onClose);
         if(_popup.addBtn)
         {
            _popup.addBtn.removeEventListener("mouseDown",onAddGiftBtn);
         }
         _popup.sortBtn.removeEventListener("mouseDown",onSortByBtn);
         _popup.sortBtnAccessories.removeEventListener("mouseDown",onSortByBtn);
         _popup.sortPopupAccessories.sort6.removeEventListener("mouseDown",onAccessorySortBtns);
         _popup.sortPopupAccessories.sort5.removeEventListener("mouseDown",onAccessorySortBtns);
         _popup.sortPopupAccessories.sort4.removeEventListener("mouseDown",onAccessorySortBtns);
         _popup.sortPopupAccessories.sort3.removeEventListener("mouseDown",onAccessorySortBtns);
         _popup.sortPopupAccessories.sort2.removeEventListener("mouseDown",onAccessorySortBtns);
         _popup.sortPopupAccessories.sort1.removeEventListener("mouseDown",onAccessorySortBtns);
         _popup.sortingPopup.timeBtn.removeEventListener("mouseDown",onDenSortBtns);
         _popup.sortingPopup.gemBtn.removeEventListener("mouseDown",onDenSortBtns);
         _popup.sortingPopup.abcBtn.removeEventListener("mouseDown",onDenSortBtns);
         _popup.denBtnUp.removeEventListener("mouseDown",tabBtnHandler);
         _popup.denBtnDown.removeEventListener("mouseDown",tabBtnHandler);
         _popup.clothesBtnUp.removeEventListener("mouseDown",tabBtnHandler);
         _popup.clothesBtnDown.removeEventListener("mouseDown",tabBtnHandler);
         _popup.petsBtnUp.removeEventListener("mouseDown",tabBtnHandler);
         _popup.petsBtnDown.removeEventListener("mouseDown",tabBtnHandler);
         _popup.searchBar.removeEventListener("change",onSearchTextInput);
         _popup.searchBar.removeEventListener("mouseDown",onSearchBarDown);
         _popup.searchBar.removeEventListener("mouseOver",onSearchBarOver);
         _popup.searchBar.removeEventListener("mouseOut",onSearchBarOut);
      }
   }
}

