package gui
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;

   public class ModMenuTabManager
   {

      public static const TAB_GAP:int = 8;

      private var _currentTab:String;

      private var _tabButtons:Object;

      private var _containers:Object;

      private var _onTabChangeCallback:Function;

      public function ModMenuTabManager(param1:String = "mods")
      {
         super();
         _currentTab = param1;
         _tabButtons = {};
         _containers = {};
      }

      public function createTabHeader() : MovieClip
      {
         var enhancementsTab:MovieClip;
         var popupsTab:MovieClip;
         var self:ModMenuTabManager;
         var modsHandler:Function;
         var enhancementsHandler:Function;
         var popupsHandler:Function;
         var step:int = ModMenuUIHelper.TAB_W + TAB_GAP;
         var tabContainer:MovieClip = new MovieClip();
         var modsTab:MovieClip = ModMenuUIHelper.createTabButton("Mods",_currentTab == "mods");
         modsTab.x = 0;
         modsTab.y = 0;
         modsTab["tabName"] = "mods";
         modsTab.mouseEnabled = true;
         modsTab.mouseChildren = false;
         modsTab.buttonMode = true;
         _tabButtons["mods"] = modsTab;
         tabContainer.addChild(modsTab);
         enhancementsTab = ModMenuUIHelper.createTabButton("Enhancements",_currentTab == "enhancements");
         enhancementsTab.x = step;
         enhancementsTab.y = 0;
         enhancementsTab["tabName"] = "enhancements";
         enhancementsTab.mouseEnabled = true;
         enhancementsTab.mouseChildren = false;
         enhancementsTab.buttonMode = true;
         _tabButtons["enhancements"] = enhancementsTab;
         tabContainer.addChild(enhancementsTab);
         popupsTab = ModMenuUIHelper.createTabButton("Popups",_currentTab == "popups");
         popupsTab.x = step * 2;
         popupsTab.y = 0;
         popupsTab["tabName"] = "popups";
         popupsTab.mouseEnabled = true;
         popupsTab.mouseChildren = false;
         popupsTab.buttonMode = true;
         _tabButtons["popups"] = popupsTab;
         tabContainer.addChild(popupsTab);
         self = this;
         modsHandler = function(e:MouseEvent):void
         {
            e.stopPropagation();
            e.stopImmediatePropagation();
            self.switchTab("mods");
         };
         modsTab.addEventListener("mouseDown",modsHandler,false,0,false);
         modsTab["_tabHandler"] = modsHandler;
         enhancementsHandler = function(e:MouseEvent):void
         {
            e.stopPropagation();
            e.stopImmediatePropagation();
            self.switchTab("enhancements");
         };
         enhancementsTab.addEventListener("mouseDown",enhancementsHandler,false,0,false);
         enhancementsTab["_tabHandler"] = enhancementsHandler;
         popupsHandler = function(e:MouseEvent):void
         {
            e.stopPropagation();
            e.stopImmediatePropagation();
            self.switchTab("popups");
         };
         popupsTab.addEventListener("mouseDown",popupsHandler,false,0,false);
         popupsTab["_tabHandler"] = popupsHandler;
         return tabContainer;
      }

      public function setTabLabel(tabName:String, label:String) : void
      {
         if(_tabButtons && _tabButtons[tabName])
         {
            ModMenuUIHelper.setTabButtonLabel(_tabButtons[tabName],label);
         }
      }

      public function getHeaderWidth() : int
      {
         return ModMenuUIHelper.TAB_W * 3 + TAB_GAP * 2;
      }

      public function registerContainer(tabName:String, container:Sprite) : void
      {
         _containers[tabName] = container;
         container.visible = tabName == _currentTab;
      }

      public function switchTab(tabName:String) : void
      {
         if(!_containers || !_tabButtons)
         {
            return;
         }
         if(tabName == _currentTab || !_containers[tabName])
         {
            return;
         }
         var oldTab:String = _currentTab;
         _currentTab = tabName;
         if(_containers[oldTab])
         {
            _containers[oldTab].visible = false;
         }
         if(_containers[tabName])
         {
            _containers[tabName].visible = true;
         }
         if(_tabButtons[oldTab])
         {
            ModMenuUIHelper.updateTabButtonState(_tabButtons[oldTab],false);
         }
         if(_tabButtons[tabName])
         {
            ModMenuUIHelper.updateTabButtonState(_tabButtons[tabName],true);
         }
         if(_onTabChangeCallback != null)
         {
            _onTabChangeCallback(tabName,oldTab);
         }
      }

      public function getActiveTab() : String
      {
         return _currentTab;
      }

      public function setOnTabChangeCallback(callback:Function) : void
      {
         _onTabChangeCallback = callback;
      }

      public function getTabButton(tabName:String) : MovieClip
      {
         return _tabButtons[tabName];
      }
   }
}
