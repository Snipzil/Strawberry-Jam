package gui
{
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;

   public class ModMenuUIHelper
   {

      public static const COLOR_BG:uint = 1316120;

      public static const COLOR_PANEL_BORDER:uint = 2765884;

      public static const COLOR_BORDER:uint = 4549845;

      public static const COLOR_ACCENT:uint = 3066993;

      public static const COLOR_ACCENT_BLUE:uint = 3899126;

      public static const COLOR_ROW_EVEN:uint = 2239032;

      public static const COLOR_ROW_ODD:uint = 1710618;

      public static const COLOR_BTN_PRIMARY:uint = 3369812;

      public static const COLOR_BTN_DANGER:uint = 14369847;

      public static const COLOR_BTN_CLOSE:uint = 15966422;

      public static const COLOR_TEXT:uint = 16777215;

      public static const COLOR_TEXT_DIM:uint = 10069688;

      public static const COLOR_TEXT_FAINT:uint = 7042702;

      public static const COLOR_ACTIVE_TAB:uint = 2771583;

      public static const COLOR_INACTIVE_TAB:uint = 2763306;

      public static const COLOR_SWITCH_OFF:uint = 3816524;

      public static const COLOR_CHIP_BG:uint = 2960707;

      public static const CORNER_RADIUS:int = 12;

      public static const CORNER_RADIUS_SM:int = 6;

      public static const SWITCH_W:int = 34;

      public static const SWITCH_H:int = 18;

      public static const TAB_W:int = 150;

      public static const TAB_H:int = 30;

      public function ModMenuUIHelper()
      {
         super();
      }

      public static function createCheckbox() : MovieClip
      {
         var checkbox:MovieClip = new MovieClip();
         drawSwitch(checkbox,false);
         checkbox.buttonMode = true;
         checkbox.mouseEnabled = true;
         checkbox.mouseChildren = false;
         checkbox.tabEnabled = false;
         checkbox.tabChildren = false;
         checkbox.hitArea = null;
         return checkbox;
      }

      public static function setCheckboxState(checkbox:MovieClip, checked:Boolean) : void
      {
         if(checkbox == null)
         {
            return;
         }
         try
         {
            drawSwitch(checkbox,checked);
         }
         catch(e:Error)
         {
         }
      }

      private static function drawSwitch(mc:MovieClip, on:Boolean) : void
      {
         var w:int = SWITCH_W;
         var h:int = SWITCH_H;
         var knobX:int = on ? w - h / 2 - 2 : h / 2 + 2;
         mc.graphics.clear();
         mc.graphics.beginFill(0,0);
         mc.graphics.drawRect(-4,-6,w + 8,h + 12);
         mc.graphics.endFill();
         if(on)
         {
            mc.graphics.beginFill(COLOR_ACCENT,1);
         }
         else
         {
            mc.graphics.beginFill(COLOR_SWITCH_OFF,1);
         }
         mc.graphics.drawRoundRect(0,0,w,h,h,h);
         mc.graphics.endFill();
         if(on)
         {
            mc.graphics.beginFill(COLOR_ACCENT,0.35);
            mc.graphics.drawRoundRect(-2,-2,w + 4,h + 4,h + 4,h + 4);
            mc.graphics.endFill();
         }
         mc.graphics.beginFill(0,0.18);
         mc.graphics.drawCircle(knobX,h / 2 + 1,h / 2 - 2);
         mc.graphics.endFill();
         mc.graphics.beginFill(COLOR_TEXT,1);
         mc.graphics.drawCircle(knobX,h / 2,h / 2 - 2);
         mc.graphics.endFill();
      }

      public static function createButton(label:String, color:uint, width:int = 80, height:int = 30) : MovieClip
      {
         var btn:MovieClip = new MovieClip();
         var bgShape:Shape = new Shape();
         drawButtonBg(bgShape,color,width,height,false);
         btn.addChild(bgShape);
         var btnTxt:TextField = new TextField();
         btnTxt.text = label;
         btnTxt.textColor = COLOR_TEXT;
         var btnFormat:TextFormat = new TextFormat();
         btnFormat.size = height >= 28 ? 13 : 12;
         btnFormat.bold = true;
         btnFormat.align = "center";
         btnTxt.setTextFormat(btnFormat);
         btnTxt.x = 4;
         btnTxt.y = height >= 28 ? 7 : 3;
         btnTxt.width = width - 8;
         btnTxt.height = 20;
         btnTxt.selectable = false;
         btnTxt.mouseEnabled = false;
         btn.addChild(btnTxt);
         btn.buttonMode = true;
         btn.mouseChildren = false;
         btn.mouseEnabled = true;
         btn.addEventListener("mouseOver",function(e:MouseEvent):void
         {
            drawButtonBg(bgShape,color,width,height,true);
         },false,0,true);
         btn.addEventListener("mouseOut",function(e:MouseEvent):void
         {
            drawButtonBg(bgShape,color,width,height,false);
         },false,0,true);
         return btn;
      }

      private static function drawButtonBg(s:Shape, color:uint, width:int, height:int, hover:Boolean) : void
      {
         s.graphics.clear();
         s.graphics.beginFill(color,hover ? 1 : 0.9);
         s.graphics.drawRoundRect(0,0,width,height,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         s.graphics.endFill();
         s.graphics.beginFill(COLOR_TEXT,hover ? 0.16 : 0.08);
         s.graphics.drawRoundRect(0,0,width,height / 2,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         s.graphics.endFill();
         s.graphics.lineStyle(1,COLOR_TEXT,hover ? 0.35 : 0.15);
         s.graphics.drawRoundRect(0,0,width,height,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
      }

      public static function createPopupBackground(width:int, height:int, alpha:Number = 0.95) : MovieClip
      {
         var bg:MovieClip = new MovieClip();
         bg.graphics.beginFill(0,0.35);
         bg.graphics.drawRoundRect(-6,-4,width + 12,height + 16,CORNER_RADIUS + 6,CORNER_RADIUS + 6);
         bg.graphics.endFill();
         bg.graphics.beginFill(COLOR_BG,alpha);
         bg.graphics.drawRoundRect(0,0,width,height,CORNER_RADIUS,CORNER_RADIUS);
         bg.graphics.endFill();
         bg.graphics.lineStyle(1,COLOR_PANEL_BORDER,1);
         bg.graphics.drawRoundRect(0,0,width,height,CORNER_RADIUS,CORNER_RADIUS);
         bg.graphics.lineStyle(0,0,0);
         bg.graphics.beginFill(COLOR_ACCENT_BLUE,0.9);
         bg.graphics.drawRoundRect(width * 0.25,0,width * 0.5,3,3,3);
         bg.graphics.endFill();
         return bg;
      }

      public static function createHeaderDivider(width:int) : Shape
      {
         var s:Shape = new Shape();
         s.graphics.beginFill(COLOR_TEXT,0.08);
         s.graphics.drawRect(0,0,width,1);
         s.graphics.endFill();
         return s;
      }

      public static function createCloseXButton() : MovieClip
      {
         var xTxt:TextField;
         var xFormat:TextFormat;
         var btn:MovieClip = new MovieClip();
         var bgShape:Shape = new Shape();
         bgShape.graphics.beginFill(COLOR_BTN_DANGER,0.75);
         bgShape.graphics.drawRoundRect(0,0,28,28,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         bgShape.graphics.endFill();
         btn.addChild(bgShape);
         xTxt = new TextField();
         xTxt.text = "×";
         xTxt.textColor = COLOR_TEXT;
         xFormat = new TextFormat();
         xFormat.size = 22;
         xFormat.bold = true;
         xFormat.align = "center";
         xTxt.setTextFormat(xFormat);
         xTxt.x = 0;
         xTxt.y = -1;
         xTxt.width = 28;
         xTxt.height = 28;
         xTxt.selectable = false;
         xTxt.mouseEnabled = false;
         btn.addChild(xTxt);
         btn.buttonMode = true;
         btn.mouseChildren = false;
         btn.mouseEnabled = true;
         btn.addEventListener("mouseOver",function(e:MouseEvent):void
         {
            bgShape.graphics.clear();
            bgShape.graphics.beginFill(COLOR_BTN_DANGER,1);
            bgShape.graphics.drawRoundRect(0,0,28,28,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
            bgShape.graphics.endFill();
         },false,0,true);
         btn.addEventListener("mouseOut",function(e:MouseEvent):void
         {
            bgShape.graphics.clear();
            bgShape.graphics.beginFill(COLOR_BTN_DANGER,0.75);
            bgShape.graphics.drawRoundRect(0,0,28,28,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
            bgShape.graphics.endFill();
         },false,0,true);
         return btn;
      }

      public static function createScrollButton(label:String) : MovieClip
      {
         var btn:MovieClip = new MovieClip();
         btn.graphics.beginFill(COLOR_ROW_EVEN,0.9);
         btn.graphics.drawRoundRect(0,0,22,22,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         btn.graphics.endFill();
         btn.graphics.lineStyle(1,COLOR_TEXT,0.12);
         btn.graphics.drawRoundRect(0,0,22,22,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         var btnTxt:TextField = new TextField();
         btnTxt.text = label;
         btnTxt.textColor = COLOR_TEXT;
         var btnFormat:TextFormat = new TextFormat();
         btnFormat.size = 11;
         btnFormat.align = "center";
         btnTxt.setTextFormat(btnFormat);
         btnTxt.x = 0;
         btnTxt.y = 2;
         btnTxt.width = 22;
         btnTxt.height = 20;
         btnTxt.selectable = false;
         btnTxt.mouseEnabled = false;
         btn.addChild(btnTxt);
         btn.buttonMode = true;
         btn.mouseChildren = false;
         btn.mouseEnabled = true;
         return btn;
      }

      public static function createScrollTrack(height:int) : MovieClip
      {
         var track:MovieClip = new MovieClip();
         track.graphics.beginFill(COLOR_TEXT,0.06);
         track.graphics.drawRoundRect(0,0,8,height,8,8);
         track.graphics.endFill();
         track.mouseEnabled = true;
         track.mouseChildren = false;
         track.tabEnabled = false;
         return track;
      }

      public static function createScrollThumb() : MovieClip
      {
         var thumb:MovieClip = new MovieClip();
         drawThumb(thumb,40,false);
         thumb.buttonMode = true;
         thumb.mouseEnabled = true;
         thumb.mouseChildren = false;
         thumb.tabEnabled = false;
         thumb.addEventListener("mouseOver",function(e:MouseEvent):void
         {
            drawThumb(thumb,int(thumb["thumbHeight"]),true);
         },false,0,true);
         thumb.addEventListener("mouseOut",function(e:MouseEvent):void
         {
            drawThumb(thumb,int(thumb["thumbHeight"]),false);
         },false,0,true);
         return thumb;
      }

      public static function drawThumb(thumb:MovieClip, height:int, hover:Boolean) : void
      {
         if(height < 24)
         {
            height = 24;
         }
         thumb["thumbHeight"] = height;
         thumb.graphics.clear();
         thumb.graphics.beginFill(COLOR_ACCENT_BLUE,hover ? 1 : 0.75);
         thumb.graphics.drawRoundRect(0,0,8,height,8,8);
         thumb.graphics.endFill();
      }

      public static function createTabButton(label:String, isActive:Boolean) : MovieClip
      {
         var btn:MovieClip = new MovieClip();
         var btnTxt:TextField = new TextField();
         btnTxt.text = label;
         btnTxt.textColor = COLOR_TEXT;
         var btnFormat:TextFormat = new TextFormat();
         btnFormat.size = 13;
         btnFormat.bold = true;
         btnFormat.align = "center";
         btnTxt.setTextFormat(btnFormat);
         btnTxt.x = 0;
         btnTxt.y = 6;
         btnTxt.width = TAB_W;
         btnTxt.height = 20;
         btnTxt.selectable = false;
         btnTxt.mouseEnabled = false;
         btn.addChild(btnTxt);
         btn["labelField"] = btnTxt;
         drawTab(btn,isActive);
         btn.buttonMode = true;
         btn.mouseChildren = false;
         btn.mouseEnabled = true;
         btn["isActive"] = isActive;
         return btn;
      }

      private static function drawTab(btn:MovieClip, isActive:Boolean) : void
      {
         btn.graphics.clear();
         if(isActive)
         {
            btn.graphics.beginFill(COLOR_ACTIVE_TAB,1);
         }
         else
         {
            btn.graphics.beginFill(COLOR_INACTIVE_TAB,0.9);
         }
         btn.graphics.drawRoundRect(0,0,TAB_W,TAB_H,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         btn.graphics.endFill();
         if(isActive)
         {
            btn.graphics.beginFill(COLOR_ACCENT_BLUE,1);
            btn.graphics.drawRoundRect(14,TAB_H - 3,TAB_W - 28,2,2,2);
            btn.graphics.endFill();
         }
         btn.graphics.lineStyle(1,COLOR_TEXT,isActive ? 0.25 : 0.08);
         btn.graphics.drawRoundRect(0,0,TAB_W,TAB_H,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         var lf:TextField = btn["labelField"] as TextField;
         if(lf)
         {
            lf.textColor = isActive ? COLOR_TEXT : COLOR_TEXT_DIM;
         }
      }

      public static function updateTabButtonState(tabBtn:MovieClip, isActive:Boolean) : void
      {
         if(tabBtn == null)
         {
            return;
         }
         try
         {
            tabBtn["isActive"] = isActive;
            drawTab(tabBtn,isActive);
         }
         catch(e:Error)
         {
         }
      }

      public static function createHotkeyChip(hotkey:String) : MovieClip
      {
         var chip:MovieClip = new MovieClip();
         var txt:TextField = new TextField();
         txt.text = hotkey;
         txt.textColor = COLOR_TEXT_DIM;
         var fmt:TextFormat = new TextFormat();
         fmt.size = 9;
         fmt.bold = true;
         txt.setTextFormat(fmt);
         txt.autoSize = "left";
         txt.selectable = false;
         txt.mouseEnabled = false;
         var w:int = int(txt.textWidth) + 12;
         var h:int = 16;
         chip.graphics.beginFill(COLOR_CHIP_BG,1);
         chip.graphics.drawRoundRect(0,0,w,h,5,5);
         chip.graphics.endFill();
         chip.graphics.lineStyle(1,COLOR_TEXT,0.12);
         chip.graphics.drawRoundRect(0,0,w,h,5,5);
         txt.x = 5;
         txt.y = 0;
         chip.addChild(txt);
         chip["chipWidth"] = w;
         chip.mouseEnabled = false;
         chip.mouseChildren = false;
         return chip;
      }

      public static function createGlobeIcon(isActive:Boolean) : MovieClip
      {
         var icon:MovieClip = new MovieClip();
         updateIconState(icon,isActive,true);
         icon.buttonMode = true;
         icon.mouseEnabled = true;
         icon.mouseChildren = false;
         icon.tabEnabled = false;
         icon.hitArea = null;
         icon["isActive"] = isActive;
         icon["isGlobe"] = true;
         return icon;
      }

      public static function createUserIcon(isActive:Boolean) : MovieClip
      {
         var icon:MovieClip = new MovieClip();
         updateIconState(icon,isActive,false);
         icon.buttonMode = true;
         icon.mouseEnabled = true;
         icon.mouseChildren = false;
         icon.tabEnabled = false;
         icon.hitArea = null;
         icon["isActive"] = isActive;
         icon["isGlobe"] = false;
         return icon;
      }

      public static function updateIconState(icon:MovieClip, isActive:Boolean, isGlobe:Boolean) : void
      {
         var blueColor:uint;
         var grayColor:uint;
         var color:uint;
         var activeColor:uint;
         var inactiveColor:uint;
         var userColor:uint;
         if(icon == null)
         {
            return;
         }
         try
         {
            icon.graphics.clear();
            icon.graphics.beginFill(0,0);
            icon.graphics.drawRect(-4,-4,28,28);
            icon.graphics.endFill();
            if(isGlobe)
            {
               blueColor = 4896994;
               grayColor = 6710886;
               color = isActive ? blueColor : grayColor;
               icon.graphics.lineStyle(1.5,16777215,isActive ? 0.9 : 0.5);
               icon.graphics.beginFill(color,isActive ? 1 : 0.55);
               icon.graphics.drawCircle(10,10,8);
               icon.graphics.endFill();
               icon.graphics.lineStyle(1,16777215,isActive ? 0.55 : 0.3);
               icon.graphics.moveTo(2,10);
               icon.graphics.lineTo(18,10);
               icon.graphics.moveTo(10,2);
               icon.graphics.curveTo(15,10,10,18);
               icon.graphics.moveTo(10,2);
               icon.graphics.curveTo(5,10,10,18);
            }
            else
            {
               activeColor = 4886574;
               inactiveColor = 6710886;
               userColor = isActive ? activeColor : inactiveColor;
               icon.graphics.lineStyle(2,userColor,1);
               icon.graphics.beginFill(userColor,0.3);
               icon.graphics.drawCircle(10,8,4);
               icon.graphics.endFill();
               icon.graphics.lineStyle(2,userColor,1);
               icon.graphics.beginFill(userColor,0.3);
               icon.graphics.drawEllipse(6,12,8,6);
               icon.graphics.endFill();
            }
            icon["isActive"] = isActive;
         }
         catch(e:Error)
         {
         }
      }

      public static function drawRowBackground(bg:MovieClip, width:int, height:int, hover:Boolean) : void
      {
         bg.graphics.clear();
         bg.graphics.beginFill(COLOR_TEXT,hover ? 0.1 : 0.04);
         bg.graphics.drawRoundRect(0,0,width,height,8,8);
         bg.graphics.endFill();
         if(hover)
         {
            bg.graphics.lineStyle(1,COLOR_ACCENT_BLUE,0.6);
            bg.graphics.drawRoundRect(0,0,width,height,8,8);
         }
      }

      public static function createSearchField(width:int, height:int) : MovieClip
      {
         var box:MovieClip = new MovieClip();
         box.graphics.beginFill(1979428,1);
         box.graphics.drawRoundRect(0,0,width,height,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         box.graphics.endFill();
         box.graphics.lineStyle(1,COLOR_TEXT,0.12);
         box.graphics.drawRoundRect(0,0,width,height,CORNER_RADIUS_SM,CORNER_RADIUS_SM);
         box.graphics.lineStyle(1.5,COLOR_TEXT_DIM,0.9);
         box.graphics.drawCircle(13,height / 2 - 1,4.5);
         box.graphics.moveTo(16.5,height / 2 + 2.5);
         box.graphics.lineTo(20,height / 2 + 6);
         var input:TextField = new TextField();
         input.type = "input";
         input.x = 26;
         input.y = int((height - 18) / 2);
         input.width = width - 34;
         input.height = 18;
         input.textColor = COLOR_TEXT;
         var fmt:TextFormat = new TextFormat();
         fmt.size = 12;
         input.defaultTextFormat = fmt;
         input.maxChars = 40;
         input.tabEnabled = false;
         box.addChild(input);
         var placeholder:TextField = new TextField();
         placeholder.text = "Search mods…";
         placeholder.textColor = COLOR_TEXT_FAINT;
         var pfmt:TextFormat = new TextFormat();
         pfmt.size = 12;
         pfmt.italic = true;
         placeholder.setTextFormat(pfmt);
         placeholder.x = 28;
         placeholder.y = input.y;
         placeholder.width = width - 34;
         placeholder.height = 18;
         placeholder.selectable = false;
         placeholder.mouseEnabled = false;
         box.addChild(placeholder);
         box["input"] = input;
         box["placeholder"] = placeholder;
         box.mouseEnabled = true;
         box.mouseChildren = true;
         return box;
      }
   }
}
