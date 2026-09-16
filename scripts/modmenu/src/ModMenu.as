package gui
{
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.geom.Point;
   import flash.net.SharedObject;
   import flash.text.TextField;
   import flash.text.TextFormat;

   public class ModMenu
   {

      public static const PANEL_W:int = 820;

      public static const PANEL_H:int = 540;

      public static const CONTENT_X:int = -400;

      public static const CONTENT_W:int = 780;

      public static const TRACK_Y:int = -154;

      public static const TRACK_H:int = 374;

      private static var _sessionLastTab:String = "mods";

      private static var _sessionScrollPositions:Object = {};

      private static var _sessionQuery:String = "";

      private static var _sessionEnabledOnly:Boolean = false;

      private static var _prefsLoaded:Boolean = false;

      private var _modMenuPopup:MovieClip;

      private var _closeCallback:Function;

      private var _modsContainer:Sprite;

      private var _enhancementsContainer:Sprite;

      private var _popupsContainer:Sprite;

      private var _activeContainer:Sprite;

      private var _checkboxes:Object;

      private var _checkboxStates:Object;

      private var _iconRows:Object;

      private var _denUsernameInput:TextField;

      private var _denLoginCheckbox:MovieClip;

      private var _denWrap:MovieClip;

      private var _searchBox:MovieClip;

      private var _searchInput:TextField;

      private var _searchPlaceholder:TextField;

      private var _emptyLabels:Object;

      private var _enabledChip:MovieClip;

      private var _tooltip:MovieClip;

      private var _tabTotals:Object;

      private var _tabVisible:Object;

      private var _itemHeight:int = 50;

      private var _startY:int = -180;

      private var _maskHeight:int = 428;

      private var _tabManager:ModMenuTabManager;

      private var _modsScroller:ModMenuScroller;

      private var _enhancementsScroller:ModMenuScroller;

      private var _popupsScroller:ModMenuScroller;

      private var _activeScroller:ModMenuScroller;

      public function ModMenu(param1:Function)
      {
         super();
         _closeCallback = param1;
         _checkboxes = {};
         _checkboxStates = {};
         _iconRows = {};
         _emptyLabels = {};
         _tabTotals = {};
         _tabVisible = {};
         loadUiPrefs();
         DarkenManager.showLoadingSpiral(true);
         createModMenuInterface();
      }

      public static function clearSessionState() : void
      {
         _sessionLastTab = "mods";
         _sessionScrollPositions = {};
      }

      private static function loadUiPrefs() : void
      {
         var so:SharedObject;
         if(_prefsLoaded)
         {
            return;
         }
         _prefsLoaded = true;
         try
         {
            so = SharedObject.getLocal("sjModMenuUi");
            if(so && so.data)
            {
               if(so.data.hasOwnProperty("query"))
               {
                  _sessionQuery = String(so.data["query"] || "");
               }
               if(so.data.hasOwnProperty("enabledOnly"))
               {
                  _sessionEnabledOnly = Boolean(so.data["enabledOnly"]);
               }
               if(so.data.hasOwnProperty("lastTab"))
               {
                  _sessionLastTab = String(so.data["lastTab"] || "mods");
               }
            }
         }
         catch(e:Error)
         {
         }
      }

      private static function saveUiPrefs() : void
      {
         var so:SharedObject;
         try
         {
            so = SharedObject.getLocal("sjModMenuUi");
            if(so)
            {
               so.data["query"] = _sessionQuery;
               so.data["enabledOnly"] = _sessionEnabledOnly;
               so.data["lastTab"] = _sessionLastTab;
               so.flush();
            }
         }
         catch(e:Error)
         {
         }
      }

      private function getToggleCheckboxCallback() : Function
      {
         var self:gui.ModMenu = this;
         return function(key:String):void
         {
            if(self)
            {
               self.toggleCheckbox(key);
            }
         };
      }

      private function createModMenuInterface() : void
      {
         var bg:MovieClip;
         var titleTxt:TextField;
         var titleFormat:TextFormat;
         var legendContainer:MovieClip;
         var blueCircle:MovieClip;
         var blueTxt:TextField;
         var legendFmt:TextFormat;
         var grayCircle:MovieClip;
         var grayTxt:TextField;
         var tabHeader:MovieClip;
         var divider:Shape;
         var closeXBtn:MovieClip;
         var scrollUpBtn:MovieClip;
         var scrollDownBtn:MovieClip;
         var track:MovieClip;
         var thumb:MovieClip;
         var hintTxt:TextField;
         var hintFmt:TextFormat;
         _modMenuPopup = new MovieClip();
         bg = ModMenuUIHelper.createPopupBackground(PANEL_W,PANEL_H,0.96);
         bg.x = -PANEL_W / 2;
         bg.y = -PANEL_H / 2;
         _modMenuPopup.addChild(bg);
         titleTxt = new TextField();
         titleTxt.text = "Mod Menu";
         titleTxt.textColor = 16777215;
         titleFormat = new TextFormat();
         titleFormat.size = 22;
         titleFormat.bold = true;
         titleTxt.setTextFormat(titleFormat);
         titleTxt.x = -394;
         titleTxt.y = -264;
         titleTxt.width = 200;
         titleTxt.height = 34;
         titleTxt.selectable = false;
         titleTxt.mouseEnabled = false;
         _modMenuPopup.addChild(titleTxt);
         legendContainer = new MovieClip();
         legendFmt = new TextFormat();
         legendFmt.size = 10;
         blueCircle = new MovieClip();
         blueCircle.graphics.lineStyle(1,16777215,0.6);
         blueCircle.graphics.beginFill(4896994);
         blueCircle.graphics.drawCircle(5,5,5);
         blueCircle.graphics.endFill();
         blueCircle.x = -230;
         blueCircle.y = -251;
         legendContainer.addChild(blueCircle);
         blueTxt = new TextField();
         blueTxt.text = "All accounts";
         blueTxt.textColor = 10066329;
         blueTxt.setTextFormat(legendFmt);
         blueTxt.x = -217;
         blueTxt.y = -256;
         blueTxt.width = 80;
         blueTxt.height = 16;
         blueTxt.selectable = false;
         blueTxt.mouseEnabled = false;
         legendContainer.addChild(blueTxt);
         grayCircle = new MovieClip();
         grayCircle.graphics.lineStyle(1,16777215,0.6);
         grayCircle.graphics.beginFill(6710886);
         grayCircle.graphics.drawCircle(5,5,5);
         grayCircle.graphics.endFill();
         grayCircle.x = -140;
         grayCircle.y = -251;
         legendContainer.addChild(grayCircle);
         grayTxt = new TextField();
         grayTxt.text = "This account only";
         grayTxt.textColor = 10066329;
         grayTxt.setTextFormat(legendFmt);
         grayTxt.x = -127;
         grayTxt.y = -256;
         grayTxt.width = 110;
         grayTxt.height = 16;
         grayTxt.selectable = false;
         grayTxt.mouseEnabled = false;
         legendContainer.addChild(grayTxt);
         legendContainer.mouseEnabled = false;
         legendContainer.mouseChildren = false;
         _modMenuPopup.addChild(legendContainer);
         _tabManager = new ModMenuTabManager(_sessionLastTab);
         tabHeader = _tabManager.createTabHeader();
         tabHeader.x = -394;
         tabHeader.y = -226;
         _modMenuPopup.addChild(tabHeader);
         _enabledChip = ModMenuUIHelper.createToggleChip("Enabled only",104,_sessionEnabledOnly);
         _enabledChip.x = PANEL_W / 2 - 14 - 104;
         _enabledChip.y = -226;
         _modMenuPopup.addChild(_enabledChip);
         _searchBox = ModMenuUIHelper.createSearchField(_enabledChip.x - 8 - (tabHeader.x + _tabManager.getHeaderWidth() + 12),30);
         _searchBox.x = tabHeader.x + _tabManager.getHeaderWidth() + 12;
         _searchBox.y = -226;
         _modMenuPopup.addChild(_searchBox);
         _searchInput = _searchBox["input"] as TextField;
         _searchPlaceholder = _searchBox["placeholder"] as TextField;
         divider = ModMenuUIHelper.createHeaderDivider(PANEL_W - 28);
         divider.x = -394;
         divider.y = -188;
         _modMenuPopup.addChild(divider);
         createContainers();
         populateContainers();
         loadSettings();
         closeXBtn = ModMenuUIHelper.createCloseXButton();
         closeXBtn.x = PANEL_W / 2 - 14 - 28;
         closeXBtn.y = -PANEL_H / 2 + 12;
         _modMenuPopup.addChild(closeXBtn);
         _modMenuPopup.closeBtn = closeXBtn;
         scrollUpBtn = ModMenuUIHelper.createScrollButton("▲");
         scrollUpBtn.x = CONTENT_X + CONTENT_W + 5;
         scrollUpBtn.y = _startY;
         _modMenuPopup.addChild(scrollUpBtn);
         _modMenuPopup.scrollUpBtn = scrollUpBtn;
         scrollDownBtn = ModMenuUIHelper.createScrollButton("▼");
         scrollDownBtn.x = CONTENT_X + CONTENT_W + 5;
         scrollDownBtn.y = _startY + _maskHeight - 22;
         _modMenuPopup.addChild(scrollDownBtn);
         _modMenuPopup.scrollDownBtn = scrollDownBtn;
         track = ModMenuUIHelper.createScrollTrack(TRACK_H);
         track.x = CONTENT_X + CONTENT_W + 12;
         track.y = TRACK_Y;
         _modMenuPopup.addChild(track);
         _modMenuPopup.scrollTrack = track;
         thumb = ModMenuUIHelper.createScrollThumb();
         thumb.x = track.x;
         thumb.y = track.y;
         _modMenuPopup.addChild(thumb);
         _modMenuPopup.scrollThumb = thumb;
         _modsScroller.setScrollButtons(scrollUpBtn,scrollDownBtn);
         _enhancementsScroller.setScrollButtons(scrollUpBtn,scrollDownBtn);
         _popupsScroller.setScrollButtons(scrollUpBtn,scrollDownBtn);
         _modsScroller.setScrollTrack(track,thumb,TRACK_H);
         _enhancementsScroller.setScrollTrack(track,thumb,TRACK_H);
         _popupsScroller.setScrollTrack(track,thumb,TRACK_H);
         hintTxt = new TextField();
         hintTxt.text = "Click a row to toggle it   •   Scroll, drag the bar, or use ▲ ▼   •   Esc closes";
         hintTxt.textColor = 7042702;
         hintFmt = new TextFormat();
         hintFmt.size = 10;
         hintFmt.align = "center";
         hintTxt.setTextFormat(hintFmt);
         hintTxt.x = -300;
         hintTxt.y = 251;
         hintTxt.width = 600;
         hintTxt.height = 16;
         hintTxt.selectable = false;
         hintTxt.mouseEnabled = false;
         _modMenuPopup.addChild(hintTxt);
         gui.ModMenuContentBuilder.hoverCallback = onRowHover;
         updateTabLabels();
         _modMenuPopup.x = 450;
         _modMenuPopup.y = 275;
         GuiManager.guiLayer.addChild(_modMenuPopup);
         DarkenManager.darken(_modMenuPopup);
         DarkenManager.showLoadingSpiral(false);
         addEventListeners();
         refreshMouseEnabled();
         updateIconStatesForAllFeatures();
         if(_sessionQuery && _searchInput)
         {
            _searchInput.text = _sessionQuery;
            applyFilterToAll();
         }
         updatePlaceholder();
         restoreSessionState();
      }

      private function makeMaskedContainer() : Sprite
      {
         var container:Sprite = new Sprite();
         var mask:Sprite;
         container.x = CONTENT_X;
         container.y = _startY;
         container.mouseEnabled = true;
         container.mouseChildren = true;
         _modMenuPopup.addChild(container);
         mask = new Sprite();
         mask.graphics.beginFill(0);
         mask.graphics.drawRect(0,0,CONTENT_W,_maskHeight);
         mask.graphics.endFill();
         mask.x = CONTENT_X;
         mask.y = _startY;
         mask.mouseEnabled = false;
         mask.mouseChildren = false;
         _modMenuPopup.addChild(mask);
         container.mask = mask;
         return container;
      }

      private function makeEmptyLabel(container:Sprite, tabName:String) : void
      {
         var txt:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         txt.text = "Nothing matches your search.";
         txt.textColor = 7042702;
         fmt.size = 13;
         fmt.italic = true;
         fmt.align = "center";
         txt.setTextFormat(fmt);
         txt.x = 0;
         txt.y = 40;
         txt.width = CONTENT_W;
         txt.height = 24;
         txt.selectable = false;
         txt.mouseEnabled = false;
         txt.visible = false;
         container.addChild(txt);
         _emptyLabels[tabName] = txt;
      }

      private function createContainers() : void
      {
         var initialTab:String;
         _modsContainer = makeMaskedContainer();
         _modsScroller = new ModMenuScroller(_modsContainer,_startY,_maskHeight);
         _modsScroller.setOnScrollChangeCallback(function(scrollY:int):void
         {
            saveScrollPosition("mods",scrollY);
         });
         makeEmptyLabel(_modsContainer,"mods");
         _enhancementsContainer = makeMaskedContainer();
         _enhancementsContainer.visible = false;
         _enhancementsScroller = new ModMenuScroller(_enhancementsContainer,_startY,_maskHeight);
         _enhancementsScroller.setOnScrollChangeCallback(function(scrollY:int):void
         {
            saveScrollPosition("enhancements",scrollY);
         });
         makeEmptyLabel(_enhancementsContainer,"enhancements");
         _popupsContainer = makeMaskedContainer();
         _popupsContainer.visible = false;
         _popupsScroller = new ModMenuScroller(_popupsContainer,_startY,_maskHeight);
         _popupsScroller.setOnScrollChangeCallback(function(scrollY:int):void
         {
            saveScrollPosition("popups",scrollY);
         });
         makeEmptyLabel(_popupsContainer,"popups");
         _tabManager.registerContainer("mods",_modsContainer);
         _tabManager.registerContainer("enhancements",_enhancementsContainer);
         _tabManager.registerContainer("popups",_popupsContainer);
         _tabManager.setOnTabChangeCallback(onTabChanged);
         initialTab = _tabManager.getActiveTab();
         if(initialTab == "enhancements")
         {
            _activeContainer = _enhancementsContainer;
            _activeScroller = _enhancementsScroller;
         }
         else if(initialTab == "popups")
         {
            _activeContainer = _popupsContainer;
            _activeScroller = _popupsScroller;
         }
         else
         {
            _activeContainer = _modsContainer;
            _activeScroller = _modsScroller;
         }
      }

      private function populateContainers() : void
      {
         var toggleFeatures:Array;
         var i:int;
         var toggleCallback:Function;
         var feature:Object;
         var category:String;
         var featureKey:String;
         var featureLabel:String;
         var featureDesc:String;
         var featureHotkey:String;
         var checkboxRow:MovieClip;
         var denLoginCallback:Function;
         var denLoginResult:Object;
         var popupFeatures:Array;
         var popupFeature:Object;
         var buttonRow:MovieClip;
         try
         {
            if(!_checkboxes || !_iconRows || !_modsContainer || !_enhancementsContainer || !_popupsContainer)
            {
               return;
            }
            toggleFeatures = null;
            try
            {
               toggleFeatures = gui.ModMenuFeatures.getToggleFeatures();
            }
            catch(featuresErr:Error)
            {
               try
               {
                  ExternalInterface.call("console.log","Error getting toggle features: " + featuresErr.message);
               }
               catch(extErr:Error)
               {
               }
               return;
            }
            if(!toggleFeatures)
            {
               return;
            }
            i = 0;
            toggleCallback = toggleCheckbox;
            while(i < toggleFeatures.length)
            {
               try
               {
                  feature = toggleFeatures[i];
                  if(!feature || !feature.hasOwnProperty("key") || !feature.hasOwnProperty("category"))
                  {
                     i++;
                     continue;
                  }
                  category = feature["category"];
                  featureKey = feature["key"];
                  featureLabel = feature.hasOwnProperty("label") ? feature["label"] : "";
                  featureDesc = feature.hasOwnProperty("desc") ? feature["desc"] : "";
                  featureHotkey = feature.hasOwnProperty("hotkey") ? feature["hotkey"] : "";
                  if(category == "mods" || category == "enhancements")
                  {
                     checkboxRow = gui.ModMenuContentBuilder.createCheckboxRow(featureKey,featureLabel,featureDesc,featureHotkey,toggleCallback);
                     if(checkboxRow && checkboxRow.checkbox && _iconRows)
                     {
                        if(category == "mods")
                        {
                           _modsContainer.addChild(checkboxRow);
                        }
                        else
                        {
                           _enhancementsContainer.addChild(checkboxRow);
                        }
                        _checkboxes[featureKey] = checkboxRow.checkbox;
                        _iconRows[featureKey] = checkboxRow;
                     }
                  }
               }
               catch(e:Error)
               {
                  try
                  {
                     ExternalInterface.call("console.log","Error populating feature at index " + i + ": " + e.message);
                  }
                  catch(extErr:Error)
                  {
                  }
               }
               i++;
            }
         }
         catch(outerErr:Error)
         {
            try
            {
               ExternalInterface.call("console.log","Critical error in populateContainers: " + outerErr.message);
            }
            catch(extErr:Error)
            {
            }
         }
         try
         {
            denLoginCallback = getToggleCheckboxCallback();
            _denWrap = new MovieClip();
            _denWrap["isSection"] = true;
            _denWrap["matchText"] = "den on login enter den of a different username target username";
            _denWrap.mouseEnabled = false;
            _denWrap.mouseChildren = true;
            _modsContainer.addChild(_denWrap);
            denLoginResult = gui.ModMenuContentBuilder.createDenLoginSection(_denWrap,0,denLoginCallback,onDenUsernameChanged);
            _denLoginCheckbox = denLoginResult["checkbox"];
            _denUsernameInput = denLoginResult["usernameInput"];
            _denWrap["sectionHeight"] = int(denLoginResult["endYPos"]);
            _checkboxes["denLoginEnabled"] = _denLoginCheckbox;
         }
         catch(denErr:Error)
         {
            try
            {
               ExternalInterface.call("console.log","Error creating den login section: " + denErr.message);
            }
            catch(extErr:Error)
            {
            }
         }
         try
         {
            popupFeatures = gui.ModMenuFeatures.getPopupFeatures();
            i = 0;
            while(i < popupFeatures.length)
            {
               popupFeature = popupFeatures[i];
               buttonRow = gui.ModMenuContentBuilder.createButtonRow(popupFeature.key,popupFeature.label,popupFeature.desc,popupFeature.hotkey,popupFeature.action);
               _popupsContainer.addChild(buttonRow);
               i++;
            }
         }
         catch(popErr:Error)
         {
            try
            {
               ExternalInterface.call("console.log","Error populating popups: " + popErr.message);
            }
            catch(extErr:Error)
            {
            }
         }
         layoutContainer(_modsContainer,_modsScroller,"mods");
         layoutContainer(_enhancementsContainer,_enhancementsScroller,"enhancements");
         layoutContainer(_popupsContainer,_popupsScroller,"popups");
      }

      private function layoutContainer(container:Sprite, scroller:ModMenuScroller, tabName:String) : void
      {
         var i:int;
         var child:*;
         var row:MovieClip;
         var visibleIndex:int = 0;
         var col:int;
         var gridRows:int;
         var yPos:int = 0;
         var query:String = getQuery();
         var matchText:String;
         var isVisible:Boolean;
         var sections:Array = [];
         var emptyLabel:TextField;
         var total:int = 0;
         var colStep:int = gui.ModMenuContentBuilder.ROW_W + gui.ModMenuContentBuilder.COL_GAP;
         if(!container || !scroller)
         {
            return;
         }
         i = 0;
         while(i < container.numChildren)
         {
            child = container.getChildAt(i);
            if(child is MovieClip && child.hasOwnProperty("matchText"))
            {
               row = MovieClip(child);
               matchText = String(row["matchText"]);
               isVisible = query == "" || matchText.indexOf(query) != -1;
               if(!row["isSection"])
               {
                  total++;
               }
               if(isVisible && _sessionEnabledOnly && row.checkbox && !row["isSection"])
               {
                  try
                  {
                     isVisible = gui.ModMenuFeatures.getFeatureState(String(row["featureKey"]));
                  }
                  catch(stateErr:Error)
                  {
                  }
               }
               row.visible = isVisible;
               if(isVisible)
               {
                  if(row["isSection"])
                  {
                     sections.push(row);
                  }
                  else
                  {
                     col = visibleIndex % 2;
                     row.x = col * colStep;
                     row.y = int(visibleIndex / 2) * _itemHeight;
                     visibleIndex++;
                  }
               }
            }
            i++;
         }
         gridRows = int((visibleIndex + 1) / 2);
         yPos = gridRows * _itemHeight;
         i = 0;
         while(i < sections.length)
         {
            row = sections[i];
            row.x = 0;
            row.y = yPos + (gridRows > 0 ? 6 : 0);
            yPos = row.y + int(row["sectionHeight"]);
            i++;
         }
         emptyLabel = _emptyLabels[tabName] as TextField;
         if(emptyLabel)
         {
            emptyLabel.visible = visibleIndex == 0 && sections.length == 0;
         }
         _tabTotals[tabName] = total;
         _tabVisible[tabName] = visibleIndex;
         scroller.setMaxScrollForHeight(yPos + 12);
      }

      private function updateTabLabels() : void
      {
         var names:Array = ["mods","enhancements","popups"];
         var titles:Array = ["Mods","Enhancements","Popups"];
         var i:int = 0;
         var filtered:Boolean = getQuery() != "" || _sessionEnabledOnly;
         var total:int;
         var shown:int;
         var label:String;
         if(!_tabManager)
         {
            return;
         }
         while(i < names.length)
         {
            total = int(_tabTotals[names[i]]);
            shown = int(_tabVisible[names[i]]);
            if(filtered && (names[i] != "popups" || getQuery() != ""))
            {
               label = titles[i] + "  " + shown + "/" + total;
            }
            else
            {
               label = titles[i] + "  " + total;
            }
            _tabManager.setTabLabel(names[i],label);
            i++;
         }
      }

      private function onEnabledChipDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         _sessionEnabledOnly = !_sessionEnabledOnly;
         ModMenuUIHelper.setToggleChipState(_enabledChip,_sessionEnabledOnly);
         saveUiPrefs();
         applyFilterToAll();
      }

      private function hideTooltip() : void
      {
         if(_tooltip && _tooltip.parent)
         {
            _tooltip.parent.removeChild(_tooltip);
         }
         _tooltip = null;
      }

      private function onRowHover(row:MovieClip, show:Boolean) : void
      {
         var globalPt:Point;
         var localPt:Point;
         var tipH:int;
         hideTooltip();
         if(!show || !row || !_modMenuPopup || !row["descClipped"] || !row.parent)
         {
            return;
         }
         try
         {
            _tooltip = ModMenuUIHelper.createTooltip(String(row["fullDesc"]),gui.ModMenuContentBuilder.ROW_W - 20);
            globalPt = row.parent.localToGlobal(new Point(row.x,row.y));
            localPt = _modMenuPopup.globalToLocal(globalPt);
            tipH = int(_tooltip["tipHeight"]);
            _tooltip.x = localPt.x + 10;
            _tooltip.y = localPt.y + gui.ModMenuContentBuilder.ROW_BG_H + 4;
            if(_tooltip.y + tipH > _startY + _maskHeight)
            {
               _tooltip.y = localPt.y - tipH - 4;
            }
            _modMenuPopup.addChild(_tooltip);
         }
         catch(e:Error)
         {
            _tooltip = null;
         }
      }

      private function getQuery() : String
      {
         var q:String;
         if(!_searchInput)
         {
            return "";
         }
         q = _searchInput.text || "";
         while(q.length > 0 && q.charAt(0) == " ")
         {
            q = q.substr(1);
         }
         while(q.length > 0 && q.charAt(q.length - 1) == " ")
         {
            q = q.substr(0,q.length - 1);
         }
         return q.toLowerCase();
      }

      private function updatePlaceholder() : void
      {
         if(_searchPlaceholder && _searchInput)
         {
            _searchPlaceholder.visible = _searchInput.text == "" || _searchInput.text == null;
         }
      }

      private function applyFilterToAll() : void
      {
         layoutContainer(_modsContainer,_modsScroller,"mods");
         layoutContainer(_enhancementsContainer,_enhancementsScroller,"enhancements");
         layoutContainer(_popupsContainer,_popupsScroller,"popups");
         if(_activeScroller)
         {
            _activeScroller.setScrollY(0);
            _activeScroller.updateScrollButtons();
         }
         hideTooltip();
         updateTabLabels();
         refreshMouseEnabled();
      }

      private function onSearchChanged(e:Event) : void
      {
         try
         {
            _sessionQuery = _searchInput ? _searchInput.text : "";
            saveUiPrefs();
            updatePlaceholder();
            applyFilterToAll();
         }
         catch(err:Error)
         {
         }
      }

      private function onSearchBoxDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         try
         {
            if(_searchInput && gMainFrame && gMainFrame.stage)
            {
               gMainFrame.stage.focus = _searchInput;
            }
         }
         catch(err:Error)
         {
         }
      }

      private function onTabChanged(newTab:String, oldTab:String) : void
      {
         if(oldTab && _activeScroller)
         {
            saveScrollPosition(oldTab,_activeScroller.getScrollY());
         }
         if(newTab == "mods")
         {
            _activeContainer = _modsContainer;
            _activeScroller = _modsScroller;
         }
         else if(newTab == "enhancements")
         {
            _activeContainer = _enhancementsContainer;
            _activeScroller = _enhancementsScroller;
         }
         else if(newTab == "popups")
         {
            _activeContainer = _popupsContainer;
            _activeScroller = _popupsScroller;
         }
         _sessionLastTab = newTab;
         saveUiPrefs();
         hideTooltip();
         if(_activeScroller)
         {
            var savedScroll:int = getSavedScrollPosition(newTab);
            _activeScroller.setScrollY(savedScroll);
            _activeScroller.updateScrollButtons();
         }
         refreshMouseEnabled();
      }

      private function saveScrollPosition(tabName:String, scrollY:int) : void
      {
         _sessionScrollPositions[tabName] = scrollY;
      }

      private function getSavedScrollPosition(tabName:String) : int
      {
         if(_sessionScrollPositions.hasOwnProperty(tabName))
         {
            return int(_sessionScrollPositions[tabName]);
         }
         return 0;
      }

      private function restoreSessionState() : void
      {
         if(!_tabManager)
         {
            return;
         }
         var savedTab:String = _sessionLastTab;
         if(savedTab != "mods" && savedTab != "enhancements" && savedTab != "popups")
         {
            savedTab = "mods";
         }
         if(savedTab != _tabManager.getActiveTab())
         {
            _tabManager.switchTab(savedTab);
         }
         else if(_activeScroller)
         {
            var savedScroll:int = getSavedScrollPosition(savedTab);
            _activeScroller.setScrollY(savedScroll);
            _activeScroller.updateScrollButtons();
         }
      }

      private function toggleCheckbox(key:String) : void
      {
         if(!_checkboxes)
         {
            return;
         }
         var checkbox:MovieClip = _checkboxes[key];
         if(!checkbox)
         {
            return;
         }
         var currentState:Boolean = gui.ModMenuFeatures.getFeatureState(key);
         var newState:Boolean = !currentState;
         _checkboxStates[key] = newState;
         ModMenuUIHelper.setCheckboxState(checkbox,newState);
         gui.ModMenuFeatures.handleFeatureToggle(key,newState);
         if(key == "denLoginEnabled" && _denUsernameInput)
         {
            _denUsernameInput.alpha = newState ? 1 : 0.5;
         }
         if(_sessionEnabledOnly && key != "denLoginEnabled")
         {
            layoutContainer(_modsContainer,_modsScroller,"mods");
            layoutContainer(_enhancementsContainer,_enhancementsScroller,"enhancements");
            hideTooltip();
            updateTabLabels();
            refreshMouseEnabled();
         }
      }

      private function onDenUsernameChanged(e:Event) : void
      {
         var enabled:Boolean;
         var usernameText:String;
         try
         {
            if(!_denUsernameInput || !_checkboxStates)
            {
               return;
            }
            enabled = Boolean(_checkboxStates["denLoginEnabled"]);
            usernameText = _denUsernameInput.text || "";
            GuiManager.setDenLoginConfig(enabled,usernameText);
         }
         catch(err:Error)
         {
         }
      }

      private function loadSettings() : void
      {
         var toggleFeatures:Array;
         var i:int;
         var key:String;
         var enabled:Boolean;
         var denConfig:Object;
         var denEnabled:Boolean;
         var denUsername:String;
         if(!_checkboxes)
         {
            return;
         }
         try
         {
            toggleFeatures = gui.ModMenuFeatures.getToggleFeatures();
         }
         catch(e:Error)
         {
            return;
         }
         if(!toggleFeatures)
         {
            return;
         }
         i = 0;
         while(i < toggleFeatures.length)
         {
            key = toggleFeatures[i]["key"];
            try
            {
               enabled = gui.ModMenuFeatures.getFeatureState(key);
               _checkboxStates[key] = enabled;
               if(_checkboxes[key])
               {
                  ModMenuUIHelper.setCheckboxState(_checkboxes[key],enabled);
               }
            }
            catch(e:Error)
            {
            }
            i++;
         }
         try
         {
            denConfig = gui.ModMenuFeatures.getDenLoginConfig();
            denEnabled = Boolean(denConfig["enabled"]);
            denUsername = denConfig["username"];
            if(_denLoginCheckbox)
            {
               _checkboxStates["denLoginEnabled"] = denEnabled;
               ModMenuUIHelper.setCheckboxState(_denLoginCheckbox,denEnabled);
            }
            if(_denUsernameInput)
            {
               _denUsernameInput.text = denUsername || "";
               _denUsernameInput.alpha = denEnabled ? 1 : 0.5;
            }
         }
         catch(e:Error)
         {
         }
         updateIconStatesForAllFeatures();
      }

      public function refreshIconStates() : void
      {
         updateIconStatesForAllFeatures();
      }

      private function updateIconStatesForAllFeatures() : void
      {
         var featureKey:String;
         var row:MovieClip;
         var isGlobal:Boolean;
         var globeIcon:MovieClip;
         if(!_iconRows)
         {
            return;
         }
         for(featureKey in _iconRows)
         {
            try
            {
               row = _iconRows[featureKey];
               if(row && row.globeIcon)
               {
                  isGlobal = gui.ModMenuFeatures.getFeatureScope(featureKey);
                  globeIcon = row.globeIcon;
                  ModMenuUIHelper.updateIconState(globeIcon,isGlobal,true);
               }
            }
            catch(e:Error)
            {
            }
         }
      }

      public function refreshSettings() : void
      {
         loadSettings();
      }

      private function addEventListeners() : void
      {
         _modMenuPopup.addEventListener("mouseDown",onPopup,false,0,false);
         if(_modMenuPopup.closeBtn)
         {
            _modMenuPopup.closeBtn.addEventListener("mouseDown",onCloseBtn,false,0,false);
         }
         if(_modMenuPopup.scrollUpBtn)
         {
            _modMenuPopup.scrollUpBtn.addEventListener("mouseDown",onScrollUp,false,0,false);
         }
         if(_modMenuPopup.scrollDownBtn)
         {
            _modMenuPopup.scrollDownBtn.addEventListener("mouseDown",onScrollDown,false,0,false);
         }
         if(_modMenuPopup)
         {
            _modMenuPopup.addEventListener("mouseWheel",onMouseWheel,false,0,false);
         }
         if(_modsContainer && !_modsContainer.hasEventListener("mouseWheel"))
         {
            _modsContainer.addEventListener("mouseWheel",onMouseWheel,false,0,false);
         }
         if(_enhancementsContainer && !_enhancementsContainer.hasEventListener("mouseWheel"))
         {
            _enhancementsContainer.addEventListener("mouseWheel",onMouseWheel,false,0,false);
         }
         if(_popupsContainer && !_popupsContainer.hasEventListener("mouseWheel"))
         {
            _popupsContainer.addEventListener("mouseWheel",onMouseWheel,false,0,false);
         }
         if(_searchInput)
         {
            _searchInput.addEventListener(Event.CHANGE,onSearchChanged,false,0,false);
         }
         if(_searchBox)
         {
            _searchBox.addEventListener("mouseDown",onSearchBoxDown,false,0,false);
         }
         if(_enabledChip)
         {
            _enabledChip.addEventListener("mouseDown",onEnabledChipDown,false,0,false);
         }
         gMainFrame.stage.addEventListener("keyDown",onKeyDown,false,0,false);
      }

      private function removeEventListeners() : void
      {
         if(_modMenuPopup)
         {
            _modMenuPopup.removeEventListener("mouseDown",onPopup);
            _modMenuPopup.removeEventListener("mouseWheel",onMouseWheel);
            if(_modMenuPopup.closeBtn)
            {
               _modMenuPopup.closeBtn.removeEventListener("mouseDown",onCloseBtn);
            }
            if(_modMenuPopup.scrollUpBtn)
            {
               _modMenuPopup.scrollUpBtn.removeEventListener("mouseDown",onScrollUp);
            }
            if(_modMenuPopup.scrollDownBtn)
            {
               _modMenuPopup.scrollDownBtn.removeEventListener("mouseDown",onScrollDown);
            }
         }
         if(_modsContainer)
         {
            _modsContainer.removeEventListener("mouseWheel",onMouseWheel);
         }
         if(_enhancementsContainer)
         {
            _enhancementsContainer.removeEventListener("mouseWheel",onMouseWheel);
         }
         if(_popupsContainer)
         {
            _popupsContainer.removeEventListener("mouseWheel",onMouseWheel);
         }
         if(_searchInput)
         {
            _searchInput.removeEventListener(Event.CHANGE,onSearchChanged);
         }
         if(_searchBox)
         {
            _searchBox.removeEventListener("mouseDown",onSearchBoxDown);
         }
         if(_enabledChip)
         {
            _enabledChip.removeEventListener("mouseDown",onEnabledChipDown);
         }
         if(gui.ModMenuContentBuilder.hoverCallback == onRowHover)
         {
            gui.ModMenuContentBuilder.hoverCallback = null;
         }
         hideTooltip();
         if(gMainFrame && gMainFrame.stage)
         {
            gMainFrame.stage.removeEventListener("keyDown",onKeyDown);
         }
      }

      private function onMouseWheel(e:MouseEvent) : void
      {
         if(!_modMenuPopup || !_modMenuPopup.visible || !_modMenuPopup.parent || !_activeScroller)
         {
            return;
         }
         if(_activeScroller.onMouseWheel(e))
         {
            e.stopPropagation();
         }
      }

      private function onScrollUp(e:MouseEvent) : void
      {
         if(_activeScroller)
         {
            _activeScroller.onScrollUp(e);
         }
      }

      private function onScrollDown(e:MouseEvent) : void
      {
         if(_activeScroller)
         {
            _activeScroller.onScrollDown(e);
         }
      }

      public function refreshAndActivate() : void
      {
         var checkbox:MovieClip;
         try
         {
            if(_modMenuPopup && _modMenuPopup.parent)
            {
               GuiManager.guiLayer.setChildIndex(_modMenuPopup,GuiManager.guiLayer.numChildren - 1);
               _modMenuPopup.mouseEnabled = true;
               _modMenuPopup.mouseChildren = true;
               _modMenuPopup.tabChildren = false;
               _modMenuPopup.tabEnabled = false;
               if(_activeContainer)
               {
                  _activeContainer.mouseEnabled = true;
                  _activeContainer.mouseChildren = true;
               }
               if(_checkboxes)
               {
                  for each(checkbox in _checkboxes)
                  {
                     if(checkbox)
                     {
                        checkbox.mouseEnabled = true;
                        checkbox.mouseChildren = false;
                     }
                  }
               }
               if(_modMenuPopup && !_modMenuPopup.hasEventListener("mouseWheel"))
               {
                  _modMenuPopup.addEventListener("mouseWheel",onMouseWheel,false,0,false);
               }
               if(_modsContainer && !_modsContainer.hasEventListener("mouseWheel"))
               {
                  _modsContainer.addEventListener("mouseWheel",onMouseWheel,false,0,false);
               }
               if(_enhancementsContainer && !_enhancementsContainer.hasEventListener("mouseWheel"))
               {
                  _enhancementsContainer.addEventListener("mouseWheel",onMouseWheel,false,0,false);
               }
               if(_popupsContainer && !_popupsContainer.hasEventListener("mouseWheel"))
               {
                  _popupsContainer.addEventListener("mouseWheel",onMouseWheel,false,0,false);
               }
               refreshMouseEnabled();
               DarkenManager.darken(_modMenuPopup);
            }
         }
         catch(e:Error)
         {
         }
      }

      private function enableRow(row:MovieClip) : void
      {
         var j:int;
         var subChild:*;
         var subMc:MovieClip;
         row.mouseEnabled = false;
         row.mouseChildren = true;
         row.tabEnabled = false;
         row.tabChildren = false;
         row.buttonMode = false;
         row.hitArea = null;
         if(row.openBtn)
         {
            row.openBtn.mouseEnabled = true;
            row.openBtn.mouseChildren = false;
            row.openBtn.buttonMode = true;
            row.openBtn.tabEnabled = false;
            row.openBtn.hitArea = null;
         }
         if(row.checkbox)
         {
            if(!row.checkbox["isToggling"])
            {
               row.checkbox.mouseEnabled = true;
               row.checkbox.mouseChildren = false;
               row.checkbox.buttonMode = true;
               row.checkbox.tabEnabled = false;
               row.checkbox.hitArea = null;
            }
         }
         if(row.hitBg)
         {
            row.hitBg.mouseEnabled = true;
            row.hitBg.mouseChildren = false;
            row.hitBg.buttonMode = true;
            row.hitBg.tabEnabled = false;
            row.hitBg.hitArea = null;
         }
         if(row.globeIcon)
         {
            row.globeIcon.mouseEnabled = true;
            row.globeIcon.mouseChildren = false;
            row.globeIcon.buttonMode = true;
            row.globeIcon.tabEnabled = false;
            row.globeIcon.hitArea = null;
         }
         j = 0;
         while(j < row.numChildren)
         {
            subChild = row.getChildAt(j);
            if(subChild)
            {
               if(subChild is TextField)
               {
                  TextField(subChild).mouseEnabled = false;
                  TextField(subChild).tabEnabled = false;
               }
               else if(subChild is MovieClip)
               {
                  subMc = MovieClip(subChild);
                  if(subMc != row.openBtn && subMc != row.checkbox && subMc != row.globeIcon && subMc != row.hitBg)
                  {
                     subMc.mouseEnabled = false;
                     subMc.mouseChildren = false;
                     subMc.tabEnabled = false;
                  }
               }
            }
            j++;
         }
      }

      private function refreshMouseEnabled() : void
      {
         var checkbox:MovieClip;
         var i:int;
         var child:*;
         var containers:Array;
         var c:int;
         var currentContainer:Sprite;
         try
         {
            if(_modMenuPopup)
            {
               _modMenuPopup.mouseEnabled = true;
               _modMenuPopup.mouseChildren = true;
               _modMenuPopup.tabEnabled = false;
               _modMenuPopup.tabChildren = false;
            }
            if(_checkboxes)
            {
               for each(checkbox in _checkboxes)
               {
                  if(checkbox)
                  {
                     checkbox.mouseEnabled = true;
                     checkbox.mouseChildren = false;
                     checkbox.buttonMode = true;
                     checkbox.tabEnabled = false;
                  }
               }
            }
            if(_modMenuPopup && _modMenuPopup.closeBtn)
            {
               _modMenuPopup.closeBtn.mouseEnabled = true;
               _modMenuPopup.closeBtn.mouseChildren = false;
               _modMenuPopup.closeBtn.buttonMode = true;
            }
            if(_modMenuPopup && _modMenuPopup.scrollUpBtn)
            {
               _modMenuPopup.scrollUpBtn.mouseEnabled = true;
               _modMenuPopup.scrollUpBtn.mouseChildren = false;
               _modMenuPopup.scrollUpBtn.buttonMode = true;
               _modMenuPopup.scrollUpBtn.tabEnabled = false;
               _modMenuPopup.scrollUpBtn.hitArea = null;
            }
            if(_modMenuPopup && _modMenuPopup.scrollDownBtn)
            {
               _modMenuPopup.scrollDownBtn.mouseEnabled = true;
               _modMenuPopup.scrollDownBtn.mouseChildren = false;
               _modMenuPopup.scrollDownBtn.buttonMode = true;
               _modMenuPopup.scrollDownBtn.tabEnabled = false;
               _modMenuPopup.scrollDownBtn.hitArea = null;
            }
            containers = [_modsContainer,_enhancementsContainer,_popupsContainer];
            c = 0;
            while(c < containers.length)
            {
               currentContainer = containers[c];
               if(currentContainer)
               {
                  currentContainer.mouseEnabled = true;
                  currentContainer.mouseChildren = true;
                  currentContainer.tabEnabled = false;
                  currentContainer.tabChildren = false;
                  i = 0;
                  while(i < currentContainer.numChildren)
                  {
                     child = currentContainer.getChildAt(i);
                     if(child && child is MovieClip)
                     {
                        enableRow(MovieClip(child));
                     }
                     i++;
                  }
               }
               c++;
            }
            if(_denLoginCheckbox)
            {
               if(!_denLoginCheckbox["isToggling"])
               {
                  _denLoginCheckbox.mouseEnabled = true;
                  _denLoginCheckbox.mouseChildren = false;
                  _denLoginCheckbox.buttonMode = true;
                  _denLoginCheckbox.tabEnabled = false;
                  _denLoginCheckbox.hitArea = null;
               }
            }
         }
         catch(e:Error)
         {
         }
      }

      private function onKeyDown(e:KeyboardEvent) : void
      {
         if(e.keyCode == 27)
         {
            destroy();
         }
      }

      private function onPopup(e:MouseEvent) : void
      {
         var target:* = e.target;
         var bg:* = null;
         if(_modMenuPopup && _modMenuPopup.numChildren > 0)
         {
            bg = _modMenuPopup.getChildAt(0);
         }
         if(target == _modMenuPopup || target == bg)
         {
            e.stopPropagation();
         }
      }

      private function onCloseBtn(e:MouseEvent) : void
      {
         e.stopPropagation();
         destroy();
      }

      public function destroy() : void
      {
         var currentTab:String;
         var cleanupKey:String;
         var cleanupRow:MovieClip;
         try
         {
            if(_tabManager && _activeScroller)
            {
               currentTab = _tabManager.getActiveTab();
               saveScrollPosition(currentTab,_activeScroller.getScrollY());
               _sessionLastTab = currentTab;
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
            if(_modsScroller)
            {
               _modsScroller.destroy();
            }
            if(_enhancementsScroller)
            {
               _enhancementsScroller.destroy();
            }
            if(_popupsScroller)
            {
               _popupsScroller.destroy();
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            if(_modMenuPopup)
            {
               if(_modMenuPopup.parent)
               {
                  GuiManager.guiLayer.removeChild(_modMenuPopup);
               }
               DarkenManager.unDarken(_modMenuPopup);
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            if(_closeCallback != null)
            {
               _closeCallback();
            }
         }
         catch(e:Error)
         {
         }
         try
         {
            if(_iconRows)
            {
               for(cleanupKey in _iconRows)
               {
                  cleanupRow = _iconRows[cleanupKey];
                  if(cleanupRow)
                  {
                     if(cleanupRow.checkbox && cleanupRow["_checkboxHandler"])
                     {
                        cleanupRow.checkbox.removeEventListener("mouseDown",cleanupRow["_checkboxHandler"]);
                     }
                     if(cleanupRow.hitBg && cleanupRow["_checkboxHandler"])
                     {
                        cleanupRow.hitBg.removeEventListener("mouseDown",cleanupRow["_checkboxHandler"]);
                     }
                     if(cleanupRow.globeIcon && cleanupRow["_scopeHandler"])
                     {
                        cleanupRow.globeIcon.removeEventListener("mouseDown",cleanupRow["_scopeHandler"]);
                     }
                     if(cleanupRow.openBtn && cleanupRow["_buttonHandler"])
                     {
                        cleanupRow.openBtn.removeEventListener("mouseDown",cleanupRow["_buttonHandler"]);
                     }
                  }
               }
            }
         }
         catch(e:Error)
         {
         }
         _modMenuPopup = null;
         _checkboxes = null;
         _checkboxStates = null;
         _iconRows = null;
         _tabManager = null;
         _denUsernameInput = null;
         _denLoginCheckbox = null;
         _denWrap = null;
         _searchBox = null;
         _searchInput = null;
         _searchPlaceholder = null;
         _emptyLabels = null;
         _enabledChip = null;
         _tooltip = null;
         _tabTotals = null;
         _tabVisible = null;
         _modsScroller = null;
         _enhancementsScroller = null;
         _popupsScroller = null;
         _activeScroller = null;
      }
   }
}
