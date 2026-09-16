package gui
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.getTimer;

   public class ModMenuContentBuilder
   {

      public static const ROW_W:int = 384;

      public static const ROW_H:int = 50;

      public static const ROW_BG_H:int = 46;

      public static const COL_GAP:int = 12;

      public static var hoverCallback:Function = null;

      public function ModMenuContentBuilder()
      {
         super();
      }

      private static function notifyHover(row:MovieClip, show:Boolean) : void
      {
         try
         {
            if(hoverCallback != null)
            {
               hoverCallback(row,show);
            }
         }
         catch(e:Error)
         {
         }
      }

      private static function hasHotkey(hotkey:String) : Boolean
      {
         return hotkey != null && hotkey != "" && hotkey != "N/A";
      }

      private static function makeLabel(text:String, x:int, y:int, w:int, size:int, bold:Boolean, color:uint, wrap:Boolean) : TextField
      {
         var txt:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         fmt.size = size;
         fmt.bold = bold;
         txt.defaultTextFormat = fmt;
         txt.wordWrap = wrap;
         txt.multiline = wrap;
         txt.text = text;
         txt.textColor = color;
         txt.x = x;
         txt.y = y;
         txt.width = w;
         txt.height = wrap ? 26 : size + 8;
         txt.selectable = false;
         txt.mouseEnabled = false;
         return txt;
      }

      private static function attachHover(bg:MovieClip, row:MovieClip) : void
      {
         var overHandler:Function = function(e:MouseEvent):void
         {
            ModMenuUIHelper.drawRowBackground(bg,ROW_W,ROW_BG_H,true);
            notifyHover(row,true);
         };
         var outHandler:Function = function(e:MouseEvent):void
         {
            ModMenuUIHelper.drawRowBackground(bg,ROW_W,ROW_BG_H,false);
            notifyHover(row,false);
         };
         bg.addEventListener("mouseOver",overHandler,false,0,false);
         bg.addEventListener("mouseOut",outHandler,false,0,false);
         row["_hoverOver"] = overHandler;
         row["_hoverOut"] = outHandler;
      }

      public static function createCheckboxRow(key:String, label:String, description:String, hotkey:String, onToggleCallback:Function) : MovieClip
      {
         var row:MovieClip;
         var bg:MovieClip;
         var isGlobal:Boolean;
         var globeIcon:MovieClip;
         var checkbox:MovieClip;
         var labelTxt:TextField;
         var descTxt:TextField;
         var chip:MovieClip;
         var labelW:int;
         var checkboxClickHandler:Function;
         var rowClickHandler:Function;
         var scopeToggleHandler:Function;
         if(!key)
         {
            key = "";
         }
         if(!label)
         {
            label = "";
         }
         if(!description)
         {
            description = "";
         }
         if(!hotkey)
         {
            hotkey = "";
         }
         row = new MovieClip();
         row["featureKey"] = key;
         row["matchText"] = (label + " " + description).toLowerCase();
         row["isToggling"] = false;
         row["lastToggleTime"] = 0;
         bg = new MovieClip();
         ModMenuUIHelper.drawRowBackground(bg,ROW_W,ROW_BG_H,false);
         bg.buttonMode = true;
         bg.mouseEnabled = true;
         bg.mouseChildren = false;
         bg.tabEnabled = false;
         row.addChild(bg);
         row.hitBg = bg;
         attachHover(bg,row);
         isGlobal = false;
         try
         {
            isGlobal = gui.ModMenuFeatures.getFeatureScope(key);
         }
         catch(scopeErr:Error)
         {
            isGlobal = false;
         }
         globeIcon = ModMenuUIHelper.createGlobeIcon(isGlobal);
         globeIcon.x = 10;
         globeIcon.y = 13;
         globeIcon["featureKey"] = key;
         row.addChild(globeIcon);
         row.globeIcon = globeIcon;
         checkbox = ModMenuUIHelper.createCheckbox();
         checkbox.x = 40;
         checkbox.y = 14;
         checkbox["featureKey"] = key;
         checkbox["isToggling"] = false;
         checkbox["lastToggleTime"] = 0;
         row.addChild(checkbox);
         row.checkbox = checkbox;
         labelW = ROW_W - 86 - 8;
         if(hasHotkey(hotkey))
         {
            chip = ModMenuUIHelper.createHotkeyChip(hotkey);
            chip.x = ROW_W - 8 - int(chip["chipWidth"]);
            chip.y = 5;
            row.addChild(chip);
            labelW = chip.x - 86 - 6;
         }
         labelTxt = makeLabel(label,86,3,labelW,13,true,ModMenuUIHelper.COLOR_TEXT,false);
         row.addChild(labelTxt);
         descTxt = makeLabel(description,86,20,ROW_W - 86 - 8,10,false,ModMenuUIHelper.COLOR_TEXT_DIM,true);
         row.addChild(descTxt);
         row["fullDesc"] = description;
         row["descClipped"] = descTxt.numLines > 2;
         checkboxClickHandler = function(e:MouseEvent):void
         {
            var currentTime:int;
            var lastToggleTime:int;
            try
            {
               e.stopPropagation();
               e.stopImmediatePropagation();
               currentTime = getTimer();
               lastToggleTime = int(int(row["lastToggleTime"]) || 0);
               if(row["isToggling"] || currentTime - lastToggleTime < 150)
               {
                  return;
               }
               row["isToggling"] = true;
               row["lastToggleTime"] = currentTime;
               if(key && onToggleCallback != null)
               {
                  onToggleCallback(key);
               }
            }
            catch(err:Error)
            {
            }
            row["isToggling"] = false;
         };
         checkbox.addEventListener("mouseDown",checkboxClickHandler,false,0,false);
         bg.addEventListener("mouseDown",checkboxClickHandler,false,0,false);
         globeIcon["isToggling"] = false;
         globeIcon["lastToggleTime"] = 0;
         scopeToggleHandler = function(e:MouseEvent):void
         {
            var currentTime:int;
            var lastToggleTime:int;
            var currentScope:Boolean;
            var newScope:Boolean;
            try
            {
               e.stopPropagation();
               e.stopImmediatePropagation();
               currentTime = getTimer();
               lastToggleTime = int(int(globeIcon["lastToggleTime"]) || 0);
               if(globeIcon["isToggling"] || currentTime - lastToggleTime < 200)
               {
                  return;
               }
               globeIcon["isToggling"] = true;
               globeIcon["lastToggleTime"] = currentTime;
               try
               {
                  currentScope = gui.ModMenuFeatures.getFeatureScope(key);
                  newScope = !currentScope;
                  gui.ModMenuFeatures.setFeatureScope(key,newScope);
                  ModMenuUIHelper.updateIconState(globeIcon,newScope,true);
               }
               catch(scopeErr:Error)
               {
                  try
                  {
                     ExternalInterface.call("console.log","Error changing scope: " + scopeErr.message);
                  }
                  catch(extErr2:Error)
                  {
                  }
               }
            }
            catch(err:Error)
            {
            }
            globeIcon["isToggling"] = false;
         };
         globeIcon.addEventListener("mouseDown",scopeToggleHandler,false,0,false);
         row["_checkboxHandler"] = checkboxClickHandler;
         row["_scopeHandler"] = scopeToggleHandler;
         row.mouseEnabled = false;
         row.mouseChildren = true;
         return row;
      }

      public static function createButtonRow(key:String, label:String, description:String, hotkey:String, action:String) : MovieClip
      {
         var bg:MovieClip;
         var labelTxt:TextField;
         var descTxt:TextField;
         var chip:MovieClip;
         var openBtn:MovieClip;
         var buttonClickHandler:Function;
         var textW:int;
         var row:MovieClip = new MovieClip();
         if(!label)
         {
            label = "";
         }
         if(!description)
         {
            description = "";
         }
         if(!hotkey)
         {
            hotkey = "";
         }
         row["featureKey"] = key;
         row["matchText"] = (label + " " + description).toLowerCase();
         bg = new MovieClip();
         ModMenuUIHelper.drawRowBackground(bg,ROW_W,ROW_BG_H,false);
         bg.buttonMode = true;
         bg.mouseEnabled = true;
         bg.mouseChildren = false;
         bg.tabEnabled = false;
         row.addChild(bg);
         row.hitBg = bg;
         attachHover(bg,row);
         textW = ROW_W - 10 - 84;
         labelTxt = makeLabel(label,10,3,textW,13,true,ModMenuUIHelper.COLOR_TEXT,false);
         row.addChild(labelTxt);
         descTxt = makeLabel(description,10,20,textW,10,false,ModMenuUIHelper.COLOR_TEXT_DIM,true);
         row.addChild(descTxt);
         row["fullDesc"] = description;
         row["descClipped"] = descTxt.numLines > 2;
         openBtn = ModMenuUIHelper.createButton("Open",5025616,72,22);
         openBtn.x = ROW_W - 8 - 72;
         openBtn.y = hasHotkey(hotkey) ? 4 : 12;
         openBtn["popupAction"] = action;
         openBtn["isProcessing"] = false;
         openBtn["lastClickTime"] = 0;
         if(hasHotkey(hotkey))
         {
            chip = ModMenuUIHelper.createHotkeyChip(hotkey);
            chip.x = ROW_W - 8 - int(chip["chipWidth"]);
            chip.y = 28;
            row.addChild(chip);
         }
         buttonClickHandler = function(e:MouseEvent):void
         {
            var currentTime:int;
            var lastClickTime:int;
            var btnAction:String;
            try
            {
               e.stopPropagation();
               e.stopImmediatePropagation();
               currentTime = getTimer();
               lastClickTime = int(int(openBtn["lastClickTime"]) || 0);
               if(openBtn["isProcessing"] || currentTime - lastClickTime < 150)
               {
                  return;
               }
               openBtn["isProcessing"] = true;
               openBtn["lastClickTime"] = currentTime;
               btnAction = openBtn["popupAction"];
               if(btnAction)
               {
                  gui.ModMenuFeatures.handlePopupAction(btnAction);
               }
            }
            catch(err:Error)
            {
            }
            openBtn["isProcessing"] = false;
         };
         openBtn.addEventListener("mouseDown",buttonClickHandler,false,0,false);
         bg.addEventListener("mouseDown",buttonClickHandler,false,0,false);
         row.addChild(openBtn);
         row.openBtn = openBtn;
         row["_buttonHandler"] = buttonClickHandler;
         row.mouseEnabled = false;
         row.mouseChildren = true;
         return row;
      }

      public static function createDenLoginSection(container:Sprite, startYPos:int, onToggleCallback:Function, onUsernameChangedCallback:Function) : Object
      {
         var sectionBg:MovieClip;
         var sectionLabel:TextField;
         var chip:MovieClip;
         var denLabel:TextField;
         var usernameLabel:TextField;
         var denLoginCheckbox:MovieClip;
         var denUsernameInput:TextField;
         var inputBg:MovieClip;
         var inputFmt:TextFormat;
         var fullW:int = ROW_W * 2 + COL_GAP;
         var yPos:int = startYPos;
         var sectionH:int = 96;
         sectionBg = new MovieClip();
         sectionBg.graphics.beginFill(ModMenuUIHelper.COLOR_TEXT,0.04);
         sectionBg.graphics.drawRoundRect(0,0,fullW,sectionH,8,8);
         sectionBg.graphics.endFill();
         sectionBg.graphics.lineStyle(1,ModMenuUIHelper.COLOR_TEXT,0.06);
         sectionBg.graphics.drawRoundRect(0,0,fullW,sectionH,8,8);
         sectionBg.x = 0;
         sectionBg.y = yPos;
         sectionBg.mouseEnabled = false;
         sectionBg.mouseChildren = false;
         container.addChild(sectionBg);
         sectionLabel = makeLabel("Den on Login",12,yPos + 8,240,14,true,ModMenuUIHelper.COLOR_TEXT,false);
         container.addChild(sectionLabel);
         chip = ModMenuUIHelper.createHotkeyChip("Ctrl+Shift+D");
         chip.x = fullW - 10 - int(chip["chipWidth"]);
         chip.y = yPos + 9;
         container.addChild(chip);
         denLoginCheckbox = ModMenuUIHelper.createCheckbox();
         denLoginCheckbox.x = 12;
         denLoginCheckbox.y = yPos + 40;
         denLoginCheckbox["featureKey"] = "denLoginEnabled";
         container.addChild(denLoginCheckbox);
         denLabel = makeLabel("Enter den of a different username on login",58,yPos + 38,340,12,true,ModMenuUIHelper.COLOR_TEXT,false);
         container.addChild(denLabel);
         usernameLabel = makeLabel("Target username",ROW_W + COL_GAP,yPos + 40,130,11,false,ModMenuUIHelper.COLOR_TEXT_DIM,false);
         container.addChild(usernameLabel);
         inputBg = new MovieClip();
         inputBg.graphics.beginFill(1979428,1);
         inputBg.graphics.drawRoundRect(0,0,230,26,6,6);
         inputBg.graphics.endFill();
         inputBg.graphics.lineStyle(1,ModMenuUIHelper.COLOR_TEXT,0.14);
         inputBg.graphics.drawRoundRect(0,0,230,26,6,6);
         inputBg.x = ROW_W + COL_GAP + 120;
         inputBg.y = yPos + 34;
         inputBg.mouseEnabled = false;
         inputBg.mouseChildren = false;
         container.addChild(inputBg);
         denUsernameInput = new TextField();
         denUsernameInput.type = "input";
         denUsernameInput.border = false;
         denUsernameInput.background = false;
         denUsernameInput.x = inputBg.x + 6;
         denUsernameInput.y = inputBg.y + 4;
         denUsernameInput.width = 218;
         denUsernameInput.height = 20;
         denUsernameInput.maxChars = 20;
         denUsernameInput.textColor = ModMenuUIHelper.COLOR_TEXT;
         inputFmt = new TextFormat();
         inputFmt.size = 12;
         denUsernameInput.defaultTextFormat = inputFmt;
         denUsernameInput.text = "";
         denUsernameInput.restrict = "a-zA-Z0-9_";
         if(onUsernameChangedCallback != null)
         {
            denUsernameInput.addEventListener(Event.CHANGE,onUsernameChangedCallback,false,0,false);
         }
         container.addChild(denUsernameInput);
         denLoginCheckbox["isToggling"] = false;
         denLoginCheckbox["lastToggleTime"] = 0;
         denLoginCheckbox.addEventListener("mouseDown",function(e:MouseEvent):void
         {
            var clickedCheckbox:MovieClip;
            var currentTime:int;
            var lastToggleTime:int;
            var cbKey:String;
            try
            {
               e.stopPropagation();
               e.stopImmediatePropagation();
               clickedCheckbox = MovieClip(e.currentTarget);
               currentTime = getTimer();
               lastToggleTime = int(int(clickedCheckbox["lastToggleTime"]) || 0);
               if(clickedCheckbox["isToggling"] || currentTime - lastToggleTime < 150)
               {
                  return;
               }
               clickedCheckbox["isToggling"] = true;
               clickedCheckbox["lastToggleTime"] = currentTime;
               cbKey = clickedCheckbox["featureKey"];
               if(cbKey && onToggleCallback != null)
               {
                  onToggleCallback(cbKey);
               }
            }
            catch(err:Error)
            {
            }
            if(clickedCheckbox)
            {
               clickedCheckbox["isToggling"] = false;
            }
         },false,0,false);
         return {
            "checkbox":denLoginCheckbox,
            "usernameInput":denUsernameInput,
            "endYPos":yPos + sectionH
         };
      }
   }
}
