package gui
{
   import avatar.AvatarEditorView;
   import com.sbi.graphics.PaletteHelper;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;

   public class ColorTable extends MovieClip
   {

      private static const HEX_ROW_HEIGHT:int = 24;

      private static const EXPANDED_COLS:int = 20;

      private static var _pending:Array = [];

      private var _bm:Bitmap;

      private var _bmd:BitmapData;

      private var _id:int;

      private var _currColor:int;

      private var _currColorSwatch:Sprite;

      private var _secretColorIdx:int;

      private var _colorValues:Array;

      private var _colorIndexes:Array;

      private var _width:int;

      private var _height:int;

      private var _gridHeight:int;

      private var _numRows:int;

      private var _numCols:int;

      private var _cellWidth:Number;

      private var _cellHeight:Number;

      private var _expanded:Boolean;

      private var _hexInput:TextField;

      private var _hexStatus:TextField;

      private var _colorChangeCallback:Function;

      public function ColorTable()
      {
         super();
      }

      private static function compareSwatches(param1:Object, param2:Object) : int
      {
         if(param1.g != param2.g)
         {
            return param1.g < param2.g ? -1 : 1;
         }
         if(param1.h != param2.h)
         {
            return param1.h < param2.h ? -1 : 1;
         }
         if(param1.v != param2.v)
         {
            return param1.v < param2.v ? -1 : 1;
         }
         return 0;
      }

      private static function allPaletteIndexes(param1:Array) : Array
      {
         var _loc2_:Array = [];
         var _loc3_:Object = {};
         var _loc4_:int = 0;
         var _loc5_:uint = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:Number = NaN;
         var _loc12_:Array = [];
         while(_loc4_ < param1.length && _loc4_ < 256)
         {
            _loc5_ = uint(param1[_loc4_]) & 0xFFFFFF;
            if(_loc3_[_loc5_] == null)
            {
               _loc3_[_loc5_] = true;
               _loc6_ = _loc5_ >> 16 & 0xFF;
               _loc7_ = _loc5_ >> 8 & 0xFF;
               _loc8_ = _loc5_ & 0xFF;
               _loc9_ = Math.max(_loc6_,_loc7_,_loc8_);
               _loc10_ = Math.min(_loc6_,_loc7_,_loc8_);
               _loc11_ = 0;
               if(_loc9_ != _loc10_)
               {
                  if(_loc9_ == _loc6_)
                  {
                     _loc11_ = ((_loc7_ - _loc8_) / (_loc9_ - _loc10_) + 6) % 6;
                  }
                  else if(_loc9_ == _loc7_)
                  {
                     _loc11_ = (_loc8_ - _loc6_) / (_loc9_ - _loc10_) + 2;
                  }
                  else
                  {
                     _loc11_ = (_loc6_ - _loc7_) / (_loc9_ - _loc10_) + 4;
                  }
               }
               _loc2_.push({
                  "i":_loc4_,
                  "g":(_loc9_ - _loc10_ < 24 ? 0 : 1),
                  "h":(_loc9_ - _loc10_ < 24 ? 0 : Math.floor(_loc11_ * 4)),
                  "v":_loc6_ + _loc7_ + _loc8_
               });
            }
            _loc4_++;
         }
         _loc2_.sort(compareSwatches);
         _loc4_ = 0;
         while(_loc4_ < _loc2_.length)
         {
            _loc12_.push(_loc2_[_loc4_].i);
            _loc4_++;
         }
         return _loc12_;
      }

      private static function onCustomRegistered(param1:uint, param2:Array) : void
      {
         var _loc3_:String = param2.join(",");
         var _loc4_:int = 0;
         var _loc5_:Object = null;
         while(_loc4_ < _pending.length)
         {
            _loc5_ = _pending[_loc4_];
            if(_loc5_.key == _loc3_)
            {
               _pending.splice(_loc4_,1);
               ColorTable(_loc5_.table).applyCustom(int(_loc5_.u),param1);
            }
            else
            {
               _loc4_++;
            }
         }
      }

      public function init(param1:int, param2:int, param3:int, param4:int, param5:int, param6:Array, param7:Array, param8:int, param9:Function, param10:int = -1) : void
      {
         _id = param1;
         _width = param2;
         _height = param3;
         _gridHeight = param3;
         _colorValues = param6;
         _colorIndexes = param7;
         _numCols = param4;
         _numRows = param5;
         _colorChangeCallback = param9;
         _secretColorIdx = param10;
         _expanded = param6 != null && param6 == PaletteHelper.gamePalette && (param7 == PaletteHelper.avatarPalette1 || param7 == PaletteHelper.avatarPalette2);
         if(_expanded)
         {
            _colorIndexes = allPaletteIndexes(param6);
            _numCols = EXPANDED_COLS;
            _numRows = Math.ceil(_colorIndexes.length / EXPANDED_COLS);
            _gridHeight = _height - HEX_ROW_HEIGHT;
            _secretColorIdx = -1;
         }
         _cellWidth = _width / _numCols;
         _cellHeight = _gridHeight / _numRows;
         _bmd = new BitmapData(_width,_gridHeight,false,0);
         fillColorTable();
         _currColor = param8;
         setCurrentColorSwatch(_currColor);
         // the hex colour row only on a Burrow server: its "xcc" is unknown
         // to Animal Jam's (ModMenuFeatures.onBurrowServer)
         if(_expanded && ModMenuFeatures.onBurrowServer())
         {
            buildHexRow();
            showHex(_currColor);
         }
         addEventListener("mouseDown",colorTableClickHandler,false,0,true);
      }

      public function destroy() : void
      {
         if(_bm)
         {
            this.removeChild(_bm);
            _bm = null;
         }
         if(_bmd)
         {
            _bmd = null;
         }
         _colorIndexes = null;
         _colorValues = null;
         _colorChangeCallback = null;
         removeEventListener("mouseDown",colorTableClickHandler);
      }

      private function fillColorTable() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         while(_loc1_ < _colorIndexes.length)
         {
            _loc2_ = _loc1_ % _numCols * _cellWidth;
            _loc3_ = Math.floor(_loc1_ / _numCols) * _cellHeight;
            _bmd.fillRect(new Rectangle(Math.round(_loc2_),Math.round(_loc3_),Math.ceil(_cellWidth),Math.ceil(_cellHeight)),uint(_colorValues[_colorIndexes[_loc1_]]) & 0xFFFFFF);
            _loc1_++;
         }
         _bm = new Bitmap(_bmd);
         this.addChild(_bm);
      }

      private function setCurrentColorSwatch(param1:int) : void
      {
         var _loc2_:int = -1;
         var _loc3_:int = 0;
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:int = _expanded ? 2 : 5;
         while(_loc3_ < _colorIndexes.length)
         {
            if(_colorIndexes[_loc3_] == param1)
            {
               _loc2_ = _loc3_;
               break;
            }
            _loc3_++;
         }
         if(_currColorSwatch)
         {
            this.removeChild(_currColorSwatch);
            _currColorSwatch = null;
         }
         if(_loc2_ >= 0)
         {
            _loc4_ = Math.round(_loc2_ % _numCols * _cellWidth);
            _loc5_ = Math.round(Math.floor(_loc2_ / _numCols) * _cellHeight);
            _currColorSwatch = new Sprite();
            _currColorSwatch.mouseEnabled = false;
            _currColorSwatch.graphics.beginFill(0);
            _currColorSwatch.graphics.drawRect(_loc4_,_loc5_,_cellWidth,_loc6_);
            _currColorSwatch.graphics.drawRect(_loc4_,_loc5_ + _cellHeight - _loc6_,_cellWidth,_loc6_);
            _currColorSwatch.graphics.drawRect(_loc4_,_loc5_,_loc6_,_cellHeight);
            _currColorSwatch.graphics.drawRect(_loc4_ + _cellWidth - _loc6_,_loc5_,_loc6_,_cellHeight);
            _currColorSwatch.graphics.endFill();
            this.addChild(_currColorSwatch);
         }
      }

      private function buildHexRow() : void
      {
         var _loc1_:Sprite = new Sprite();
         var _loc2_:TextField = new TextField();
         var _loc3_:TextFormat = new TextFormat("_sans",11,16777215,true);
         _hexInput = new TextField();
         _hexInput.defaultTextFormat = new TextFormat("_sans",12,2302234);
         _hexInput.type = "input";
         _hexInput.border = true;
         _hexInput.borderColor = 10066329;
         _hexInput.background = true;
         _hexInput.backgroundColor = 16777215;
         _hexInput.restrict = "0-9a-fA-F#";
         _hexInput.maxChars = 7;
         _hexInput.x = 0;
         _hexInput.y = _gridHeight + 3;
         _hexInput.width = 66;
         _hexInput.height = 19;
         _hexInput.addEventListener("keyDown",onHexKey);
         _hexInput.addEventListener("keyUp",onHexKeyUp);
         addChild(_hexInput);
         _loc1_.graphics.beginFill(3112271);
         _loc1_.graphics.drawRoundRect(0,0,40,19,6,6);
         _loc1_.graphics.endFill();
         _loc3_.align = "center";
         _loc2_.defaultTextFormat = _loc3_;
         _loc2_.selectable = false;
         _loc2_.mouseEnabled = false;
         _loc2_.width = 40;
         _loc2_.height = 18;
         _loc2_.text = "Set";
         _loc1_.addChild(_loc2_);
         _loc1_.x = 70;
         _loc1_.y = _gridHeight + 3;
         _loc1_.buttonMode = true;
         _loc1_.mouseChildren = false;
         _loc1_.addEventListener("click",onHexSetClick);
         addChild(_loc1_);
         _hexStatus = new TextField();
         _hexStatus.defaultTextFormat = new TextFormat("_sans",10,5592405);
         _hexStatus.selectable = false;
         _hexStatus.mouseEnabled = false;
         _hexStatus.x = 114;
         _hexStatus.y = _gridHeight + 5;
         _hexStatus.width = _width - 114;
         _hexStatus.height = 18;
         _hexStatus.text = "any colour, e.g. #FF8800";
         addChild(_hexStatus);
      }

      private function showHex(param1:int) : void
      {
         var _loc2_:String = null;
         if(_hexInput == null || param1 < 0 || param1 >= _colorValues.length)
         {
            return;
         }
         _loc2_ = (uint(_colorValues[param1]) & 0xFFFFFF).toString(16).toUpperCase();
         while(_loc2_.length < 6)
         {
            _loc2_ = "0" + _loc2_;
         }
         _hexInput.text = "#" + _loc2_;
      }

      private function onHexKey(param1:KeyboardEvent) : void
      {
         param1.stopPropagation();
         if(param1.keyCode == 13)
         {
            applyHex();
         }
      }

      private function onHexKeyUp(param1:KeyboardEvent) : void
      {
         param1.stopPropagation();
      }

      private function onHexSetClick(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         applyHex();
      }

      private function applyHex() : void
      {
         var _loc1_:String = _hexInput.text.split("#").join("");
         if(_loc1_.length != 6)
         {
            _hexStatus.text = "use 6 hex digits";
            return;
         }
         applyRgb(uint(parseInt(_loc1_,16)) & 0xFFFFFF);
      }

      private function colorSlot() : int
      {
         return _id == 0 || _id == 1 ? 0 : (_id == 2 ? 2 : 1);
      }

      private function findView() : AvatarEditorView
      {
         var _loc1_:DisplayObjectContainer = parent;
         var _loc2_:DisplayObjectContainer = null;
         var _loc3_:int = 0;
         var _loc4_:AvatarEditorView = null;
         while(_loc1_ != null)
         {
            _loc2_ = _loc1_.getChildByName("charBox") as DisplayObjectContainer;
            if(_loc2_ != null)
            {
               _loc3_ = 0;
               while(_loc3_ < _loc2_.numChildren)
               {
                  _loc4_ = _loc2_.getChildAt(_loc3_) as AvatarEditorView;
                  if(_loc4_ != null)
                  {
                     return _loc4_;
                  }
                  _loc3_++;
               }
            }
            _loc1_ = _loc1_.parent;
         }
         return null;
      }

      private function applyRgb(param1:uint) : void
      {
         var _loc2_:AvatarEditorView = findView();
         var _loc3_:Array = null;
         if(_loc2_ == null || _loc2_.colors == null)
         {
            if(_hexStatus != null)
            {
               _hexStatus.text = "not available here";
            }
            return;
         }
         _loc3_ = PaletteHelper.resolve(uint(_loc2_.colors[colorSlot()]));
         _loc3_[_id == 1 ? 1 : 0] = param1;
         _pending.push({
            "key":_loc3_.join(","),
            "table":this,
            "u":colorSlot()
         });
         PaletteHelper.onCustomRegistered = onCustomRegistered;
         if(_hexStatus != null)
         {
            _hexStatus.text = "setting...";
         }
         gMainFrame.server.setXtObject_Str("xcc",_loc3_);
      }

      public function applyCustom(param1:int, param2:uint) : void
      {
         var _loc3_:AvatarEditorView = findView();
         var _loc4_:Array = null;
         if(_loc3_ == null || _loc3_.colors == null)
         {
            return;
         }
         _loc4_ = _loc3_.colors.concat();
         _loc4_[param1] = param2;
         _loc3_.colors = _loc4_;
         _currColor = -1;
         setCurrentColorSwatch(-1);
         if(_hexStatus != null)
         {
            _hexStatus.text = "set";
         }
      }

      private function colorTableClickHandler(param1:MouseEvent) : void
      {
         var _loc2_:Number = mouseX;
         var _loc3_:Number = mouseY;
         var _loc4_:int = -1;
         var _loc5_:int = 0;
         var _loc6_:AvatarEditorView = null;
         if(_loc3_ < 0 || _loc3_ >= _gridHeight || _loc2_ < 0)
         {
            return;
         }
         if(_loc2_ >= _width)
         {
            if(_secretColorIdx == -1 || _loc3_ < _cellHeight * (_numRows - 1))
            {
               _loc2_ = _width - 1;
            }
            else
            {
               _loc4_ = _secretColorIdx;
            }
         }
         if(_loc4_ < 0)
         {
            _loc5_ = Math.floor(_loc2_ / _cellWidth) + Math.floor(_loc3_ / _cellHeight) * _numCols;
            if(_loc5_ < 0 || _loc5_ >= _colorIndexes.length)
            {
               return;
            }
            _loc4_ = int(_colorIndexes[_loc5_]);
         }
         if(_expanded)
         {
            showHex(_loc4_);
            _loc6_ = findView();
            if(_loc6_ != null && _loc6_.colors != null && PaletteHelper.isCustom(uint(_loc6_.colors[colorSlot()])))
            {
               _currColor = _loc4_;
               applyRgb(uint(_colorValues[_loc4_]) & 0xFFFFFF);
               return;
            }
         }
         if(_currColor != _loc4_)
         {
            _currColor = _loc4_;
            setCurrentColorSwatch(_loc4_);
            if(_colorChangeCallback != null)
            {
               _colorChangeCallback(_id,_loc4_);
            }
         }
      }
   }
}
