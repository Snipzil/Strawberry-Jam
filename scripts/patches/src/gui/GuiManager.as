package gui
{
   import Enums.DenItemDef;
   import Party.PartyManager;
   import achievement.Achievement;
   import achievement.AchievementXtCommManager;
   import adoptAPet.AdoptAPetManager;
   import avatar.Avatar;
   import avatar.AvatarInfo;
   import avatar.AvatarManager;
   import avatar.AvatarUtility;
   import avatar.AvatarView;
   import avatar.AvatarWorldView;
   import avatar.PhantomModeVisibility;
   import avatar.UserCommXtCommManager;
   import avatar.UserInfo;
   import buddy.BuddyList;
   import buddy.BuddyManager;
   import collection.IitemCollection;
   import collection.IntItemCollection;
   import collection.StreamDefCollection;
   import com.greensock.TimelineLite;
   import com.greensock.easing.SlowMo;
   import com.sbi.analytics.SBTracker;
   import com.sbi.corelib.audio.SBAudio;
   import com.sbi.debug.DebugUtility;
   import com.sbi.graphics.SortLayer;
   import com.sbi.popup.SBOkPopup;
   import com.sbi.popup.SBPopup;
   import com.sbi.popup.SBPopupManager;
   import com.sbi.popup.SBYesNoPopup;
   import createAccountGui.GuiAvatarCreationAssets;
   import currency.UserCurrency;
   import den.DenItem;
   import den.DenXtCommManager;
   import ecard.ECardManager;
   import flash.display.*;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.external.ExternalInterface;
   import flash.filters.ColorMatrixFilter;
   import flash.geom.Point;
   import flash.net.SharedObject;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   import flash.utils.Timer;
   import flash.utils.setTimeout;
   import game.MinigameManager;
   import gamePlayFlow.GamePlay;
   import gamePlayFlow.HeadlessManager;
   import gamePlayFlow.PerformanceManager;
   import gameRedemption.CodeRedemptionPopup;
   import giftPopup.GiftPopup;
   import giftPopup.ReferAFriendGiftPopup;
   import gui.itemWindows.ItemWindowHeart;
   import inventory.Iitem;
   import item.ItemXtCommManager;
   import loadProgress.LoadProgress;
   import loader.DefPacksDefHelper;
   import loader.DenItemHelper;
   import loader.MediaHelper;
   import localization.LocalizationManager;
   import movie.VideoPlayerOSMF;
   import newspaper.NewspaperManager;
   import pet.GuiPet;
   import pet.PetCertificatePopup;
   import pet.PetManager;
   import playerWall.PlayerWallManager;
   import quest.QuestManager;
   import quest.QuestXtCommManager;
   import room.RoomJoinType;
   import room.RoomManagerWorld;
   import room.RoomXtCommManager;
   import shop.ShopManager;
   import shop.ShopToSellXtCommManager;
   import trade.TutorialPopups;
   
   public final class GuiManager
   {
      
      public static var mainHud:MovieClip;
      
      public static var chatHist:gui.ChatHistory;
      
      public static var actionMgr:ActionManager;
      
      public static var emoteMgr:EmoticonManager;
      
      public static var volumeMgr:VolumeSelector;
      
      public static var denEditor:DenEditor;
      
      public static var guiLayer:DisplayLayer;
      
      public static var fpsLayer:DisplayLayer;
      
      public static var worldLayer:SortLayer;
      
      public static var chatLayer:DisplayLayer;
      
      public static var bgLayer:DisplayLayer;
      
      public static var toolTip:ToolTipPopup;
      
      public static var isInFFM:Boolean;
      
      private static var _currRoomDisplayName:String;
      
      private static var _currRoomDisplayNameModeratedLocalized:String;
      
      private static var _currRoomDisplayNameId:int;
      
      private static var _room:String;
      
      private static var _hudAvtView:AvatarView;
      
      private static var _avEditor:gui.AvatarEditor;
      
      private static var _avtSwitcher:AvatarSwitcher;
      
      private static var _denSwitcher:DenSwitcher;
      
      private static var _mySettings:MySettings;
      
      private static var _reportAPlayer:ReportAPlayer;
      
      private static var _startupPopups:StartupPopups;
      
      private static var _jammerCentral:BulletinBoard;
      
      private static var _gemBonusWheel:GemBonusSpinWheel;
      
      private static var _dailyGiftManager:DailyGiftManager;
      
      private static var _museumDonation:MuseumDonation;
      
      private static var _playerEngagement:PlayerEngagement;
      
      private static var _photoBooth:PhotoBooth;
      
      private static var _photoBoothCallback:Function;
      
      private static var _diamondConfirmationPopup:MovieClip;
      
      private static var _diamondShopInfoPopup:MovieClip;
      
      private static var _diamondSpinInfoPopup:MovieClip;
      
      private static var _demotionMessage:DemotionMessages;
      
      private static var _scrollButtons:MovieClip;
      
      private static var _videoPlayer:VideoPlayerOSMF;
      
      private static var _pageFlip:PageFlip;
      
      private static var _imageDisplayPopup:ImageDisplayPopup;
      
      private static var _petInventory:PetInventory;
      
      private static var _joeyPopup:MovieClip;
      
      private static var _secondaryJoeyPopup:MovieClip;
      
      private static var _avatarCreator:GuiAvatarCreationAssets;
      
      private static var _eBookChooser:EBookChooser;
      
      private static var _holidayBanner:MovieClip;
      
      private static var _joinGamesPopup:GameJoinPopup;
      
      private static var _emailConfirmation:EmailConfirmation;
      
      private static var _codeRedemptionPopup:CodeRedemptionPopup;
      
      private static var _masterpiecePreview:MasterpiecePreview;
      
      private static var _teleportPopup:TeleportPopup;
      
      private static var _cloneAFriendPopup:CloneAFriendPopup;
      
      private static var _roomScannerPopup:RoomScannerPopup;
      
      private static var _marketplacePopup:MarketplacePopup;
      
      private static var _shopExplorerPopup:ShopExplorerPopup;
      
      private static var _nametagColorPickerPopup:NametagColorPickerPopup;
      
      private static var _salesLogPopup:SalesLogPopup;
      
      private static var _quantityInputPopup:QuantityInputPopup;
      
      private static var _barrierPopup:BarrierPopup;
      
      private static var _petCertificatePopup:PetCertificatePopup;
      
      private static var _expiringDaysPopup:ExpiringDaysPopup;
      
      private static var _swap:MovieClip;
      
      private static var _swapPopup:SBPopup;
      
      private static var _awards:MovieClip;
      
      private static var _awardsPopup:SBPopup;
      
      private static var _timer:MovieClip;
      
      private static var _timerPopup:SBPopup;
      
      private static var _report:MovieClip;
      
      private static var _reportPopup:SBPopup;
      
      private static var _rulesPopup:SBPopup;
      
      private static var _differentVersionPopup:SBPopup;
      
      private static var _denBtnGlowTimer:Timer;
      
      private static var _tooManyGemsPopup:SBPopup;
      
      private static var _avEditorCloseCallback:Function;
      
      private static var _codeRedemptionCloseCallback:Function;
      
      private static var _masterpieceCloseCallback:Function;
      
      private static var _petCertificatePopupCloseCallback:Function;
      
      private static var _diamondMediaHelper:MediaHelper;
      
      private static var _heartItemWindow:WindowGenerator;
      
      private static var _giftPopup:GiftPopup;
      
      private static var _referGiftPopup:ReferAFriendGiftPopup;
      
      private static var _prizeOkPopup:SBOkPopup;
      
      private static var _prizeData:Object;
      
      private static var _prizeDenItemHelper:DenItemHelper;
      
      private static var _prizeImg:Sprite;
      
      private static var _currentBookId:int;
      
      private static var _needToRebuildMainHud:Boolean;
      
      private static var _currentDenRoomCount:int;
      
      private static var _newsOpenedFromBtn:Boolean;
      
      private static var _roomMgr:RoomManagerWorld;
      
      private static var _reconnecting:Boolean;
      
      private static var _hasClosedGemBonus:Boolean;
      
      private static var _namebarBadgeList:Array;
      
      private static var _sharedObj:SharedObject;
      
      private static var _giftGemsMediaHelper:MediaHelper;
      
      private static var _gemTimeline:TimelineLite;
      
      private static var _hasInittedGemsTween:Boolean;
      
      private static var _modMenu:gui.ModMenu;
      
      private static var _denStartupEnabled:Boolean = false;
      
      private static var _disableStartupPopups:Boolean = false;
      
      private static var _alwaysOpenGems:Boolean = false;
      
      private static var _wasdMovement:Boolean = false;
      
      private static var _alwaysPrivateChat:Boolean = false;
      
      private static var _autoPrivateChatBadText:Boolean = false;
      
      private static var _headlessMode:Boolean = false;
      
      private static var _performanceMode:Boolean = false;

      private static var _hdGraphicsEnabled:Boolean = false;

      private static var _migratedSOs:Object = {};
      
      private static var _noClip:Boolean = false;
      
      private static var _phantomMode:Boolean = false;
      
      private static var _wheelAutoSpin:Boolean = false;

      private static var _followBuddyRetryEnabled:Boolean = false;

      private static var _roomJoinRetryTimer:Timer;

      private static var _roomJoinRetryTargetRoom:String;

      private static var _roomJoinRetrySeekUsername:String;

      private static var _roomJoinRetryStatusWidget:MovieClip;

      private static const ROOM_JOIN_RETRY_INTERVAL_MS:int = 2000;
      
      private static var _antiAfkEnabled:Boolean = false;
      
      private static var _autoDismissShopPurchase:Boolean = false;
      
      private static var _allowOwnNametagClick:Boolean = false;
      
      private static var _denLoginEnabled:Boolean = false;
      
      private static var _denLoginUsername:String = "";
      
      private static var _enhancedAnimalPalette:Boolean = false;
      
      private static var _multiClothingEnabled:Boolean = false;
      
      private static var _cartSystemEnabled:Boolean = false;
      
      private static var _autoRestockEnabled:Boolean = false;
      
      private static var _rememberPriceEnabled:Boolean = false;
      
      private static var _musicEnabled:Boolean = false;
      
      private static var _soundEffectsEnabled:Boolean = false;
      
      private static var _zoomHotkeysEnabled:Boolean = false;
      
      private static var _allAnimalsShopEnabled:Boolean = false;
      
      private static var _allPetsShopEnabled:Boolean = false;
      
      private static var _allPetAccessoriesEnabled:Boolean = false;
      
      private static var _membershipBypassEnabled:Boolean = false;
      
      private static var _modsMasterEnabled:Boolean = true;
      
      private static var _expandedInventoryEnabled:Boolean = false;
      
      private static var _buddyRoomServerInfoEnabled:Boolean = false;
      
      private static var _displayClothesInHudEnabled:Boolean = false;
      
      private static var _denItemCounterEnabled:Boolean = false;
      
      private static var _preventListCrashingEnabled:Boolean = false;
      
      private static var _hidePlayerAvatar:Boolean = false;
      
      private static var _hidePlayerNametag:Boolean = false;
      
      private static var _inventoryRowsPerColumn:int = 4;
      
      private static var _inventoryColsPerRow:int = 3;
      
      private static var _customEmojiEnabled:Boolean = true;
      
      private static var _customEmojiUseProxy:Boolean = true;
      
      private static var _customEmojiAliasUrl:String = "https://raw.githubusercontent.com/DrEmoji/AJPrivChat/refs/heads/main/Emojis/Alias.json";
      
      private static const DAILY_GIFT_NUM_DAYS:int = 31;
      
      private static const MAX_GEMS:int = 1000;
      
      private static const JB_LIST_ID:int = 53;
      
      private static const NEWSPAPER_LIST_ID_ENG:int = 34;
      
      private static const NEWSPAPER_LIST_ID_FRE:int = 287;
      
      private static const NEWSPAPER_LIST_ID_GER:int = 288;
      
      private static const NEWSPAPER_LIST_ID_SPA:int = 289;
      
      private static const NEWSPAPER_LIST_ID_POR:int = 290;
      
      private static const DIAMOND_SHOP_INFO:int = 2222;
      
      private static const DIAMOND_SPIN_INFO:int = 5714;
      
      private static const AJ_JUMP_POPUP:int = 2540;
      
      public static const FFM:int = 0;
      
      public static const WAS_MEMBER_ADDITIONAL_ITEMS:int = 1;
      
      public static const SHOP_TUTORIAL:int = 3;
      
      public static const NAME_BAR_ICONS_LIST_ID:int = 110;
      
      public static var _originalHudFrame:int = -1;
      
      private static const HOLIDAY_BANNER_MEDIA_IDS:Array = [3871,4431];
      
      private static const HOLIDAY_BANNER_TIMES:Array = [{
         "start":1586649600,
         "end":1586735999
      },{
         "start":1577836800,
         "end":1577923199
      }];
      
      private static var _namebarBadgeDefs:Object = {};
      
      private static var _screenshotMode:Boolean = false;
      
      private static var _screenshotPreviousZoom:Number = 100;
      
      public function GuiManager()
      {
         super();
      }
      
      public static function init(param1:DisplayLayer, param2:DisplayLayer, param3:SortLayer, param4:DisplayLayer, param5:DisplayLayer, param6:Function) : void
      {
         _roomMgr = RoomManagerWorld.instance;
         DarkenManager.init(param1);
         SBPopupManager.darken = DarkenManager.darken;
         SBPopupManager.lighten = DarkenManager.unDarken;
         DarkenManager.setFocus = param6;
         guiLayer = param1;
         fpsLayer = param2;
         worldLayer = param3;
         chatLayer = param4;
         bgLayer = param5;
         mainHud = GETDEFINITIONBYNAME("MainHud");
         mainHud.x = 6;
         mainHud.y = 5;
         mainHud.safeChatTreeWindow.visible = false;
         mainHud.actionsWindow.visible = false;
         mainHud.emotesWindow.visible = false;
         if(mainHud.swapBtn.hasGrayState)
         {
            mainHud.swapBtn.activateGrayState(false);
         }
         _denBtnGlowTimer = new Timer(4000);
         mainHud.newsBtn.glow.visible = false;
         mainHud.newsBtn.newJournal.visible = false;
         mainHud.book.glow.visible = false;
         mainHud.book.gift.visible = false;
         mainHud.partyBtn.glow.visible = false;
         mainHud.playerWall.glow.visible = false;
         mainHud.denBtn.glow.visible = false;
         mainHud.denCount.visible = false;
         guiLayer.addChild(mainHud);
         volumeMgr = new VolumeSelector();
         volumeMgr.VolumeSelctor(guiLayer);
         volumeMgr.enable(true,mainHud.worldMapBtn,mainHud.zoneName,mainHud.worldHelp);
         var _loc7_:DefPacksDefHelper = new DefPacksDefHelper();
         _loc7_.init(1049,namebarBadgeDefResponse,null,2);
         DefPacksDefHelper.mediaArray[1049] = _loc7_;
      }
      
      public static function setupAllItems() : void
      {
         chatHist = new gui.ChatHistory(mainHud.chatHist,mainHud.chatBar,mainHud.chatHistUpDownBtn,mainHud.buddyListBtn,mainHud.chatTxt,mainHud.sendChatBtn,UserCommXtCommManager.onSendMessage,mainHud.predictTxtTag,mainHud.specialCharCont,mainHud.chatRepeatBtn,mainHud.chatRepeatWindow);
         SafeChatManager.init(UserCommXtCommManager.sendAvatarSafeChat,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,mainHud.actionsBtn,mainHud.actionWindow,mainHud.emotesBtn,mainHud.emotesWindow);
         emoteMgr = new EmoticonManager(0,onEmoteClick,mainHud.emotesBtn,mainHud.emotesWindow,mainHud.actionsBtn,mainHud.actionsWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,gMainFrame.userInfo.firstFiveMinutes > 0);
         actionMgr = new ActionManager(UserCommXtCommManager.sendAvatarAction,mainHud.actionsBtn,mainHud.actionsWindow,mainHud.emotesBtn,mainHud.emotesWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow);
         mainHud.furnBtn.visible = false;
         mainHud.mySettingsBtn.glow.visible = false;
         if(mainHud.mySettingsBtn.hasGrayState)
         {
            mainHud.mySettingsBtn.activateGrayState(false);
         }
         if(mainHud.reportBtn.hasGrayState)
         {
            mainHud.reportBtn.activateGrayState(false);
         }
         if(mainHud.ajEmailBtn)
         {
            mainHud.ajEmailBtn.visible = showAjEmailBtn();
         }
         updateDaysLeftCount();
         addListeners();
         UpsellManager.init(guiLayer,PetManager.getPetInventoryMax);
         setToolTipText();
         toolTip = GETDEFINITIONBYNAME("Tooltip");
         setupSoundButton();
      }
      
      public static function setupSharedObject() : void
      {
         _sharedObj = null;
         if(gMainFrame.myFlashVarUserName != null)
         {
            try
            {
               _sharedObj = SharedObject.getLocal(gMainFrame.myFlashVarUserName);
               if(_sharedObj.data.cursor == null || _sharedObj.data.cursor == "custom")
               {
                  CursorManager.switchToCursor("custom_cursor");
               }
            }
            catch(e:Error)
            {
               CursorManager.switchToCursor("custom_cursor");
               _sharedObj = null;
            }
         }
         setupGlobalDenStartupPreference();
         setupGlobalModSettings();
         AJAudio.setupSharedObject(_sharedObj);
         PlayerWallManager.init(mainHud.playerWall);
      }
      
      public static function setupSoundButton() : void
      {
         if(SBAudio.isMusicMuted || SBAudio.areSoundsMuted)
         {
            depressSoundButton(true);
         }
      }
      
      public static function setSharedObj(param1:String, param2:*) : void
      {
         if(_sharedObj != null)
         {
            switch(param1)
            {
               case "cursor":
                  if(_sharedObj.data.cursor != param2)
                  {
                     _sharedObj.data.cursor = param2;
                  }
                  break;
               case "msgColor":
                  if(_sharedObj.data.msgColor != param2)
                  {
                     _sharedObj.data.msgColor = param2;
                  }
                  break;
               case "msgPattern":
                  if(_sharedObj.data.msgPattern != param2)
                  {
                     _sharedObj.data.msgPattern = param2;
                  }
                  break;
               case "expiration":
                  if(_sharedObj.data.expiration != param2)
                  {
                     _sharedObj.data.expiration = param2;
                  }
                  break;
               case "decorId":
                  if(_sharedObj.data.decorId != param2)
                  {
                     _sharedObj.data.decorId = param2;
                  }
                  break;
               case "reportedPosts":
                  _sharedObj.data.reportedPosts = param2;
                  break;
               case "stickerPositions":
                  _sharedObj.data.stickerPositions = param2;
                  break;
               case "volume":
                  _sharedObj.data.volume = param2;
            }
            try
            {
               _sharedObj.flush();
            }
            catch(e:Error)
            {
            }
         }
      }
      
      public static function get avatarEditor() : gui.AvatarEditor
      {
         return _avEditor;
      }
      
      public static function get sharedObj() : SharedObject
      {
         return _sharedObj;
      }
      
      public static function getDenStartupEnabled() : Boolean
      {
         return _denStartupEnabled;
      }
      
      public static function toggleDenStartup() : Boolean
      {
         var oldValue:Boolean = _denStartupEnabled;
         _denStartupEnabled = !_denStartupEnabled;
         DebugUtility.debugTrace("GuiManager.toggleDenStartup() called - changed from " + oldValue + " to " + _denStartupEnabled);
         saveDenStartupPreference();
         return _denStartupEnabled;
      }
      
      private static function setupGlobalDenStartupPreference() : void
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_den_startup");
            if(globalSharedObj.data.denStartup != null)
            {
               _denStartupEnabled = globalSharedObj.data.denStartup;
               DebugUtility.debugTrace("Global den startup preference loaded: " + _denStartupEnabled);
            }
            else
            {
               _denStartupEnabled = false;
               globalSharedObj.data.denStartup = false;
               globalSharedObj.flush();
               DebugUtility.debugTrace("Global den startup preference initialized to: false");
            }
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to setup global den startup preference: " + e.message);
            _denStartupEnabled = false;
         }
      }
      
      private static function saveDenStartupPreference() : void
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_den_startup");
            globalSharedObj.data.denStartup = _denStartupEnabled;
            globalSharedObj.flush();
            DebugUtility.debugTrace("Global den startup preference saved successfully: " + _denStartupEnabled);
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to save global den startup preference: " + e.message);
         }
      }
      
      private static function getCurrentUsername() : String
      {
         try
         {
            if(gMainFrame && gMainFrame.myFlashVarUserName)
            {
               return gMainFrame.myFlashVarUserName;
            }
         }
         catch(e:Error)
         {
         }
         return "";
      }
      
      private static function getFeatureScope(featureKey:String) : Object
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data.featureScopes != null && globalSharedObj.data.featureScopes[featureKey] != null)
            {
               return globalSharedObj.data.featureScopes[featureKey];
            }
         }
         catch(e:Error)
         {
            ExternalInterface.call("console.log","Error getting feature scope " + featureKey + ": " + e.message);
         }
         return null;
      }
      
      public static function getFeatureScopeForUI(featureKey:String) : Boolean
      {
         if(featureKey == "denLoginEnabled")
         {
            return true;
         }
         var scope:Object = getFeatureScope(featureKey);
         if(scope == null || scope.isGlobal == null)
         {
            return true;
         }
         return Boolean(scope.isGlobal);
      }
      
      public static function setFeatureScope(featureKey:String, isGlobal:Boolean) : void
      {
         var globalSharedObj:SharedObject;
         var username:String;
         var currentValue:*;
         var oldScope:Object;
         var wasGlobal:Boolean;
         var userKey:String;
         var userData:Object;
         if(featureKey == "denLoginEnabled")
         {
            return;
         }
         globalSharedObj = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data.featureScopes == null)
            {
               globalSharedObj.data.featureScopes = {};
            }
            if(globalSharedObj.data.perUserSettings == null)
            {
               globalSharedObj.data.perUserSettings = {};
            }
            oldScope = getFeatureScope(featureKey);
            wasGlobal = oldScope != null && oldScope.isGlobal === true;
            if(wasGlobal && !isGlobal)
            {
               username = getCurrentUsername();
               if(username && username != "")
               {
                  if(globalSharedObj.data.perUserSettings[username] == null)
                  {
                     globalSharedObj.data.perUserSettings[username] = {};
                  }
                  currentValue = getGlobalSettingValue(featureKey);
                  if(currentValue != null)
                  {
                     globalSharedObj.data.perUserSettings[username][featureKey] = currentValue;
                  }
               }
            }
            if(!wasGlobal && isGlobal)
            {
               for(userKey in globalSharedObj.data.perUserSettings)
               {
                  userData = globalSharedObj.data.perUserSettings[userKey];
                  if(userData != null)
                  {
                     delete userData[featureKey];
                  }
               }
            }
            globalSharedObj.data.featureScopes[featureKey] = {"isGlobal":isGlobal};
            globalSharedObj.flush();
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to set feature scope: " + e.message);
         }
      }
      
      private static function getGlobalSettingValue(featureKey:String) : *
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data.modSettings != null && globalSharedObj.data.modSettings[featureKey] != null)
            {
               return globalSharedObj.data.modSettings[featureKey];
            }
         }
         catch(e:Error)
         {
            ExternalInterface.call("console.log","Error getting global setting " + featureKey + ": " + e.message);
         }
         return null;
      }
      
      private static function getPerUserSetting(featureKey:String, username:String) : *
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            if(username == null || username == "")
            {
               return null;
            }
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data.perUserSettings != null && globalSharedObj.data.perUserSettings[username] != null)
            {
               return globalSharedObj.data.perUserSettings[username][featureKey];
            }
         }
         catch(e:Error)
         {
            ExternalInterface.call("console.log","Error getting per-user setting " + featureKey + " for " + username + ": " + e.message);
         }
         return null;
      }
      
      private static function setPerUserSetting(featureKey:String, username:String, value:*) : void
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            if(username == null || username == "")
            {
               return;
            }
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data.perUserSettings == null)
            {
               globalSharedObj.data.perUserSettings = {};
            }
            if(globalSharedObj.data.perUserSettings[username] == null)
            {
               globalSharedObj.data.perUserSettings[username] = {};
            }
            globalSharedObj.data.perUserSettings[username][featureKey] = value;
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to set per-user setting: " + e.message);
         }
      }
      
      private static function getFeatureValue(featureKey:String) : *
      {
         var username:String;
         var scope:Object;
         var isGlobal:Boolean;
         var perUserValue:*;
         try
         {
            if(featureKey == "denLoginEnabled" || featureKey == "denLoginUsername")
            {
               return getGlobalSettingValue(featureKey);
            }
            username = getCurrentUsername();
            scope = getFeatureScope(featureKey);
            isGlobal = scope == null || scope.isGlobal !== false;
            if(isGlobal)
            {
               return getGlobalSettingValue(featureKey);
            }
            perUserValue = getPerUserSetting(featureKey,username);
            if(perUserValue != null)
            {
               return perUserValue;
            }
            return getGlobalSettingValue(featureKey);
         }
         catch(e:Error)
         {
            ExternalInterface.call("console.log","Error in getFeatureValue for " + featureKey + ": " + e.message);
            return null;
         }
      }
      
      private static function setFeatureValue(featureKey:String, value:*) : void
      {
         var globalSharedObj:SharedObject;
         var username:String;
         var scope:Object;
         var isGlobal:Boolean;
         if(featureKey == "denLoginEnabled" || featureKey == "denLoginUsername")
         {
            globalSharedObj = null;
            try
            {
               globalSharedObj = getPersistentSO("aj_global_mod_settings");
               if(globalSharedObj.data.modSettings == null)
               {
                  globalSharedObj.data.modSettings = {};
               }
               globalSharedObj.data.modSettings[featureKey] = value;
               globalSharedObj.flush();
            }
            catch(e:Error)
            {
               DebugUtility.debugTrace("Failed to set global setting: " + e.message);
            }
            return;
         }
         username = getCurrentUsername();
         scope = getFeatureScope(featureKey);
         isGlobal = scope == null || scope.isGlobal !== false;
         if(isGlobal)
         {
            globalSharedObj = null;
            try
            {
               globalSharedObj = getPersistentSO("aj_global_mod_settings");
               if(globalSharedObj.data.modSettings == null)
               {
                  globalSharedObj.data.modSettings = {};
               }
               globalSharedObj.data.modSettings[featureKey] = value;
               globalSharedObj.flush();
            }
            catch(e:Error)
            {
               DebugUtility.debugTrace("Failed to set global setting: " + e.message);
            }
         }
         else
         {
            setPerUserSetting(featureKey,username,value);
         }
      }
      
      private static function loadBooleanFeature(featureKey:String, defaultValue:Boolean) : Boolean
      {
         var value:*;
         try
         {
            value = getFeatureValue(featureKey);
            if(value != null)
            {
               return value;
            }
            setFeatureValue(featureKey,defaultValue);
            return defaultValue;
         }
         catch(e:Error)
         {
            ExternalInterface.call("console.log","Error in loadBooleanFeature for " + featureKey + ": " + e.message);
            return defaultValue;
         }
      }
      
      private static function loadStringFeature(featureKey:String, defaultValue:String) : String
      {
         var value:*;
         try
         {
            value = getFeatureValue(featureKey);
            if(value != null)
            {
               return value;
            }
            setFeatureValue(featureKey,defaultValue);
            return defaultValue;
         }
         catch(e:Error)
         {
            ExternalInterface.call("console.log","Error in loadStringFeature for " + featureKey + ": " + e.message);
            return defaultValue;
         }
      }
      
      private static function loadIntFeature(featureKey:String, defaultValue:int) : int
      {
         var value:*;
         try
         {
            value = getFeatureValue(featureKey);
            if(value != null)
            {
               return value;
            }
            setFeatureValue(featureKey,defaultValue);
            return defaultValue;
         }
         catch(e:Error)
         {
            ExternalInterface.call("console.log","Error in loadIntFeature for " + featureKey + ": " + e.message);
            return defaultValue;
         }
      }
      
      private static function setupGlobalModSettings() : void
      {
         var _globalDefaults:Array;
         var _scopeIdx:int;
         var _firstRunDefaults:Array;
         var _firstRunIdx:int;
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data.featureScopes == null)
            {
               globalSharedObj.data.featureScopes = {};
            }
            if(globalSharedObj.data.perUserSettings == null)
            {
               globalSharedObj.data.perUserSettings = {};
            }
            if(globalSharedObj.data.modSettings != null)
            {
               _disableStartupPopups = loadBooleanFeature("disableStartupPopups",false);
               _alwaysOpenGems = loadBooleanFeature("alwaysOpenGems",false);
               _wasdMovement = loadBooleanFeature("wasdMovement",false);
               _alwaysPrivateChat = loadBooleanFeature("alwaysPrivateChat",false);
               GamePlay.alwaysPrivateChatEnabled = _alwaysPrivateChat;
               _performanceMode = loadBooleanFeature("performanceMode",false);
               _hdGraphicsEnabled = loadBooleanFeature("hdGraphics",false);
               _headlessMode = loadBooleanFeature("headlessMode",false);
               _noClip = loadBooleanFeature("noClip",false);
               _phantomMode = loadBooleanFeature("phantomMode",false);
               _wheelAutoSpin = loadBooleanFeature("wheelAutoSpin",false);
               _antiAfkEnabled = loadBooleanFeature("antiAfkEnabled",false);
               _denLoginEnabled = loadBooleanFeature("denLoginEnabled",false);
               _denLoginUsername = loadStringFeature("denLoginUsername","");
               _autoDismissShopPurchase = loadBooleanFeature("autoDismissShopPurchase",false);
               _allowOwnNametagClick = loadBooleanFeature("allowOwnNametagClick",false);
               _enhancedAnimalPalette = loadBooleanFeature("enhancedAnimalPalette",false);
               _multiClothingEnabled = loadBooleanFeature("multiClothingEnabled",false);
               _cartSystemEnabled = loadBooleanFeature("cartSystemEnabled",false);
               _autoRestockEnabled = loadBooleanFeature("autoRestockEnabled",false);
               _rememberPriceEnabled = loadBooleanFeature("rememberPriceEnabled",false);
               _musicEnabled = loadBooleanFeature("musicEnabled",false);
               if(!_musicEnabled)
               {
                  SBAudio.muteMusic();
               }
               _soundEffectsEnabled = loadBooleanFeature("soundEffectsEnabled",false);
               if(!_soundEffectsEnabled)
               {
                  SBAudio.muteSounds();
               }
               _zoomHotkeysEnabled = loadBooleanFeature("zoomHotkeysEnabled",false);
               _allAnimalsShopEnabled = loadBooleanFeature("allAnimalsShopEnabled",false);
               _allPetsShopEnabled = loadBooleanFeature("allPetsShopEnabled",false);
               _allPetAccessoriesEnabled = loadBooleanFeature("allPetAccessoriesEnabled",false);
               _membershipBypassEnabled = loadBooleanFeature("membershipBypassEnabled",false);
               _modsMasterEnabled = loadBooleanFeature("modsMasterEnabled",true);
               _expandedInventoryEnabled = loadBooleanFeature("expandedInventoryEnabled",false);
               _buddyRoomServerInfoEnabled = loadBooleanFeature("buddyRoomServerInfoEnabled",false);
               _followBuddyRetryEnabled = loadBooleanFeature("followBuddyRetryEnabled",false);
               _denItemCounterEnabled = loadBooleanFeature("denItemCounterEnabled",false);
               _autoPrivateChatBadText = loadBooleanFeature("autoPrivateChatBadText",false);
               GamePlay.autoPrivateChatBadTextEnabled = _autoPrivateChatBadText;
               _preventListCrashingEnabled = loadBooleanFeature("preventListCrashingEnabled",false);
               _hidePlayerAvatar = loadBooleanFeature("hidePlayerAvatar",false);
               _hidePlayerNametag = loadBooleanFeature("hidePlayerNametag",false);
               _displayClothesInHudEnabled = loadBooleanFeature("displayClothesInHud",false);
               _allDensShopEnabled = loadBooleanFeature("allDensShopEnabled",false);
               _inventoryRowsPerColumn = loadIntFeature("inventoryRowsPerColumn",4);
               _inventoryColsPerRow = loadIntFeature("inventoryColsPerRow",3);
               _customEmojiEnabled = loadBooleanFeature("customEmojiEnabled",false);
               _customEmojiUseProxy = loadBooleanFeature("customEmojiUseProxy",false);
               _customEmojiAliasUrl = loadStringFeature("customEmojiAliasUrl","https://raw.githubusercontent.com/DrEmoji/AJPrivChat/refs/heads/main/Emojis/Alias.json");
               _globalDefaults = ["disableStartupPopups","alwaysOpenGems","wasdMovement","alwaysPrivateChat","performanceMode","headlessMode","noClip","phantomMode","wheelAutoSpin","antiAfkEnabled","denLoginEnabled","autoDismissShopPurchase","allowOwnNametagClick","enhancedAnimalPalette","multiClothingEnabled","cartSystemEnabled","autoRestockEnabled","rememberPriceEnabled","musicEnabled","soundEffectsEnabled","zoomHotkeysEnabled","allAnimalsShopEnabled","allPetsShopEnabled","allPetAccessoriesEnabled","membershipBypassEnabled","modsMasterEnabled","expandedInventoryEnabled","buddyRoomServerInfoEnabled","followBuddyRetryEnabled","denItemCounterEnabled","autoPrivateChatBadText","preventListCrashingEnabled","hidePlayerAvatar","hidePlayerNametag","displayClothesInHud","hdGraphics","customEmojiEnabled","customEmojiUseProxy","allDensShopEnabled"];
               _scopeIdx = 0;
               while(_scopeIdx < _globalDefaults.length)
               {
                  if(globalSharedObj.data.featureScopes[_globalDefaults[_scopeIdx]] == null)
                  {
                     globalSharedObj.data.featureScopes[_globalDefaults[_scopeIdx]] = {"isGlobal":true};
                  }
                  _scopeIdx++;
               }
               globalSharedObj.flush();
               applyLoadedModSettings();
               if(_alwaysOpenGems && mainHud != null && mainHud.money != null)
               {
                  setTimeout(openGemsTooltip,100);
               }
            }
            else
            {
               _disableStartupPopups = false;
               _alwaysOpenGems = false;
               _wasdMovement = false;
               _alwaysPrivateChat = false;
               _headlessMode = false;
               _noClip = false;
               _phantomMode = false;
               _wheelAutoSpin = false;
               _antiAfkEnabled = false;
               _denLoginEnabled = false;
               _denLoginUsername = "";
               _enhancedAnimalPalette = false;
               _multiHatEnabled = true;
               _cartSystemEnabled = false;
               _autoRestockEnabled = false;
               _rememberPriceEnabled = false;
               _musicEnabled = false;
               _soundEffectsEnabled = false;
               _zoomHotkeysEnabled = false;
               _allAnimalsShopEnabled = false;
               _allPetsShopEnabled = false;
               _allPetAccessoriesEnabled = false;
               _membershipBypassEnabled = false;
               _modsMasterEnabled = true;
               _expandedInventoryEnabled = false;
               _buddyRoomServerInfoEnabled = false;
               _followBuddyRetryEnabled = false;
               _autoPrivateChatBadText = false;
               _preventListCrashingEnabled = false;
               _hidePlayerAvatar = false;
               _hidePlayerNametag = false;
               _inventoryRowsPerColumn = 4;
               _inventoryColsPerRow = 3;
               _customEmojiEnabled = false;
               _customEmojiUseProxy = false;
               _customEmojiAliasUrl = "https://raw.githubusercontent.com/DrEmoji/AJPrivChat/refs/heads/main/Emojis/Alias.json";
               globalSharedObj.data.modSettings = {
                  "disableStartupPopups":false,
                  "alwaysOpenGems":false,
                  "wasdMovement":false,
                  "alwaysPrivateChat":false,
                  "performanceMode":false,
                  "headlessMode":false,
                  "noClip":false,
                  "phantomMode":false,
                  "wheelAutoSpin":false,
                  "antiAfkEnabled":false,
                  "denLoginEnabled":false,
                  "denLoginUsername":"",
                  "enhancedAnimalPalette":false,
                  "multiClothingEnabled":false,
                  "cartSystemEnabled":false,
                  "autoRestockEnabled":false,
                  "rememberPriceEnabled":false,
                  "musicEnabled":false,
                  "soundEffectsEnabled":false,
                  "zoomHotkeysEnabled":false,
                  "allAnimalsShopEnabled":false,
                  "allPetsShopEnabled":false,
                  "allPetAccessoriesEnabled":false,
                  "membershipBypassEnabled":false,
                  "modsMasterEnabled":true,
                  "expandedInventoryEnabled":false,
                  "autoPrivateChatBadText":false,
                  "preventListCrashingEnabled":false,
                  "hidePlayerAvatar":false,
                  "hidePlayerNametag":false,
                  "inventoryRowsPerColumn":4,
                  "inventoryColsPerRow":3,
                  "customEmojiEnabled":false,
                  "customEmojiUseProxy":false,
                  "customEmojiAliasUrl":"https://raw.githubusercontent.com/DrEmoji/AJPrivChat/refs/heads/main/Emojis/Alias.json"
               };
               _firstRunDefaults = ["disableStartupPopups","alwaysOpenGems","wasdMovement","alwaysPrivateChat","performanceMode","headlessMode","noClip","phantomMode","wheelAutoSpin","antiAfkEnabled","denLoginEnabled","autoDismissShopPurchase","allowOwnNametagClick","enhancedAnimalPalette","multiClothingEnabled","cartSystemEnabled","autoRestockEnabled","rememberPriceEnabled","musicEnabled","soundEffectsEnabled","zoomHotkeysEnabled","allAnimalsShopEnabled","allPetsShopEnabled","allPetAccessoriesEnabled","membershipBypassEnabled","modsMasterEnabled","expandedInventoryEnabled","buddyRoomServerInfoEnabled","followBuddyRetryEnabled","denItemCounterEnabled","autoPrivateChatBadText","preventListCrashingEnabled","hidePlayerAvatar","hidePlayerNametag","displayClothesInHud","hdGraphics","customEmojiEnabled","customEmojiUseProxy","allDensShopEnabled"];
               _firstRunIdx = 0;
               while(_firstRunIdx < _firstRunDefaults.length)
               {
                  globalSharedObj.data.featureScopes[_firstRunDefaults[_firstRunIdx]] = {"isGlobal":true};
                  _firstRunIdx++;
               }
               globalSharedObj.flush();
            }
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to setup global mod settings: " + e.message);
            ExternalInterface.call("console.log","Critical error in setupGlobalModSettings: " + e.message + " | stack: " + e.getStackTrace());
            _disableStartupPopups = false;
            _alwaysOpenGems = false;
            _wasdMovement = false;
            _alwaysPrivateChat = false;
            _performanceMode = false;
            _headlessMode = false;
            _noClip = false;
            _phantomMode = false;
            _wheelAutoSpin = false;
            _antiAfkEnabled = true;
            _denLoginEnabled = false;
            _denLoginUsername = "";
            _enhancedAnimalPalette = false;
            _multiHatEnabled = false;
            _cartSystemEnabled = false;
            _autoRestockEnabled = false;
            _rememberPriceEnabled = false;
            _zoomHotkeysEnabled = false;
            _expandedInventoryEnabled = false;
            _autoPrivateChatBadText = false;
            _preventListCrashingEnabled = false;
            _hidePlayerAvatar = false;
            _hidePlayerNametag = false;
            _inventoryRowsPerColumn = 4;
            _inventoryColsPerRow = 3;
            _customEmojiEnabled = false;
            _customEmojiUseProxy = false;
            _customEmojiAliasUrl = "https://raw.githubusercontent.com/DrEmoji/AJPrivChat/refs/heads/main/Emojis/Alias.json";
         }
      }
      
      private static function applyLoadedModSettings() : void
      {
         var tempModsMaster:Boolean;
         var tempHeadless:Boolean;
         var tempPerformance:Boolean;
         try
         {
            tempModsMaster = _modsMasterEnabled;
            tempHeadless = _headlessMode;
            tempPerformance = _performanceMode;
            _modsMasterEnabled = true;
            _headlessMode = false;
            setPerformanceMode(tempPerformance);
            setDisableStartupPopups(_disableStartupPopups);
            setAlwaysOpenGems(_alwaysOpenGems);
            setWasdMovement(_wasdMovement);
            setAlwaysPrivateChat(_alwaysPrivateChat);
            setNoClip(_noClip);
            setPhantomMode(_phantomMode);
            setWheelAutoSpin(_wheelAutoSpin);
            setAntiAfkEnabled(_antiAfkEnabled);
            setAutoDismissShopPurchase(_autoDismissShopPurchase);
            setAllowOwnNametagClick(_allowOwnNametagClick);
            setEnhancedAnimalPalette(_enhancedAnimalPalette);
            setMultiClothingEnabled(_multiClothingEnabled);
            setCartSystemEnabled(_cartSystemEnabled);
            setAutoRestockEnabled(_autoRestockEnabled);
            setRememberPriceEnabled(_rememberPriceEnabled);
            setMusicEnabled(_musicEnabled);
            setSoundEffectsEnabled(_soundEffectsEnabled);
            setZoomHotkeysEnabled(_zoomHotkeysEnabled);
            setAllAnimalsShopEnabled(_allAnimalsShopEnabled);
            setAllPetsShopEnabled(_allPetsShopEnabled);
            setAllPetAccessoriesEnabled(_allPetAccessoriesEnabled);
            setMembershipBypassEnabled(_membershipBypassEnabled);
            setExpandedInventoryEnabled(_expandedInventoryEnabled);
            setBuddyRoomServerInfoEnabled(_buddyRoomServerInfoEnabled);
            setFollowBuddyRetryEnabled(_followBuddyRetryEnabled);
            setDisplayClothesInHudEnabled(_displayClothesInHudEnabled);
            setDenItemCounterEnabled(_denItemCounterEnabled);
            setAutoPrivateChatBadText(_autoPrivateChatBadText);
            setPreventListCrashingEnabled(_preventListCrashingEnabled);
            setHidePlayerAvatar(_hidePlayerAvatar);
            setHidePlayerNametag(_hidePlayerNametag);
            _modsMasterEnabled = tempModsMaster;
            _headlessMode = tempHeadless;
            setModsMasterEnabled(_modsMasterEnabled);
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to apply loaded mod settings: " + e.message);
            ExternalInterface.call("console.log","Error in applyLoadedModSettings: " + e.message + " | stack: " + e.getStackTrace());
         }
      }
      
      private static function saveModSettings() : void
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data.modSettings == null)
            {
               globalSharedObj.data.modSettings = {};
            }
            if(globalSharedObj.data.featureScopes == null)
            {
               globalSharedObj.data.featureScopes = {};
            }
            if(globalSharedObj.data.perUserSettings == null)
            {
               globalSharedObj.data.perUserSettings = {};
            }
            setFeatureValue("disableStartupPopups",_disableStartupPopups);
            setFeatureValue("alwaysOpenGems",_alwaysOpenGems);
            setFeatureValue("wasdMovement",_wasdMovement);
            setFeatureValue("alwaysPrivateChat",_alwaysPrivateChat);
            setFeatureValue("headlessMode",_headlessMode);
            setFeatureValue("noClip",_noClip);
            setFeatureValue("phantomMode",_phantomMode);
            setFeatureValue("wheelAutoSpin",_wheelAutoSpin);
            setFeatureValue("antiAfkEnabled",_antiAfkEnabled);
            setFeatureValue("autoDismissShopPurchase",_autoDismissShopPurchase);
            setFeatureValue("allowOwnNametagClick",_allowOwnNametagClick);
            setFeatureValue("denLoginEnabled",_denLoginEnabled);
            setFeatureValue("denLoginUsername",_denLoginUsername);
            setFeatureValue("enhancedAnimalPalette",_enhancedAnimalPalette);
            setFeatureValue("multiClothingEnabled",_multiClothingEnabled);
            setFeatureValue("cartSystemEnabled",_cartSystemEnabled);
            setFeatureValue("autoRestockEnabled",_autoRestockEnabled);
            setFeatureValue("rememberPriceEnabled",_rememberPriceEnabled);
            setFeatureValue("musicEnabled",_musicEnabled);
            setFeatureValue("soundEffectsEnabled",_soundEffectsEnabled);
            setFeatureValue("zoomHotkeysEnabled",_zoomHotkeysEnabled);
            setFeatureValue("allAnimalsShopEnabled",_allAnimalsShopEnabled);
            setFeatureValue("allPetsShopEnabled",_allPetsShopEnabled);
            setFeatureValue("allPetAccessoriesEnabled",_allPetAccessoriesEnabled);
            setFeatureValue("membershipBypassEnabled",_membershipBypassEnabled);
            setFeatureValue("modsMasterEnabled",_modsMasterEnabled);
            setFeatureValue("expandedInventoryEnabled",_expandedInventoryEnabled);
            setFeatureValue("buddyRoomServerInfoEnabled",_buddyRoomServerInfoEnabled);
            setFeatureValue("followBuddyRetryEnabled",_followBuddyRetryEnabled);
            setFeatureValue("denItemCounterEnabled",_denItemCounterEnabled);
            setFeatureValue("autoPrivateChatBadText",_autoPrivateChatBadText);
            setFeatureValue("preventListCrashingEnabled",_preventListCrashingEnabled);
            setFeatureValue("hidePlayerAvatar",_hidePlayerAvatar);
            setFeatureValue("hidePlayerNametag",_hidePlayerNametag);
            setFeatureValue("displayClothesInHud",_displayClothesInHudEnabled);
            setFeatureValue("performanceMode",_performanceMode);
            setFeatureValue("hdGraphics",_hdGraphicsEnabled);
            setFeatureValue("allDensShopEnabled",_allDensShopEnabled);
            if(_inventoryRowsPerColumn >= 3 && _inventoryRowsPerColumn <= 7)
            {
               setFeatureValue("inventoryRowsPerColumn",_inventoryRowsPerColumn);
            }
            if(_inventoryColsPerRow >= 3 && _inventoryColsPerRow <= 5)
            {
               setFeatureValue("inventoryColsPerRow",_inventoryColsPerRow);
            }
            setFeatureValue("customEmojiEnabled",_customEmojiEnabled);
            setFeatureValue("customEmojiUseProxy",_customEmojiUseProxy);
            setFeatureValue("customEmojiAliasUrl",_customEmojiAliasUrl);
            globalSharedObj.flush();
            DebugUtility.debugTrace("Mod settings saved");
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to save mod settings: " + e.message);
         }
      }
      
      public static function getSalesLog() : Array
      {
         var salesArray:Array;
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data != null)
            {
               if(globalSharedObj.data.salesLog != null)
               {
                  if(globalSharedObj.data.salesLog.sales != null)
                  {
                     salesArray = globalSharedObj.data.salesLog.sales;
                     if(salesArray != null && salesArray.length > 0)
                     {
                        return salesArray.concat();
                     }
                     return [];
                  }
               }
            }
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to get sales log: " + e.message);
         }
         return [];
      }
      
      public static function addSaleToLog(saleData:Object) : void
      {
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data == null)
            {
               globalSharedObj.data = {};
            }
            if(globalSharedObj.data.salesLog == null)
            {
               globalSharedObj.data.salesLog = {};
            }
            if(globalSharedObj.data.salesLog.sales == null)
            {
               globalSharedObj.data.salesLog.sales = [];
            }
            globalSharedObj.data.salesLog.sales.push(saleData);
            globalSharedObj.flush();
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to add sale to log: " + e.message);
         }
      }
      
      public static function clearSalesLog() : void
      {
         var verifyArray:Array;
         var verifyCount:int;
         var globalSharedObj:SharedObject = null;
         try
         {
            globalSharedObj = getPersistentSO("aj_global_mod_settings");
            if(globalSharedObj.data == null)
            {
               globalSharedObj.data = {};
            }
            if(globalSharedObj.data.salesLog != null && globalSharedObj.data.salesLog.sales != null)
            {
               globalSharedObj.data.salesLog.sales.splice(0,globalSharedObj.data.salesLog.sales.length);
            }
            else
            {
               globalSharedObj.data.salesLog = {};
               globalSharedObj.data.salesLog.sales = [];
            }
            try
            {
               globalSharedObj.flush();
            }
            catch(flushErr:Error)
            {
            }
            verifyArray = globalSharedObj.data.salesLog.sales;
            verifyCount = verifyArray ? verifyArray.length : 0;
            if(verifyCount > 0)
            {
               globalSharedObj.data.salesLog.sales = [];
               globalSharedObj.flush();
            }
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("Failed to clear sales log: " + e.message);
         }
      }
      
      public static function getDisableStartupPopups() : Boolean
      {
         return _modsMasterEnabled && _disableStartupPopups;
      }
      
      public static function getDisableStartupPopupsRaw() : Boolean
      {
         return _disableStartupPopups;
      }
      
      public static function setDisableStartupPopups(value:Boolean) : void
      {
         _disableStartupPopups = value;
         saveModSettings();
      }
      
      public static function toggleDisableStartupPopups() : Boolean
      {
         var oldValue:Boolean = _disableStartupPopups;
         _disableStartupPopups = !_disableStartupPopups;
         DebugUtility.debugTrace("GuiManager.toggleDisableStartupPopups() called - changed from " + oldValue + " to " + _disableStartupPopups);
         saveModSettings();
         return _disableStartupPopups;
      }
      
      public static function getAlwaysOpenGems() : Boolean
      {
         return _modsMasterEnabled && _alwaysOpenGems;
      }
      
      public static function getAlwaysOpenGemsRaw() : Boolean
      {
         return _alwaysOpenGems;
      }
      
      public static function setAlwaysOpenGems(value:Boolean) : void
      {
         _alwaysOpenGems = value;
         saveModSettings();
      }
      
      public static function toggleAlwaysOpenGems() : Boolean
      {
         var oldValue:Boolean = _alwaysOpenGems;
         _alwaysOpenGems = !_alwaysOpenGems;
         DebugUtility.debugTrace("GuiManager.toggleAlwaysOpenGems() called - changed from " + oldValue + " to " + _alwaysOpenGems);
         saveModSettings();
         if(_alwaysOpenGems && mainHud != null && mainHud.money != null)
         {
            openGemsTooltip();
         }
         else if(!_alwaysOpenGems && _gemTimeline != null && mainHud != null && mainHud.money != null)
         {
            if(_gemTimeline.reversed() == false)
            {
               _gemTimeline.reverse();
            }
         }
         return _alwaysOpenGems;
      }
      
      public static function getWasdMovement() : Boolean
      {
         return _modsMasterEnabled && _wasdMovement;
      }
      
      public static function getWasdMovementRaw() : Boolean
      {
         return _wasdMovement;
      }
      
      public static function setWasdMovement(value:Boolean) : void
      {
         _wasdMovement = value;
         saveModSettings();
         GamePlay.wasdMovementEnabled = value;
      }
      
      public static function getAlwaysPrivateChat() : Boolean
      {
         return _modsMasterEnabled && _alwaysPrivateChat;
      }
      
      public static function getAlwaysPrivateChatRaw() : Boolean
      {
         return _alwaysPrivateChat;
      }
      
      public static function setAlwaysPrivateChat(value:Boolean) : void
      {
         _alwaysPrivateChat = value;
         GamePlay.alwaysPrivateChatEnabled = value;
         saveModSettings();
         if(chatHist)
         {
            chatHist.setAlwaysPrivateMode(value);
         }
      }
      
      public static function getAutoPrivateChatBadText() : Boolean
      {
         return _autoPrivateChatBadText && getModsMasterEnabled();
      }
      
      public static function getAutoPrivateChatBadTextRaw() : Boolean
      {
         return _autoPrivateChatBadText;
      }
      
      public static function setAutoPrivateChatBadText(value:Boolean) : void
      {
         _autoPrivateChatBadText = value;
         GamePlay.autoPrivateChatBadTextEnabled = _autoPrivateChatBadText;
         saveModSettings();
      }
      
      public static function getPreventListCrashingEnabled() : Boolean
      {
         return _modsMasterEnabled && _preventListCrashingEnabled;
      }
      
      public static function getPreventListCrashingEnabledRaw() : Boolean
      {
         return _preventListCrashingEnabled;
      }
      
      public static function setPreventListCrashingEnabled(value:Boolean) : void
      {
         _preventListCrashingEnabled = value;
         saveModSettings();
      }
      
      public static function getHidePlayerAvatar() : Boolean
      {
         return _modsMasterEnabled && _hidePlayerAvatar;
      }
      
      public static function getHidePlayerAvatarRaw() : Boolean
      {
         return _hidePlayerAvatar;
      }
      
      public static function setHidePlayerAvatar(value:Boolean) : void
      {
         _hidePlayerAvatar = value;
         if(AvatarManager.playerSfsUserId > 0 && AvatarManager.playerAvatarWorldView)
         {
            AvatarManager.playerAvatarWorldView.visible = !(_modsMasterEnabled && value);
         }
         saveModSettings();
      }
      
      public static function getHidePlayerNametag() : Boolean
      {
         return _modsMasterEnabled && _hidePlayerNametag;
      }
      
      public static function getHidePlayerNametagRaw() : Boolean
      {
         return _hidePlayerNametag;
      }
      
      public static function setHidePlayerNametag(value:Boolean) : void
      {
         _hidePlayerNametag = value;
         if(AvatarManager.playerSfsUserId > 0 && AvatarManager.playerAvatarWorldView && AvatarManager.playerAvatarWorldView.nameBar)
         {
            AvatarManager.playerAvatarWorldView.nameBar.visible = !(_modsMasterEnabled && value);
         }
         saveModSettings();
      }
      
      public static function toggleScreenshotMode() : void
      {
         if(!gMainFrame || !gMainFrame.clientInfo)
         {
            return;
         }
         _screenshotMode = !_screenshotMode;
         if(guiLayer)
         {
            guiLayer.visible = !_screenshotMode;
         }
         if(mainHud)
         {
            mainHud.visible = !_screenshotMode;
         }
         if(_screenshotMode)
         {
            _screenshotPreviousZoom = MainFrame.electronManagedZoomLevel;
            RoomManagerWorld.screenshotModeActive = true;
            if(RoomManagerWorld.instance != null)
            {
               var fitZoom:int = RoomManagerWorld.instance.getFitToRoomZoom();
               RoomManagerWorld.instance.updateRoomZoom(fitZoom);
            }
         }
         else
         {
            RoomManagerWorld.screenshotModeActive = false;
            if(RoomManagerWorld.instance != null)
            {
               RoomManagerWorld.instance.updateRoomZoom(_screenshotPreviousZoom);
            }
            MainFrame.electronManagedZoomLevel = _screenshotPreviousZoom;
         }
      }
      
      public static function getHeadlessMode() : Boolean
      {
         var actualState:Boolean;
         if(!_modsMasterEnabled)
         {
            return false;
         }
         try
         {
            if(HeadlessManager)
            {
               actualState = HeadlessManager.isHeadlessMode;
               if(actualState != _headlessMode)
               {
                  _headlessMode = actualState;
               }
            }
         }
         catch(e:Error)
         {
         }
         return _headlessMode;
      }
      
      public static function getHeadlessModeRaw() : Boolean
      {
         return _headlessMode;
      }
      
      public static function setHeadlessMode(value:Boolean) : void
      {
         _headlessMode = value;
         saveModSettings();
         applyHeadlessMode(value);
      }
      
      private static function applyHeadlessMode(enabled:Boolean) : void
      {
         var headlessMgr:*;
         var currentState:Boolean;
         try
         {
            if(HeadlessManager)
            {
               headlessMgr = HeadlessManager.getInstance();
               if(headlessMgr)
               {
                  currentState = HeadlessManager.isHeadlessMode;
                  if(enabled != currentState)
                  {
                     if(enabled)
                     {
                        headlessMgr.enableHeadlessMode();
                     }
                     else
                     {
                        headlessMgr.disableHeadlessMode();
                     }
                  }
                  _headlessMode = HeadlessManager.isHeadlessMode;
               }
            }
         }
         catch(e:Error)
         {
         }
      }
      
      // Mod data used SharedObject.getLocal(name), which Flash scopes to the SWF path
      // (/<deploy>/ajclient.swf), so every AJ deploy started from an empty file and
      // all mod settings reset. "/" survives deploys (AJ's own com/sbi/login uses it);
      // the first open copies over whatever the current deploy's file still holds.
      public static function getPersistentSO(name:String) : SharedObject
      {
         var so:SharedObject = SharedObject.getLocal(name,"/");
         var legacy:SharedObject;
         var key:String;
         if(_migratedSOs[name])
         {
            return so;
         }
         _migratedSOs[name] = true;
         try
         {
            if(isEmptySO(so))
            {
               legacy = SharedObject.getLocal(name);
               if(!isEmptySO(legacy))
               {
                  for(key in legacy.data)
                  {
                     so.data[key] = legacy.data[key];
                  }
                  so.flush();
               }
            }
         }
         catch(e:Error)
         {
         }
         return so;
      }

      private static function isEmptySO(so:SharedObject) : Boolean
      {
         var key:String;
         if(so == null)
         {
            return true;
         }
         for(key in so.data)
         {
            return false;
         }
         return true;
      }

      // Single stage-quality policy. Resize, game init and headless exit used to
      // hard-code "medium" (or "low" on high-DPI screens), which silently undid
      // Performance Mode. Minigames restore gMainFrame.currStageQuality, so keeping
      // that in sync covers them too. "high" is opt-in: Flash rasterizes on the CPU,
      // and high's 4x4 anti-aliasing on a large or high-DPI window made startup lag.
      public static function getPreferredStageQuality() : String
      {
         if(_performanceMode)
         {
            return "low";
         }
         if(_modsMasterEnabled && _hdGraphicsEnabled)
         {
            return "high";
         }
         try
         {
            if(gMainFrame && gMainFrame.stage && gMainFrame.stage.contentsScaleFactor > 1)
            {
               return "low";
            }
         }
         catch(e:Error)
         {
         }
         return "medium";
      }

      public static function applyStageQuality() : void
      {
         try
         {
            if(!gMainFrame || !gMainFrame.stage)
            {
               return;
            }
            gMainFrame.currStageQuality = getPreferredStageQuality();
            if(!_headlessMode)
            {
               gMainFrame.stage.quality = gMainFrame.currStageQuality;
            }
         }
         catch(e:Error)
         {
         }
      }

      public static function getHdGraphicsEnabledRaw() : Boolean
      {
         return _hdGraphicsEnabled;
      }

      public static function setHdGraphicsEnabled(value:Boolean) : void
      {
         _hdGraphicsEnabled = value;
         saveModSettings();
         applyStageQuality();
      }

      public static function getPerformanceMode() : Boolean
      {
         var actualState:Boolean;
         if(!_modsMasterEnabled)
         {
            return false;
         }
         try
         {
            actualState = PerformanceManager.isEnabled;
            if(actualState != _performanceMode)
            {
               _performanceMode = actualState;
            }
         }
         catch(e:Error)
         {
         }
         return _performanceMode;
      }
      
      public static function getPerformanceModeRaw() : Boolean
      {
         return _performanceMode;
      }
      
      public static function setPerformanceMode(value:Boolean) : void
      {
         _performanceMode = value;
         saveModSettings();
         applyPerformanceMode(value);
      }
      
      private static function applyPerformanceMode(enabled:Boolean) : void
      {
         try
         {
            PerformanceManager.setEnabled(enabled);
            _performanceMode = PerformanceManager.isEnabled;
         }
         catch(e:Error)
         {
         }
         applyStageQuality();
      }
      
      public static function getNoClip() : Boolean
      {
         return _modsMasterEnabled && _noClip;
      }
      
      public static function getNoClipRaw() : Boolean
      {
         return _noClip;
      }
      
      public static function setNoClip(value:Boolean) : void
      {
         _noClip = value;
         saveModSettings();
         if(Utility)
         {
            Utility.noClipEnabled = value;
         }
         if(RoomManagerWorld.instance)
         {
            RoomManagerWorld.instance.resetCameraCentering();
         }
      }
      
      public static function getPhantomMode() : Boolean
      {
         return _modsMasterEnabled && _phantomMode;
      }
      
      public static function getPhantomModeRaw() : Boolean
      {
         return _phantomMode;
      }
      
      public static function setPhantomMode(value:Boolean) : void
      {
         var playerAvatarView:*;
         _phantomMode = value;
         saveModSettings();
         if(gMainFrame.userInfo && gMainFrame.userInfo.myUserName && gMainFrame.userInfo.myPerUserAvId > 0)
         {
            if(value)
            {
               PhantomModeVisibility.setPhantomState(gMainFrame.userInfo.myUserName,gMainFrame.userInfo.myPerUserAvId,true);
            }
            else
            {
               PhantomModeVisibility.clearPhantomState(gMainFrame.userInfo.myUserName,gMainFrame.userInfo.myPerUserAvId);
            }
         }
         try
         {
            if(AvatarManager.playerAvatarWorldView != null)
            {
               gMainFrame.clientInfo.persistentPhantomMode = value;
               playerAvatarView = AvatarManager.getAvatarWorldViewBySfsUserId(AvatarManager.playerSfsUserId);
               if(playerAvatarView != null)
               {
                  playerAvatarView.setAvatarAsPhantom(value);
               }
            }
         }
         catch(e:Error)
         {
         }
      }
      
      public static function getBuddyRoomServerInfoEnabled() : Boolean
      {
         return _modsMasterEnabled && _buddyRoomServerInfoEnabled;
      }
      
      public static function getBuddyRoomServerInfoEnabledRaw() : Boolean
      {
         return _buddyRoomServerInfoEnabled;
      }
      
      public static function setBuddyRoomServerInfoEnabled(value:Boolean) : void
      {
         _buddyRoomServerInfoEnabled = value;
         saveModSettings();
      }

      public static function getFollowBuddyRetryEnabled() : Boolean
      {
         return _modsMasterEnabled && _followBuddyRetryEnabled;
      }

      public static function getFollowBuddyRetryEnabledRaw() : Boolean
      {
         return _followBuddyRetryEnabled;
      }

      public static function setFollowBuddyRetryEnabled(value:Boolean) : void
      {
         _followBuddyRetryEnabled = value;
         saveModSettings();
         if(!value)
         {
            cancelRoomJoinRetry();
         }
      }

      // Periodically resends a same-node room join request until the target
      // room is actually joined, instead of giving up after one attempt.
      // Used for teleporting to a player and (when enabled) for following a
      // buddy into a full room. targetRoomWithNode may include a "@node"
      // suffix; only the room-name portion is compared against the room we
      // actually land in.
      public static function beginRoomJoinRetry(targetRoomWithNode:String, seekUsername:String) : void
      {
         if(!targetRoomWithNode || targetRoomWithNode == "")
         {
            return;
         }
         cancelRoomJoinRetry();
         var nodeIdx:int = int(targetRoomWithNode.indexOf("@"));
         _roomJoinRetryTargetRoom = nodeIdx >= 0 ? targetRoomWithNode.substring(0,nodeIdx) : targetRoomWithNode;
         _roomJoinRetrySeekUsername = seekUsername;
         attemptRoomJoinRetry(targetRoomWithNode);
         _roomJoinRetryTimer = new Timer(ROOM_JOIN_RETRY_INTERVAL_MS);
         _roomJoinRetryTimer.addEventListener(TimerEvent.TIMER,onRoomJoinRetryTick);
         _roomJoinRetryTimer.start();
         showRoomJoinRetryStatusWidget(seekUsername);
      }

      public static function cancelRoomJoinRetry() : void
      {
         if(_roomJoinRetryTimer)
         {
            _roomJoinRetryTimer.stop();
            _roomJoinRetryTimer.removeEventListener(TimerEvent.TIMER,onRoomJoinRetryTick);
            _roomJoinRetryTimer = null;
         }
         _roomJoinRetryTargetRoom = null;
         _roomJoinRetrySeekUsername = null;
         hideRoomJoinRetryStatusWidget();
      }

      // Small non-blocking banner shown while a retry loop is active, with a
      // Stop button so the player isn't stuck retrying forever with no way
      // to cancel. Lives on guiLayer directly (no DarkenManager involved) so
      // it never blocks clicks on the game underneath it.
      private static function showRoomJoinRetryStatusWidget(seekUsername:String) : void
      {
         hideRoomJoinRetryStatusWidget();
         try
         {
            var w:int = 320;
            var h:int = 44;
            var widget:MovieClip = new MovieClip();
            var bg:MovieClip = ModMenuUIHelper.createPopupBackground(w,h,0.92);
            bg.x = -w / 2;
            bg.y = -h / 2;
            widget.addChild(bg);
            var labelTxt:TextField = new TextField();
            labelTxt.text = seekUsername ? "Trying to join " + seekUsername + "\'s room..." : "Trying to join room...";
            labelTxt.textColor = ModMenuUIHelper.COLOR_TEXT;
            labelTxt.x = -w / 2 + 14;
            labelTxt.y = -h / 2 + 4;
            labelTxt.width = w - 100;
            labelTxt.height = h - 8;
            labelTxt.selectable = false;
            labelTxt.mouseEnabled = false;
            var labelFmt:TextFormat = new TextFormat();
            labelFmt.size = 12;
            labelTxt.setTextFormat(labelFmt);
            widget.addChild(labelTxt);
            var stopBtn:MovieClip = ModMenuUIHelper.createButton("Stop",14369847,64,26);
            stopBtn.x = w / 2 - 14 - 64;
            stopBtn.y = -13;
            stopBtn.addEventListener("mouseDown",onRoomJoinRetryStopBtn,false,0,true);
            widget.addChild(stopBtn);
            widget["stopBtn"] = stopBtn;
            widget.x = 450;
            widget.y = 40;
            widget.mouseEnabled = true;
            widget.mouseChildren = true;
            guiLayer.addChild(widget);
            _roomJoinRetryStatusWidget = widget;
         }
         catch(err:Error)
         {
         }
      }

      private static function onRoomJoinRetryStopBtn(e:MouseEvent) : void
      {
         e.stopPropagation();
         cancelRoomJoinRetry();
      }

      private static function hideRoomJoinRetryStatusWidget() : void
      {
         if(!_roomJoinRetryStatusWidget)
         {
            return;
         }
         try
         {
            if(_roomJoinRetryStatusWidget["stopBtn"])
            {
               _roomJoinRetryStatusWidget["stopBtn"].removeEventListener("mouseDown",onRoomJoinRetryStopBtn);
            }
            if(_roomJoinRetryStatusWidget.parent)
            {
               _roomJoinRetryStatusWidget.parent.removeChild(_roomJoinRetryStatusWidget);
            }
         }
         catch(err:Error)
         {
         }
         _roomJoinRetryStatusWidget = null;
      }

      public static function get isRoomJoinRetryActive() : Boolean
      {
         return _roomJoinRetryTimer != null;
      }

      private static function onRoomJoinRetryTick(e:TimerEvent) : void
      {
         try
         {
            if(!_roomJoinRetryTargetRoom)
            {
               cancelRoomJoinRetry();
               return;
            }
            if(gMainFrame.server.getCurrentRoomName() == _roomJoinRetryTargetRoom)
            {
               cancelRoomJoinRetry();
               return;
            }
            if(RoomXtCommManager.loadingNewRoom)
            {
               return;
            }
            attemptRoomJoinRetry(_roomJoinRetryTargetRoom);
         }
         catch(err:Error)
         {
            cancelRoomJoinRetry();
         }
      }

      private static function attemptRoomJoinRetry(targetRoomWithNode:String) : void
      {
         try
         {
            DarkenManager.showLoadingSpiral(true);
            if(_roomJoinRetrySeekUsername)
            {
               RoomXtCommManager._seekBuddyName = _roomJoinRetrySeekUsername;
            }
            RoomXtCommManager.sendRoomJoinRequest(targetRoomWithNode,-1,false,false,true,RoomJoinType.DIRECT_JOIN_AND_HALT_ON_FAILURE);
         }
         catch(err:Error)
         {
         }
      }

      public static function getDisplayClothesInHudEnabled() : Boolean
      {
         return _modsMasterEnabled && _displayClothesInHudEnabled;
      }
      
      public static function getDisplayClothesInHudEnabledRaw() : Boolean
      {
         return _displayClothesInHudEnabled;
      }
      
      public static function setDisplayClothesInHudEnabled(value:Boolean) : void
      {
         _displayClothesInHudEnabled = value;
         saveModSettings();
         if(_hudAvtView)
         {
            showHudAvt();
         }
      }
      
      public static function getDenItemCounterEnabled() : Boolean
      {
         return _modsMasterEnabled && _denItemCounterEnabled;
      }
      
      public static function getDenItemCounterEnabledRaw() : Boolean
      {
         return _denItemCounterEnabled;
      }
      
      public static function setDenItemCounterEnabled(value:Boolean) : void
      {
         _denItemCounterEnabled = value;
         ExternalInterface.call("console.log","[Den Item Counter] Feature toggled: " + (value ? "Enabled" : "Disabled"));
         saveModSettings();
         if(DenEditor.staticEditor)
         {
            DenEditor.updateItemCounterVisibility();
         }
      }
      
      public static function getCustomEmojiEnabled() : Boolean
      {
         return _customEmojiEnabled;
      }
      
      public static function setCustomEmojiEnabled(value:Boolean) : void
      {
         _customEmojiEnabled = value;
         saveModSettings();
      }
      
      public static function getCustomEmojiUseProxy() : Boolean
      {
         return _customEmojiUseProxy;
      }
      
      public static function setCustomEmojiUseProxy(value:Boolean) : void
      {
         _customEmojiUseProxy = value;
         saveModSettings();
      }
      
      public static function getCustomEmojiAliasUrl() : String
      {
         return _customEmojiAliasUrl;
      }
      
      public static function setCustomEmojiAliasUrl(value:String) : void
      {
         _customEmojiAliasUrl = value;
         saveModSettings();
      }
      
      public static function getForceOfflineShopState() : Boolean
      {
         return _modsMasterEnabled && Boolean(_forceOfflineShopState);
      }
      
      public static function getForceOfflineShopStateRaw() : Boolean
      {
         return _forceOfflineShopState;
      }
      
      public static function setForceOfflineShopState(value:Boolean) : void
      {
         _forceOfflineShopState = value;
         saveModSettings();
         ExternalInterface.call("console.log","Force Offline Shop State: " + (value ? "ENABLED" : "DISABLED"));
      }
      
      public static function getWheelAutoSpin() : Boolean
      {
         return _modsMasterEnabled && _wheelAutoSpin;
      }
      
      public static function getWheelAutoSpinRaw() : Boolean
      {
         return _wheelAutoSpin;
      }
      
      public static function setWheelAutoSpin(value:Boolean) : void
      {
         _wheelAutoSpin = value;
         saveModSettings();
      }
      
      public static function getAntiAfkEnabled() : Boolean
      {
         return _modsMasterEnabled && _antiAfkEnabled;
      }
      
      public static function getAntiAfkEnabledRaw() : Boolean
      {
         return _antiAfkEnabled;
      }
      
      public static function setAntiAfkEnabled(value:Boolean) : void
      {
         _antiAfkEnabled = value;
         saveModSettings();
      }
      
      public static function getDenLoginEnabled() : Boolean
      {
         return _modsMasterEnabled && _denLoginEnabled;
      }
      
      public static function getDenLoginEnabledRaw() : Boolean
      {
         return _denLoginEnabled;
      }
      
      public static function getDenLoginUsername() : String
      {
         return _denLoginUsername;
      }
      
      public static function setDenLoginConfig(enabled:Boolean, username:String) : void
      {
         _denLoginEnabled = enabled;
         _denLoginUsername = username || "";
         saveModSettings();
      }
      
      public static function getAutoDismissShopPurchase() : Boolean
      {
         return _modsMasterEnabled && _autoDismissShopPurchase;
      }
      
      public static function getAutoDismissShopPurchaseRaw() : Boolean
      {
         return _autoDismissShopPurchase;
      }
      
      public static function setAutoDismissShopPurchase(value:Boolean) : void
      {
         _autoDismissShopPurchase = value;
         saveModSettings();
      }
      
      public static function getAllowOwnNametagClick() : Boolean
      {
         return _modsMasterEnabled && _allowOwnNametagClick;
      }
      
      public static function getAllowOwnNametagClickRaw() : Boolean
      {
         return _allowOwnNametagClick;
      }
      
      public static function setAllowOwnNametagClick(value:Boolean) : void
      {
         _allowOwnNametagClick = value;
         saveModSettings();
      }
      
      public static function getEnhancedAnimalPalette() : Boolean
      {
         return _modsMasterEnabled && _enhancedAnimalPalette;
      }
      
      public static function getEnhancedAnimalPaletteRaw() : Boolean
      {
         return _enhancedAnimalPalette;
      }
      
      public static function setEnhancedAnimalPalette(value:Boolean) : void
      {
         _enhancedAnimalPalette = value;
         saveModSettings();
      }
      
      public static function getMultiClothingEnabled() : Boolean
      {
         return _modsMasterEnabled && _multiClothingEnabled;
      }
      
      public static function getMultiClothingEnabledRaw() : Boolean
      {
         return _multiClothingEnabled;
      }
      
      public static function setMultiClothingEnabled(value:Boolean) : void
      {
         _multiClothingEnabled = value;
         if(!value && AvatarManager.playerSfsUserId > 0 && AvatarManager.playerAvatar && AvatarManager.playerAvatarWorldView)
         {
            var removedIds:Array = AvatarManager.playerAvatar.accState.removeDuplicateLayers();
            if(removedIds.length > 0)
            {
               var itemsOff:IntItemCollection = new IntItemCollection();
               var ri:int = 0;
               while(ri < removedIds.length)
               {
                  itemsOff.pushIntItem(removedIds[ri]);
                  ri++;
               }
               ItemXtCommManager.requestItemUse(null,new IntItemCollection(),itemsOff);
            }
            AvatarManager.playerAvatarWorldView.playAnim(AvatarManager.playerAvatarWorldView.animId);
            var avatarListObj:Object = AvatarManager.avatarList;
            var avatarViewListObj:Object = AvatarManager.avatarViewList;
            for(var sfsId in avatarListObj)
            {
               if(sfsId != AvatarManager.playerSfsUserId)
               {
                  var remoteAvatar:Avatar = avatarListObj[sfsId];
                  if(remoteAvatar && remoteAvatar.accState)
                  {
                     remoteAvatar.accState.removeDuplicateLayers();
                     var remoteView:AvatarWorldView = avatarViewListObj[sfsId];
                     if(remoteView)
                     {
                        remoteView.playAnim(remoteView.animId);
                     }
                  }
               }
            }
         }
         saveModSettings();
      }
      
      public static function getCartSystemEnabled() : Boolean
      {
         return _modsMasterEnabled && _cartSystemEnabled;
      }
      
      public static function getCartSystemEnabledRaw() : Boolean
      {
         return _cartSystemEnabled;
      }
      
      public static function setCartSystemEnabled(value:Boolean) : void
      {
         _cartSystemEnabled = value;
         saveModSettings();
      }
      
      public static function getAutoRestockEnabled() : Boolean
      {
         return _modsMasterEnabled && _autoRestockEnabled;
      }
      
      public static function getAutoRestockEnabledRaw() : Boolean
      {
         return _autoRestockEnabled;
      }
      
      public static function setAutoRestockEnabled(value:Boolean) : void
      {
         _autoRestockEnabled = value;
         saveModSettings();
      }
      
      public static function getRememberPriceEnabled() : Boolean
      {
         return _modsMasterEnabled && _rememberPriceEnabled;
      }
      
      public static function getRememberPriceEnabledRaw() : Boolean
      {
         return _rememberPriceEnabled;
      }
      
      public static function setRememberPriceEnabled(value:Boolean) : void
      {
         _rememberPriceEnabled = value;
         saveModSettings();
      }
      
      public static function getMusicEnabled() : Boolean
      {
         return _modsMasterEnabled && _musicEnabled;
      }
      
      public static function getMusicEnabledRaw() : Boolean
      {
         return _musicEnabled;
      }
      
      public static function setMusicEnabled(value:Boolean) : void
      {
         _musicEnabled = value;
         if(value)
         {
            SBAudio.unmuteMusic();
         }
         else
         {
            SBAudio.muteMusic();
         }
         saveModSettings();
      }
      
      public static function getSoundEffectsEnabled() : Boolean
      {
         return _modsMasterEnabled && _soundEffectsEnabled;
      }
      
      public static function getSoundEffectsEnabledRaw() : Boolean
      {
         return _soundEffectsEnabled;
      }
      
      public static function setSoundEffectsEnabled(value:Boolean) : void
      {
         _soundEffectsEnabled = value;
         if(value)
         {
            SBAudio.unmuteSounds();
         }
         else
         {
            SBAudio.muteSounds();
         }
         saveModSettings();
      }
      
      public static function getZoomHotkeysEnabled() : Boolean
      {
         return _modsMasterEnabled && _zoomHotkeysEnabled;
      }
      
      public static function getZoomHotkeysEnabledRaw() : Boolean
      {
         return _zoomHotkeysEnabled;
      }
      
      public static function setZoomHotkeysEnabled(value:Boolean) : void
      {
         _zoomHotkeysEnabled = value;
         saveModSettings();
      }
      
      public static function toggleZoomHotkeysEnabled() : Boolean
      {
         var oldValue:Boolean = _zoomHotkeysEnabled;
         _zoomHotkeysEnabled = !_zoomHotkeysEnabled;
         saveModSettings();
         return _zoomHotkeysEnabled;
      }
      
      public static function getAllAnimalsShopEnabled() : Boolean
      {
         return _modsMasterEnabled && _allAnimalsShopEnabled;
      }
      
      public static function getAllAnimalsShopEnabledRaw() : Boolean
      {
         return _allAnimalsShopEnabled;
      }
      
      public static function setAllAnimalsShopEnabled(value:Boolean) : void
      {
         _allAnimalsShopEnabled = value;
         saveModSettings();
      }
      
      public static function getAllPetsShopEnabled() : Boolean
      {
         return _modsMasterEnabled && _allPetsShopEnabled;
      }
      
      public static function getAllPetsShopEnabledRaw() : Boolean
      {
         return _allPetsShopEnabled;
      }
      
      public static function setAllPetsShopEnabled(value:Boolean) : void
      {
         _allPetsShopEnabled = value;
         saveModSettings();
      }
      
      public static function getAllPetAccessoriesEnabled() : Boolean
      {
         return _modsMasterEnabled && _allPetAccessoriesEnabled;
      }
      
      public static function getAllPetAccessoriesEnabledRaw() : Boolean
      {
         return _allPetAccessoriesEnabled;
      }
      
      public static function setAllPetAccessoriesEnabled(value:Boolean) : void
      {
         _allPetAccessoriesEnabled = value;
         saveModSettings();
      }
      
      public static function getMembershipBypassEnabled() : Boolean
      {
         return _modsMasterEnabled && _membershipBypassEnabled;
      }
      
      public static function getMembershipBypassEnabledRaw() : Boolean
      {
         return _membershipBypassEnabled;
      }
      
      public static function setMembershipBypassEnabled(value:Boolean) : void
      {
         _membershipBypassEnabled = value;
         saveModSettings();
      }
      
      public static function toggleMembershipBypassEnabled() : Boolean
      {
         _membershipBypassEnabled = !_membershipBypassEnabled;
         saveModSettings();
         return _membershipBypassEnabled;
      }
      
      public static function getExpandedInventoryEnabled() : Boolean
      {
         return _modsMasterEnabled && _expandedInventoryEnabled;
      }
      
      public static function getExpandedInventoryEnabledRaw() : Boolean
      {
         return _expandedInventoryEnabled;
      }
      
      public static function setExpandedInventoryEnabled(value:Boolean) : void
      {
         _expandedInventoryEnabled = value;
         saveModSettings();
         if(_avEditor)
         {
            _avEditor.refreshInventoryLayout();
         }
      }
      
      public static function getInventoryLayoutRows() : int
      {
         return _inventoryRowsPerColumn;
      }
      
      public static function getInventoryLayoutCols() : int
      {
         return _inventoryColsPerRow;
      }
      
      public static function setInventoryLayout(rows:int, cols:int) : void
      {
         var validLayouts:Array = [{
            "cols":3,
            "rows":4
         },{
            "cols":4,
            "rows":4
         },{
            "cols":5,
            "rows":4
         }];
         var isValid:Boolean = false;
         var i:int = 0;
         while(i < validLayouts.length)
         {
            if(validLayouts[i].cols == cols && validLayouts[i].rows == rows)
            {
               isValid = true;
               break;
            }
            i++;
         }
         if(isValid)
         {
            _inventoryRowsPerColumn = rows;
            _inventoryColsPerRow = cols;
            saveModSettings();
         }
      }
      
      public static function getModsMasterEnabled() : Boolean
      {
         return _modsMasterEnabled;
      }
      
      public static function setModsMasterEnabled(value:Boolean) : void
      {
         var playerAvatarView:*;
         var wasEnabled:Boolean = _modsMasterEnabled;
         _modsMasterEnabled = value;
         saveModSettings();
         applyStageQuality();
         if(!value && wasEnabled)
         {
            try
            {
               if(_phantomMode && AvatarManager.playerAvatarWorldView != null)
               {
                  gMainFrame.clientInfo.persistentPhantomMode = false;
                  playerAvatarView = AvatarManager.getAvatarWorldViewBySfsUserId(AvatarManager.playerSfsUserId);
                  if(playerAvatarView != null)
                  {
                     playerAvatarView.setAvatarAsPhantom(false);
                  }
               }
            }
            catch(e:Error)
            {
            }
            if(_noClip && Utility)
            {
               Utility.noClipEnabled = false;
            }
            if(_headlessMode)
            {
               applyHeadlessMode(false);
            }
            if(_wasdMovement)
            {
               GamePlay.wasdMovementEnabled = false;
            }
            if(_alwaysPrivateChat)
            {
               GamePlay.alwaysPrivateChatEnabled = false;
               if(chatHist)
               {
                  chatHist.setAlwaysPrivateMode(false);
               }
            }
            if(_alwaysOpenGems && _gemTimeline != null && mainHud != null && mainHud.money != null)
            {
               if(_gemTimeline.reversed() == false)
               {
                  _gemTimeline.reverse();
               }
            }
            if(_musicEnabled)
            {
               SBAudio.muteMusic();
            }
            if(_soundEffectsEnabled)
            {
               SBAudio.muteSounds();
            }
         }
         else if(value && !wasEnabled)
         {
            try
            {
               if(_phantomMode && AvatarManager.playerAvatarWorldView != null)
               {
                  gMainFrame.clientInfo.persistentPhantomMode = true;
                  playerAvatarView = AvatarManager.getAvatarWorldViewBySfsUserId(AvatarManager.playerSfsUserId);
                  if(playerAvatarView != null)
                  {
                     playerAvatarView.setAvatarAsPhantom(true);
                  }
               }
            }
            catch(e:Error)
            {
            }
            if(_noClip && Utility)
            {
               Utility.noClipEnabled = true;
            }
            if(_headlessMode)
            {
               applyHeadlessMode(true);
            }
            if(_wasdMovement)
            {
               GamePlay.wasdMovementEnabled = true;
            }
            if(_alwaysPrivateChat)
            {
               GamePlay.alwaysPrivateChatEnabled = true;
               if(chatHist)
               {
                  chatHist.setAlwaysPrivateMode(true);
               }
            }
            if(_alwaysOpenGems && mainHud != null && mainHud.money != null)
            {
               openGemsTooltip();
            }
            if(_musicEnabled)
            {
               SBAudio.unmuteMusic();
            }
            if(_soundEffectsEnabled)
            {
               SBAudio.unmuteSounds();
            }
         }
      }
      
      public static function toggleModMenu() : void
      {
         if(_modMenu == null && ModMenuFeatures.toggleHtmlMenu())
         {
            return;
         }
         if(_modMenu == null)
         {
            _modMenu = new gui.ModMenu(function():void
            {
               _modMenu = null;
            });
         }
         else
         {
            destroyModMenu();
         }
      }
      
      public static function destroyModMenu() : void
      {
         if(_modMenu != null)
         {
            _modMenu.destroy();
            _modMenu = null;
         }
      }
      
      public static function isModMenuOpen() : Boolean
      {
         return _modMenu != null;
      }
      
      public static function refreshModMenu() : void
      {
         if(_modMenu != null)
         {
            _modMenu.refreshSettings();
            _modMenu.refreshIconStates();
         }
      }
      
      private static function openGemsTooltip() : void
      {
         if(mainHud == null || mainHud.money == null || mainHud.money.isGray)
         {
            return;
         }
         var _loc1_:String = null;
         var _loc3_:int = 0;
         if(_gemTimeline == null)
         {
            _gemTimeline = new TimelineLite();
         }
         _loc1_ = "gem";
         if(UserCurrency.getCurrency(1) > 0)
         {
            _loc1_ += "Tic";
         }
         if(UserCurrency.getCurrency(3) > 0)
         {
            _loc1_ += "Dia";
         }
         _gemTimeline.progress(0);
         _gemTimeline.reversed(false);
         mainHud.money.gotoAndStop(_loc1_);
         mainHud.money.mouse.currencyToolTipCont.currencyTxt.text = Utility.convertNumberToString(UserCurrency.getCurrency(0));
         _loc3_ = 1;
         _gemTimeline.clear();
         _gemTimeline.paused(true);
         _gemTimeline.to(mainHud.money.mouse.currencyToolTipCont,0.1,{
            "x":-6.15,
            "y":-12.25,
            "scaleX":1,
            "scaleY":1,
            "alpha":1,
            "ease":SlowMo.ease
         },0);
         _gemTimeline.to(mainHud.money.mouse.bg,0.1,{
            "scaleX":1,
            "scaleY":1,
            "alpha":0.3,
            "ease":SlowMo.ease
         },0);
         if(mainHud.money.mouse.tickets)
         {
            mainHud.money.mouse.tickets.currencyToolTipCont.currencyTxt.text = Utility.convertNumberToString(UserCurrency.getCurrency(1));
            _gemTimeline.to(mainHud.money.mouse.tickets,0.1,{
               "y":"+=" + 40 * _loc3_,
               "scaleX":1,
               "scaleY":1,
               "alpha":1,
               "ease":SlowMo.ease
            },0);
            _loc3_++;
         }
         if(mainHud.money.mouse.diamonds)
         {
            mainHud.money.mouse.diamonds.currencyToolTipCont.currencyTxt.text = Utility.convertNumberToString(UserCurrency.getCurrency(3));
            _gemTimeline.to(mainHud.money.mouse.diamonds,0.1,{
               "y":"+=" + 40 * _loc3_,
               "scaleX":1,
               "scaleY":1,
               "alpha":1,
               "ease":SlowMo.ease
            },0);
         }
         if(!_gemTimeline.reversed())
         {
            _gemTimeline.play();
         }
      }
      
      public static function startFFM(param1:Boolean = false) : void
      {
         if(gMainFrame.server.getCurrentRoom())
         {
            ffmAssetsLoadedCallback();
         }
         else
         {
            RoomXtCommManager.sendRoomFFMRequest(rfCallback);
         }
         updateMainHudButtons(true);
      }
      
      private static function rfCallback() : void
      {
         _roomMgr.callback_FFMRoomAssetsLoaded = ffmAssetsLoadedCallback;
         var _loc1_:String = "ffm" + gMainFrame.userInfo.myUserName;
         RoomXtCommManager.sendNonDenRoomJoinRequest(_loc1_);
      }
      
      private static function ffmAssetsLoadedCallback() : void
      {
         LoadProgress.show(true);
         QuestXtCommManager.sendQuestCreateJoinPublic(39);
         isInFFM = true;
      }
      
      public static function destroy() : void
      {
         if(_gemBonusWheel)
         {
            _gemBonusWheel.destroy();
         }
         closeAnyHudPopups();
         closeAnyInventoryRelatedWindows();
         removeListeners();
         chatHist.destroy();
         chatHist = null;
         SafeChatManager.destroy();
         emoteMgr.destroy();
         emoteMgr = null;
         actionMgr.destroy();
         actionMgr = null;
         volumeMgr.destroy();
         volumeMgr = null;
         DarkenManager.destroy();
         ItemXtCommManager.setHudAvtItemListLayerAnim(null);
         _reconnecting = false;
         gui.ModMenu.clearSessionState();
      }
      
      private static function setToolTipText() : void
      {
         if(mainHud.buddyListBtn)
         {
            mainHud.buddyListBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14656),mainHud.x,40);
         }
         if(mainHud.eCardBtn)
         {
            mainHud.eCardBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14657),mainHud.x,40);
         }
         if(mainHud.newsBtn)
         {
            mainHud.newsBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14658),mainHud.x,40);
         }
         if(mainHud.mySettingsBtn)
         {
            mainHud.mySettingsBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14659),mainHud.x,45);
         }
         if(mainHud.reportBtn)
         {
            mainHud.reportBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14660),mainHud.x,45);
         }
         if(mainHud.charWindow)
         {
            mainHud.charWindow.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14673),mainHud.x,mainHud.currentFrameLabel == "quest" ? -40 : -55);
         }
         if(mainHud.swapBtn)
         {
            mainHud.swapBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14661),mainHud.x,-35);
         }
         if(mainHud.actionsBtn)
         {
            mainHud.actionsBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14662),mainHud.x,-30);
         }
         if(mainHud.emotesBtn)
         {
            mainHud.emotesBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14663),mainHud.x,-30);
         }
         if(mainHud.sendChatBtn)
         {
            if(mainHud.currentFrameLabel == "quest")
            {
               mainHud.sendChatBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14648),528 + mainHud.x,497);
            }
            else
            {
               mainHud.sendChatBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14648),521 + mainHud.x,505);
            }
         }
         if(mainHud.safeChatBtn)
         {
            mainHud.safeChatBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14664),mainHud.x,-30);
         }
         if(mainHud.denBtn)
         {
            mainHud.denBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14665),mainHud.x,-35);
         }
         if(mainHud.soundBtn)
         {
            mainHud.soundBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14666),mainHud.x,-25);
         }
         if(mainHud.worldMapBtn)
         {
            mainHud.worldMapBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14667),mainHud.x,-50);
         }
         if(mainHud.book)
         {
            mainHud.book.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14668),mainHud.x,40);
         }
         if(mainHud.partyBtn)
         {
            mainHud.partyBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14669),mainHud.x,40);
         }
         if(mainHud.questPlayersBtn)
         {
            mainHud.questPlayersBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14670),mainHud.x,-30);
         }
         if(mainHud.questingExit_btnQuest)
         {
            mainHud.questingExit_btnQuest.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14671),mainHud.x,-35);
         }
         if(mainHud.miniMap_btnQuest)
         {
            mainHud.miniMap_btnQuest.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14672),mainHud.x,-35);
         }
         if(mainHud.chatRepeatBtn)
         {
            mainHud.chatRepeatBtn.initToolTip(guiLayer,LocalizationManager.translateIdOnly(18215),mainHud.x,-24);
         }
         if(mainHud.games)
         {
            mainHud.games.initToolTip(guiLayer,LocalizationManager.translateIdOnly(6285),mainHud.x,40);
         }
         if(mainHud.playerWall)
         {
            mainHud.playerWall.initToolTip(guiLayer,LocalizationManager.translateIdOnly(14637),mainHud.x,40);
         }
      }
      
      private static function blockMouseHandler(param1:MouseEvent) : void
      {
         param1.stopPropagation();
      }
      
      public static function setSwapBtnGray(param1:Boolean) : void
      {
         if(mainHud.swapBtn && mainHud.swapBtn.isGray != param1)
         {
            mainHud.swapBtn.activateGrayState(param1);
         }
      }
      
      public static function isModal() : Boolean
      {
         if(volumeMgr)
         {
            return volumeMgr.visible;
         }
         return false;
      }
      
      public static function setupGemGiftPopup(param1:int) : void
      {
         DarkenManager.showLoadingSpiral(true);
         _giftGemsMediaHelper = new MediaHelper();
         _giftGemsMediaHelper.init(1086,onGemIconLoaded,param1);
      }
      
      private static function onGemIconLoaded(param1:MovieClip) : void
      {
         DarkenManager.showLoadingSpiral(false);
         if(param1)
         {
            _roomMgr.forceStopMovement();
            _giftPopup = new GiftPopup();
            _giftPopup.init(guiLayer,param1,LocalizationManager.translateIdAndInsertOnly(11097,param1.passback),param1.passback,2,0,null,keepGemGiftCallback,null,false,1);
         }
         _giftGemsMediaHelper.destroy();
         _giftGemsMediaHelper = null;
      }
      
      private static function keepGemGiftCallback() : void
      {
         if(_giftPopup)
         {
            _giftPopup.destroy();
            _giftPopup = null;
         }
         if(denEditor)
         {
            denEditor.onDenTutorialGiftClose();
         }
      }
      
      public static function onItemPrize(param1:Object) : void
      {
         _prizeData = {
            "userVarId":int(param1[2]),
            "isClothing":param1[3] == "1",
            "defId":int(param1[4]),
            "itemName":LocalizationManager.translateIdOnly(int(param1[5])),
            "desc":LocalizationManager.translateIdOnly(int(param1[6])),
            "color":uint(param1[7])
         };
      }
      
      public static function showPrizePopupIfAny() : Boolean
      {
         var _loc1_:DenItemDef = null;
         if(_prizeData)
         {
            _loc1_ = DenXtCommManager.getDenItemDef(_prizeData.defId);
            if(!_loc1_)
            {
               return false;
            }
            _prizeDenItemHelper = new DenItemHelper();
            _prizeDenItemHelper.initGeneric(_loc1_,onPrizeIconReceived,_prizeData.color);
            return true;
         }
         return false;
      }
      
      private static function onPrizeIconReceived(param1:DenItemHelper) : void
      {
         var _loc2_:Sprite = null;
         var _loc3_:Number = Number(NaN);
         if(param1 && param1.displayObject)
         {
            _loc2_ = new Sprite();
            _loc3_ = 168 / Math.max(param1.displayObject.width,param1.displayObject.height);
            param1.displayObject.width *= _loc3_;
            param1.displayObject.height *= _loc3_;
            _loc2_.addChild(param1.displayObject);
            _loc2_.x = -_loc2_.width * 0.5;
            _loc2_.y = -_loc2_.height * 0.5;
            _prizeImg = _loc2_;
            _prizeOkPopup = new SBOkPopup(guiLayer,_prizeData.desc,true,onPrizeDescOkDown);
         }
      }
      
      private static function onPrizeDescOkDown(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         _prizeOkPopup.destroy();
         _giftPopup = new GiftPopup();
         _giftPopup.init(guiLayer,_prizeImg,_prizeData.itemName,_prizeData.defId,2,2,onKeepPrizeDown,onDiscardPrizeDown,destroyPrizePopup);
      }
      
      private static function onKeepPrizeDown() : void
      {
         AchievementXtCommManager.requestSetUserVar(_prizeData.userVarId,3 | _prizeData.color << 4);
         destroyPrizePopup();
      }
      
      private static function onDiscardPrizeDown() : void
      {
         AchievementXtCommManager.requestSetUserVar(_prizeData.userVarId,2 | _prizeData.color << 4);
         destroyPrizePopup();
      }
      
      private static function destroyPrizePopup() : void
      {
         if(_giftPopup)
         {
            _giftPopup.destroy();
            _giftPopup = null;
         }
         _prizeData = null;
         if(_prizeDenItemHelper)
         {
            _prizeDenItemHelper.destroy();
            _prizeDenItemHelper = null;
         }
         _prizeImg = null;
         guiStartupChecks();
      }
      
      public static function guiStartupChecks(param1:Boolean = false) : void
      {
         var _loc2_:Number = Number(NaN);
         var _loc3_:Number = Number(NaN);
         if(!gMainFrame.clientInfo.invisMode)
         {
            if(!param1)
            {
               if(!showPrizePopupIfAny())
               {
                  if(NewspaperManager.hasUnseenPages && !NewspaperManager.hasSeenFirstPage)
                  {
                     NewspaperManager.hasUnseenPages = false;
                     if(!NewspaperManager.hasSeenFirstPage)
                     {
                        onNewsPaperBtn(null);
                     }
                     NewspaperManager.hasSeenFirstPage = true;
                  }
                  else if(!_hasClosedGemBonus)
                  {
                     _loc2_ = Number(gMainFrame.userInfo.userVarCache.getUserVarValueById(214));
                     _loc3_ = Number(gMainFrame.userInfo.userVarCache.getUserVarValueById(458));
                     if(_loc2_ == -1 || (_loc2_ & 0xFFFF) < gMainFrame.clientInfo.jamaaDate || gMainFrame.clientInfo.dailyGiftIndex >= 0 && gMainFrame.clientInfo.dailyGiftIndex < 31 && (_loc3_ == -1 || (_loc3_ & 1 << gMainFrame.clientInfo.dailyGiftIndex) <= 0))
                     {
                        DarkenManager.showLoadingSpiral(true);
                        if(gMainFrame.clientInfo.dailyGiftIndex >= 0 && gMainFrame.clientInfo.dailyGiftIndex < 31)
                        {
                           openDailyGift(gMainFrame.clientInfo.dailyGiftIndex);
                        }
                        else
                        {
                           openGemBonusWheel(_loc2_);
                        }
                     }
                     else
                     {
                        _hasClosedGemBonus = true;
                        guiStartupChecks();
                     }
                  }
                  else if(!checkShouldDisplayHolidayBanner())
                  {
                     if(PetManager.hasAtLeastOneHatchedEggPet())
                     {
                        PetManager.showPetHatchedPopups();
                     }
                     else if(AdoptAPetManager.shouldShowFirstAdoptAPetPopup)
                     {
                        AdoptAPetManager.showFirstAdoptAPetPopup(onAdoptAPetPopupClosed);
                     }
                     else if(ShopToSellXtCommManager.hasBuysToProcess)
                     {
                        ShopToSellXtCommManager.processBuyResponses();
                     }
                     else if(showAjEmailBtn() && gMainFrame.userInfo.numLogins % 5 == 0)
                     {
                        initEmailConfirmation(null);
                     }
                  }
               }
            }
            else if(AdoptAPetManager.shouldShowFirstAdoptAPetPopup)
            {
               AdoptAPetManager.showFirstAdoptAPetPopup(onAdoptAPetPopupClosed);
            }
            else if(ShopToSellXtCommManager.hasBuysToProcess)
            {
               ShopToSellXtCommManager.processBuyResponses();
            }
         }
      }
      
      private static function onAdoptAPetPopupClosed() : void
      {
         guiStartupChecks(true);
      }
      
      public static function openGiftPopup(param1:Sprite, param2:String, param3:int, param4:int, param5:Function, param6:Function, param7:Function, param8:int, param9:String, param10:int, param11:String, param12:Boolean, param13:Iitem) : void
      {
         _roomMgr.forceStopMovement();
         _giftPopup = new GiftPopup();
         _giftPopup.init(guiLayer,param1,param2,param3,param10,GiftPopup.giftTypeForECardType(param4),param5,param6,param7,false,param8,0,param9,param11,null,param12,param13);
      }
      
      public static function openReferGiftPopup(param1:Sprite, param2:String, param3:int, param4:int, param5:Function, param6:Function, param7:Function, param8:int, param9:String, param10:int, param11:String, param12:Boolean, param13:Iitem) : void
      {
         _roomMgr.forceStopMovement();
         _referGiftPopup = new ReferAFriendGiftPopup();
         _referGiftPopup.init(guiLayer,param1,param2,param3,param10,GiftPopup.giftTypeForECardType(param4),param5,param6,param7,false,param8,0,param9,param11,null,param12,param13);
      }
      
      public static function closePromoPopup() : Boolean
      {
         if(_giftPopup)
         {
            _giftPopup.close();
            return true;
         }
         if(_referGiftPopup)
         {
            _referGiftPopup.close();
            return true;
         }
         return false;
      }
      
      public static function destroyPromotionalPopup() : void
      {
         if(_giftPopup)
         {
            _giftPopup.destroy();
            _giftPopup = null;
         }
         if(_referGiftPopup)
         {
            _referGiftPopup.destroy();
            _referGiftPopup = null;
         }
      }
      
      private static function checkShouldDisplayHolidayBanner() : Boolean
      {
         if(HOLIDAY_BANNER_TIMES.length > 0 && Utility.currTimeOffsetToMatchUTC() >= HOLIDAY_BANNER_TIMES[0].start)
         {
            if(Utility.currTimeOffsetToMatchUTC() <= HOLIDAY_BANNER_TIMES[0].end)
            {
               if(gMainFrame.userInfo.userVarCache.getUserVarValueById(Achievement.HOLIDAY_BANNER) != HOLIDAY_BANNER_TIMES[0].start)
               {
                  openHolidayBanner();
                  return true;
               }
            }
            else
            {
               HOLIDAY_BANNER_TIMES.splice(0,1);
               HOLIDAY_BANNER_MEDIA_IDS.splice(0,1);
               checkShouldDisplayHolidayBanner();
            }
         }
         return false;
      }
      
      public static function initMessagePopups(param1:Boolean = false) : void
      {
         DarkenManager.showLoadingSpiral(true);
         _startupPopups = new StartupPopups();
         _startupPopups.init(guiLayer,startupPopupsDestroyed,param1);
      }
      
      public static function setupInGameRedemptions() : void
      {
         if(_startupPopups)
         {
            _startupPopups.setNeedsToLoadAdditional();
         }
         else
         {
            initMessagePopups(true);
         }
      }
      
      private static function startupPopupsDestroyed() : void
      {
         if(_startupPopups)
         {
            _startupPopups = null;
         }
      }
      
      public static function openDaysRemainingPopup() : void
      {
         _expiringDaysPopup = new ExpiringDaysPopup(GuiManager.guiLayer,onExpiringPopupClose);
      }
      
      public static function onExpiringPopupClose(param1:MouseEvent) : void
      {
         if(_expiringDaysPopup)
         {
            _expiringDaysPopup.destroy();
            _expiringDaysPopup = null;
         }
      }
      
      public static function initDemotionMessage(param1:Function) : void
      {
         _demotionMessage = new DemotionMessages();
         _demotionMessage.init(param1);
      }
      
      public static function initPlayerEngagement(param1:Function) : void
      {
         _playerEngagement = new PlayerEngagement();
         _playerEngagement.init(param1);
      }
      
      public static function closePlayerEngagement(param1:Boolean) : void
      {
         if(_playerEngagement)
         {
            _playerEngagement.destroy(param1,true);
            _playerEngagement = null;
         }
      }
      
      public static function initEmailConfirmation(param1:Function, param2:MovieClip = null, param3:Boolean = false) : void
      {
         _emailConfirmation = new EmailConfirmation();
         _emailConfirmation.init(param1,param2,param3);
      }
      
      public static function set reconnecting(param1:Boolean) : void
      {
         _reconnecting = param1;
      }
      
      public static function get reconnecting() : Boolean
      {
         return _reconnecting;
      }
      
      public static function initMoviePlayer(param1:int, param2:StreamDefCollection, param3:Boolean = true, param4:int = 512, param5:int = 288) : void
      {
         if(_videoPlayer)
         {
            _videoPlayer.destroy();
         }
         _videoPlayer = new VideoPlayerOSMF();
         _videoPlayer.init(param2,param1,-1,param3,param4,param5);
      }
      
      public static function setVideoPlayerSkin(param1:int) : void
      {
         if(_videoPlayer)
         {
            _videoPlayer.setSkinFrame(param1);
         }
      }
      
      public static function togglePlayPauseVideoPlayer(param1:Boolean) : void
      {
         if(_videoPlayer)
         {
            _videoPlayer.togglePlayPause(param1);
         }
      }
      
      public static function startDenBtnGlow() : void
      {
         if(mainHud.denBtn)
         {
            _denBtnGlowTimer.start();
            mainHud.denBtn.glow.visible = true;
         }
      }
      
      public static function denBtnGlowTimerHandler(param1:TimerEvent) : void
      {
         _denBtnGlowTimer.reset();
         if(mainHud.denBtn)
         {
            mainHud.denBtn.glow.visible = false;
         }
      }
      
      public static function onNewsPaperBtn(param1:MouseEvent) : void
      {
         _newsOpenedFromBtn = param1 != null;
         if(_newsOpenedFromBtn)
         {
            param1.stopPropagation();
         }
         if(!mainHud.newsBtn.isGray)
         {
            if(mainHud.newsBtn.glow.visible && param1)
            {
               mainHud.newsBtn.glow.visible = false;
               mainHud.newsBtn.newJournal.visible = false;
               NewspaperManager.hasUnseenPages = false;
               NewspaperManager.hasSeenFirstPage = true;
            }
            NewspaperManager.openNewspaperPopup(onPageFlipCloseNP);
         }
      }
      
      private static function getNewsPaperList() : int
      {
         if(LocalizationManager.currentLanguage != LocalizationManager.LANG_ENG)
         {
            switch(LocalizationManager.currentLanguage)
            {
               case LocalizationManager.LANG_DE:
                  return 288;
               case LocalizationManager.LANG_FRE:
                  return 287;
               case LocalizationManager.LANG_POR:
                  return 290;
               case LocalizationManager.LANG_SPA:
                  return 289;
            }
         }
         return 34;
      }
      
      public static function onJourneyBookBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(!param1.currentTarget.isGray)
         {
            if(mainHud.book.glow.visible)
            {
               mainHud.book.glow.visible = false;
            }
            openJourneyBook();
         }
      }
      
      public static function openJourneyBook(param1:int = -1) : void
      {
         if(_pageFlip)
         {
            _pageFlip.destroy();
         }
         DarkenManager.showLoadingSpiral(true);
         if(param1 != -1)
         {
            GenericListXtCommManager.requestGenericList(53,onJourneyBookMediaListReceivedWithInfo,param1);
         }
         else
         {
            GenericListXtCommManager.requestGenericList(53,onJourneyBookMediaListReceived);
         }
      }
      
      private static function onJourneyBookMediaListReceived(param1:int, param2:Array, param3:Array, param4:int = -1) : void
      {
         var _loc5_:int = 0;
         SBTracker.push();
         var _loc6_:int = 1;
         _loc5_ = 0;
         while(_loc5_ < param3.length)
         {
            if(LocalizationManager.translateIdOnly(param3[_loc5_]).toLowerCase() == _currRoomDisplayNameModeratedLocalized.toLowerCase())
            {
               _loc6_ = _loc5_ + 1;
               break;
            }
            _loc5_++;
         }
         _roomMgr.forceStopMovement();
         _pageFlip = new PageFlip();
         _pageFlip.init(guiLayer,param2,true,onEBookClose,onJourneyBookFlipNP,false,0,false,true,_loc6_,param4);
      }
      
      private static function onJourneyBookMediaListReceivedWithInfo(param1:int, param2:Array, param3:Array, param4:Object) : void
      {
         onJourneyBookMediaListReceived(param1,param2,param3,int(param4));
      }
      
      public static function showJBGlow(param1:Boolean) : void
      {
         if(mainHud.book != null && !mainHud.book.isGray)
         {
            mainHud.book.glow.visible = param1;
         }
      }
      
      public static function updateJBIcon(param1:Boolean) : void
      {
         updateMainHudButtons(false,{
            "btnName":(mainHud as GuiHud).journeyBook.name,
            "show":param1
         });
         if(JBManager.numUnclaimedGifts > 0)
         {
            mainHud.book.gift.visible = true;
            mainHud.book.gift.giftCountTxt.text = JBManager.numUnclaimedGifts;
         }
         else
         {
            mainHud.book.gift.visible = false;
            mainHud.book.gift.giftCountTxt.text = "";
         }
      }
      
      public static function openEBookChooser(param1:String) : void
      {
         if(_eBookChooser)
         {
            _eBookChooser.destroy();
         }
         _roomMgr.forceStopMovement();
         _eBookChooser = new EBookChooser();
         _eBookChooser.init(param1,onEBookChooserClose);
         togglePlayPauseVideoPlayer(false);
         GenericListGuiManager.togglePlayPauseVideoPlayer(false);
      }
      
      private static function onEBookChooserClose() : void
      {
         togglePlayPauseVideoPlayer(true);
         GenericListGuiManager.togglePlayPauseVideoPlayer(true);
         if(_eBookChooser)
         {
            _eBookChooser.destroy();
            _eBookChooser = null;
         }
      }
      
      public static function openPageFlipBook(param1:int, param2:Boolean, param3:int, param4:int = 1) : void
      {
         if(_pageFlip)
         {
            _pageFlip.destroy();
         }
         DarkenManager.showLoadingSpiral(true);
         GenericListXtCommManager.requestGenericList(param1,onMediaListReceived,{
            "isRectangular":param2,
            "bookType":param3,
            "pageNumToOpenTo":param4
         });
      }
      
      private static function onMediaListReceived(param1:int, param2:Array, param3:Array, param4:Object) : void
      {
         _currentBookId = param1;
         SBTracker.push();
         _pageFlip = new PageFlip();
         _pageFlip.init(guiLayer,param2,false,onEBookClose,onEBookFlipNP,param4.isRectangular,param4.bookType,false,false,param4.pageNumToOpenTo);
         DarkenManager.showLoadingSpiral(false);
      }
      
      public static function onMyUserVarsReceived() : void
      {
         if(NewspaperManager.hasUnseenPages)
         {
            mainHud.newsBtn.glow.visible = true;
            mainHud.newsBtn.newJournal.visible = true;
         }
         else
         {
            mainHud.newsBtn.glow.visible = false;
            mainHud.newsBtn.newJournal.visible = false;
         }
         updateMainHudButtons(false,{
            "btnName":(mainHud as GuiHud).playerWallBtn.name,
            "show":Utility.isSettingOn(MySettings.SETTINGS_JAMMER_WALL_ICON)
         },{
            "btnName":(mainHud as GuiHud).newsBtn.name,
            "show":gMainFrame.userInfo.numLogins >= 2
         });
      }
      
      private static function onJourneyBookFlipNP(param1:String) : void
      {
         SBTracker.trackPageview("/game/play/popup/jb/#" + param1);
      }
      
      private static function onFlipNP(param1:int) : void
      {
         SBTracker.trackPageview("/game/play/popup/newspaper/#page" + param1);
      }
      
      private static function onEBookFlipNP(param1:int) : void
      {
         SBTracker.trackPageview("/game/play/popup/#book_" + _currentBookId + "/page" + param1);
      }
      
      public static function openJumpPopup(param1:Boolean, param2:Function, param3:MovieClip, param4:int) : void
      {
         SBTracker.trackPageview("/game/play/popup/ajJump" + (param1 ? "/joey" : "/gems"),-1,1);
         if(_joeyPopup)
         {
            if(!_joeyPopup.isJoey && !param1)
            {
               LocalizationManager.translateIdAndInsert(_joeyPopup.contentTxt,11097,Utility.convertNumberToString(_joeyPopup.currGiftId + param4));
               _joeyPopup.currGiftId += param4;
               return;
            }
            if(_joeyPopup.isJoey && param1)
            {
               return;
            }
            DarkenManager.unDarken(_joeyPopup);
            guiLayer.removeChild(_joeyPopup);
            _secondaryJoeyPopup = _joeyPopup;
         }
         var _loc5_:MediaHelper = new MediaHelper();
         _loc5_.init(2540,onJumpPopupLoaded,{
            "isJoey":param1,
            "callback":param2,
            "gemsImage":param3,
            "currGiftId":param4
         });
      }
      
      private static function onJumpPopupLoaded(param1:MovieClip) : void
      {
         var _loc2_:MediaHelper = null;
         if(param1)
         {
            _joeyPopup = param1.getChildAt(0);
            _joeyPopup.x = 900 * 0.5;
            _joeyPopup.y = 550 * 0.5;
            _joeyPopup.callback = param1.passback.callback;
            _joeyPopup.isJoey = param1.passback.isJoey;
            _joeyPopup.currGiftId = param1.passback.currGiftId;
            _joeyPopup.image = param1.passback.gemsImage;
            _joeyPopup.addEventListener("mouseDown",onPopup,false,0,true);
            _joeyPopup.xBtn.addEventListener("mouseDown",jumpCloseHandler,false,0,true);
            _loc2_ = new MediaHelper();
            if(param1.passback.isJoey)
            {
               _loc2_.init(2541,onJumpImageLoaded,_joeyPopup);
               LocalizationManager.translateId(_joeyPopup.contentTxt,11137);
            }
            else
            {
               if(_joeyPopup.image)
               {
                  _joeyPopup.itemWindow.addChild(_joeyPopup.image);
               }
               else
               {
                  _loc2_.init(1086,onJumpImageLoaded,_joeyPopup);
               }
               LocalizationManager.translateIdAndInsert(_joeyPopup.contentTxt,11097,_joeyPopup.currGiftId);
            }
            guiLayer.addChild(_joeyPopup);
            DarkenManager.showLoadingSpiral(false);
            DarkenManager.darken(_joeyPopup);
            param1.mediaHelper.destroy();
            delete param1.mediaHelper;
            delete param1.passback;
         }
      }
      
      private static function onJumpImageLoaded(param1:MovieClip) : void
      {
         if(param1)
         {
            param1.passback.itemWindow.addChild(param1);
            param1.mediaHelper.destroy();
            delete param1.mediaHelper;
            delete param1.passback;
         }
      }
      
      private static function jumpCloseHandler(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         _joeyPopup.removeEventListener("mouseDown",onPopup);
         _joeyPopup.xBtn.removeEventListener("mouseDown",jumpCloseHandler);
         DarkenManager.unDarken(_joeyPopup);
         guiLayer.removeChild(_joeyPopup);
         var _loc2_:MovieClip = _joeyPopup;
         _joeyPopup = null;
         if(_secondaryJoeyPopup)
         {
            _joeyPopup = _secondaryJoeyPopup;
            guiLayer.addChild(_joeyPopup);
            DarkenManager.darken(_joeyPopup);
            _secondaryJoeyPopup = null;
         }
         if(_loc2_.callback)
         {
            _loc2_.callback(_loc2_.isJoey,_loc2_.currGiftId,_loc2_.image);
         }
         _loc2_ = null;
      }
      
      public static function onSwapBtnClickHandler(param1:MouseEvent) : void
      {
         if(mainHud.swapBtn && mainHud.swapBtn.isGray || RoomXtCommManager.isSwitching)
         {
            return;
         }
         param1.stopPropagation();
         _roomMgr.forceStopMovement();
         if(_avtSwitcher)
         {
            _avtSwitcher.destroy();
         }
         SBTracker.push();
         SBTracker.trackPageview("/game/play/popup/avatarSwitch");
         _avtSwitcher = new AvatarSwitcher();
         _avtSwitcher.init(guiLayer,onAvtSwitchClose,false,false);
      }
      
      private static function onPetSwapBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(isBeYourPetRoom())
         {
            if(_petInventory)
            {
               _petInventory.destroy();
            }
            _petInventory = new PetInventory();
            _petInventory.init(onPetInventoryClose);
         }
      }
      
      private static function onPetInventoryClose() : void
      {
         _petInventory = null;
         showHudAvt();
         var _loc1_:AvatarWorldView = AvatarManager.playerAvatarWorldView;
         if(_loc1_)
         {
            _loc1_.setPos(_loc1_.x,_loc1_.y,false);
            _loc1_.updateChatBallonBgOffsets();
            if(!_loc1_.isActivePetGroundPet())
            {
               actionMgr.grayOutPetDanceBtn(true);
            }
            else
            {
               actionMgr.grayOutPetDanceBtn(false);
            }
            _roomMgr.rebuildGrid();
            if(RoomManagerWorld.instance.collisionTestGrid(_loc1_.x,_loc1_.y))
            {
               _roomMgr.teleportPlayerToDefault();
            }
         }
      }
      
      public static function switchToOceanAnimal(param1:Object) : void
      {
         if(param1.status)
         {
            if(mainHud.swapBtn && mainHud.swapBtn.isGray || RoomXtCommManager.isSwitching)
            {
               return;
            }
            if(QuestManager.isInPrivateAdventureState)
            {
               QuestManager.showLeaveQuestLobbyPopup(switchToOceanAnimal,param1);
               return;
            }
            _roomMgr.forceStopMovement();
            SBTracker.push();
            SBTracker.trackPageview("/game/play/popup/noOceanAnimal");
            _avtSwitcher = new AvatarSwitcher();
            _avtSwitcher.init(guiLayer,onAvtSwitchClose,false,true,param1.passback.switchRooms,param1.passback.switchDens);
         }
      }
      
      public static function openAvatarChoose() : void
      {
         if(_avtSwitcher)
         {
            _avtSwitcher.destroy();
         }
         _avtSwitcher = new AvatarSwitcher();
         _avtSwitcher.init(guiLayer,chooseAvatarCloseCallback,true,false);
      }
      
      public static function openDenRoomSwitcher(param1:Boolean = false, param2:Function = null, param3:Boolean = false, param4:int = -1, param5:int = -1, param6:int = -1) : void
      {
         if(_denSwitcher)
         {
            _denSwitcher.destroy();
         }
         if(!param1)
         {
            SBTracker.push();
            SBTracker.trackPageview("/game/play/popup/denSwitch");
         }
         if(param2 == null)
         {
            param2 = onDenSwitchClose;
         }
         _denSwitcher = new DenSwitcher();
         _denSwitcher.init(AvatarManager.playerAvatar,guiLayer,param1,param3,param2,param4,param5,param6,900 * 0.5,550 * 0.5);
      }
      
      public static function get denSwitcherCurrentIndex() : int
      {
         if(_denSwitcher)
         {
            return _denSwitcher.idx;
         }
         return -1;
      }
      
      public static function showDenSwitcher(param1:Boolean, param2:int = -1) : void
      {
         if(_denSwitcher)
         {
            _denSwitcher.showDenSwitcher(param1,param2);
         }
      }
      
      public static function get currDenSwitcher() : DenSwitcher
      {
         return _denSwitcher;
      }
      
      public static function updateDenRoomCount(param1:int, param2:Boolean, param3:String) : void
      {
         if(param3 == gMainFrame.userInfo.myUserName)
         {
            if(param2)
            {
               param1--;
            }
         }
         else if(denEditor != null)
         {
            param1--;
         }
         if(mainHud.denCount)
         {
            if(param1 > 0)
            {
               if(_currentDenRoomCount < param1)
               {
                  startDenBtnGlow();
                  if(!Utility.isSettingOn(MySettings.SETTINGS_DOOR_BELL))
                  {
                     AJAudio.playDoorBellSound();
                  }
               }
               mainHud.denCount.denCountTxt.text = param1;
               mainHud.denCount.visible = true;
            }
            else
            {
               mainHud.denCount.visible = false;
            }
         }
         _currentDenRoomCount = param1;
      }
      
      private static function updateDaysLeftCount() : void
      {
         if(mainHud.memDaysLeft)
         {
            if(gMainFrame.clientInfo.subscriptionSourceType == 11)
            {
               mainHud.memDaysLeft.visible = true;
               if(gMainFrame.clientInfo.numDaysLeftOnSubscription > 1)
               {
                  (mainHud.memDaysLeft as GuiSoundToggleButton).setTextInLayer(LocalizationManager.translateIdAndInsertOnly(6260,gMainFrame.clientInfo.numDaysLeftOnSubscription),"daysLeftTxt");
               }
               else if(gMainFrame.clientInfo.numDaysLeftOnSubscription == 1)
               {
                  (mainHud.memDaysLeft as GuiSoundToggleButton).setTextInLayer(LocalizationManager.translateIdOnly(33589),"daysLeftTxt");
               }
               else
               {
                  (mainHud.memDaysLeft as GuiSoundToggleButton).setTextInLayer(LocalizationManager.translateIdOnly(18061),"daysLeftTxt");
               }
            }
            else
            {
               mainHud.memDaysLeft.visible = false;
            }
         }
      }
      
      private static function chooseAvatarCloseCallback() : void
      {
         if(_avtSwitcher)
         {
            _avtSwitcher.destroy();
            _avtSwitcher = null;
         }
         _demotionMessage.hasChosen = true;
         _demotionMessage.goToNextPage();
      }
      
      private static function onSoundBtnClickHandler(param1:MouseEvent) : void
      {
         SBAudio.toggleMuteAll();
         toggleMuteVideo();
         if(_mySettings)
         {
            _mySettings.updateSoundBtn();
         }
         TutorialPopups.handleSoundBtnClick();
      }
      
      public static function updateSettingsMessage() : void
      {
         if(_mySettings)
         {
            _mySettings.updateWorldMessage();
         }
      }
      
      public static function toggleMuteVideo() : void
      {
         if(_roomMgr.theaterWindow && GenericListGuiManager.movieSelector && GenericListGuiManager.movieSelector.videoPlayer)
         {
            GenericListGuiManager.movieSelector.videoPlayer.toggleSound();
         }
      }
      
      public static function depressSoundButton(param1:Boolean) : void
      {
         if(param1)
         {
            mainHud.soundBtn.upToDownState();
         }
         else
         {
            mainHud.soundBtn.downToUpState();
         }
      }
      
      public static function onPartyBtn(param1:MouseEvent) : void
      {
         if(param1)
         {
            param1.stopPropagation();
         }
         if(!mainHud.partyBtn.isGray)
         {
            if(!param1)
            {
               mainHud.partyBtn.upToDownState();
            }
            if(BuddyList.visible)
            {
               BuddyList.closeBuddyList();
            }
            if(mainHud.partyBtn.glow.visible)
            {
               mainHud.partyBtn.glow.visible = false;
            }
            PartyManager.openPartyPopup();
         }
      }
      
      public static function showPartyBtnGlow(param1:Boolean) : void
      {
         if(mainHud.partyBtn && !mainHud.partyBtn.isGray)
         {
            if(gMainFrame.userInfo.firstFiveMinutes > 0)
            {
               mainHud.partyBtn.glow.visible = param1;
            }
         }
      }
      
      private static function onMySettingsBtnClickHandler(param1:MouseEvent) : void
      {
         if(!param1.currentTarget.isGray)
         {
            if(_mySettings != null)
            {
               _mySettings.destroy();
               _mySettings = null;
            }
            else
            {
               if(_reportAPlayer)
               {
                  _reportAPlayer.destroy();
                  _reportAPlayer = null;
                  mainHud.reportBtn.downToUpState();
               }
               _mySettings = new MySettings();
               _mySettings.init(guiLayer,740,240,onMySettingsClose);
            }
         }
      }
      
      private static function onReportBtnClickHandler(param1:MouseEvent) : void
      {
         if(!param1.currentTarget.isGray)
         {
            if(_reportAPlayer)
            {
               _reportAPlayer.destroy();
               _reportAPlayer = null;
            }
            else
            {
               if(_mySettings)
               {
                  _mySettings.destroy();
                  _mySettings = null;
                  mainHud.mySettingsBtn.downToUpState();
               }
               _reportAPlayer = new ReportAPlayer();
               _reportAPlayer.init(0,guiLayer,onReportAPlayerClose,false,null,null,true,null,-1,756,130);
            }
         }
      }
      
      public static function displayRulesPopup(param1:Boolean, param2:Function = null) : void
      {
         if(param1)
         {
            if(_rulesPopup)
            {
               _rulesPopup.destroy();
               _rulesPopup = null;
            }
            _rulesPopup = new SBPopup(guiLayer,GETDEFINITIONBYNAME("ReportRulesPopupSkin"),GETDEFINITIONBYNAME("ReportRulesPopupContent"),true,true,false,false,true);
            _rulesPopup.x = 900 * 0.5;
            _rulesPopup.y = 550 * 0.5;
            if(param2 != null)
            {
               _rulesPopup.closeBtn.addEventListener("mouseDown",param2,false,0,true);
            }
         }
         else if(_rulesPopup)
         {
            _rulesPopup.destroy();
            _rulesPopup = null;
         }
      }
      
      public static function openJammerCentral() : void
      {
         if(_jammerCentral)
         {
            _jammerCentral.destroy();
            _jammerCentral = null;
         }
         SBTracker.push();
         SBTracker.trackPageview("/game/play/popup/jammerCentral");
         _jammerCentral = new BulletinBoard();
         _jammerCentral.init(guiLayer,onJammerCentralClose);
      }
      
      private static function onJammerCentralClose() : void
      {
         SBTracker.flush(true);
         _jammerCentral.destroy();
         _jammerCentral = null;
      }
      
      private static function onGemsBtnRollOverOutHandler(param1:MouseEvent) : void
      {
         var _loc2_:String = null;
         var _loc3_:int = 0;
         param1.stopPropagation();
         if(!param1.currentTarget.isGray)
         {
            if(_gemTimeline == null)
            {
               _gemTimeline = new TimelineLite();
            }
            if(param1.type == "rollOut")
            {
               if(_alwaysOpenGems)
               {
                  return;
               }
               if(_gemTimeline)
               {
                  _gemTimeline.reverse();
               }
               return;
            }
            _loc2_ = "gem";
            if(UserCurrency.getCurrency(1) > 0)
            {
               _loc2_ += "Tic";
            }
            if(UserCurrency.getCurrency(3) > 0)
            {
               _loc2_ += "Dia";
            }
            _gemTimeline.progress(0);
            _gemTimeline.reversed(false);
            mainHud.money.gotoAndStop(_loc2_);
            mainHud.money.mouse.currencyToolTipCont.currencyTxt.text = Utility.convertNumberToString(UserCurrency.getCurrency(0));
            _loc3_ = 1;
            _gemTimeline.clear();
            _gemTimeline.paused(true);
            _gemTimeline.to(mainHud.money.mouse.currencyToolTipCont,0.1,{
               "x":-6.15,
               "y":-12.25,
               "scaleX":1,
               "scaleY":1,
               "alpha":1,
               "ease":SlowMo.ease
            },0);
            _gemTimeline.to(mainHud.money.mouse.bg,0.1,{
               "scaleX":1,
               "scaleY":1,
               "alpha":0.3,
               "ease":SlowMo.ease
            },0);
            if(mainHud.money.mouse.tickets)
            {
               mainHud.money.mouse.tickets.currencyToolTipCont.currencyTxt.text = Utility.convertNumberToString(UserCurrency.getCurrency(1));
               _gemTimeline.to(mainHud.money.mouse.tickets,0.1,{
                  "y":"+=" + 40 * _loc3_,
                  "scaleX":1,
                  "scaleY":1,
                  "alpha":1,
                  "ease":SlowMo.ease
               },0);
               _loc3_++;
            }
            if(mainHud.money.mouse.diamonds)
            {
               mainHud.money.mouse.diamonds.currencyToolTipCont.currencyTxt.text = Utility.convertNumberToString(UserCurrency.getCurrency(3));
               _gemTimeline.to(mainHud.money.mouse.diamonds,0.1,{
                  "y":"+=" + 40 * _loc3_,
                  "scaleX":1,
                  "scaleY":1,
                  "alpha":1,
                  "ease":SlowMo.ease
               },0);
            }
            if(!_gemTimeline.reversed())
            {
               _gemTimeline.play();
            }
         }
      }
      
      private static function denBtnMouseDownHandler(param1:MouseEvent) : void
      {
         if(!param1.currentTarget.isGray)
         {
            param1.currentTarget.downToUpState();
            param1.stopPropagation();
            DarkenManager.showLoadingSpiral(true);
            DenXtCommManager.requestDenJoinFull("den" + gMainFrame.userInfo.myUserName);
            mainHud.denBtn.downToUpState();
         }
      }
      
      public static function openJoinGamesPopup() : void
      {
         onGamesBtn(null);
      }
      
      public static function closeJoinGamesPopup() : void
      {
         onCloseGamesPopup();
      }
      
      private static function onGamesBtn(param1:MouseEvent) : void
      {
         if(param1)
         {
            param1.stopPropagation();
         }
         if(!mainHud.games.isGray)
         {
            if(_joinGamesPopup)
            {
               _joinGamesPopup.destroy();
            }
            _roomMgr.forceStopMovement();
            _joinGamesPopup = new GameJoinPopup(onCloseGamesPopup);
         }
      }
      
      private static function onMemDaysLeft(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         openDaysRemainingPopup();
      }
      
      private static function onAjEmailBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         initEmailConfirmation(null,null,false);
      }
      
      private static function onCloseGamesPopup() : void
      {
         if(_joinGamesPopup)
         {
            _joinGamesPopup.destroy();
            _joinGamesPopup = null;
         }
      }
      
      public static function openCodeRedemptionPopup(param1:Function = null) : void
      {
         if(_codeRedemptionPopup)
         {
            _codeRedemptionPopup.destroy();
         }
         _codeRedemptionCloseCallback = param1;
         _codeRedemptionPopup = new CodeRedemptionPopup();
         _codeRedemptionPopup.init(onCodeRedemptionClose);
      }
      
      private static function onCodeRedemptionClose() : void
      {
         if(_codeRedemptionPopup)
         {
            _codeRedemptionPopup.destroy();
            _codeRedemptionPopup = null;
         }
         if(_codeRedemptionCloseCallback != null)
         {
            _codeRedemptionCloseCallback();
            _codeRedemptionCloseCallback = null;
         }
      }
      
      public static function onExitRoom(param1:Boolean = false, param2:Boolean = false) : void
      {
         if(!param1)
         {
            BuddyList.closeBuddyList();
         }
         NGFactManager.closeFact();
         if(!param1)
         {
            if(_mySettings != null)
            {
               _mySettings.destroy();
               _mySettings = null;
               mainHud.mySettingsBtn.downToUpState();
            }
            if(_reportAPlayer)
            {
               if(_reportAPlayer.visible)
               {
                  mainHud.reportBtn.downToUpState();
               }
               _reportAPlayer.destroy();
               _reportAPlayer = null;
            }
            chatHist.resetTreeSearch();
            PlayerWallManager.setForWaitingOnWallResponse(false);
         }
         ReportAPlayer.closeReportFromCardPopoup();
         if(_videoPlayer)
         {
            _videoPlayer.destroy();
            _videoPlayer = null;
         }
         PartyManager.closePartyPopup(param2);
         if(_pageFlip)
         {
            onPageFlipCloseNP();
         }
         ECardManager.closeECard();
         if(volumeMgr && volumeMgr.visible)
         {
            volumeMgr.show(false,0);
         }
         if(_avEditor)
         {
            _avEditor.destroy();
            _avEditor = null;
         }
         if(chatHist)
         {
            chatHist.closeChat();
            chatHist.closeChatRepeatWindow();
         }
         gui.TradeManager.closeAllTradingRelatedPopups();
         QuestManager.closeAdventurePopups();
         PlayerWallManager.closeWalls();
         if(!param2)
         {
            ShopManager.closeWorldShop();
         }
         showJBGlow(false);
         BuddyManager.destroyBuddyCard();
         onCloseGamesPopup();
         closeMasterpiecePreview();
         if(_denSwitcher != null && !param2)
         {
            _denSwitcher.destroy();
            _denSwitcher = null;
         }
      }
      
      public static function closeAnyInventoryRelatedWindows() : void
      {
         ECardManager.closeECard();
         if(_avEditor)
         {
            gui.TradeManager.resetNumTradeItems(_avEditor.numClothingItemsInTradeListInitially,_avEditor.numDenItemsInTradeListInitially,_avEditor.numPetItemsInTradeListInitially);
            _avEditor.destroy();
            _avEditor = null;
         }
         if(_roomMgr)
         {
            _roomMgr.onRecycleClose();
         }
         if(denEditor)
         {
            denEditor.closeDenCustomization();
            onDenSwitchClose();
         }
      }
      
      public static function closeAnyHudPopups() : void
      {
         BuddyList.closeBuddyList();
         NGFactManager.closeFact();
         if(_mySettings != null)
         {
            _mySettings.destroy();
            _mySettings = null;
            mainHud.mySettingsBtn.downToUpState();
         }
         if(_reportAPlayer)
         {
            if(_reportAPlayer.visible)
            {
               mainHud.reportBtn.downToUpState();
            }
            _reportAPlayer.destroy();
            _reportAPlayer = null;
         }
         PartyManager.closePartyPopup();
      }
      
      public static function closeWorldMapIfOpen() : void
      {
         if(volumeMgr && volumeMgr.visible)
         {
            volumeMgr.show(false,0);
         }
      }
      
      public static function resetPetWindowListAndUpdateBtns() : void
      {
         if(denEditor)
         {
            denEditor.resetPetWindowListAndUpdateBtns();
         }
      }
      
      public static function updateSwitchRecycleBtnVisibility() : void
      {
         if(denEditor)
         {
            denEditor.updateSwitchRecycleBtnVisibility();
         }
      }
      
      public static function refreshDenLockSettings() : void
      {
         if(denEditor)
         {
            denEditor.refreshDenLockSettings();
         }
      }
      
      public static function resetItemAndThemeDenWindows() : void
      {
         if(denEditor)
         {
            denEditor.clearItemWindows();
         }
      }
      
      public static function resetWindowsAndTabsToNormal() : void
      {
         if(denEditor)
         {
            denEditor.resetWindowsAndTabsToNormal();
         }
      }
      
      public static function openWorldMap() : void
      {
         _roomMgr.forceStopMovement();
         volumeMgr.show(true,0);
      }
      
      public static function onPhotoBoothClose(param1:int = -1, param2:int = -1, param3:int = -1) : void
      {
         SBTracker.pop();
         _photoBooth.destroy();
         _photoBooth = null;
         if(_photoBoothCallback != null)
         {
            _photoBoothCallback(param1,param2,param3);
            _photoBoothCallback = null;
         }
      }
      
      public static function onAvEditorClose() : void
      {
         SBTracker.pop();
         _avEditor.destroy();
         _avEditor = null;
         if(_avEditorCloseCallback != null)
         {
            _avEditorCloseCallback();
            _avEditorCloseCallback = null;
         }
      }
      
      public static function onPageFlipCloseNP() : void
      {
         if(!_newsOpenedFromBtn && !_hasClosedGemBonus)
         {
            guiStartupChecks();
         }
      }
      
      public static function openDailyGift(param1:int) : void
      {
         if(_dailyGiftManager)
         {
            _dailyGiftManager.destroy();
            _dailyGiftManager = null;
         }
         DarkenManager.showLoadingSpiral(true);
         _dailyGiftManager = new DailyGiftManager();
         _dailyGiftManager.init(param1,onDailyGiftClose);
      }
      
      private static function onDailyGiftClose() : void
      {
         _dailyGiftManager.destroy();
         _dailyGiftManager = null;
         _hasClosedGemBonus = true;
         guiStartupChecks();
      }
      
      public static function openMuseumDonation() : void
      {
         if(_museumDonation)
         {
            _museumDonation.destroy();
            _museumDonation = null;
         }
         _museumDonation = new MuseumDonation();
         _museumDonation.init(onMuseumDonationClose);
      }
      
      private static function onMuseumDonationClose() : void
      {
         _museumDonation.destroy();
         _museumDonation = null;
      }
      
      public static function openGemBonusWheel(param1:int) : void
      {
         if(_gemBonusWheel)
         {
            _gemBonusWheel.destroy();
            _gemBonusWheel = null;
         }
         _roomMgr.forceStopMovement();
         _gemBonusWheel = new GemBonusSpinWheel();
         _gemBonusWheel.init(param1,onGemBonusClose);
      }
      
      public static function setGemBonusValues(param1:uint) : void
      {
         if(_gemBonusWheel)
         {
            _gemBonusWheel.setupValuesAndSpin(param1);
         }
      }
      
      private static function onGemBonusClose() : void
      {
         _gemBonusWheel.destroy();
         _gemBonusWheel = null;
         _hasClosedGemBonus = true;
         guiStartupChecks();
      }
      
      public static function openHolidayBanner() : void
      {
         DarkenManager.showLoadingSpiral(true);
         var _loc1_:MediaHelper = new MediaHelper();
         _loc1_.init(HOLIDAY_BANNER_MEDIA_IDS[0],onHolidayBannerLoaded);
      }
      
      private static function onHolidayBannerLoaded(param1:MovieClip) : void
      {
         DarkenManager.showLoadingSpiral(false);
         _holidayBanner = param1.getChildAt(0);
         _holidayBanner.addEventListener("mouseDown",onPopup,false,0,true);
         _holidayBanner.bx.addEventListener("mouseDown",onCloseHolidayBanner,false,0,true);
         guiLayer.addChild(_holidayBanner);
         DarkenManager.darken(_holidayBanner);
         AchievementXtCommManager.requestSetUserVar(Achievement.HOLIDAY_BANNER,HOLIDAY_BANNER_TIMES[0].start);
         var _loc2_:Timer = new Timer(7000);
         _loc2_.addEventListener("timer",onHolidayTimerComplete,false,0,true);
         _loc2_.start();
         _holidayBanner.timer = _loc2_;
      }
      
      private static function onHolidayTimerComplete(param1:TimerEvent) : void
      {
         _holidayBanner.timer.stop();
         _holidayBanner.timer.removeEventListener("timer",onHolidayTimerComplete);
         _holidayBanner.timer = null;
         onCloseHolidayBanner(null);
      }
      
      private static function onCloseHolidayBanner(param1:MouseEvent) : void
      {
         if(param1)
         {
            param1.stopPropagation();
         }
         if(_holidayBanner)
         {
            if(_holidayBanner.timer)
            {
               _holidayBanner.timer.stop();
               _holidayBanner.timer.removeEventListener("timer",onHolidayTimerComplete);
               _holidayBanner.timer = null;
            }
            DarkenManager.unDarken(_holidayBanner);
            guiLayer.removeChild(_holidayBanner);
            _holidayBanner.removeEventListener("mouseDown",onPopup);
            _holidayBanner.bx.removeEventListener("mouseDown",onCloseHolidayBanner);
            _holidayBanner = null;
         }
      }
      
      public static function onEBookClose() : void
      {
         if(_pageFlip)
         {
            SBTracker.pop();
            _pageFlip.destroy();
            _pageFlip = null;
         }
      }
      
      public static function onAvtSwitchClose() : void
      {
         SBTracker.pop();
         if(_avtSwitcher)
         {
            _avtSwitcher.destroy();
            _avtSwitcher = null;
         }
         _roomMgr.setMinigameIdToJoin(-1);
      }
      
      public static function closeAvtSwitcherFromRoomJoin() : void
      {
         if(_avtSwitcher && _avtSwitcher.isChoosing)
         {
            return;
         }
         RoomXtCommManager.isSwitching = false;
         if(_avtSwitcher)
         {
            _avtSwitcher.destroy();
            _avtSwitcher = null;
         }
      }
      
      public static function onDenSwitchClose(param1:Boolean = false) : void
      {
         if(!param1)
         {
            SBTracker.pop();
         }
         if(_denSwitcher)
         {
            _denSwitcher.destroy();
            _denSwitcher = null;
         }
      }
      
      public static function onMySettingsClose() : void
      {
         if(_mySettings)
         {
            mainHud.mySettingsBtn.downToUpState();
            _mySettings.destroy();
            _mySettings = null;
         }
      }
      
      public static function onReportAPlayerClose(param1:Boolean) : void
      {
         if(_reportAPlayer)
         {
            mainHud.reportBtn.downToUpState();
            _reportAPlayer.destroy();
            _reportAPlayer = null;
         }
      }
      
      public static function openDiamondShopInfo() : void
      {
         if(_diamondShopInfoPopup == null)
         {
            DarkenManager.showLoadingSpiral(true);
            _diamondMediaHelper = new MediaHelper();
            _diamondMediaHelper.init(2222,onDiamondInfoLoaded);
         }
         else
         {
            guiLayer.addChild(_diamondShopInfoPopup);
            DarkenManager.darken(_diamondShopInfoPopup);
         }
      }
      
      public static function openDisplayImagesPopup() : void
      {
         if(_imageDisplayPopup)
         {
            _imageDisplayPopup.destroy();
         }
         _imageDisplayPopup = new ImageDisplayPopup(onImageDisplayClose,189,372);
      }
      
      private static function onImageDisplayClose() : void
      {
         if(_imageDisplayPopup)
         {
            _imageDisplayPopup.destroy();
            _imageDisplayPopup = null;
         }
      }
      
      private static function onDiamondInfoLoaded(param1:MovieClip) : void
      {
         DarkenManager.showLoadingSpiral(false);
         _diamondShopInfoPopup = param1.getChildAt(0);
         _diamondShopInfoPopup.addEventListener("mouseDown",onPopup,false,0,true);
         if(!gMainFrame.userInfo.isMember)
         {
            _diamondShopInfoPopup.memberSpinBtn.addEventListener("mouseDown",onDiamondMemberSpinInfoBtn,false,0,true);
            _diamondShopInfoPopup.memberSpinBtn.visible = true;
         }
         else
         {
            _diamondShopInfoPopup.memberSpinBtn.visible = false;
         }
         _diamondShopInfoPopup.bx.addEventListener("mouseDown",onDiamondInfoClose,false,0,true);
         _diamondShopInfoPopup.x = 900 * 0.5;
         _diamondShopInfoPopup.y = 550 * 0.5;
         guiLayer.addChild(_diamondShopInfoPopup);
         DarkenManager.darken(_diamondShopInfoPopup);
      }
      
      private static function onDiamondMemberSpinInfoBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         openDailySpinInfoPopup();
      }
      
      private static function onDiamondInfoClose(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         DarkenManager.unDarken(_diamondShopInfoPopup);
         guiLayer.removeChild(_diamondShopInfoPopup);
      }
      
      public static function openDailySpinInfoPopup() : void
      {
         DarkenManager.showLoadingSpiral(true);
         _diamondMediaHelper = new MediaHelper();
         _diamondMediaHelper.init(5714,onDiamondSpinInfoLoaded);
      }
      
      private static function onDiamondSpinInfoLoaded(param1:MovieClip) : void
      {
         DarkenManager.showLoadingSpiral(false);
         _diamondSpinInfoPopup = param1.getChildAt(0);
         _diamondSpinInfoPopup.addEventListener("mouseDown",onPopup,false,0,true);
         _diamondSpinInfoPopup.bx.addEventListener("mouseDown",onDiamondSpinInfoClose,false,0,true);
         _diamondSpinInfoPopup.joinClubBtn.addEventListener("mouseDown",onJoinClubBtn,false,0,true);
         _diamondSpinInfoPopup.x = 900 * 0.5;
         _diamondSpinInfoPopup.y = 550 * 0.5;
         guiLayer.addChild(_diamondSpinInfoPopup);
         DarkenManager.darken(_diamondSpinInfoPopup);
      }
      
      private static function onJoinClubBtn(param1:MouseEvent) : void
      {
         var _loc3_:String;
         var _loc2_:URLRequest;
         param1.stopPropagation();
         _loc3_ = gMainFrame.clientInfo.websiteURL + "membership";
         _loc2_ = new URLRequest(_loc3_);
         try
         {
            navigateToURL(_loc2_,"_blank");
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace("error with loading URL");
         }
      }
      
      private static function onDiamondSpinInfoClose(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         DarkenManager.unDarken(_diamondSpinInfoPopup);
         guiLayer.removeChild(_diamondSpinInfoPopup);
      }
      
      public static function openVersionPopup(param1:Boolean) : void
      {
         if(param1)
         {
            _differentVersionPopup = new SBYesNoPopup(guiLayer,LocalizationManager.translateIdOnly(21795),true,onVersionPopupConfirm);
         }
         else
         {
            _differentVersionPopup = new SBOkPopup(guiLayer,LocalizationManager.translateIdOnly(21850),true,onVersionPopupConfirm);
         }
      }
      
      public static function isVersionPopupOpen() : Boolean
      {
         if(_differentVersionPopup && _differentVersionPopup.visible)
         {
            _differentVersionPopup.parent.setChildIndex(_differentVersionPopup,_differentVersionPopup.parent.numChildren - 1);
            return true;
         }
         return false;
      }
      
      private static function onVersionPopupConfirm(param1:Object = null) : void
      {
         if(param1 && param1.hasOwnProperty("status"))
         {
            if(param1.status)
            {
               Utility.reloadSWFOrGetIp();
            }
         }
         else
         {
            param1.stopPropagation();
         }
         _differentVersionPopup.destroy();
         _differentVersionPopup = null;
      }
      
      private static function mainHudMouseDownHandler(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         gMainFrame.stage.addEventListener("mouseDown",clickedOutsideChatCui,false,0,true);
      }
      
      private static function charWindowDownHandler(param1:MouseEvent) : void
      {
         var _loc2_:Object = null;
         if(!param1.currentTarget.isGray)
         {
            param1.stopPropagation();
            if(!RoomXtCommManager.isSwitching && !QuestManager.isInPrivateAdventureState)
            {
               if(isBeYourPetRoom())
               {
                  DarkenManager.showLoadingSpiral(false);
                  _loc2_ = {"typeDefId":52};
                  MinigameManager.handleGameClick(_loc2_,null,false,showHudAvt);
               }
               else
               {
                  openAvatarEditor();
               }
               toolTip.resetTimerAndSetVisibility();
            }
         }
      }
      
      public static function openPhotoBooth(param1:Function = null, param2:Boolean = false) : void
      {
         if(_photoBooth)
         {
            _photoBooth.destroy();
            _photoBooth = null;
         }
         else
         {
            _roomMgr.forceStopMovement();
            SBTracker.push();
            SBTracker.trackPageview("/game/play/popup/photoBooth");
            _photoBoothCallback = param1;
            _photoBooth = new PhotoBooth();
            _photoBooth.init(onPhotoBoothClose,param2);
         }
      }
      
      public static function openAvatarEditor(param1:Function = null, param2:Boolean = false) : void
      {
         _roomMgr.forceStopMovement();
         _avEditorCloseCallback = param1;
         if(_avEditor)
         {
            _avEditor.destroy();
            _avEditor = null;
         }
         else
         {
            SBTracker.push();
            SBTracker.trackPageview("/game/play/popup/avatarEditor");
            _avEditor = new gui.AvatarEditor();
            _avEditor.init(AvatarManager.playerAvatar,guiLayer,onAvEditorClose,isInFFM,param2);
         }
      }
      
      public static function openAvEditorRecycle() : void
      {
         if(_avEditor)
         {
            _avEditor.openRecycle();
         }
      }
      
      public static function openAvatarCreator(param1:Boolean, param2:Boolean, param3:int = -1, param4:Boolean = false, param5:Iitem = null) : void
      {
         if(_avatarCreator)
         {
            if(_avatarCreator.parent == guiLayer)
            {
               guiLayer.removeChild(_avatarCreator);
            }
            _avatarCreator.destroy();
         }
         _avatarCreator = new GuiAvatarCreationAssets();
         _avatarCreator.initFromWorld(param1,param2,param3,param4,false,param5);
         guiLayer.addChild(_avatarCreator);
      }
      
      public static function closeAvatarCreator() : void
      {
         if(_avatarCreator)
         {
            guiLayer.removeChild(_avatarCreator);
            _avatarCreator.destroy();
            _avatarCreator = null;
         }
      }
      
      public static function openFastPassAvatarCreator() : void
      {
         if(_avatarCreator)
         {
            guiLayer.removeChild(_avatarCreator);
            _avatarCreator.destroy();
         }
         _avatarCreator = new GuiAvatarCreationAssets();
         _avatarCreator.initFromWorld(false,true,-1,false,true);
         guiLayer.addChild(_avatarCreator);
      }
      
      public static function openPetCertificatePopup(param1:GuiPet, param2:Function) : void
      {
         if(_petCertificatePopup)
         {
            _petCertificatePopup.destroy();
         }
         _petCertificatePopupCloseCallback = param2;
         _petCertificatePopup = new PetCertificatePopup();
         _petCertificatePopup.init(param1,onPetCertificateClose);
      }
      
      public static function onPetCertificateClose() : void
      {
         _petCertificatePopup.destroy();
         _petCertificatePopup = null;
         if(_petCertificatePopupCloseCallback != null)
         {
            _petCertificatePopupCloseCallback();
         }
         _petCertificatePopupCloseCallback = null;
      }
      
      public static function onEnterRoom(param1:int) : void
      {
         var _loc3_:Boolean = false;
         var _loc2_:Object = null;
         if(_currRoomDisplayName == "Brady Barr\'s Lab")
         {
            if(gMainFrame.userInfo.userVarCache.getUserVarValueById(128) < 0)
            {
               AchievementXtCommManager.requestSetUserVar(128,1);
               GenericListGuiManager.genericListVolumeClicked(19,{"msg":"bb"});
            }
         }
         else if(_currRoomDisplayName == "Tierney\'s Aquarium")
         {
            if(gMainFrame.userInfo.userVarCache.getUserVarValueById(297) < 0)
            {
               AchievementXtCommManager.requestSetUserVar(297,1);
               GenericListGuiManager.genericListVolumeClicked(78,{"msg":"tt"});
            }
         }
         else if(_currRoomDisplayName == "Medical Center")
         {
            if(gMainFrame.userInfo.userVarCache.getUserVarValueById(436) < 0)
            {
               AchievementXtCommManager.requestSetUserVar(436,1);
               GenericListGuiManager.genericListVolumeClicked(433,{"msg":""});
            }
         }
         setFocusToChatText();
         if(mainHud.currentFrame != param1 + 1 || gMainFrame.clientInfo.roomType == 7)
         {
            _loc3_ = false;
            if(gMainFrame.clientInfo.roomType == 7 && QuestManager._questScriptDefId != 0)
            {
               _loc2_ = QuestXtCommManager.getScriptDef(QuestManager._questScriptDefId);
               if(_loc2_ != null && _loc2_.hudType == 0)
               {
                  _loc3_ = true;
               }
            }
            if(_loc3_)
            {
               if(mainHud.currentFrameLabel != "quest")
               {
                  enableGameHud(true,"quest");
               }
               else
               {
                  updateQuestHud();
               }
            }
            else
            {
               if(mainHud.currentFrameLabel == "quest" || mainHud.currentFrameLabel == "game")
               {
                  enableGameHud(false);
               }
               mainHud.gotoAndStop(param1 + 1);
               mainHud.chat.chatHistoryBG.chatHistBox.hud01_chatHistory.gotoAndStop(param1 + 1);
            }
            actionMgr.turnOnOceanActions(param1 == 1);
         }
         if(isBeYourPetRoom())
         {
            if(mainHud.swapBtn)
            {
               mainHud.swapBtn.visible = false;
            }
         }
         else if(mainHud.swapBtn)
         {
            mainHud.swapBtn.visible = true;
         }
         if(!QuestManager.isInPrivateAdventureState)
         {
            GuiManager.setSwapBtnGray(false);
         }
      }
      
      public static function setFocusToChatText() : void
      {
         if(chatHist)
         {
            chatHist.setFocusOnMsgText();
         }
      }
      
      public static function setFocusToChatTextWithEvent(param1:KeyboardEvent, param2:String) : void
      {
         if(chatHist)
         {
            chatHist.setFocusToChatTextWithKeydown(param1,param2);
         }
      }
      
      public static function showHudAvt() : void
      {
         var _loc1_:Object = null;
         while(mainHud.charWindow.charLayer.numChildren > 0)
         {
            mainHud.charWindow.charLayer.removeChildAt(0);
         }
         if(isBeYourPetRoom())
         {
            _loc1_ = PetManager.myActivePet;
            if(_loc1_)
            {
               new GuiPet(_loc1_.createdTs,_loc1_.idx,_loc1_.lBits,_loc1_.uBits,_loc1_.eBits,_loc1_.type,_loc1_.name,_loc1_.personalityDefId,_loc1_.favoriteToyDefId,_loc1_.favoriteFoodDefId,onBigPetLoaded);
            }
         }
         else
         {
            if(_hudAvtView)
            {
               if(_hudAvtView.parent == mainHud.charWindow.charLayer)
               {
                  mainHud.charWindow.charLayer.removeChild(_hudAvtView);
               }
               _hudAvtView.destroy();
            }
            if(AvatarManager.playerAvatar)
            {
               _hudAvtView = new AvatarView();
               _hudAvtView.init(AvatarManager.playerAvatar,null,onHudViewChanged);
               _hudAvtView.playAnim(15,false,1,null,!getDisplayClothesInHudEnabled());
               positionHudAvatar();
               mainHud.charWindow.charLayer.addChild(_hudAvtView);
            }
         }
         if(mainHud.currentFrameLabel != "quest")
         {
            mainHud.text01_charName.text = gMainFrame.userInfo.userNameModerated;
         }
         try
         {
            GamePlay._instance.enforceHeadlessMode();
         }
         catch(e:Error)
         {
         }
      }
      
      private static function onHudViewChanged(param1:AvatarView) : void
      {
         if(_hudAvtView)
         {
            _hudAvtView.playAnim(15,false,1,null,!getDisplayClothesInHudEnabled());
         }
      }
      
      public static function grayHudAvatar(param1:Boolean) : void
      {
         if(_hudAvtView)
         {
            if(param1)
            {
               _hudAvtView.filters = [new ColorMatrixFilter([0.3086,0.6094,0.082,0,0,0.3086,0.6094,0.082,0,0,0.3086,0.6094,0.082,0,0,0,0,0,1,0])];
            }
            else
            {
               _hudAvtView.filters = null;
            }
         }
      }
      
      private static function onBigPetLoaded(param1:MovieClip, param2:GuiPet) : void
      {
         param1.scaleY = 1.7;
         param1.scaleX = 1.7;
         param1.y += mainHud.charWindow.mouse.height * 0.5 - 10;
         mainHud.charWindow.charLayer.addChild(param1);
         param2.animatePet(false);
      }
      
      public static function positionHudAvatar() : void
      {
         var _loc1_:Point = AvatarUtility.getAvatarHudPosition(_hudAvtView.avTypeId);
         _hudAvtView.x = _loc1_.x;
         _hudAvtView.y = _loc1_.y;
      }
      
      public static function activateDenHud(param1:Boolean) : void
      {
         if(mainHud.denBtn)
         {
            mainHud.denBtn.removeEventListener("mouseDown",denBtnMouseDownHandler);
            mainHud.denBtn.visible = !param1;
         }
         if(!param1)
         {
            if(mainHud.denBtn)
            {
               mainHud.denBtn.addEventListener("mouseDown",denBtnMouseDownHandler,false,0,true);
            }
            if(denEditor)
            {
               denEditor.destroy();
               denEditor = null;
               mainHud.furnBtn.visible = false;
            }
            BuddyList.destroyInWorldBuddyList();
         }
         else
         {
            if(denEditor)
            {
               denEditor.destroy();
               denEditor = null;
            }
            denEditor = new DenEditor();
            denEditor.init(AvatarManager.playerAvatar,guiLayer,mainHud);
         }
         try
         {
            GamePlay._instance.enforceHeadlessMode();
         }
         catch(e:Error)
         {
         }
      }
      
      public static function showDenHudItems(param1:Boolean) : void
      {
         if(denEditor)
         {
            denEditor.toggleEditorHud(param1);
         }
      }
      
      public static function onPetsChanged() : void
      {
         if(denEditor)
         {
            denEditor.reloadDenItems();
         }
      }
      
      public static function onToggleDenLock(param1:Function) : void
      {
         if(denEditor)
         {
            denEditor.openDenLockPopup(param1);
            return;
         }
         param1();
      }
      
      public static function findMannequinAndRemoveAccessory(param1:int, param2:int) : Boolean
      {
         if(denEditor && param1 != -1)
         {
            return denEditor.findMannequinAndRemoveAccessory(param1,param2);
         }
         return false;
      }
      
      public static function clickedOutsideChatCui(param1:MouseEvent) : void
      {
         if(!mainHud.contains(param1.target))
         {
            if(mainHud.safeChatTreeWindow.visible)
            {
               mainHud.safeChatTreeWindow.visible = false;
            }
            if(mainHud.emotesWindow.visible && !isInFFM)
            {
               mainHud.emotesWindow.visible = false;
            }
            if(mainHud.actionsWindow.visible)
            {
               mainHud.actionsWindow.visible = false;
            }
         }
         gMainFrame.stage.removeEventListener("mouseUp",clickedOutsideChatCui);
      }
      
      public static function onEmoteClick(param1:Sprite) : void
      {
         UserCommXtCommManager.sendAvatarEmote(param1);
      }
      
      public static function resizeHudZoneNameBar(param1:MovieClip) : void
      {
         param1.mouse.name_txt.width = param1.mouse.name_txt.textWidth + 5;
         param1.mouse.mid.width = param1.mouse.name_txt.textWidth + 5 + 0.5 * param1.mouse.left.width;
         param1.mouse.mid.x = param1.mouse.right.x - param1.mouse.mid.width + 1;
         param1.mouse.left.x = param1.mouse.mid.x - 0.5 * param1.mouse.left.width;
         param1.mouse.name_txt.x = param1.mouse.mid.x + 12;
      }
      
      private static function layerGuiMouseDownHandler(param1:MouseEvent) : void
      {
         if(!mainHud.contains(param1.target))
         {
            if(mainHud.safeChatTreeWindow.visible)
            {
               mainHud.safeChatBtn.dispatchEvent(param1);
            }
            if(mainHud.emotesWindow.visible)
            {
               mainHud.emotesBtn.dispatchEvent(param1);
            }
            if(mainHud.actionsWindow.visible)
            {
               mainHud.actionsBtn.dispatchEvent(param1);
            }
         }
      }
      
      private static function layerBkgMouseUpHandler(param1:MouseEvent) : void
      {
         if(chatHist)
         {
            chatHist.setFocusOnMsgText();
         }
      }
      
      public static function setRoomNameDisplay(param1:String, param2:int) : void
      {
         var _loc3_:RegExp = null;
         var _loc4_:Array = null;
         var _loc5_:UserInfo = null;
         _currRoomDisplayName = param1;
         _currRoomDisplayNameId = param2;
         if(mainHud.zoneNameTxt)
         {
            if(param1.indexOf(gMainFrame.userInfo.myUserName) == 0)
            {
               if(gMainFrame.clientInfo.userNameModerated == 0)
               {
                  _loc3_ = new RegExp(gMainFrame.userInfo.myUserName,"gi");
                  _currRoomDisplayNameModeratedLocalized = _currRoomDisplayName.replace(_loc3_,LocalizationManager.translateIdOnly(11098));
               }
               else
               {
                  _currRoomDisplayNameModeratedLocalized = _currRoomDisplayNameId != 0 ? LocalizationManager.translateIdOnly(param2) : LocalizationManager.translateIdAndInsertOnly(18427,gMainFrame.userInfo.myUserName);
               }
            }
            else
            {
               _loc4_ = _currRoomDisplayName.split("\'");
               _loc5_ = gMainFrame.userInfo.getUserInfoByUserName(_loc4_[0]);
               if(_loc5_)
               {
                  if(_loc4_[1] == "s Den")
                  {
                     _currRoomDisplayNameModeratedLocalized = _currRoomDisplayNameId != 0 ? LocalizationManager.translateIdOnly(param2) : LocalizationManager.translateIdAndInsertOnly(18427,_loc4_[0]);
                  }
                  else
                  {
                     _currRoomDisplayNameModeratedLocalized = _currRoomDisplayNameId != 0 ? LocalizationManager.translateIdOnly(param2) : _currRoomDisplayName;
                  }
               }
               else
               {
                  _currRoomDisplayNameModeratedLocalized = _currRoomDisplayNameId != 0 ? LocalizationManager.translateIdOnly(param2) : _currRoomDisplayName;
               }
            }
            mainHud.zoneNameTxt.text = _currRoomDisplayNameModeratedLocalized;
            resizeHudZoneNameBar(mainHud.zoneName);
         }
      }
      
      public static function handleMouseDown() : void
      {
         if(chatHist)
         {
            chatHist.dimChat();
         }
         SafeChatManager.closeSafeChat();
         if(actionMgr)
         {
            actionMgr.closeActions();
         }
         if(emoteMgr)
         {
            emoteMgr.closeEmotes();
         }
      }
      
      public static function handleGameExit() : void
      {
         chatHist.resetTreeSearch();
         setFocusToChatText();
      }
      
      public static function isBeYourPetRoom() : Boolean
      {
         return QuestManager.isBeYourPetQuest() || PartyManager.isBeYourPetParty();
      }
      
      public static function addQuestXP(param1:Number) : void
      {
         if(mainHud.xpMeter)
         {
            if(!isBeYourPetRoom())
            {
               mainHud.xpMeter.xpBar.visible = true;
               mainHud.xpMeter.xpBar.width = mainHud.xpMeter.xpBarContainer.width * (param1 / 100);
            }
            else
            {
               mainHud.xpMeter.xpBar.visible = false;
            }
         }
      }
      
      public static function setQuestHearts(param1:Number) : void
      {
         var _loc2_:Object = null;
         var _loc4_:Number = Number(NaN);
         var _loc3_:AvatarInfo = null;
         if(mainHud.heartWindow)
         {
            if(_heartItemWindow)
            {
               if(_heartItemWindow.parent && _heartItemWindow.parent == mainHud.heartWindow)
               {
                  mainHud.heartWindow.removeChild(_heartItemWindow);
               }
               _heartItemWindow.destroy();
            }
            _loc2_ = QuestXtCommManager.getScriptDef(QuestManager._questScriptDefId);
            _loc4_ = 0;
            if(_loc2_ != null && _loc2_.playAsPet)
            {
               _loc4_ = 1;
            }
            else
            {
               _loc3_ = gMainFrame.userInfo.getAvatarInfoByUsernamePerUserAvId(gMainFrame.userInfo.myUserName,gMainFrame.userInfo.myPerUserAvId);
               _loc4_ = Math.round(_loc3_.healthBase * 0.5);
            }
            _heartItemWindow = new WindowGenerator();
            _heartItemWindow.init(_loc4_,1,_loc4_,0,0,0,ItemWindowHeart,null,"",null,{"hpPercentage":param1},onHeartsLoaded,true,false);
            mainHud.heartWindow.addChild(_heartItemWindow);
         }
      }
      
      private static function onHeartsLoaded() : void
      {
         var _loc1_:int = 0;
         _loc1_ = 0;
         while(_loc1_ < _heartItemWindow.bg.numChildren)
         {
            _heartItemWindow.bg.getChildAt(_loc1_).updateFrame();
            _loc1_++;
         }
      }
      
      public static function updateXPShape(param1:MovieClip) : void
      {
         var shape:MovieClip;
         var img:MovieClip = param1;
         if(mainHud.xpLevelShape)
         {
            with(mainHud)
            {
               
               while(xpLevelShape.numChildren > 0)
               {
                  xpLevelShape.removeChildAt(0);
               }
               shape = img.getChildAt(0);
               if(shape)
               {
                  shape.dark.text.text = img.passback;
                  xpLevelShape.addChild(shape);
               }
            }
         }
      }
      
      public static function updateShapeXP(param1:int) : void
      {
         var shape:MovieClip;
         var level:int = param1;
         if(mainHud.xpLevelShape)
         {
            with(mainHud)
            {
               
               if(xpLevelShape.numChildren > 0)
               {
                  shape = xpLevelShape.getChildAt(0);
                  if(shape && shape.dark.hasOwnProperty("text"))
                  {
                     shape.dark.text.text = level;
                  }
               }
            }
         }
      }
      
      public static function showDiamondConfirmation(param1:int, param2:Function, param3:String = "", param4:String = "") : void
      {
         if(_diamondConfirmationPopup == null)
         {
            _diamondConfirmationPopup = GETDEFINITIONBYNAME("diamondShopConf");
            _diamondConfirmationPopup.cancelBtn.addEventListener("mouseDown",onDiamondConfBtn,false,0,true);
            _diamondConfirmationPopup.buyBtn.addEventListener("mouseDown",onDiamondConfBtn,false,0,true);
            _diamondConfirmationPopup.closeButton.addEventListener("mouseDown",onDiamondConfBtn,false,0,true);
            _diamondConfirmationPopup.addEventListener("mouseDown",onPopup,false,0,true);
            _diamondConfirmationPopup.x = 900 * 0.5;
            _diamondConfirmationPopup.y = 550 * 0.5;
            _diamondConfirmationPopup.originalText = _diamondConfirmationPopup.txt.text;
            _diamondConfirmationPopup.originalBtnText = _diamondConfirmationPopup.buyBtn.down.txt.text;
         }
         if(param3 != "")
         {
            LocalizationManager.updateToFit(_diamondConfirmationPopup.txt,param3);
         }
         else
         {
            LocalizationManager.updateToFit(_diamondConfirmationPopup.txt,_diamondConfirmationPopup.originalText);
         }
         if(param4 != "")
         {
            LocalizationManager.updateToFit(_diamondConfirmationPopup.buyBtn.down.txt,param4);
            LocalizationManager.updateToFit(_diamondConfirmationPopup.buyBtn.mouse.up.txt,param4);
            LocalizationManager.updateToFit(_diamondConfirmationPopup.buyBtn.mouse.mouse.txt,param4);
         }
         else
         {
            LocalizationManager.updateToFit(_diamondConfirmationPopup.buyBtn.down.txt,_diamondConfirmationPopup.originalBtnText);
            LocalizationManager.updateToFit(_diamondConfirmationPopup.buyBtn.mouse.up.txt,_diamondConfirmationPopup.originalBtnText);
            LocalizationManager.updateToFit(_diamondConfirmationPopup.buyBtn.mouse.mouse.txt,_diamondConfirmationPopup.originalBtnText);
         }
         _diamondConfirmationPopup.callback = param2;
         _diamondConfirmationPopup.diamondTxt.text = Utility.convertNumberToString(param1);
         guiLayer.addChild(_diamondConfirmationPopup);
         DarkenManager.darken(_diamondConfirmationPopup);
      }
      
      public static function onMinimapBtn(param1:MouseEvent) : void
      {
         if(!param1.currentTarget.isGray)
         {
            if(mainHud.miniMap.visible)
            {
               mainHud.miniMap.visible = false;
            }
            else
            {
               if(mainHud.playersCont.visible)
               {
                  mainHud.playersCont.visible = false;
                  mainHud.questPlayersBtn.downToUpState();
               }
               if(AvatarManager.playerAvatarWorldView)
               {
                  _roomMgr.updatePlayerPos(AvatarManager.playerAvatarWorldView.x,AvatarManager.playerAvatarWorldView.y);
               }
               mainHud.miniMap.visible = true;
            }
         }
      }
      
      private static function onMinimapZoon(param1:MouseEvent) : void
      {
         if(param1.currentTarget.parent.currentFrameLabel == "small")
         {
            param1.currentTarget.parent.gotoAndStop("big");
            param1.currentTarget.mouse.plus.visible = false;
         }
         else
         {
            param1.currentTarget.parent.gotoAndStop("small");
            param1.currentTarget.mouse.plus.visible = true;
         }
      }
      
      private static function onPopup(param1:MouseEvent) : void
      {
         param1.stopPropagation();
      }
      
      private static function onDiamondConfBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         DarkenManager.unDarken(_diamondConfirmationPopup);
         guiLayer.removeChild(_diamondConfirmationPopup);
         if(param1.currentTarget.name == "buyBtn")
         {
            _diamondConfirmationPopup.callback();
         }
         _diamondConfirmationPopup.cancelBtn.removeEventListener("mouseDown",onDiamondConfBtn);
         _diamondConfirmationPopup.buyBtn.removeEventListener("mouseDown",onDiamondConfBtn);
         _diamondConfirmationPopup.removeEventListener("mouseDown",onPopup);
         _diamondConfirmationPopup = null;
      }
      
      public static function openMasterpiecePreview(param1:String, param2:String, param3:int, param4:String, param5:int, param6:String, param7:DenItem = null, param8:Function = null, param9:Object = null, param10:Boolean = false) : void
      {
         closeMasterpiecePreview();
         _masterpieceCloseCallback = param8;
         _masterpiecePreview = new MasterpiecePreview(guiLayer,0,param1,param2,param3,param4,param5,onMasterpieceClose,param6,param7,param9,param10);
      }
      
      private static function onMasterpieceClose(param1:Boolean) : void
      {
         _masterpiecePreview.destroy();
         _masterpiecePreview = null;
         if(_masterpieceCloseCallback != null)
         {
            _masterpieceCloseCallback(param1);
            _masterpieceCloseCallback = null;
         }
      }
      
      private static function closeMasterpiecePreview() : void
      {
         if(_masterpiecePreview)
         {
            _masterpiecePreview.destroy(false);
            _masterpiecePreview = null;
            _masterpieceCloseCallback = null;
         }
      }
      
      public static function showBarrierPopup(param1:int, param2:Boolean, param3:Boolean = false, param4:int = -1) : void
      {
         if(_barrierPopup)
         {
            _barrierPopup.destroy();
         }
         _barrierPopup = new BarrierPopup();
         _barrierPopup.init(param1,onBarrierPopupClose,param2,param3,param4);
      }
      
      private static function onBarrierPopupClose() : void
      {
         if(_barrierPopup)
         {
            _barrierPopup.destroy();
            _barrierPopup = null;
         }
      }
      
      private static function addListeners() : void
      {
         guiLayer.addEventListener("mouseDown",layerGuiMouseDownHandler,false,0,true);
         bgLayer.addEventListener("mouseUp",layerBkgMouseUpHandler,false,0,true);
         mainHud.addEventListener("mouseDown",mainHudMouseDownHandler,false,0,true);
         if(mainHud.money != null)
         {
            mainHud.money.addEventListener("rollOver",onGemsBtnRollOverOutHandler,false,0,true);
            mainHud.money.addEventListener("rollOut",onGemsBtnRollOverOutHandler,false,0,true);
            if(_alwaysOpenGems)
            {
               openGemsTooltip();
            }
         }
         if(mainHud.charWindow != null)
         {
            mainHud.charWindow.addEventListener("mouseDown",charWindowDownHandler,false,0,true);
         }
         if(mainHud.swapBtn != null)
         {
            mainHud.swapBtn.addEventListener("mouseDown",onSwapBtnClickHandler,false,0,true);
         }
         if(mainHud.mySettingsBtn != null)
         {
            mainHud.mySettingsBtn.addEventListener("mouseDown",onMySettingsBtnClickHandler,false,0,true);
         }
         if(mainHud.reportBtn != null)
         {
            mainHud.reportBtn.addEventListener("mouseDown",onReportBtnClickHandler,false,0,true);
         }
         if(mainHud.soundBtn != null)
         {
            mainHud.soundBtn.addEventListener("mouseDown",onSoundBtnClickHandler,false,0,true);
         }
         if(mainHud.newsBtn != null)
         {
            mainHud.newsBtn.addEventListener("mouseDown",onNewsPaperBtn,false,0,true);
         }
         if(mainHud.book != null)
         {
            mainHud.book.addEventListener("mouseDown",onJourneyBookBtn,false,0,true);
         }
         if(mainHud.partyBtn != null)
         {
            mainHud.partyBtn.addEventListener("mouseDown",onPartyBtn,false,0,true);
         }
         if(mainHud.safeChatBtn != null)
         {
            mainHud.safeChatBtn.addEventListener("mouseDown",safeChatBtnDownHandler,false,0,true);
         }
         if(mainHud.questExitBtn != null)
         {
            mainHud.questExitBtn.addEventListener("mouseDown",QuestManager.onQuestExit,false,0,true);
         }
         if(mainHud.questPlayersBtn != null)
         {
            mainHud.questPlayersBtn.addEventListener("mouseDown",QuestManager.onQuestPlayersBtn,false,0,true);
         }
         if(mainHud.miniMap_btnQuest != null)
         {
            mainHud.miniMap_btnQuest.addEventListener("mouseDown",onMinimapBtn,false,0,true);
            mainHud.miniMap.zoom.addEventListener("mouseDown",onMinimapZoon,false,0,true);
         }
         if(mainHud.swapPet != null)
         {
            mainHud.swapPet.addEventListener("mouseDown",onPetSwapBtn,false,0,true);
         }
         if(mainHud.games != null)
         {
            mainHud.games.addEventListener("mouseDown",onGamesBtn,false,0,true);
         }
         if(mainHud.memDaysLeft)
         {
            mainHud.memDaysLeft.addEventListener("mouseDown",onMemDaysLeft,false,0,true);
         }
         if(mainHud.ajEmailBtn)
         {
            mainHud.ajEmailBtn.addEventListener("mouseDown",onAjEmailBtn,false,0,true);
         }
         mainHud.addEventListener("mouseOver",onMainHudOver,false,0,true);
         _denBtnGlowTimer.addEventListener("timer",denBtnGlowTimerHandler,false,0,true);
      }
      
      private static function removeListeners() : void
      {
         guiLayer.removeEventListener("mouseDown",layerGuiMouseDownHandler);
         bgLayer.removeEventListener("mouseUp",layerBkgMouseUpHandler);
         mainHud.removeEventListener("mouseDown",mainHudMouseDownHandler);
         if(mainHud.money != null)
         {
            mainHud.money.removeEventListener("rollOver",onGemsBtnRollOverOutHandler);
            mainHud.money.removeEventListener("rollOut",onGemsBtnRollOverOutHandler);
         }
         if(mainHud.charWindow != null)
         {
            mainHud.charWindow.removeEventListener("mouseDown",charWindowDownHandler);
         }
         if(mainHud.swapBtn != null)
         {
            mainHud.swapBtn.removeEventListener("mouseDown",onSwapBtnClickHandler);
         }
         if(mainHud.mySettingsBtn != null)
         {
            mainHud.mySettingsBtn.removeEventListener("mouseDown",onMySettingsBtnClickHandler);
         }
         if(mainHud.reportBtn != null)
         {
            mainHud.reportBtn.removeEventListener("mouseDown",onReportBtnClickHandler);
         }
         if(mainHud.soundBtn != null)
         {
            mainHud.soundBtn.removeEventListener("mouseDown",onSoundBtnClickHandler);
         }
         if(mainHud.newsBtn != null)
         {
            mainHud.newsBtn.removeEventListener("mouseDown",onNewsPaperBtn);
         }
         if(mainHud.book != null)
         {
            mainHud.book.removeEventListener("mouseDown",onJourneyBookBtn);
         }
         if(mainHud.partyBtn != null)
         {
            mainHud.partyBtn.removeEventListener("mouseDown",onPartyBtn);
         }
         if(mainHud.safeChatBtn != null)
         {
            mainHud.safeChatBtn.removeEventListener("mouseDown",safeChatBtnDownHandler);
         }
         if(mainHud.questExitBtn != null)
         {
            mainHud.questExitBtn.removeEventListener("mouseDown",QuestManager.onQuestExit);
         }
         if(mainHud.questPlayersBtn != null)
         {
            mainHud.questPlayersBtn.removeEventListener("mouseDown",QuestManager.onQuestPlayersBtn);
         }
         if(mainHud.miniMap_btnQuest != null)
         {
            mainHud.miniMap_btnQuest.removeEventListener("mouseDown",onMinimapBtn);
            mainHud.miniMap.zoom.removeEventListener("mouseDown",onMinimapZoon);
         }
         if(mainHud.swapPet != null)
         {
            mainHud.swapPet.removeEventListener("mouseDown",onPetSwapBtn);
         }
         if(mainHud.games != null)
         {
            mainHud.games.removeEventListener("mouseDown",onGamesBtn);
         }
         if(mainHud.memDaysLeft)
         {
            mainHud.memDaysLeft.removeEventListener("mouseDown",onMemDaysLeft);
         }
         if(mainHud.ajEmailBtn)
         {
            mainHud.ajEmailBtn.removeEventListener("mouseDown",onAjEmailBtn);
         }
         mainHud.removeEventListener("mouseOver",onMainHudOver);
         _denBtnGlowTimer.removeEventListener("timer",denBtnGlowTimerHandler);
      }
      
      private static function onMainHudOver(param1:MouseEvent) : void
      {
         QuestManager.updatePrivateAdventureIndexComparedToMainHud();
      }
      
      public static function safeChatBtnDownHandler(param1:MouseEvent) : void
      {
         if(!mainHud.safeChatBtn.isGray)
         {
            if(mainHud.safeChatTreeWindow.visible)
            {
               SafeChatManager.closeSafeChat();
            }
            else
            {
               if(mainHud.emotesWindow.visible)
               {
                  mainHud.emotesBtn.dispatchEvent(param1);
               }
               if(mainHud.actionsWindow.visible)
               {
                  mainHud.actionsBtn.dispatchEvent(param1);
               }
               if(param1)
               {
                  param1.stopPropagation();
               }
               SafeChatManager.openSafeChat(true);
            }
         }
      }
      
      public static function toggleHud() : void
      {
         if(mainHud.visible)
         {
            mainHud.visible = false;
            gMainFrame.stage.focus = null;
         }
         else if(!AvatarManager.isMyAvtInPreviewRoom)
         {
            mainHud.visible = true;
            setFocusToChatText();
         }
      }
      
      private static function namebarBadgeDefResponse(param1:DefPacksDefHelper) : void
      {
         var _loc2_:Object = null;
         for each(var _loc3_ in param1.def)
         {
            _loc2_ = {
               "defId":int(_loc3_.id),
               "pendingFlagsBit":int(_loc3_.pendingFlagsBit),
               "mediaRefId":int(_loc3_.mediaRefId)
            };
            _namebarBadgeDefs[_loc2_.defId] = _loc2_;
         }
      }
      
      public static function loadNameBarBadgeList() : void
      {
         GenericListXtCommManager.requestGenericList(110,onNameBarListLoaded);
      }
      
      private static function onNameBarListLoaded(param1:Array) : void
      {
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         _namebarBadgeList = [];
         _loc2_ = 0;
         while(_loc2_ < param1.length)
         {
            _loc3_ = getNamebarBadgeDef(param1[_loc2_]);
            if(_loc3_)
            {
               _namebarBadgeList[_loc2_] = _loc3_.mediaRefId;
            }
            _loc2_++;
         }
      }
      
      public static function getNamebarBadgeList() : Array
      {
         return _namebarBadgeList;
      }
      
      public static function getNamebarBadgeDefs() : Object
      {
         return _namebarBadgeDefs;
      }
      
      public static function getNamebarBadgeDef(param1:int) : Object
      {
         return _namebarBadgeDefs[param1];
      }
      
      public static function updateQuestHud() : void
      {
         if(QuestManager.isSideScrollQuest() == true)
         {
            mainHud.actionsBtn.activateGrayState(true);
         }
         else
         {
            mainHud.actionsBtn.activateGrayState(false);
         }
      }
      
      public static function updateMainHudButtons(param1:Boolean, ... rest) : void
      {
         var _loc7_:int = 0;
         var _loc8_:String = null;
         var _loc6_:Boolean = false;
         var _loc9_:int = 0;
         var _loc3_:Number = Number(NaN);
         if((mainHud as GuiHud).upperHudItems == null)
         {
            (mainHud as GuiHud).upperHudItems = getUpperHudItems();
         }
         var _loc4_:Array = (mainHud as GuiHud).upperHudItems;
         var _loc5_:* = param1;
         if(rest != null && rest.length > 0)
         {
            _loc9_ = 0;
            while(_loc9_ < rest.length)
            {
               _loc8_ = rest[_loc9_].btnName;
               _loc6_ = Boolean(rest[_loc9_].show);
               _loc7_ = 0;
               while(_loc7_ < _loc4_.length)
               {
                  if(_loc4_[_loc7_].name == _loc8_)
                  {
                     if(_loc4_[_loc7_].visible != _loc6_)
                     {
                        _loc5_ = true;
                        _loc4_[_loc7_].visible = _loc6_;
                     }
                     break;
                  }
                  _loc7_++;
               }
               _loc9_++;
            }
         }
         if(_loc5_)
         {
            _loc3_ = Number(_loc4_[0].originalX);
            _loc7_ = 0;
            while(_loc7_ < _loc4_.length)
            {
               if(rest == null || rest.length == 0)
               {
                  _loc4_[_loc7_].visible = !param1;
               }
               if(_loc4_[_loc7_].visible)
               {
                  _loc4_[_loc7_].x = _loc3_;
                  _loc3_ += _loc4_[_loc7_].differenceToNext;
               }
               _loc7_++;
            }
            setToolTipText();
         }
      }
      
      private static function getUpperHudItems() : Array
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         var _loc3_:Array = [];
         _loc1_ = 0;
         while(_loc1_ < (mainHud as GuiHud).numChildren)
         {
            _loc2_ = (mainHud as GuiHud).getChildAt(_loc1_) as MovieClip;
            if(_loc2_ && _loc2_.y > 15 && _loc2_.y < 25 && _loc2_.x < (mainHud as GuiHud).zoneName.x)
            {
               _loc3_.push(_loc2_);
            }
            _loc1_++;
         }
         _loc3_.sortOn("x",16);
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _loc2_ = _loc3_[_loc1_];
            _loc2_.differenceToNext = _loc1_ + 1 == _loc3_.length ? 0 : _loc3_[_loc1_ + 1].x - _loc2_.x;
            _loc2_.originalX = _loc2_.x;
            _loc1_++;
         }
         return _loc3_;
      }
      
      public static function enableGameHud(param1:Boolean, param2:String = null) : void
      {
         var _loc4_:AvatarInfo = null;
         var _loc3_:Object = null;
         if(denEditor)
         {
            denEditor.destroy();
            denEditor = null;
         }
         if(param1)
         {
            volumeMgr.enable(false);
            removeListeners();
            _originalHudFrame = mainHud.currentFrame;
            mainHud.gotoAndStop(param2);
            (mainHud as GuiHud).init(true);
            addListeners();
            chatHist.toggleInGameHud(true);
            if(param2 == "quest")
            {
               _loc4_ = gMainFrame.userInfo.getAvatarInfoByUsernamePerUserAvId(gMainFrame.userInfo.myUserName,gMainFrame.userInfo.myPerUserAvId);
               addQuestXP(_loc4_.questXPPercentage);
               setQuestHearts(_loc4_.questHealthPercentage);
               QuestManager.loadLevelShape(_loc4_.questLevel);
               if(_needToRebuildMainHud)
               {
                  rebuildMainHud();
               }
               else
               {
                  chatHist.reload(mainHud.chatHist,mainHud.chatBar,mainHud.chatHistUpDownBtn,mainHud.buddyListBtn,mainHud.chatTxt,mainHud.sendChatBtn,UserCommXtCommManager.onSendMessage,mainHud.predictTxtTagQuest,mainHud.specialCharContQuest,mainHud.chatRepeatBtn,mainHud.chatRepeatWindow,false);
                  SafeChatManager.buildSafeChatTree(mainHud.safeChatTreeWindow,null,4);
                  SafeChatManager.reload(false,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,mainHud.actionsBtn,mainHud.actionWindow,mainHud.emotesBtn,mainHud.emotesWindow);
                  actionMgr.reload(mainHud.actionsBtn,mainHud.actionsWindow,mainHud.emotesBtn,mainHud.emotesWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,UserCommXtCommManager.sendAvatarAction);
                  emoteMgr.reload(mainHud.emotesBtn,mainHud.emotesWindow,mainHud.actionsBtn,mainHud.actionsWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,onEmoteClick,gMainFrame.userInfo.firstFiveMinutes > 0);
                  setToolTipText();
               }
               setupSoundButton();
               _loc3_ = QuestXtCommManager.getScriptDef(QuestManager._questScriptDefId);
               if(_loc3_ != null && (_loc3_.time != 1 && _loc3_.avatarLimit != 1) && QuestManager.isSideScrollQuest() == false)
               {
                  mainHud.miniMap_btnQuest.upToDownState();
                  mainHud.miniMap.visible = true;
               }
               else
               {
                  mainHud.miniMap.visible = false;
               }
               mainHud.playersCont.visible = false;
               updateQuestHud();
            }
            else if(param2 == "game")
            {
               if(_needToRebuildMainHud)
               {
                  rebuildMainHud();
               }
               else
               {
                  chatHist.reload(mainHud.chatHist,mainHud.chatBar,mainHud.chatHistUpDownBtn,mainHud.buddyListBtn,mainHud.chatTxt,mainHud.sendChatBtn,MinigameManager.sendChatMsg,mainHud.predictTxtTag,mainHud.specialCharCont,mainHud.chatRepeatBtn,mainHud.chatRepeatWindow,false);
                  SafeChatManager.buildSafeChatTree(mainHud.safeChatTreeWindow,null,4,MinigameManager.sendSafeChatMsg);
                  SafeChatManager.reload(false,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,mainHud.actionsBtn,mainHud.actionWindow,mainHud.emotesBtn,mainHud.emotesWindow);
                  actionMgr.reload(mainHud.actionsBtn,mainHud.actionsWindow,mainHud.emotesBtn,mainHud.emotesWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,MinigameManager.sendActionMsg);
                  emoteMgr.reload(mainHud.emotesBtn,mainHud.emotesWindow,mainHud.actionsBtn,mainHud.actionsWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,MinigameManager.sendEmoteMsg,gMainFrame.userInfo.firstFiveMinutes > 0);
                  setToolTipText();
               }
            }
         }
         else if(_originalHudFrame != -1)
         {
            removeListeners();
            mainHud.gotoAndStop(_originalHudFrame);
            (mainHud as GuiHud).init(true);
            addListeners();
            setToolTipText();
            _originalHudFrame = -1;
            if(_needToRebuildMainHud)
            {
               rebuildMainHud();
            }
            else
            {
               chatHist.reload(mainHud.chatHist,mainHud.chatBar,mainHud.chatHistUpDownBtn,mainHud.buddyListBtn,mainHud.chatTxt,mainHud.sendChatBtn,UserCommXtCommManager.onSendMessage,mainHud.predictTxtTag,mainHud.specialCharCont,mainHud.chatRepeatBtn,mainHud.chatRepeatWindow,false);
               SafeChatManager.buildSafeChatTree(mainHud.safeChatTreeWindow,null,0);
               SafeChatManager.reload(false,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,mainHud.actionsBtn,mainHud.actionWindow,mainHud.emotesBtn,mainHud.emotesWindow);
               actionMgr.reload(mainHud.actionsBtn,mainHud.actionsWindow,mainHud.emotesBtn,mainHud.emotesWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,UserCommXtCommManager.sendAvatarAction);
               emoteMgr.reload(mainHud.emotesBtn,mainHud.emotesWindow,mainHud.actionsBtn,mainHud.actionsWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,onEmoteClick,gMainFrame.userInfo.firstFiveMinutes > 0);
               volumeMgr.enable(true,mainHud.worldMapBtn,mainHud.zoneName,mainHud.worldHelp);
               setToolTipText();
               ECardManager.init(guiLayer,mainHud.eCardBtn,true);
               BuddyList.rebuildBtn(mainHud.buddyListBtn);
               PlayerWallManager.init(mainHud.playerWall);
               updateDaysLeftCount();
            }
            chatHist.toggleInGameHud(false);
            setupSoundButton();
            mainHud.safeChatTreeWindow.visible = false;
            mainHud.actionsWindow.visible = false;
            mainHud.emotesWindow.visible = false;
            if(mainHud.swapBtn.hasGrayState)
            {
               mainHud.swapBtn.activateGrayState(false);
            }
            mainHud.newsBtn.glow.visible = false;
            mainHud.newsBtn.newJournal.visible = false;
            mainHud.denBtn.glow.visible = false;
            mainHud.book.glow.visible = false;
            mainHud.book.gift.visible = false;
            mainHud.partyBtn.glow.visible = false;
            mainHud.playerWall.glow.visible = false;
            mainHud.mySettingsBtn.glow.visible = false;
            mainHud.furnBtn.glow.visible = false;
            mainHud.furnBtn.visible = false;
            mainHud.denCount.visible = false;
            mainHud.ajEmailBtn.visible = showAjEmailBtn();
         }
         _hasInittedGemsTween = false;
         if(_currRoomDisplayName)
         {
            setRoomNameDisplay(_currRoomDisplayName,_currRoomDisplayNameId);
         }
         setFocusToChatText();
      }
      
      public static function rebuildMainHud() : void
      {
         if(LocalizationManager.currentLanguage == LocalizationManager.LANG_ENG)
         {
            if(gMainFrame.userInfo.sgChatType == 2 || PredictiveTextManager.lastRequestedPredictiveLanguage != LocalizationManager.currentLanguage || !PredictiveTextManager.hasRequestDictionaryBlob && LocalizationManager.accountLanguage != LocalizationManager.LANG_ENG)
            {
               PredictiveTextManager.resetDictionaryBlob();
            }
         }
         else
         {
            PredictiveTextManager.resetDictionaryBlob();
         }
         if(chatHist)
         {
            (mainHud as GuiHud).init(true);
            chatHist.reload(mainHud.chatHist,mainHud.chatBar,mainHud.chatHistUpDownBtn,mainHud.buddyListBtn,mainHud.chatTxt,mainHud.sendChatBtn,UserCommXtCommManager.onSendMessage,mainHud.predictTxtTag == null ? mainHud.predictTxtTagQuest : mainHud.predictTxtTag,mainHud.specialCharCont == null ? mainHud.specialCharContQuest : mainHud.specialCharCont,mainHud.chatRepeatBtn,mainHud.chatRepeatWindow,true);
            SafeChatManager.buildSafeChatTree(mainHud.safeChatTreeWindow,null,0);
            SafeChatManager.reload(true,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,mainHud.actionsBtn,mainHud.actionWindow,mainHud.emotesBtn,mainHud.emotesWindow);
            actionMgr.reload(mainHud.actionsBtn,mainHud.actionsWindow,mainHud.emotesBtn,mainHud.emotesWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,UserCommXtCommManager.sendAvatarAction);
            emoteMgr.reload(mainHud.emotesBtn,mainHud.emotesWindow,mainHud.actionsBtn,mainHud.actionsWindow,mainHud.safeChatBtn,mainHud.safeChatTreeWindow,onEmoteClick,gMainFrame.userInfo.firstFiveMinutes > 0);
            if(mainHud.worldMapBtn)
            {
               volumeMgr.enable(true,mainHud.worldMapBtn,mainHud.zoneName,mainHud.worldHelp);
            }
            setToolTipText();
            if(mainHud.eCardBtn)
            {
               ECardManager.init(guiLayer,mainHud.eCardBtn,true);
            }
            if(mainHud.buddyListBtn)
            {
               BuddyList.destroy();
               BuddyList.init(guiLayer,mainHud.buddyListBtn,true);
            }
            updateDenRoomCount(_currentDenRoomCount,false,gMainFrame.userInfo.myUserName);
            updateDaysLeftCount();
         }
         ItemXtCommManager.relocalizeItems();
         DenXtCommManager.relocalizeDenItems();
         DenXtCommManager.relocalizeDenRooms();
         PetManager.relocalizePetDefs();
         ItemXtCommManager.relocalizeCurrencyExchanges();
         if(mainHud.playerWall)
         {
            PlayerWallManager.init(mainHud.playerWall);
         }
         _needToRebuildMainHud = false;
      }
      
      public static function grayOutHudItemsForPrivateLobby(param1:Boolean, param2:Boolean = false) : void
      {
         if(mainHud.partyBnt)
         {
            mainHud.partyBtn.activateGrayState(param1);
         }
         if(mainHud.book)
         {
            mainHud.book.activateGrayState(param1);
         }
         if(mainHud.swapBtn)
         {
            mainHud.swapBtn.activateGrayState(param1);
         }
         if(mainHud.buddyListBtn)
         {
            mainHud.buddyListBtn.activateGrayState(param1);
         }
         if(mainHud.eCardBtn)
         {
            mainHud.eCardBtn.activateGrayState(param1);
         }
         if(mainHud.newsBtn)
         {
            mainHud.newsBtn.activateGrayState(param1);
         }
         if(mainHud.games)
         {
            mainHud.games.activateGrayState(param2 ? false : param1);
         }
      }
      
      private static function showAjEmailBtn() : Boolean
      {
         if((gMainFrame.clientInfo.userEmail == null || gMainFrame.clientInfo.userEmail == "") && (gMainFrame.clientInfo.pendingEmail == null || gMainFrame.clientInfo.pendingEmail == ""))
         {
            return true;
         }
         return false;
      }
      
      public static function showTeleportPopup() : void
      {
         if(_teleportPopup)
         {
            _teleportPopup.destroy();
         }
         _teleportPopup = new TeleportPopup(onTeleportPopupClose);
      }
      
      private static function onTeleportPopupClose() : void
      {
         if(_teleportPopup)
         {
            _teleportPopup.destroy();
            _teleportPopup = null;
         }
         if(_modMenu)
         {
            _modMenu.refreshAndActivate();
         }
      }
      
      public static function destroyTeleportPopup() : void
      {
         if(_teleportPopup)
         {
            _teleportPopup.destroy();
            _teleportPopup = null;
         }
      }
      
      public static function showCloneAFriendPopup() : void
      {
         if(_cloneAFriendPopup)
         {
            _cloneAFriendPopup.destroy();
         }
         _cloneAFriendPopup = new CloneAFriendPopup(onCloneAFriendPopupClose);
      }
      
      public static function showRoomScannerPopup() : void
      {
         if(_roomScannerPopup)
         {
            _roomScannerPopup.destroy();
         }
         _roomScannerPopup = new RoomScannerPopup(onRoomScannerPopupClose);
      }
      
      private static function onCloneAFriendPopupClose() : void
      {
         if(_cloneAFriendPopup)
         {
            _cloneAFriendPopup.destroy();
            _cloneAFriendPopup = null;
         }
         if(_modMenu)
         {
            _modMenu.refreshAndActivate();
         }
      }
      
      private static function onRoomScannerPopupClose() : void
      {
         if(_roomScannerPopup)
         {
            _roomScannerPopup.destroy();
            _roomScannerPopup = null;
         }
         if(_modMenu)
         {
            _modMenu.refreshAndActivate();
         }
      }
      
      public static function destroyCloneAFriendPopup() : void
      {
         if(_cloneAFriendPopup)
         {
            _cloneAFriendPopup.destroy();
            _cloneAFriendPopup = null;
         }
      }
      
      public static function destroyRoomScannerPopup() : void
      {
         if(_roomScannerPopup)
         {
            _roomScannerPopup.destroy();
            _roomScannerPopup = null;
         }
      }
      
      public static function showMarketplacePopup() : void
      {
         if(_marketplacePopup)
         {
            _marketplacePopup.destroy();
         }
         _marketplacePopup = new MarketplacePopup(onMarketplacePopupClose);
      }
      
      private static function onMarketplacePopupClose() : void
      {
         _marketplacePopup = null;
         if(_modMenu)
         {
            _modMenu.refreshAndActivate();
         }
      }
      
      public static function destroyMarketplacePopup() : void
      {
         if(_marketplacePopup)
         {
            _marketplacePopup.destroy();
            _marketplacePopup = null;
         }
      }
      
      public static function showShopExplorerPopup() : void
      {
         try
         {
            if(_shopExplorerPopup)
            {
               _shopExplorerPopup.destroy();
            }
            _shopExplorerPopup = new ShopExplorerPopup(onShopExplorerPopupClose);
         }
         catch(error:Error)
         {
            DebugUtility.debugTrace("GuiManager.showShopExplorerPopup error: " + error.message + " " + error.getStackTrace());
            if(ExternalInterface.available)
            {
            }
         }
      }
      
      private static function onShopExplorerPopupClose() : void
      {
         if(_shopExplorerPopup)
         {
            _shopExplorerPopup.destroy();
            _shopExplorerPopup = null;
         }
         if(_modMenu)
         {
            _modMenu.refreshAndActivate();
         }
      }
      
      public static function refreshShopExplorerPopup() : void
      {
         if(_shopExplorerPopup)
         {
            _shopExplorerPopup.refreshAndActivate();
         }
      }
      
      public static function showOutfitBuilder() : void
      {
         ShopManager.launchStore(-999,1000);
      }
      
      public static function showNametagColorPickerPopup() : void
      {
         try
         {
            if(_nametagColorPickerPopup)
            {
               _nametagColorPickerPopup.destroy();
            }
            _nametagColorPickerPopup = new NametagColorPickerPopup(onNametagColorPickerPopupClose);
         }
         catch(error:Error)
         {
            DebugUtility.debugTrace("GuiManager.showNametagColorPickerPopup error: " + error.message + " " + error.getStackTrace());
            if(ExternalInterface.available)
            {
            }
         }
      }
      
      private static function onNametagColorPickerPopupClose() : void
      {
         if(_nametagColorPickerPopup)
         {
            _nametagColorPickerPopup.destroy();
            _nametagColorPickerPopup = null;
         }
         if(_modMenu)
         {
            _modMenu.refreshAndActivate();
         }
      }
      
      public static function showSalesLogPopup() : void
      {
         try
         {
            if(_salesLogPopup)
            {
               _salesLogPopup.destroy();
            }
            _salesLogPopup = new SalesLogPopup(onSalesLogPopupClose);
         }
         catch(error:Error)
         {
            DebugUtility.debugTrace("GuiManager.showSalesLogPopup error: " + error.message + " " + error.getStackTrace());
            if(ExternalInterface.available)
            {
            }
         }
      }
      
      private static function onSalesLogPopupClose() : void
      {
         if(_salesLogPopup)
         {
            _salesLogPopup.destroy();
            _salesLogPopup = null;
         }
         if(_modMenu)
         {
            _modMenu.refreshAndActivate();
         }
      }
      
      public static function showShopIdPopup() : void
      {
         try
         {
            new ShopIdPopup(function():*
            {
               if(ExternalInterface.available)
               {
                  ExternalInterface.call("console.log","GuiManager: Shop ID popup closed");
               }
            });
         }
         catch(error:Error)
         {
            DebugUtility.debugTrace("GuiManager.showShopIdPopup error: " + error.message + " " + error.getStackTrace());
            if(ExternalInterface.available)
            {
            }
         }
      }
      
      public static function showClothingLayerOrderPopup() : void
      {
         new ClothingLayerOrderPopup(function():void
         {
         });
      }
      
      public static function isMarketplacePopupOpen() : Boolean
      {
         return _marketplacePopup != null;
      }
      
      public static function onMarketplaceTradeListReceived(param1:String, param2:IitemCollection) : void
      {
         if(_marketplacePopup)
         {
            _marketplacePopup.onTradeListReceived(param1,param2);
         }
      }
      
      public static function openQuantityInputPopup(param1:String, param2:Function) : void
      {
         if(_quantityInputPopup)
         {
            _quantityInputPopup.destroy();
         }
         _quantityInputPopup = new QuantityInputPopup(guiLayer,param1,param2);
      }
      
      public static function onQuantityInputPopupClose() : void
      {
         if(_quantityInputPopup)
         {
            _quantityInputPopup.destroy();
            _quantityInputPopup = null;
         }
      }
   }
}

