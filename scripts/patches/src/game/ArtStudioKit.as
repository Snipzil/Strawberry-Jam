package game
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.FocusEvent;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;

   // Mod-added (not vanilla). Shared look for the controls the mod adds to the
   // Art Studio painters (ArtStudioPainting and ArtStudioGridDrawing): dark
   // wood panels, cream buttons with drawn icons, the same yellow "selected"
   // outline the native tool buttons use, hover tooltips and sliders.
   // Buttons and sliders are dynamic MovieClips that carry their own state.
   public class ArtStudioKit
   {

      public static const FONT:String = "TikiIsland-Regular";

      public static const PANEL_FILL:uint = 5910032;

      public static const PANEL_LINE:uint = 9197094;

      public static const BTN_TOP:uint = 16775142;

      public static const BTN_BOTTOM:uint = 15455142;

      public static const BTN_HOVER_TOP:uint = 16777215;

      public static const BTN_HOVER_BOTTOM:uint = 16180924;

      public static const BTN_LINE:uint = 7027222;

      public static const ICON:uint = 4859144;

      public static const ACTIVE:uint = 16762913;

      public static const TEXT_LIGHT:uint = 16771522;

      private static var _tip:Sprite;

      private static var _tipText:TextField;

      private static var _tipLayer:DisplayObjectContainer;

      private static var _dragSlider:MovieClip;

      private static var _dragStage:Stage;
      
      private static var _placer:MovieClip;
      
      private static var _placeStage:Stage;
      
      private static var _placeDrag:Object;

      private static var _menu:MovieClip;

      private static var _dialog:MovieClip;

      public function ArtStudioKit()
      {
         super();
      }

      public static function setTipLayer(layer:DisplayObjectContainer) : void
      {
         hideTip();
         _tipLayer = layer;
      }

      public static function panel(parent:DisplayObjectContainer, x:Number, y:Number, w:Number, h:Number) : Shape
      {
         var s:Shape = new Shape();
         var g:Graphics = s.graphics;
         g.lineStyle(2,PANEL_LINE,1,true);
         g.beginFill(PANEL_FILL,0.94);
         g.drawRoundRect(0,0,w,h,14,14);
         g.endFill();
         s.x = x;
         s.y = y;
         s.filters = [new DropShadowFilter(2,90,0,0.35,4,4,1,1)];
         parent.addChild(s);
         return s;
      }

      public static function divider(parent:DisplayObjectContainer, x:Number, y:Number, h:Number) : void
      {
         var s:Shape = new Shape();
         s.graphics.lineStyle(1,PANEL_LINE,1,true);
         s.graphics.moveTo(0,0);
         s.graphics.lineTo(0,h);
         s.x = x;
         s.y = y;
         parent.addChild(s);
      }

      public static function text(str:String, size:int, color:uint, width:Number, align:String = "left") : TextField
      {
         var tf:TextField = new TextField();
         var fmt:TextFormat = new TextFormat(FONT,size,color,true);
         fmt.align = align;
         tf.embedFonts = true;
         tf.defaultTextFormat = fmt;
         tf.selectable = false;
         tf.mouseEnabled = false;
         tf.width = width;
         tf.height = size + 8;
         tf.text = str;
         return tf;
      }

      public static function input(width:Number, restrict:String, maxChars:int) : TextField
      {
         var tf:TextField = new TextField();
         var fmt:TextFormat = new TextFormat(FONT,15,3808520,true);
         fmt.align = "center";
         tf.embedFonts = true;
         tf.defaultTextFormat = fmt;
         tf.type = TextFieldType.INPUT;
         tf.background = true;
         tf.backgroundColor = 16774364;
         tf.border = true;
         tf.borderColor = BTN_LINE;
         tf.restrict = restrict;
         tf.maxChars = maxChars;
         tf.width = width;
         tf.height = 24;
         return tf;
      }

      public static function button(icon:String, tip:String, w:int, h:int, onClick:Function, label:String = null) : MovieClip
      {
         var b:MovieClip = new MovieClip();
         var face:Shape = new Shape();
         var art:Shape = new Shape();
         var tf:TextField = null;
         b.bw = w;
         b.bh = h;
         b.tip = tip;
         b.isActive = false;
         b.isOn = true;
         b.hover = false;
         b.clickFn = onClick;
         b.addChild(face);
         b.addChild(art);
         b.face = face;
         b.art = art;
         if(icon != null)
         {
            drawIcon(art.graphics,icon,ICON);
            art.x = int((w - 20) / 2);
            art.y = int((h - 20) / 2);
         }
         if(label != null)
         {
            tf = text(label,14,ICON,w,"center");
            tf.y = int((h - tf.height) / 2) + 1;
            b.addChild(tf);
            b.labelField = tf;
         }
         b.buttonMode = true;
         b.useHandCursor = true;
         b.mouseChildren = false;
         b.addEventListener(MouseEvent.ROLL_OVER,onBtnOver);
         b.addEventListener(MouseEvent.ROLL_OUT,onBtnOut);
         b.addEventListener(MouseEvent.MOUSE_DOWN,onBtnDown);
         b.addEventListener(MouseEvent.MOUSE_UP,onBtnUp);
         b.addEventListener(MouseEvent.CLICK,onBtnClick);
         paintButton(b);
         return b;
      }

      public static function paintButton(b:MovieClip) : void
      {
         var g:Graphics = b.face.graphics;
         var w:int = int(b.bw);
         var h:int = int(b.bh);
         var m:Matrix = new Matrix();
         var hot:Boolean = Boolean(b.hover) && Boolean(b.isOn);
         m.createGradientBox(w,h,Math.PI / 2,0,0);
         g.clear();
         if(b.isActive)
         {
            g.lineStyle(3,ACTIVE,1,true);
         }
         else
         {
            g.lineStyle(1.5,BTN_LINE,1,true);
         }
         g.beginGradientFill(GradientType.LINEAR,hot ? [BTN_HOVER_TOP,BTN_HOVER_BOTTOM] : [BTN_TOP,BTN_BOTTOM],[1,1],[0,255],m);
         g.drawRoundRect(0,0,w,h,10,10);
         g.endFill();
         b.alpha = b.isOn ? 1 : 0.4;
         if(b.isActive)
         {
            b.filters = [new GlowFilter(ACTIVE,0.8,6,6,2)];
         }
         else
         {
            b.filters = [new DropShadowFilter(1,90,0,0.35,2,2,1,1)];
         }
      }

      public static function setActive(b:MovieClip, on:Boolean) : void
      {
         if(b != null && b.isActive != on)
         {
            b.isActive = on;
            paintButton(b);
         }
      }

      public static function setEnabled(b:MovieClip, on:Boolean) : void
      {
         if(b != null && b.isOn != on)
         {
            b.isOn = on;
            b.buttonMode = on;
            paintButton(b);
         }
      }

      public static function setIcon(b:MovieClip, icon:String) : void
      {
         drawIcon(b.art.graphics,icon,ICON);
      }

      public static function setLabel(b:MovieClip, label:String) : void
      {
         if(b.labelField != null)
         {
            b.labelField.text = label;
         }
      }

      private static function onBtnOver(e:MouseEvent) : void
      {
         var b:MovieClip = e.currentTarget as MovieClip;
         b.hover = true;
         paintButton(b);
         if(b.tip)
         {
            showTip(b,b.tip);
         }
      }

      private static function onBtnOut(e:MouseEvent) : void
      {
         var b:MovieClip = e.currentTarget as MovieClip;
         b.hover = false;
         b.art.y = int((b.bh - 20) / 2);
         paintButton(b);
         hideTip();
      }

      private static function onBtnDown(e:MouseEvent) : void
      {
         var b:MovieClip = e.currentTarget as MovieClip;
         if(b.isOn)
         {
            b.art.y = int((b.bh - 20) / 2) + 1;
         }
      }

      private static function onBtnUp(e:MouseEvent) : void
      {
         var b:MovieClip = e.currentTarget as MovieClip;
         b.art.y = int((b.bh - 20) / 2);
      }

      private static function onBtnClick(e:MouseEvent) : void
      {
         var b:MovieClip = e.currentTarget as MovieClip;
         e.stopPropagation();
         if(!b.isOn)
         {
            return;
         }
         AJAudio.playHudBtnClick();
         if(b.clickFn != null)
         {
            b.clickFn(e);
         }
      }

      public static function showTip(target:DisplayObject, str:String) : void
      {
         var r:Rectangle = null;
         var w:Number = NaN;
         var h:Number = NaN;
         var tx:Number = NaN;
         var ty:Number = NaN;
         if(_tipLayer == null || target.stage == null)
         {
            return;
         }
         if(_tip == null)
         {
            _tip = new Sprite();
            _tip.mouseEnabled = false;
            _tip.mouseChildren = false;
            _tipText = text("",13,TEXT_LIGHT,200,"left");
            _tipText.autoSize = TextFieldAutoSize.LEFT;
            _tipText.x = 6;
            _tipText.y = 2;
            _tip.addChild(_tipText);
         }
         _tipText.text = str;
         w = _tipText.width + 12;
         h = _tipText.height + 4;
         _tip.graphics.clear();
         _tip.graphics.lineStyle(1,PANEL_LINE,1,true);
         _tip.graphics.beginFill(3020294,0.95);
         _tip.graphics.drawRoundRect(0,0,w,h,8,8);
         _tip.graphics.endFill();
         r = target.getBounds(_tipLayer);
         tx = r.x + r.width / 2 - w / 2;
         ty = r.bottom + 5;
         if(ty + h > 548)
         {
            ty = r.y - h - 5;
         }
         tx = Math.max(2,Math.min(898 - w,tx));
         _tip.x = int(tx);
         _tip.y = int(ty);
         _tipLayer.addChild(_tip);
      }

      public static function hideTip() : void
      {
         if(_tip != null && _tip.parent != null)
         {
            _tip.parent.removeChild(_tip);
         }
      }

      // A slider with its caption and value drawn above the track.
      // Horizontal: caption left, value right. Vertical: value only, and the
      // top of the track is the maximum. curve > 1 gives finer control near
      // min (brush size). onChange(value:Number) runs while dragging.
      public static function slider(caption:String, length:int, vertical:Boolean, min:Number, max:Number, curve:Number, format:Function, onChange:Function, tip:String = null) : MovieClip
      {
         var s:MovieClip = new MovieClip();
         var track:Sprite = new Sprite();
         var fill:Shape = new Shape();
         var knob:Sprite = new Sprite();
         var m:Matrix = new Matrix();
         var cap:TextField = null;
         var val:TextField = null;
         s.len = length;
         s.vertical = vertical;
         s.min = min;
         s.max = max;
         s.curve = curve;
         s.format = format;
         s.onChange = onChange;
         s.t = 0;
         s.track = track;
         s.fill = fill;
         s.knob = knob;
         s.tip = tip;
         track.graphics.beginFill(0,0);
         if(vertical)
         {
            track.graphics.drawRect(-9,-4,18,length + 8);
         }
         else
         {
            track.graphics.drawRect(-4,-9,length + 8,18);
         }
         track.graphics.endFill();
         track.graphics.lineStyle(1,BTN_LINE,1,true);
         track.graphics.beginFill(3020294,1);
         if(vertical)
         {
            track.graphics.drawRoundRect(-3,0,6,length,6,6);
         }
         else
         {
            track.graphics.drawRoundRect(0,-3,length,6,6,6);
         }
         track.graphics.endFill();
         track.addChild(fill);
         track.buttonMode = true;
         m.createGradientBox(14,14,Math.PI / 2,-7,-7);
         knob.graphics.lineStyle(1.5,BTN_LINE,1,true);
         knob.graphics.beginGradientFill(GradientType.LINEAR,[BTN_HOVER_TOP,BTN_BOTTOM],[1,1],[0,255],m);
         knob.graphics.drawCircle(0,0,7);
         knob.graphics.endFill();
         knob.buttonMode = true;
         knob.filters = [new DropShadowFilter(1,90,0,0.4,2,2,1,1)];
         if(vertical)
         {
            val = text("",12,TEXT_LIGHT,40,"center");
            val.x = -20;
            val.y = -2;
            track.y = 20;
         }
         else
         {
            cap = text(caption,11,TEXT_LIGHT,length,"left");
            cap.x = -2;
            cap.y = -2;
            s.addChild(cap);
            val = text("",11,ACTIVE,length + 4,"right");
            val.x = 0;
            val.y = -2;
            track.y = 24;
         }
         s.addChild(val);
         s.val = val;
         s.addChild(track);
         s.addChild(knob);
         track.addEventListener(MouseEvent.MOUSE_DOWN,onSliderDown);
         knob.addEventListener(MouseEvent.MOUSE_DOWN,onSliderDown);
         if(tip != null)
         {
            track.addEventListener(MouseEvent.ROLL_OVER,onSliderOver);
            track.addEventListener(MouseEvent.ROLL_OUT,onSliderOut);
            knob.addEventListener(MouseEvent.ROLL_OVER,onSliderOver);
            knob.addEventListener(MouseEvent.ROLL_OUT,onSliderOut);
         }
         sliderSet(s,min);
         return s;
      }

      public static function sliderValue(s:MovieClip) : Number
      {
         return s.min + (s.max - s.min) * Math.pow(s.t,s.curve);
      }

      public static function sliderSet(s:MovieClip, value:Number) : void
      {
         var t:Number = (value - s.min) / (s.max - s.min);
         t = Math.max(0,Math.min(1,t));
         s.t = Math.pow(t,1 / s.curve);
         layoutSlider(s);
      }

      private static function layoutSlider(s:MovieClip) : void
      {
         var g:Graphics = s.fill.graphics;
         var len:Number = Number(s.len);
         var t:Number = Number(s.t);
         g.clear();
         g.beginFill(ACTIVE,1);
         if(s.vertical)
         {
            g.drawRoundRect(-3,len * (1 - t),6,len * t,6,6);
            s.knob.x = s.track.x;
            s.knob.y = s.track.y + len * (1 - t);
         }
         else
         {
            g.drawRoundRect(0,-3,len * t,6,6,6);
            s.knob.x = s.track.x + len * t;
            s.knob.y = s.track.y;
         }
         g.endFill();
         s.val.text = s.format != null ? s.format(sliderValue(s)) : String(Math.round(sliderValue(s)));
      }

      private static function onSliderOver(e:MouseEvent) : void
      {
         var s:MovieClip = (e.currentTarget as DisplayObject).parent as MovieClip;
         if(s != null && s.tip)
         {
            showTip(s,s.tip);
         }
      }

      private static function onSliderOut(e:MouseEvent) : void
      {
         hideTip();
      }

      private static function onSliderDown(e:MouseEvent) : void
      {
         var target:DisplayObject = e.currentTarget as DisplayObject;
         e.stopPropagation();
         stopSliderDrag();
         _dragSlider = target.parent as MovieClip;
         _dragStage = target.stage;
         if(_dragSlider == null || _dragStage == null)
         {
            return;
         }
         _dragStage.addEventListener(MouseEvent.MOUSE_MOVE,onSliderMove);
         _dragStage.addEventListener(MouseEvent.MOUSE_UP,onSliderUp);
         onSliderMove(e);
      }

      private static function onSliderMove(e:MouseEvent) : void
      {
         var s:MovieClip = _dragSlider;
         var p:Point = null;
         var t:Number = NaN;
         if(s == null)
         {
            return;
         }
         p = s.track.globalToLocal(new Point(e.stageX,e.stageY));
         if(s.vertical)
         {
            t = 1 - p.y / s.len;
         }
         else
         {
            t = p.x / s.len;
         }
         s.t = Math.max(0,Math.min(1,t));
         layoutSlider(s);
         if(s.onChange != null)
         {
            s.onChange(sliderValue(s));
         }
         e.updateAfterEvent();
      }

      private static function onSliderUp(e:MouseEvent) : void
      {
         stopSliderDrag();
      }

      public static function stopSliderDrag() : void
      {
         if(_dragStage != null)
         {
            _dragStage.removeEventListener(MouseEvent.MOUSE_MOVE,onSliderMove);
            _dragStage.removeEventListener(MouseEvent.MOUSE_UP,onSliderUp);
         }
         _dragStage = null;
         _dragSlider = null;
      }

      // The current colour as a swatch, hex and RGB, in a 244x36 panel.
      // content is the native interface timeline (red/green/blue,
      // rgbColors, currentPalette). Typing a value recolours the selected
      // palette slot the way the native picker does, so the palette, cursor
      // tint and colour history stay in step. Call syncColorPanel every frame.
      public static function colorPanel(parent:DisplayObjectContainer, x:Number, y:Number, content:Object) : MovieClip
      {
         var p:MovieClip = new MovieClip();
         var sw:Shape = new Shape();
         panel(p,0,0,244,36);
         sw.x = 8;
         sw.y = 6;
         p.addChild(sw);
         p.swatch = sw;
         p.content = content;
         p.last = -1;
         p.hex = colorField(p,38,6,70,"#0-9A-Fa-f",7,3808520,"Hex colour, then Enter");
         p.r = colorField(p,112,6,38,"0-9",3,12592656,"Red (0-255)");
         p.g = colorField(p,154,6,38,"0-9",3,1673520,"Green (0-255)");
         p.b = colorField(p,196,6,38,"0-9",3,1534888,"Blue (0-255)");
         p.x = x;
         p.y = y;
         parent.addChild(p);
         return p;
      }

      private static function colorField(p:MovieClip, x:Number, y:Number, w:Number, restrict:String, maxChars:int, color:uint, tip:String) : TextField
      {
         var tf:TextField = input(w,restrict,maxChars);
         var fmt:TextFormat = tf.defaultTextFormat;
         fmt.color = color;
         tf.defaultTextFormat = fmt;
         tf.x = x;
         tf.y = y;
         tf.name = tip;
         tf.addEventListener(KeyboardEvent.KEY_DOWN,onFieldKey);
         tf.addEventListener(FocusEvent.FOCUS_OUT,onFieldCommit);
         tf.addEventListener(Event.CHANGE,onFieldChange);
         tf.addEventListener(MouseEvent.ROLL_OVER,onFieldOver);
         tf.addEventListener(MouseEvent.ROLL_OUT,onFieldOut);
         p.addChild(tf);
         return tf;
      }

      private static function onFieldOver(e:MouseEvent) : void
      {
         var tf:TextField = e.currentTarget as TextField;
         showTip(tf,tf.name);
      }

      private static function onFieldOut(e:MouseEvent) : void
      {
         hideTip();
      }

      private static function onFieldKey(e:KeyboardEvent) : void
      {
         var tf:TextField = e.currentTarget as TextField;
         if(e.keyCode == 13 && tf.stage != null)
         {
            tf.stage.focus = null;
         }
      }

      private static function onFieldCommit(e:FocusEvent) : void
      {
         var tf:TextField = e.currentTarget as TextField;
         var p:MovieClip = tf.parent as MovieClip;
         var rgb:int = readFields(p,tf == p.hex);
         if(rgb >= 0)
         {
            applyColor(p.content,rgb);
         }
         p.last = -1;
      }

      // Live preview while typing: keeps hex and RGB in step and tints the
      // swatch, without touching the palette until Enter or focus leaves.
      private static function onFieldChange(e:Event) : void
      {
         var tf:TextField = e.currentTarget as TextField;
         var p:MovieClip = tf.parent as MovieClip;
         var fromHex:Boolean = tf == p.hex;
         var rgb:int = readFields(p,fromHex);
         if(rgb < 0)
         {
            return;
         }
         if(fromHex)
         {
            p.r.text = String(rgb >> 16 & 0xFF);
            p.g.text = String(rgb >> 8 & 0xFF);
            p.b.text = String(rgb & 0xFF);
         }
         else
         {
            p.hex.text = "#" + hex6(rgb);
         }
         drawSwatch(p.swatch,rgb);
      }

      private static function readFields(p:MovieClip, fromHex:Boolean) : int
      {
         var s:String = null;
         var r:int = 0;
         var g:int = 0;
         var b:int = 0;
         if(fromHex)
         {
            s = String(p.hex.text).replace(/#/g,"");
            if(s.length == 3)
            {
               s = s.charAt(0) + s.charAt(0) + s.charAt(1) + s.charAt(1) + s.charAt(2) + s.charAt(2);
            }
            if(s.length != 6)
            {
               return -1;
            }
            return int(parseInt(s,16));
         }
         if(p.r.text == "" || p.g.text == "" || p.b.text == "")
         {
            return -1;
         }
         r = Math.max(0,Math.min(255,int(p.r.text)));
         g = Math.max(0,Math.min(255,int(p.g.text)));
         b = Math.max(0,Math.min(255,int(p.b.text)));
         return r << 16 | g << 8 | b;
      }

      public static function hex6(rgb:int) : String
      {
         var s:String = rgb.toString(16).toUpperCase();
         while(s.length < 6)
         {
            s = "0" + s;
         }
         return s;
      }

      private static function drawSwatch(sw:Shape, rgb:int) : void
      {
         sw.graphics.clear();
         sw.graphics.lineStyle(2,BTN_LINE,1,true);
         sw.graphics.beginFill(rgb);
         sw.graphics.drawRoundRect(0,0,24,24,8,8);
         sw.graphics.endFill();
      }

      // Sets the drawing colour through the selected palette slot, exactly as
      // the native colour picker does.
      public static function applyColor(c:Object, rgb:int) : void
      {
         var r:int = rgb >> 16 & 0xFF;
         var g:int = rgb >> 8 & 0xFF;
         var b:int = rgb & 0xFF;
         var slot:int = int(c.currentPalette);
         if(slot >= 1 && slot <= 8)
         {
            c.rgbColors[slot - 1] = [r,g,b];
            c.colorizeButton(slot);
            c.newColor(c["_" + slot].colorIndex,c["_" + slot].transform.colorTransform);
         }
         else
         {
            c.red = r;
            c.green = g;
            c.blue = b;
         }
      }

      public static function currentColor(c:Object) : int
      {
         return (int(c.red) & 0xFF) << 16 | (int(c.green) & 0xFF) << 8 | int(c.blue) & 0xFF;
      }

      public static function syncColorPanel(p:MovieClip) : void
      {
         var rgb:int = currentColor(p.content);
         var f:Object = p.stage != null ? p.stage.focus : null;
         if(rgb == p.last || f == p.hex || f == p.r || f == p.g || f == p.b)
         {
            return;
         }
         p.last = rgb;
         p.hex.text = "#" + hex6(rgb);
         p.r.text = String(rgb >> 16 & 0xFF);
         p.g.text = String(rgb >> 8 & 0xFF);
         p.b.text = String(rgb & 0xFF);
         drawSwatch(p.swatch,rgb);
      }

      // Lets the user move and resize an imported image before it is painted
      // in. host is the drawing canvas (canvas-pixel coordinates, may be
      // zoomed, panned and masked): the image is shown inside it, so it is
      // clipped like the painting, while the frame and corner handles sit in
      // an unclipped layer above it that follows its transform, so they can
      // be grabbed even when the image overhangs the canvas. The image starts
      // fitted inside areaW x areaH. Drag it to move; drag a corner to resize
      // (aspect kept, Shift for free). A bar of Fit / Fill / 1:1 / Place /
      // Cancel buttons is centred on barCenterX at barY in barParent.
      // onDone(matrix:Matrix) receives the image-to-canvas transform, or null
      // when cancelled. Enter places, Escape cancels. One at a time.
      public static function beginPlace(host:Sprite, src:BitmapData, areaW:int, areaH:int, barParent:DisplayObjectContainer, barCenterX:Number, barY:Number, onDone:Function) : MovieClip
      {
         var p:MovieClip = new MovieClip();
         var bmp:Bitmap = new Bitmap(src,"auto",true);
         var frame:Shape = new Shape();
         var hit:Sprite = new Sprite();
         var bar:MovieClip = new MovieClip();
         var handle:MovieClip = null;
         var x:int = 6;
         var i:int = 0;
         cancelPlace();
         p.src = src;
         p.host = host;
         p.areaW = areaW;
         p.areaH = areaH;
         p.onDone = onDone;
         p.bmp = bmp;
         p.frame = frame;
         p.hit = hit;
         p.handles = [];
         p.lastScale = -1;
         host.addChild(bmp);
         hit.buttonMode = true;
         hit.addEventListener(MouseEvent.MOUSE_DOWN,onPlaceBodyDown);
         p.addChild(hit);
         p.addChild(frame);
         i = 0;
         while(i < 4)
         {
            handle = new MovieClip();
            handle.corner = i;
            handle.buttonMode = true;
            handle.addEventListener(MouseEvent.MOUSE_DOWN,onPlaceHandleDown);
            p.addChild(handle);
            p.handles.push(handle);
            i++;
         }
         host.parent.addChild(p);
         x = addBarButton(bar,x,"FIT","Fit inside the canvas",42,onPlaceFit);
         x = addBarButton(bar,x,"FILL","Cover the whole canvas",44,onPlaceFill);
         x = addBarButton(bar,x,"1:1","Original size",36,onPlaceOriginal);
         x += 8;
         x = addBarButton(bar,x,"PLACE","Paint it in (Enter)",58,onPlaceApply);
         x = addBarButton(bar,x,"CANCEL","Cancel (Esc)",64,onPlaceCancel);
         bar.setChildIndex(panel(bar,0,0,x + 2,36),0);
         bar.x = int(barCenterX - (x + 2) / 2);
         bar.y = barY;
         barParent.addChild(bar);
         p.bar = bar;
         _placer = p;
         _placeStage = host.stage;
         if(_placeStage != null)
         {
            _placeStage.addEventListener(KeyboardEvent.KEY_DOWN,onPlaceKey);
         }
         p.addEventListener(Event.ENTER_FRAME,onPlaceFrame);
         placeFit(p,false,0.8);
         return p;
      }

      public static function isPlacing() : Boolean
      {
         return _placer != null;
      }

      public static function cancelPlace() : void
      {
         if(_placer != null)
         {
            finishPlace(false);
         }
      }

      private static function addBarButton(bar:MovieClip, x:int, label:String, tip:String, w:int, fn:Function) : int
      {
         var b:MovieClip = button(null,tip,w,26,fn,label);
         b.x = x;
         b.y = 5;
         bar.addChild(b);
         return x + w + 4;
      }

      // cover=false fits inside the area, true covers it; centred. The first
      // placement uses shrink 0.8 so every handle starts inside the canvas.
      private static function placeFit(p:MovieClip, cover:Boolean, shrink:Number = 1) : void
      {
         var sw:Number = Number(p.src.width);
         var sh:Number = Number(p.src.height);
         var s:Number = (cover ? Math.max(p.areaW / sw,p.areaH / sh) : Math.min(p.areaW / sw,p.areaH / sh)) * shrink;
         setPlaceRect(p,(p.areaW - sw * s) / 2,(p.areaH - sh * s) / 2,sw * s,sh * s);
      }

      private static function setPlaceRect(p:MovieClip, x:Number, y:Number, w:Number, h:Number) : void
      {
         p.rx = x;
         p.ry = y;
         p.rw = Math.max(4,w);
         p.rh = Math.max(4,h);
         p.bmp.x = p.rx;
         p.bmp.y = p.ry;
         p.bmp.width = p.rw;
         p.bmp.height = p.rh;
         p.lastScale = -1;
         onPlaceFrame(null,p);
      }

      // Follows the host's zoom/pan and redraws the frame and handles at a
      // constant on-screen size.
      private static function onPlaceFrame(e:Event, target:MovieClip = null) : void
      {
         var p:MovieClip = target != null ? target : (e.currentTarget as MovieClip);
         var host:Sprite = p.host;
         var s:Number = Math.abs(host.scaleX);
         var hs:Number = 14 / s;
         var g:Graphics = null;
         var corners:Array = null;
         var i:int = 0;
         var handle:MovieClip = null;
         p.x = host.x;
         p.y = host.y;
         p.scaleX = host.scaleX;
         p.scaleY = host.scaleY;
         if(s == p.lastScale && e != null)
         {
            return;
         }
         p.lastScale = s;
         g = p.hit.graphics;
         g.clear();
         g.beginFill(0,0);
         g.drawRect(p.rx,p.ry,p.rw,p.rh);
         g.endFill();
         g = p.frame.graphics;
         g.clear();
         g.lineStyle(3 / s,0,0.6);
         g.drawRect(p.rx,p.ry,p.rw,p.rh);
         g.lineStyle(1.5 / s,ACTIVE,1);
         g.drawRect(p.rx,p.ry,p.rw,p.rh);
         corners = [[p.rx,p.ry],[p.rx + p.rw,p.ry],[p.rx + p.rw,p.ry + p.rh],[p.rx,p.ry + p.rh]];
         i = 0;
         while(i < 4)
         {
            handle = p.handles[i];
            handle.graphics.clear();
            handle.graphics.lineStyle(2 / s,BTN_LINE,1);
            handle.graphics.beginFill(ACTIVE);
            handle.graphics.drawRect(-hs / 2,-hs / 2,hs,hs);
            handle.graphics.endFill();
            handle.x = corners[i][0];
            handle.y = corners[i][1];
            i++;
         }
      }

      private static function onPlaceBodyDown(e:MouseEvent) : void
      {
         startPlaceDrag(e,-1);
      }

      private static function onPlaceHandleDown(e:MouseEvent) : void
      {
         startPlaceDrag(e,int((e.currentTarget as MovieClip).corner));
      }

      private static function startPlaceDrag(e:MouseEvent, corner:int) : void
      {
         var p:MovieClip = _placer;
         e.stopPropagation();
         if(p == null || _placeStage == null)
         {
            return;
         }
         _placeDrag = {
            "corner":corner,
            "mx":p.mouseX,
            "my":p.mouseY,
            "x":p.rx,
            "y":p.ry,
            "w":p.rw,
            "h":p.rh
         };
         _placeStage.addEventListener(MouseEvent.MOUSE_MOVE,onPlaceMove);
         _placeStage.addEventListener(MouseEvent.MOUSE_UP,onPlaceUp);
      }

      private static function onPlaceMove(e:MouseEvent) : void
      {
         var p:MovieClip = _placer;
         var d:Object = _placeDrag;
         var ax:Number = NaN;
         var ay:Number = NaN;
         var w:Number = NaN;
         var h:Number = NaN;
         var s:Number = NaN;
         if(p == null || d == null)
         {
            return;
         }
         if(d.corner < 0)
         {
            setPlaceRect(p,d.x + p.mouseX - d.mx,d.y + p.mouseY - d.my,d.w,d.h);
         }
         else
         {
            ax = d.corner == 1 || d.corner == 2 ? Number(d.x) : d.x + d.w;
            ay = d.corner == 2 || d.corner == 3 ? Number(d.y) : d.y + d.h;
            w = Math.abs(p.mouseX - ax);
            h = Math.abs(p.mouseY - ay);
            if(!e.shiftKey)
            {
               s = Math.max(w / p.src.width,h / p.src.height);
               w = p.src.width * s;
               h = p.src.height * s;
            }
            w = Math.max(4,w);
            h = Math.max(4,h);
            setPlaceRect(p,p.mouseX < ax ? ax - w : ax,p.mouseY < ay ? ay - h : ay,w,h);
         }
         e.updateAfterEvent();
      }

      private static function onPlaceUp(e:MouseEvent) : void
      {
         stopPlaceDrag();
      }

      private static function stopPlaceDrag() : void
      {
         if(_placeStage != null)
         {
            _placeStage.removeEventListener(MouseEvent.MOUSE_MOVE,onPlaceMove);
            _placeStage.removeEventListener(MouseEvent.MOUSE_UP,onPlaceUp);
         }
         _placeDrag = null;
      }

      private static function onPlaceKey(e:KeyboardEvent) : void
      {
         if(_placer == null || (_placeStage != null && _placeStage.focus is TextField))
         {
            return;
         }
         if(e.keyCode == 13)
         {
            finishPlace(true);
         }
         else if(e.keyCode == 27)
         {
            finishPlace(false);
         }
      }

      private static function onPlaceFit(e:MouseEvent) : void
      {
         placeFit(_placer,false);
      }

      private static function onPlaceFill(e:MouseEvent) : void
      {
         placeFit(_placer,true);
      }

      private static function onPlaceOriginal(e:MouseEvent) : void
      {
         var p:MovieClip = _placer;
         setPlaceRect(p,(p.areaW - p.src.width) / 2,(p.areaH - p.src.height) / 2,p.src.width,p.src.height);
      }

      private static function onPlaceApply(e:MouseEvent) : void
      {
         finishPlace(true);
      }

      private static function onPlaceCancel(e:MouseEvent) : void
      {
         finishPlace(false);
      }

      private static function finishPlace(apply:Boolean) : void
      {
         var p:MovieClip = _placer;
         var m:Matrix = null;
         if(p == null)
         {
            return;
         }
         stopPlaceDrag();
         _placer = null;
         if(_placeStage != null)
         {
            _placeStage.removeEventListener(KeyboardEvent.KEY_DOWN,onPlaceKey);
         }
         _placeStage = null;
         p.removeEventListener(Event.ENTER_FRAME,onPlaceFrame);
         if(p.bmp.parent != null)
         {
            p.bmp.parent.removeChild(p.bmp);
         }
         if(p.parent != null)
         {
            p.parent.removeChild(p);
         }
         if(p.bar.parent != null)
         {
            p.bar.parent.removeChild(p.bar);
         }
         hideTip();
         if(apply)
         {
            m = new Matrix(p.rw / p.src.width,0,0,p.rh / p.src.height,p.rx,p.ry);
         }
         p.onDone(m);
      }

      // Drop-down menu, right-aligned to rightX. columns is an array of
      // columns, each an array of entries: {id, label} or {header}. checked(id)
      // ticks an entry; disabled(id) greys it out. onPick(id) runs after the
      // menu closes. A click outside it (other than on owner, whose own click
      // toggles it) or Escape closes it.
      public static function openMenu(parent:DisplayObjectContainer, rightX:Number, topY:Number, columns:Array, onPick:Function, checked:Function, disabled:Function, owner:DisplayObject) : MovieClip
      {
         var m:MovieClip = new MovieClip();
         var colW:int = 178;
         var maxH:int = 0;
         var c:int = 0;
         var i:int = 0;
         var y:int = 0;
         var e:Object = null;
         var row:MovieClip = null;
         var tf:TextField = null;
         var tick:Shape = null;
         closeMenu();
         m.onPick = onPick;
         m.owner = owner;
         while(c < columns.length)
         {
            y = 8;
            i = 0;
            while(i < columns[c].length)
            {
               e = columns[c][i];
               if(e.header != null)
               {
                  tf = text(e.header,11,ACTIVE,colW - 16,"left");
                  tf.x = 8 + c * colW + 8;
                  tf.y = y + (i == 0 ? 0 : 4);
                  m.addChild(tf);
                  y += i == 0 ? 18 : 22;
               }
               else
               {
                  row = new MovieClip();
                  row.menuId = e.id;
                  row.isOn = disabled == null || !disabled(e.id);
                  row.rw = colW - 8;
                  row.x = 8 + c * colW - 4;
                  row.y = y;
                  row.graphics.beginFill(0,0);
                  row.graphics.drawRect(0,0,row.rw,20);
                  row.graphics.endFill();
                  tf = text(e.label,13,row.isOn ? TEXT_LIGHT : 9206612,colW - 30,"left");
                  tf.x = 20;
                  tf.y = 0;
                  row.addChild(tf);
                  if(checked != null && checked(e.id))
                  {
                     tick = new Shape();
                     tick.graphics.lineStyle(2.5,ACTIVE,1,true,"normal","round","round");
                     tick.graphics.moveTo(5,10);
                     tick.graphics.lineTo(9,14);
                     tick.graphics.lineTo(15,5);
                     row.addChild(tick);
                  }
                  row.mouseChildren = false;
                  if(row.isOn)
                  {
                     row.buttonMode = true;
                     row.addEventListener(MouseEvent.ROLL_OVER,onMenuRowOver);
                     row.addEventListener(MouseEvent.ROLL_OUT,onMenuRowOut);
                     row.addEventListener(MouseEvent.CLICK,onMenuRowClick);
                  }
                  m.addChild(row);
                  y += 20;
               }
               i++;
            }
            maxH = Math.max(maxH,y);
            c++;
         }
         m.setChildIndex(panel(m,0,0,columns.length * colW + 8,maxH + 8),0);
         m.x = int(rightX - (columns.length * colW + 8));
         m.y = int(topY);
         parent.addChild(m);
         _menu = m;
         if(m.stage != null)
         {
            m.stage.addEventListener(MouseEvent.MOUSE_DOWN,onMenuStageDown,true);
            m.stage.addEventListener(KeyboardEvent.KEY_DOWN,onMenuKey);
         }
         return m;
      }

      public static function isMenuOpen() : Boolean
      {
         return _menu != null;
      }

      public static function closeMenu() : void
      {
         var m:MovieClip = _menu;
         if(m == null)
         {
            return;
         }
         _menu = null;
         if(m.stage != null)
         {
            m.stage.removeEventListener(MouseEvent.MOUSE_DOWN,onMenuStageDown,true);
            m.stage.removeEventListener(KeyboardEvent.KEY_DOWN,onMenuKey);
         }
         if(m.parent != null)
         {
            m.parent.removeChild(m);
         }
      }

      private static function onMenuStageDown(e:MouseEvent) : void
      {
         var t:DisplayObject = e.target as DisplayObject;
         var owner:DisplayObject = _menu != null ? _menu.owner : null;
         if(_menu == null || t == null || _menu.contains(t))
         {
            return;
         }
         if(owner != null && (t == owner || owner is DisplayObjectContainer && (owner as DisplayObjectContainer).contains(t)))
         {
            return;
         }
         closeMenu();
      }

      private static function onMenuKey(e:KeyboardEvent) : void
      {
         if(e.keyCode == 27)
         {
            closeMenu();
         }
      }

      private static function onMenuRowOver(e:MouseEvent) : void
      {
         var row:MovieClip = e.currentTarget as MovieClip;
         row.graphics.clear();
         row.graphics.beginFill(PANEL_LINE,0.9);
         row.graphics.drawRoundRect(0,0,row.rw,20,8,8);
         row.graphics.endFill();
      }

      private static function onMenuRowOut(e:MouseEvent) : void
      {
         var row:MovieClip = e.currentTarget as MovieClip;
         row.graphics.clear();
         row.graphics.beginFill(0,0);
         row.graphics.drawRect(0,0,row.rw,20);
         row.graphics.endFill();
      }

      private static function onMenuRowClick(e:MouseEvent) : void
      {
         var row:MovieClip = e.currentTarget as MovieClip;
         var pick:Function = _menu != null ? _menu.onPick : null;
         e.stopPropagation();
         AJAudio.playHudBtnClick();
         closeMenu();
         if(pick != null)
         {
            pick(row.menuId);
         }
      }

      // A small dialog of sliders, each {id, label, min, max, value} with an
      // optional fmt(value):String. onChange(values) runs live while
      // dragging (values maps id to value); onClose(ok) runs on OK / Enter or
      // Cancel / Escape. One at a time.
      public static function openDialog(parent:DisplayObjectContainer, centerX:Number, centerY:Number, title:String, sliders:Array, onChange:Function, onClose:Function) : MovieClip
      {
         var d:MovieClip = new MovieClip();
         var w:int = 260;
         var y:int = 0;
         var i:int = 0;
         var tf:TextField = null;
         var sl:MovieClip = null;
         var okBtn:MovieClip = null;
         var cancelBtn:MovieClip = null;
         closeDialog(false);
         d.onChange = onChange;
         d.onClose = onClose;
         d.sliders = [];
         tf = text(title,15,ACTIVE,w - 20,"left");
         tf.x = 12;
         tf.y = 8;
         d.addChild(tf);
         y = 36;
         while(i < sliders.length)
         {
            sl = slider(String(sliders[i].label).toUpperCase(),w - 40,false,sliders[i].min,sliders[i].max,1,sliders[i].fmt != null ? sliders[i].fmt : formatNumber,onDialogSlider);
            sl.dialogId = sliders[i].id;
            sl.x = 20;
            sl.y = y;
            sliderSet(sl,sliders[i].value);
            d.addChild(sl);
            d.sliders.push(sl);
            y += 44;
            i++;
         }
         okBtn = button(null,"Apply (Enter)",70,26,onDialogOk,"OK");
         okBtn.x = w - 160;
         okBtn.y = y + 4;
         d.addChild(okBtn);
         cancelBtn = button(null,"Cancel (Esc)",76,26,onDialogCancel,"CANCEL");
         cancelBtn.x = w - 86;
         cancelBtn.y = y + 4;
         d.addChild(cancelBtn);
         d.setChildIndex(panel(d,0,0,w,y + 40),0);
         d.x = int(centerX - w / 2);
         d.y = int(centerY - (y + 40) / 2);
         parent.addChild(d);
         _dialog = d;
         if(d.stage != null)
         {
            d.stage.addEventListener(KeyboardEvent.KEY_DOWN,onDialogKey);
         }
         return d;
      }

      public static function isDialogOpen() : Boolean
      {
         return _dialog != null;
      }

      public static function closeDialog(ok:Boolean) : void
      {
         var d:MovieClip = _dialog;
         if(d == null)
         {
            return;
         }
         _dialog = null;
         stopSliderDrag();
         hideTip();
         if(d.stage != null)
         {
            d.stage.removeEventListener(KeyboardEvent.KEY_DOWN,onDialogKey);
         }
         if(d.parent != null)
         {
            d.parent.removeChild(d);
         }
         if(d.onClose != null)
         {
            d.onClose(ok);
         }
      }

      public static function formatNumber(v:Number) : String
      {
         return String(Math.round(v));
      }

      public static function formatSigned(v:Number) : String
      {
         var n:int = Math.round(v);
         return n > 0 ? "+" + n : String(n);
      }

      private static function onDialogSlider(v:Number) : void
      {
         var d:MovieClip = _dialog;
         var values:Object = {};
         var i:int = 0;
         if(d == null)
         {
            return;
         }
         while(i < d.sliders.length)
         {
            values[d.sliders[i].dialogId] = sliderValue(d.sliders[i]);
            i++;
         }
         if(d.onChange != null)
         {
            d.onChange(values);
         }
      }

      private static function onDialogOk(e:MouseEvent) : void
      {
         closeDialog(true);
      }

      private static function onDialogCancel(e:MouseEvent) : void
      {
         closeDialog(false);
      }

      private static function onDialogKey(e:KeyboardEvent) : void
      {
         if(e.keyCode == 13)
         {
            closeDialog(true);
         }
         else if(e.keyCode == 27)
         {
            closeDialog(false);
         }
      }

      // Icons are drawn in a 20x20 box.
      public static function drawIcon(g:Graphics, name:String, c:uint) : void
      {
         var i:int = 0;
         var m2:Matrix = null;
         g.clear();
         switch(name)
         {
            case "undo":
               g.lineStyle(2.5,c,1,true,"normal","round","round");
               g.moveTo(16,16);
               g.curveTo(17,6,8,6);
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(2,6);
               g.lineTo(9,1);
               g.lineTo(9,11);
               g.lineTo(2,6);
               g.endFill();
               break;
            case "redo":
               g.lineStyle(2.5,c,1,true,"normal","round","round");
               g.moveTo(4,16);
               g.curveTo(3,6,12,6);
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(18,6);
               g.lineTo(11,1);
               g.lineTo(11,11);
               g.lineTo(18,6);
               g.endFill();
               break;
            case "import":
               drawTray(g,c);
               g.lineStyle(2.5,c,1,true,"normal","none");
               g.moveTo(10,1);
               g.lineTo(10,9);
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(5,8);
               g.lineTo(15,8);
               g.lineTo(10,14);
               g.lineTo(5,8);
               g.endFill();
               break;
            case "export":
               drawTray(g,c);
               g.lineStyle(2.5,c,1,true,"normal","none");
               g.moveTo(10,14);
               g.lineTo(10,6);
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(5,7);
               g.lineTo(15,7);
               g.lineTo(10,1);
               g.lineTo(5,7);
               g.endFill();
               break;
            case "pen":
               g.lineStyle(1.5,c,1,true);
               g.beginFill(2939864);
               g.moveTo(13,2);
               g.lineTo(18,7);
               g.lineTo(8,17);
               g.lineTo(3,12);
               g.lineTo(13,2);
               g.endFill();
               g.beginFill(c);
               g.moveTo(3,12);
               g.lineTo(8,17);
               g.lineTo(1,19);
               g.lineTo(3,12);
               g.endFill();
               break;
            case "eraser":
               g.lineStyle(1.5,c,1,true);
               g.beginFill(15896488);
               g.moveTo(11,2);
               g.lineTo(18,9);
               g.lineTo(12,15);
               g.lineTo(5,8);
               g.lineTo(11,2);
               g.endFill();
               g.beginFill(16777215);
               g.moveTo(5,8);
               g.lineTo(12,15);
               g.lineTo(9,18);
               g.lineTo(2,11);
               g.lineTo(5,8);
               g.endFill();
               break;
            case "blur":
               g.lineStyle();
               g.beginFill(c,0.18);
               g.drawCircle(10,10,9);
               g.endFill();
               g.beginFill(c,0.38);
               g.drawCircle(10,10,6.5);
               g.endFill();
               g.beginFill(c,0.9);
               g.drawCircle(10,10,3.5);
               g.endFill();
               break;
            case "picker":
               g.lineStyle();
               g.beginFill(c);
               g.drawCircle(15,5,4);
               g.endFill();
               g.lineStyle(3.5,c,1,true,"normal","none");
               g.moveTo(14,6);
               g.lineTo(6,14);
               g.lineStyle(1.5,c,1,true,"normal","round");
               g.moveTo(6,14);
               g.lineTo(2,18);
               break;
            case "gradient":
               m2 = new Matrix();
               m2.createGradientBox(16,16,0,2,2);
               g.lineStyle(1.5,c,1,true);
               g.beginGradientFill(GradientType.LINEAR,[c,c],[1,0],[0,255],m2);
               g.drawRoundRect(2,3,16,14,4,4);
               g.endFill();
               break;
            case "menu":
               g.lineStyle(2.5,c,1,true,"normal","round");
               g.moveTo(4,5);
               g.lineTo(16,5);
               g.moveTo(4,10);
               g.lineTo(16,10);
               g.moveTo(4,15);
               g.lineTo(16,15);
               break;
            case "hand":
               g.lineStyle(1.5,c,1,true,"normal","round","round");
               g.beginFill(16771522);
               g.drawRoundRect(4.5,1.5,3,11,3,3);
               g.drawRoundRect(7.5,0.5,3,12,3,3);
               g.drawRoundRect(10.5,1,3,11.5,3,3);
               g.drawRoundRect(13.5,3,3,9.5,3,3);
               g.endFill();
               g.lineStyle();
               g.beginFill(16771522);
               g.moveTo(4.5,8);
               g.lineTo(2,7);
               g.curveTo(0.5,7.5,1.5,9.5);
               g.lineTo(5,15);
               g.curveTo(7,19,11,19);
               g.curveTo(16.5,19,16.5,13);
               g.lineTo(16.5,8);
               g.lineTo(4.5,8);
               g.endFill();
               g.lineStyle(1.5,c,1,true,"normal","round","round");
               g.moveTo(4.5,10);
               g.lineTo(2,7);
               g.curveTo(0.5,7.5,1.5,9.5);
               g.lineTo(5,15);
               g.curveTo(7,19,11,19);
               g.curveTo(16.5,19,16.5,13);
               g.lineTo(16.5,10);
               break;
            case "eye":
            case "eyeOff":
               g.lineStyle(2,c,1,true);
               g.moveTo(1,10);
               g.curveTo(10,1,19,10);
               g.curveTo(10,19,1,10);
               g.lineStyle();
               g.beginFill(c);
               g.drawCircle(10,10,3);
               g.endFill();
               if(name == "eyeOff")
               {
                  g.lineStyle(2.5,12593182,1,true,"normal","round");
                  g.moveTo(3,17);
                  g.lineTo(17,3);
               }
               break;
            case "up":
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(10,2);
               g.lineTo(18,11);
               g.lineTo(13,11);
               g.lineTo(13,18);
               g.lineTo(7,18);
               g.lineTo(7,11);
               g.lineTo(2,11);
               g.lineTo(10,2);
               g.endFill();
               break;
            case "down":
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(10,18);
               g.lineTo(18,9);
               g.lineTo(13,9);
               g.lineTo(13,2);
               g.lineTo(7,2);
               g.lineTo(7,9);
               g.lineTo(2,9);
               g.lineTo(10,18);
               g.endFill();
               break;
            case "merge":
               g.lineStyle(1.5,c,1,true);
               g.beginFill(16777215,0.7);
               g.drawRect(4,1,12,6);
               g.endFill();
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(6,8);
               g.lineTo(14,8);
               g.lineTo(10,13);
               g.lineTo(6,8);
               g.drawRect(2,15,16,3);
               g.endFill();
               break;
            case "zoomIn":
            case "zoomOut":
               g.lineStyle(2,c,1,true);
               g.drawCircle(8,8,6);
               g.lineStyle(3.5,c,1,true,"normal","round");
               g.moveTo(12.5,12.5);
               g.lineTo(17.5,17.5);
               g.lineStyle(2,c,1,true,"normal","none");
               g.moveTo(5,8);
               g.lineTo(11,8);
               if(name == "zoomIn")
               {
                  g.moveTo(8,5);
                  g.lineTo(8,11);
               }
               break;
            case "grid":
               g.lineStyle(1.5,c,1,true);
               g.drawRect(2,2,16,16);
               g.moveTo(7.3,2);
               g.lineTo(7.3,18);
               g.moveTo(12.7,2);
               g.lineTo(12.7,18);
               g.moveTo(2,7.3);
               g.lineTo(18,7.3);
               g.moveTo(2,12.7);
               g.lineTo(18,12.7);
               break;
            case "mirror":
               g.lineStyle(1.5,c,1,true,"normal","none");
               i = 1;
               while(i < 19)
               {
                  g.moveTo(10,i);
                  g.lineTo(10,i + 2);
                  i += 4;
               }
               g.lineStyle();
               g.beginFill(c);
               g.moveTo(8,5);
               g.lineTo(8,15);
               g.lineTo(2,10);
               g.lineTo(8,5);
               g.endFill();
               g.beginFill(c,0.4);
               g.moveTo(12,5);
               g.lineTo(12,15);
               g.lineTo(18,10);
               g.lineTo(12,5);
               g.endFill();
         }
      }

      private static function drawTray(g:Graphics, c:uint) : void
      {
         g.lineStyle(2,c,1,true,"normal","round","round");
         g.moveTo(3,12);
         g.lineTo(3,18);
         g.lineTo(17,18);
         g.lineTo(17,12);
      }
   }
}
