package gui
{
   import com.sbi.client.KeepAlive;
   import flash.external.ExternalInterface;
   import flash.utils.setTimeout;
   
   public class ModMenuFeatures
   {
      
      private static var _bridgeReady:Boolean = false;
      
      public function ModMenuFeatures()
      {
         super();
      }
      
      public static function getToggleFeatures() : Array
      {
         return [{
            "key":"modsMasterEnabled",
            "label":"Enable All Mods",
            "desc":"Master switch for all mods and enhancements",
            "hotkey":"",
            "category":"mods"
         },{
            "key":"antiAfkEnabled",
            "label":"Anti-AFK System",
            "desc":"Prevents automatic disconnection due to inactivity",
            "hotkey":"N/A",
            "category":"mods"
         },{
            "key":"cartSystemEnabled",
            "label":"Cart System",
            "desc":"Enable cart functionality in personal shops",
            "hotkey":"N/A",
            "category":"mods"
         },{
            "key":"autoRestockEnabled",
            "label":"Auto Restock Shop",
            "desc":"Automatically restock sold items using saved shop layout",
            "hotkey":"N/A",
            "category":"mods"
         },{
            "key":"rememberPriceEnabled",
            "label":"Remember Last Price",
            "desc":"Remember the last price set for each item type when listing in My Shop",
            "hotkey":"N/A",
            "category":"mods"
         },{
            "key":"enhancedAnimalPalette",
            "label":"Enhanced Animal Palette",
            "desc":"Use expanded color palette (20x13) in avatar editor",
            "hotkey":"N/A",
            "category":"mods"
         },{
            "key":"headlessMode",
            "label":"Headless Mode (Automation)",
            "desc":"Used for Auto TFD/Botting. Hides everything - NOT for playing!",
            "hotkey":"Ctrl+Shift+X",
            "category":"mods"
         },{
            "key":"membershipBypassEnabled",
            "label":"Membership Bypass (Nametags)",
            "desc":"Allow non-members to use member nametag colors and badges.",
            "hotkey":"N/A",
            "category":"mods"
         },{
            "key":"multiClothingEnabled",
            "label":"Multi-Clothing Support",
            "desc":"Allow wearing multiple clothing items simultaneously",
            "hotkey":"N/A",
            "category":"mods"
         },{
            "key":"noClip",
            "label":"No-Clip",
            "desc":"Walk through walls and objects",
            "hotkey":"Ctrl+Shift+N",
            "category":"mods"
         },{
            "key":"phantomMode",
            "label":"Phantom Mode",
            "desc":"Become a phantom. (client side only)",
            "hotkey":"Ctrl+Shift+P",
            "category":"mods"
         },{
            "key":"alwaysPrivateChat",
            "label":"Private Message Toggle",
            "desc":"All chat messages default to private",
            "hotkey":"Ctrl+Shift+U",
            "category":"mods"
         },{
            "key":"allAnimalsShopEnabled",
            "label":"All Animals Available in Shop",
            "desc":"Show all animals in avatar creator, some are server validated",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"allPetAccessoriesEnabled",
            "label":"Exclusive Pet Accessories in Salon",
            "desc":"Unlock party-exclusive pet accessories.",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"allPetsShopEnabled",
            "label":"All Pets Available in Shop",
            "desc":"Show all pets in pet creator, some are server validated",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"allowOwnNametagClick",
            "label":"Allow Own Nametag Clicking",
            "desc":"Click your own nametag to view your player card",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"alwaysOpenGems",
            "label":"Always Open Currency",
            "desc":"Keep currency always visible",
            "hotkey":"Ctrl+Shift+G",
            "category":"enhancements"
         },{
            "key":"autoDismissShopPurchase",
            "label":"Auto-Dismiss Shop Purchase",
            "desc":"Automatically dismiss purchase notifications after 4 seconds",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"autoPrivateChatBadText",
            "label":"Auto Private Chat Send",
            "desc":"Automatically send bad/red text to private chat instead of blocking",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"buddyRoomServerInfo",
            "label":"Buddy Room/Server Display",
            "desc":"Show room and server information when viewing buddy cards",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"followBuddyRetryEnabled",
            "label":"Retry Follow Buddy (Room Full)",
            "desc":"Keep retrying to join a buddy's room every ~4.4s until you get in",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"denItemCounter",
            "label":"Den Item Counter",
            "desc":"Show placed item count in your den",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"disableStartupPopups",
            "label":"Disable Startup Popups",
            "desc":"Skip tutorial and welcome messages",
            "hotkey":"Ctrl+Shift+-",
            "category":"enhancements"
         },{
            "key":"displayClothesInHud",
            "label":"Display Clothes in HUD",
            "desc":"Show equipped clothing and accessories on the HUD avatar",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"expandedInventory",
            "label":"Expanded Inventory",
            "desc":"Expand inventory layout with adjustable rows and columns",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"hidePlayerAvatar",
            "label":"Hide Player Avatar",
            "desc":"Great for screenshots",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"hidePlayerNametag",
            "label":"Hide Player Nametag",
            "desc":"Great for screenshots",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"musicEnabled",
            "label":"Music",
            "desc":"Enable background music",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"performanceMode",
            "label":"Performance Mode",
            "desc":"Reduce rendering load for smoother gameplay",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"preventListCrashingEnabled",
            "label":"Prevent Pet & Animal List Crashing",
            "desc":"Prevents crashing when loading large pet and animal lists",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"soundEffectsEnabled",
            "label":"Sound Effects",
            "desc":"Enable game sound effects (jag alerts, trades, etc.)",
            "hotkey":"N/A",
            "category":"enhancements"
         },{
            "key":"wasdMovement",
            "label":"WASD Movement",
            "desc":"Use WASD keys for movement",
            "hotkey":"Ctrl+Shift+W",
            "category":"enhancements"
         },{
            "key":"wheelAutoSpin",
            "label":"Wheel Auto-Spin",
            "desc":"Automatically spin wheel on login",
            "hotkey":"Ctrl+Shift+S",
            "category":"enhancements"
         },{
            "key":"zoomHotkeysEnabled",
            "label":"Zoom Hotkeys",
            "desc":"Enable/disable zoom hotkeys (Shift+Plus/Minus)",
            "hotkey":"Shift+Plus/Minus",
            "category":"enhancements"
         }];
      }
      
      public static function getPopupFeatures() : Array
      {
         return [{
            "key":"cloneAFriend",
            "label":"Clone A Friend",
            "desc":"Clone another player\'s appearance",
            "hotkey":"Ctrl+Shift+C",
            "action":"openCloneAFriend",
            "category":"popups"
         },{
            "key":"clothingLayerOrder",
            "label":"Clothing Layer Order",
            "desc":"Reorder which clothing items display on top",
            "hotkey":"N/A",
            "action":"openClothingLayerOrder",
            "category":"popups"
         },{
            "key":"nametagColorPicker",
            "label":"Custom Nametag Colors",
            "desc":"Choose custom colors for your nametag.",
            "hotkey":"N/A",
            "action":"openNametagColorPicker",
            "category":"popups"
         },{
            "key":"roomScanner",
            "label":"Room User Scan",
            "desc":"Scan for users in rooms",
            "hotkey":"Ctrl+Shift+R",
            "action":"openRoomScanner",
            "category":"popups"
         },{
            "key":"salesLog",
            "label":"Sales Log",
            "desc":"View and manage your shop sales history",
            "hotkey":"N/A",
            "action":"openSalesLog",
            "category":"popups"
         },{
            "key":"shopExplorer",
            "label":"Shop Explorer",
            "desc":"Explore all personal shops in the den",
            "hotkey":"Ctrl+Shift+E",
            "action":"openShopExplorer",
            "category":"popups"
         },{
            "key":"outfitBuilder",
            "label":"Outfit Builder",
            "desc":"Build and equip outfits on your animal",
            "hotkey":"Ctrl+Shift+V",
            "action":"openOutfitBuilder",
            "category":"popups"
         },{
            "key":"shopTester",
            "label":"Shop Tester",
            "desc":"Force open shop by using defPacks generic lists ID.",
            "hotkey":"N/A",
            "action":"openShopTester",
            "category":"popups"
         },{
            "key":"teleportation",
            "label":"Teleportation",
            "desc":"Teleport to a room or player",
            "hotkey":"Ctrl+Shift+T",
            "action":"openTeleport",
            "category":"popups"
         },{
            "key":"marketplace",
            "label":"Trade Marketplace",
            "desc":"Browse players trade lists.",
            "hotkey":"Ctrl+Shift+M",
            "action":"openMarketplace",
            "category":"popups"
         }];
      }
      
      public static function handleFeatureToggle(featureName:String, enabled:Boolean) : void
      {
         try
         {
            switch(featureName)
            {
               case "modsMasterEnabled":
                  GuiManager.setModsMasterEnabled(enabled);
                  break;
               case "wasdMovement":
                  GuiManager.setWasdMovement(enabled);
                  break;
               case "alwaysPrivateChat":
                  GuiManager.setAlwaysPrivateChat(enabled);
                  break;
               case "performanceMode":
                  GuiManager.setPerformanceMode(enabled);
                  break;
               case "headlessMode":
                  GuiManager.setHeadlessMode(enabled);
                  break;
               case "noClip":
                  GuiManager.setNoClip(enabled);
                  break;
               case "phantomMode":
                  GuiManager.setPhantomMode(enabled);
                  break;
               case "disableStartupPopups":
                  GuiManager.setDisableStartupPopups(enabled);
                  break;
               case "alwaysOpenGems":
                  GuiManager.setAlwaysOpenGems(enabled);
                  break;
               case "wheelAutoSpin":
                  GuiManager.setWheelAutoSpin(enabled);
                  break;
               case "antiAfkEnabled":
                  GuiManager.setAntiAfkEnabled(enabled);
                  KeepAlive.updateAntiAfkState();
                  break;
               case "autoDismissShopPurchase":
                  GuiManager.setAutoDismissShopPurchase(enabled);
                  break;
               case "allowOwnNametagClick":
                  GuiManager.setAllowOwnNametagClick(enabled);
                  break;
               case "enhancedAnimalPalette":
                  GuiManager.setEnhancedAnimalPalette(enabled);
                  break;
               case "multiClothingEnabled":
                  GuiManager.setMultiClothingEnabled(enabled);
                  break;
               case "cartSystemEnabled":
                  GuiManager.setCartSystemEnabled(enabled);
                  break;
               case "autoRestockEnabled":
                  GuiManager.setAutoRestockEnabled(enabled);
                  break;
               case "rememberPriceEnabled":
                  GuiManager.setRememberPriceEnabled(enabled);
                  break;
               case "musicEnabled":
                  GuiManager.setMusicEnabled(enabled);
                  break;
               case "soundEffectsEnabled":
                  GuiManager.setSoundEffectsEnabled(enabled);
                  break;
               case "zoomHotkeysEnabled":
                  GuiManager.setZoomHotkeysEnabled(enabled);
                  break;
               case "allAnimalsShopEnabled":
                  GuiManager.setAllAnimalsShopEnabled(enabled);
                  break;
               case "allPetsShopEnabled":
                  GuiManager.setAllPetsShopEnabled(enabled);
                  break;
               case "allPetAccessoriesEnabled":
                  GuiManager.setAllPetAccessoriesEnabled(enabled);
                  break;
               case "membershipBypassEnabled":
                  GuiManager.setMembershipBypassEnabled(enabled);
                  break;
               case "expandedInventory":
                  GuiManager.setExpandedInventoryEnabled(enabled);
                  break;
               case "buddyRoomServerInfo":
                  GuiManager.setBuddyRoomServerInfoEnabled(enabled);
                  break;
               case "followBuddyRetryEnabled":
                  GuiManager.setFollowBuddyRetryEnabled(enabled);
                  break;
               case "displayClothesInHud":
                  GuiManager.setDisplayClothesInHudEnabled(enabled);
                  break;
               case "denItemCounter":
                  GuiManager.setDenItemCounterEnabled(enabled);
                  break;
               case "autoPrivateChatBadText":
                  GuiManager.setAutoPrivateChatBadText(enabled);
                  break;
               case "preventListCrashingEnabled":
                  GuiManager.setPreventListCrashingEnabled(enabled);
                  break;
               case "hidePlayerAvatar":
                  GuiManager.setHidePlayerAvatar(enabled);
                  break;
               case "hidePlayerNametag":
                  GuiManager.setHidePlayerNametag(enabled);
                  break;
               case "denLoginEnabled":
                  GuiManager.setDenLoginConfig(enabled,"");
            }
         }
         catch(err:Error)
         {
         }
      }
      
      public static function handlePopupAction(action:String) : void
      {
         try
         {
            switch(action)
            {
               case "openCloneAFriend":
                  GuiManager.showCloneAFriendPopup();
                  break;
               case "openTeleport":
                  GuiManager.showTeleportPopup();
                  break;
               case "openRoomScanner":
                  GuiManager.showRoomScannerPopup();
                  break;
               case "openMarketplace":
                  GuiManager.showMarketplacePopup();
                  break;
               case "openShopExplorer":
                  GuiManager.showShopExplorerPopup();
                  break;
               case "openOutfitBuilder":
                  GuiManager.showOutfitBuilder();
                  break;
               case "openNametagColorPicker":
                  GuiManager.showNametagColorPickerPopup();
                  break;
               case "openSalesLog":
                  GuiManager.showSalesLogPopup();
                  break;
               case "openShopTester":
                  GuiManager.showShopIdPopup();
                  break;
               case "openClothingLayerOrder":
                  GuiManager.showClothingLayerOrderPopup();
            }
         }
         catch(err:Error)
         {
         }
      }
      
      public static function getFeatureState(key:String) : Boolean
      {
         try
         {
            switch(key)
            {
               case "modsMasterEnabled":
                  return GuiManager.getModsMasterEnabled();
               case "wasdMovement":
                  return GuiManager.getWasdMovementRaw();
               case "alwaysPrivateChat":
                  return GuiManager.getAlwaysPrivateChatRaw();
               case "performanceMode":
                  return GuiManager.getPerformanceModeRaw();
               case "headlessMode":
                  return GuiManager.getHeadlessModeRaw();
               case "noClip":
                  return GuiManager.getNoClipRaw();
               case "phantomMode":
                  return GuiManager.getPhantomModeRaw();
               case "disableStartupPopups":
                  return GuiManager.getDisableStartupPopupsRaw();
               case "alwaysOpenGems":
                  return GuiManager.getAlwaysOpenGemsRaw();
               case "wheelAutoSpin":
                  return GuiManager.getWheelAutoSpinRaw();
               case "antiAfkEnabled":
                  return GuiManager.getAntiAfkEnabledRaw();
               case "autoDismissShopPurchase":
                  return GuiManager.getAutoDismissShopPurchaseRaw();
               case "allowOwnNametagClick":
                  return GuiManager.getAllowOwnNametagClickRaw();
               case "enhancedAnimalPalette":
                  return GuiManager.getEnhancedAnimalPaletteRaw();
               case "multiClothingEnabled":
                  return GuiManager.getMultiClothingEnabledRaw();
               case "cartSystemEnabled":
                  return GuiManager.getCartSystemEnabledRaw();
               case "autoRestockEnabled":
                  return GuiManager.getAutoRestockEnabledRaw();
               case "rememberPriceEnabled":
                  return GuiManager.getRememberPriceEnabledRaw();
               case "musicEnabled":
                  return GuiManager.getMusicEnabledRaw();
               case "soundEffectsEnabled":
                  return GuiManager.getSoundEffectsEnabledRaw();
               case "zoomHotkeysEnabled":
                  return GuiManager.getZoomHotkeysEnabledRaw();
               case "allAnimalsShopEnabled":
                  return GuiManager.getAllAnimalsShopEnabledRaw();
               case "allPetsShopEnabled":
                  return GuiManager.getAllPetsShopEnabledRaw();
               case "allPetAccessoriesEnabled":
                  return GuiManager.getAllPetAccessoriesEnabledRaw();
               case "membershipBypassEnabled":
                  return GuiManager.getMembershipBypassEnabledRaw();
               case "expandedInventory":
                  return GuiManager.getExpandedInventoryEnabledRaw();
               case "buddyRoomServerInfo":
                  return GuiManager.getBuddyRoomServerInfoEnabledRaw();
               case "followBuddyRetryEnabled":
                  return GuiManager.getFollowBuddyRetryEnabledRaw();
               case "displayClothesInHud":
                  return GuiManager.getDisplayClothesInHudEnabledRaw();
               case "denItemCounter":
                  return GuiManager.getDenItemCounterEnabledRaw();
               case "autoPrivateChatBadText":
                  return GuiManager.getAutoPrivateChatBadTextRaw();
               case "preventListCrashingEnabled":
                  return GuiManager.getPreventListCrashingEnabledRaw();
               case "hidePlayerAvatar":
                  return GuiManager.getHidePlayerAvatarRaw();
               case "hidePlayerNametag":
                  return GuiManager.getHidePlayerNametagRaw();
               case "denLoginEnabled":
                  return GuiManager.getDenLoginEnabledRaw();
               default:
                  return false;
            }
         }
         catch(e:Error)
         {
            return false;
         }
      }
      
      public static function getDenLoginConfig() : Object
      {
         try
         {
            return {
               "enabled":GuiManager.getDenLoginEnabled(),
               "username":GuiManager.getDenLoginUsername()
            };
         }
         catch(e:Error)
         {
            return {
               "enabled":false,
               "username":""
            };
         }
      }
      
      public static function getFeaturesByCategory(category:String) : Array
      {
         var result:Array = [];
         var toggleFeatures:Array = getToggleFeatures();
         var popupFeatures:Array = getPopupFeatures();
         var i:int = 0;
         while(i < toggleFeatures.length)
         {
            if(toggleFeatures[i]["category"] == category)
            {
               result.push(toggleFeatures[i]);
            }
            i++;
         }
         i = 0;
         while(i < popupFeatures.length)
         {
            if(popupFeatures[i]["category"] == category)
            {
               result.push(popupFeatures[i]);
            }
            i++;
         }
         return result;
      }
      
      public static function getFeatureScope(featureKey:String) : Boolean
      {
         try
         {
            return GuiManager.getFeatureScopeForUI(featureKey);
         }
         catch(e:Error)
         {
            return true;
         }
      }
      
      public static function setFeatureScope(featureKey:String, isGlobal:Boolean) : void
      {
         try
         {
            GuiManager.setFeatureScope(featureKey,isGlobal);
         }
         catch(e:Error)
         {
         }
      }

      // HTML mod menu bridge. The launcher draws the menu in the client window and
      // drives these through ExternalInterface; all state stays in GuiManager.
      public static function initBridge() : void
      {
         if(_bridgeReady || !ExternalInterface.available)
         {
            return;
         }
         try
         {
            ExternalInterface.addCallback("sjModMenuGetState",bridgeGetState);
            ExternalInterface.addCallback("sjModMenuSetToggle",bridgeSetToggle);
            ExternalInterface.addCallback("sjModMenuSetScope",bridgeSetScope);
            ExternalInterface.addCallback("sjModMenuSetDenLogin",bridgeSetDenLogin);
            ExternalInterface.addCallback("sjModMenuOpenPopup",bridgeOpenPopup);
            _bridgeReady = true;
         }
         catch(e:Error)
         {
         }
      }
      
      // F10 asks the launcher to toggle the HTML menu; false means it is off or
      // unavailable and the caller falls back to the Flash menu.
      public static function toggleHtmlMenu() : Boolean
      {
         if(!_bridgeReady)
         {
            return false;
         }
         try
         {
            return ExternalInterface.call("sjModMenu.toggle") === true;
         }
         catch(e:Error)
         {
         }
         return false;
      }
      
      private static function bridgeGetState() : Object
      {
         var toggles:Array = [];
         var popups:Array = [];
         var features:Array = getToggleFeatures();
         var popupFeatures:Array = getPopupFeatures();
         var f:Object;
         var i:int = 0;
         while(i < features.length)
         {
            f = features[i];
            toggles.push({
               "key":f.key,
               "label":f.label,
               "desc":f.desc,
               "hotkey":f.hotkey,
               "category":f.category,
               "enabled":getFeatureState(f.key),
               "global":getFeatureScope(f.key)
            });
            i++;
         }
         i = 0;
         while(i < popupFeatures.length)
         {
            f = popupFeatures[i];
            popups.push({
               "key":f.key,
               "label":f.label,
               "desc":f.desc,
               "hotkey":f.hotkey,
               "action":f.action
            });
            i++;
         }
         return {
            "toggles":toggles,
            "popups":popups,
            "den":getDenLoginConfig()
         };
      }
      
      private static function bridgeSetToggle(key:String, enabled:Boolean) : Boolean
      {
         handleFeatureToggle(key,enabled);
         return getFeatureState(key);
      }
      
      private static function bridgeSetScope(key:String, isGlobal:Boolean) : Boolean
      {
         setFeatureScope(key,isGlobal);
         return getFeatureScope(key);
      }
      
      private static function bridgeSetDenLogin(enabled:Boolean, username:String) : Object
      {
         try
         {
            GuiManager.setDenLoginConfig(enabled,username);
         }
         catch(e:Error)
         {
         }
         return getDenLoginConfig();
      }
      
      private static function bridgeOpenPopup(action:String) : void
      {
         // leave the JS call stack before building display objects
         setTimeout(handlePopupAction,1,action);
      }
   }
}
