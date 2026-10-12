package game.artStudioPainting
{
   import collection.DenItemCollection;
   import com.adobe.images.PNGEncoder;
   import com.sbi.analytics.SBTracker;
   import com.sbi.debug.DebugUtility;
   import com.sbi.graphics.JPEGAsyncCompleteEvent;
   import com.sbi.graphics.JpegAsynchEncoder;
   import com.sbi.popup.SBOkPopup;
   import com.sbi.popup.SBYesNoPopup;
   import currency.UserCurrency;
   import den.DenItem;
   import den.DenXtCommManager;
   import diamond.DiamondXtCommManager;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.BlendMode;
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.Loader;
   import flash.display.LoaderInfo;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.SpreadMethod;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.HTTPStatusEvent;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.events.ProgressEvent;
   import flash.filters.BlurFilter;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.media.SoundChannel;
   import flash.net.FileFilter;
   import flash.net.FileReference;
   import flash.net.SharedObject;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLRequestHeader;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.ui.Keyboard;
   import flash.ui.Mouse;
   import flash.ui.MouseCursor;
   import flash.utils.ByteArray;
   import flash.utils.getTimer;
   import game.GameBase;
   import game.IMinigame;
   import game.MinigameManager;
   import gui.DarkenManager;
   import gui.GenericListGuiManager;
   import gui.GuiManager;
   import gui.GuiSoundButton;
   import gui.ItemReceivedPopup;
   import gui.LoadingSpiral;
   import gui.MasterpiecePreview;
   import gui.RecycleItems;
   import gui.SubmissionRulesPopup;
   import item.ItemXtCommManager;
   import loader.MediaHelper;
   import localization.LocalizationManager;
   import shop.ShopManager;
   import flash.events.FocusEvent;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import game.ArtStudioKit;
   import flash.display.BitmapDataChannel;
   import flash.filters.ColorMatrixFilter;
   import flash.filters.ConvolutionFilter;
   import gui.QuantityInputPopup;
   
   public class ArtStudioPainting extends GameBase implements IMinigame
   {
      
      private static const TYPE_ARTSTUDIO:int = 14;
      
      private static const TYPE_ARTSTUDIO_MASTERPIECE:int = 20;
      
      private static const POPUP_X:int = 450;
      
      private static const POPUP_Y:int = 275;
      
      private static const ORIGIN:Point = new Point(0,0);
      
      private static const CHOOSE_MASTERPIECE_POPUP_ID:int = 4811;
      
      private static const ITEMS_PER_SCREEN:int = 4;
      
      private static var _blurMasks:Object = {};

      private static const NUM_LAYERS:int = 7;
      
      private static const MAX_UNDO:int = 40;
      
      private static const PAN_MARGIN:int = 60;
      
      private var _overCanvas:Boolean;
      
      private var _placingSrc:BitmapData;

      private var _layerBlends:Array = ["normal","normal","normal","normal","normal","normal","normal"];

      private var _layerLocks:Array = [false,false,false,false,false,false,false];

      private var _menuBtn:MovieClip;

      private var _viewFlipped:Boolean;

      private var _fillShapes:Boolean;

      private var _smoothing:Number = 0;

      private var _smX:Number = 0;

      private var _smY:Number = 0;

      private var _gradShape:Shape = new Shape();

      private var _sizeRing:Shape = new Shape();

      private var _sizeRingRadius:Number = -1;

      private var _adjustBase:BitmapData;

      private var _adjustKind:String;
      
      private var _spaceHeld:Boolean;
      
      private static const TOKEN_TIMEOUT_MS:int = 20000;

      private static const COPY_GAP_MS:int = 1200;
      
      private static const UPLOAD_TIMEOUT_MS:int = 60000;
      
      private var _undoBtn:MovieClip;
      
      private var _redoBtn:MovieClip;
      
      private var _importBtn:MovieClip;
      
      private var _exportBtn:MovieClip;
      
      private var _colorPanel:MovieClip;
      
      private var _toolBtns:Object;
      
      private var _modTool:int;
      
      private var _toolBeforePick:int = 1;
      
      private var _sizeSlider:MovieClip;
      
      private var _opacitySlider:MovieClip;
      
      private var _softSlider:MovieClip;
      
      private var _zoomInBtn:MovieClip;
      
      private var _zoomOutBtn:MovieClip;
      
      private var _zoomLabelBtn:MovieClip;
      
      private var _layerChips:Array;
      
      private var _layerThumbs:Array;
      
      private var _thumbChecker:BitmapData;
      
      private var _eyeBtn:MovieClip;
      
      private var _upBtn:MovieClip;
      
      private var _downBtn:MovieClip;
      
      private var _mergeBtn:MovieClip;
      
      private var _layerOpacitySlider:MovieClip;
      
      private var _canvasW:int;
      
      private var _canvasH:int;
      
      private var _canvasMask:Shape;
      
      private var _copyPopup:QuantityInputPopup;

      private var _copyFreeSlots:int = 1;

      private var _copiesWanted:int = 1;

      private var _copiesDone:int;

      private var _copiesNote:String = "";

      private var _copyBanner:Sprite;

      private var _copyBannerStamp:int;

      private var _submitPending:Boolean;
      
      private var _submitTimer:uint;
      
      private var _uploadLoader:URLLoader;
            
      private var _pencilShape:Shape;
      
      private var _prevFrameRate:Number;
      
      private const FRAME_SELECT_FILTER_DARKER:GlowFilter = new GlowFilter(3047612,1,5,5,15);
      
      private const FRAME_SELECT_FILTER_LIGHTER:GlowFilter = new GlowFilter(3648190,1,7,7,15);
      
      private const FRAME_SELECT_FILTER_MOUSE_OVER:GlowFilter = new GlowFilter(16777215,1,10,10,15);
      
      private const TOOL_BLUR:int = 9;
      
      private const TOOL_EYEDROP:int = 10;
      
      private var _myId:uint;
      
      private var _pIDs:Array;
      
      private var _dbIDs:Array;
      
      private const TOOL_ERASER:int = 11;
      
      private var _sceneLoaded:Boolean;
      
      private var _bInit:Boolean;
      
      private var _exitConfirmationActive:Boolean;
      
      private var _interfaceObject:Object;
      
      private const TOOL_PEN:int = 12;
      
      private const TOOL_HAND:int = 13;

      private const TOOL_GRADIENT:int = 14;

      private static const SMOOTHING:Array = [0,0.55,0.8];
      
      private var _brush:Object;
      
      private var _layerBackground:Sprite;
      
      private var _layerInterface:Sprite;
      
      private var _layerMouse:Sprite;
      
      private var _submitButton:MovieClip;
      
      private var _clearAllButton:MovieClip;
      
      private var _printBtn:MovieClip;
      
      private var _masterpieceSubmitBtn:MovieClip;
      
      private var _storageButton:MovieClip;
      
      private var _brushOpacity:Number = 1;
      
      private var _jpgEncoder:JpegAsynchEncoder;
      
      private var _selectBackground:Object;
      
      private var _drawBitmapUndoSnapShot:BitmapData;
      
      private var _lastPenX:Number;
      
      private var _lastPenY:Number;
      
      private var _drawBitmapUndo:Bitmap;
      
      private var _defaultBitmapData:BitmapData;
      
      private const MIN_SIZE:int = 1;
      
      private const MAX_SIZE:int = 300;
      
      private var _brushSizeVal:int = 10;
      
      private var _drawBitmapDataSnapShot:BitmapData;
      
      private var _drawBitmapSnapShot:Bitmap;
      
      private var _drawBitmapData:BitmapData;
      
      private var _encodingBitmapData:BitmapData;
      
      private var _layerBitmapDatas:Array;
      
      private var _layerBitmaps:Array;
      
      private var _activeLayerIndex:int = 0;
      
      private var _layersContainer:Sprite;
      
      private var _drawBitmap:Bitmap;
      
      private var _drawGraphics:Sprite;
      
      private var _drawCanvas:Sprite;
      
      private var _drawSize:Number;
      
      private var _activeBrush:Object;
      
      private var _drawing:Boolean;
      
      private var _drawStartX:Number;
      
      private var _drawStartY:Number;
      
      private var _currentTool:int;
      
      private var _drawBitmapDataRect:Rectangle;
      
      private var _drawPoint_0_0:Point;
      
      private var _undoable:Boolean;
      
      private var _undoStack:Array = [];
      
      private var _redoStack:Array = [];
      
      private var _airbrushes:Array;
      
      private var _drawSizes:Array;
      
      private var _printBackground:Object;
      
      private var _smudges:Array;
      
      private var _activeSmudge:Object;
      
      private var _hasDrawn:Boolean;
      
      private var _needsSave:Boolean;
      
      private var _frameTime:Number;
      
      private var _lastTime:Number;
      
      private var _uploadFileRef:FileReference;
      
      private var _timeSinceErase:Number;
      
      private var _pencilMoved:Boolean = false;
      
      private var _sharedObject:SharedObject;
      
      private var _musicLoop:SoundChannel;
      
      private var _keepAliveTimer:Number;
      
      private var _mediaHelper:MediaHelper;
      
      private var _chooseMasterpiecePopup:MovieClip;
      
      private var _masterpiecePreviewIconIds:Array;
      
      private var _masterpiecePreviewIcons:Array;
      
      private var _masterpiecePreviewIconIdsOrdered:Array;
      
      private var _iconMediaHelpers:Array;
      
      private var _masterpiecePreviewPopup:MasterpiecePreview;
      
      private var _masterpiecePreviewIconStrIds:Array;
      
      private var _currPreviewIndex:int;
      
      private var _currItemVersion:int;
      
      private var _denPreviewInvId:int;
      
      private var _airbrushCache:Object = {};
      
      private var _smudgeCache:Object = {};
      
      private var _recyclePopup:RecycleItems;
      
      private var _submissionRules:SubmissionRulesPopup;
      
      private var _itemReceivedPopup:ItemReceivedPopup;
      
      private var _isMasterpieceSubmit:Boolean;
      
      private var _exitAfterSave:Boolean;
      
      private var _itemOffset:int;
      
      private var _URLStatus:int;
      
      private var _mediaLoader:MediaHelper;
      
      private var _mediaObject:MovieClip;
      
      private var _numMasterpieceTokens:int;
      
      private var _isUsingTokens:Boolean;
      
      private var _masterPieceSubmissionToken:String;
      
      private var _brushHardness:Number = 1;
      
      private var _masterpieceUuid:String;
      
      private var _fileRef:FileReference;
      
      private var _zoomLevel:Number = 1;
      
      private var _minZoom:Number = 0.25;
      
      private var _maxZoom:Number = 4;
      
      private var _zoomStep:Number = 0.25;
      
      private var _isPanning:Boolean = false;
      
      private var _panStartX:Number;
      
      private var _panStartY:Number;
      
      private var _canvasOriginalX:Number;
      
      private var _canvasOriginalY:Number;
      
      private var _layerOpacities:Array = [1,1,1,1,1,1,1];
      
      public function ArtStudioPainting()
      {
         super();
      }
      
      private static function px(n:Number) : int
      {
         return int(n + 0.5);
      }
      
      public function start(param1:uint, param2:Array) : void
      {
         _myId = param1;
         _pIDs = param2;
         DarkenManager.checkParentForPosition = false;
         init();
      }
      
      public function end(param1:Array) : void
      {
         var k:int = 0;
         stopSubmitWatchdog();
         _submitPending = false;
         _copiesWanted = 1;
         _copiesDone = 0;
         if(_copyPopup != null)
         {
            _copyPopup.destroy();
            _copyPopup = null;
         }
         ArtStudioKit.cancelPlace();
         ArtStudioKit.closeMenu();
         ArtStudioKit.closeDialog(false);
         ArtStudioKit.stopSliderDrag();
         ArtStudioKit.setTipLayer(null);
         if(_sharedObject != null && _interfaceObject != null && _interfaceObject.loader != null && _interfaceObject.loader.content != null)
         {
            _sharedObject.data.userColors = _interfaceObject.loader.content.saveColors();
            try
            {
               _sharedObject.flush();
            }
            catch(e:Error)
            {
            }
         }
         DarkenManager.checkParentForPosition = true;
         if(_chooseMasterpiecePopup != null)
         {
            try
            {
               DarkenManager.unDarken(_chooseMasterpiecePopup);
            }
            catch(e:Error)
            {
            }
         }
         Mouse.cursor = MouseCursor.AUTO;
         Mouse.show();
         try
         {
            releaseBase();
         }
         catch(e:Error)
         {
            trace("[ArtStudioPainting] end: ERROR in releaseBase() - " + e.message);
         }
         if(_musicLoop)
         {
            _musicLoop.stop();
            _musicLoop = null;
         }
         if(_jpgEncoder != null)
         {
            try
            {
               _jpgEncoder.removeEventListener("JPEGAsyncComplete",asyncEncodingComplete);
               _jpgEncoder.removeEventListener("progress",onEncodingProgress);
            }
            catch(e:Error)
            {
            }
            _jpgEncoder = null;
         }
         _chooseMasterpiecePopup = null;
         if(stage)
         {
            stage.removeEventListener("enterFrame",heartbeat);
            stage.removeEventListener("mouseMove",moveMouse);
            stage.removeEventListener("mouseUp",endDraw);
            stage.removeEventListener("keyDown",onKeyDown);
            stage.removeEventListener("keyUp",onKeyUp);
            stage.removeEventListener(MouseEvent.MOUSE_MOVE,updatePan);
            stage.removeEventListener(MouseEvent.MOUSE_UP,endPan);
            stage.removeEventListener("mouseWheel",onMouseWheel);
         }
         if(_prevFrameRate && stage)
         {
            stage.frameRate = _prevFrameRate;
         }
         if(_drawCanvas)
         {
            _drawCanvas.removeEventListener("mouseDown",startDraw);
            _drawCanvas.removeEventListener("mouseOver",drawCanvasMouseOver);
            _drawCanvas.removeEventListener("mouseOut",drawCanvasMouseOut);
         }
         clearRedo();
         while(_undoStack.length > 0)
         {
            disposeState(_undoStack.pop());
         }
         if(_layerThumbs != null)
         {
            k = 0;
            while(k < _layerThumbs.length)
            {
               (_layerThumbs[k] as BitmapData).dispose();
               k++;
            }
            _layerThumbs = null;
         }
         if(_thumbChecker != null)
         {
            _thumbChecker.dispose();
            _thumbChecker = null;
         }
         _bInit = false;
         try
         {
            removeLayer(_layerBackground);
            removeLayer(_layerInterface);
            removeLayer(_layerMouse);
            removeLayer(_guiLayer);
            if(_layerBitmapDatas != null)
            {
               k = 0;
               while(k < _layerBitmapDatas.length)
               {
                  (_layerBitmapDatas[k] as BitmapData).dispose();
                  k++;
               }
            }
            _drawBitmapUndoSnapShot.dispose();
            _drawBitmapUndo = null;
            _defaultBitmapData.dispose();
            _drawBitmapDataSnapShot.dispose();
            _drawBitmapSnapShot = null;
            _layerBackground = null;
            _layerInterface = null;
            _layerMouse = null;
            _guiLayer = null;
         }
         catch(e:Error)
         {
            trace("[ArtStudioPainting] end: ERROR during cleanup - " + e.message);
         }
         try
         {
            MinigameManager.leave();
         }
         catch(e:Error)
         {
            trace("[ArtStudioPainting] end: ERROR calling MinigameManager.leave() - " + e.message);
            throw e;
         }
      }
      
      private function onMediaLoaded(param1:MovieClip) : void
      {
         _mediaObject = param1;
      }
      
      private function getCompositeColor(x:int, y:int) : uint
      {
         var sampler:BitmapData = new BitmapData(1,1,true,0);
         var m:Matrix = new Matrix(1,0,0,1,-x,-y);
         var i:int = 0;
         while(i < _layerBitmaps.length)
         {
            var bmp:Bitmap = _layerBitmaps[i] as Bitmap;
            if(!(!bmp || !bmp.visible))
            {
               sampler.draw(bmp,m,null,null,null,true);
            }
            i++;
         }
         var col:uint = sampler.getPixel32(0,0);
         sampler.dispose();
         return col;
      }
      
      private function init() : void
      {
         var _loc7_:Array;
         var _loc10_:Matrix;
         _undoStack = [];
         _redoStack = [];
         var _loc9_:int = 0;
         var _loc1_:Shape = null;
         var _loc11_:BitmapData = null;
         var _loc8_:* = undefined;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc5_:* = 0;
         var _loc6_:* = 0;
         var _loc12_:Shape = null;
         var _loc4_:Matrix = null;
         _mediaLoader = new MediaHelper();
         _mediaLoader.init(5556,onMediaLoaded);
         try
         {
            _sharedObject = SharedObject.getLocal(gMainFrame.userInfo.myUserName);
            if(_sharedObject.data.userSubmits == null)
            {
               _sharedObject.data.userSubmits = [];
               _sharedObject.flush();
            }
         }
         catch(e:Error)
         {
            _sharedObject = null;
         }
         _lastTime = getTimer();
         _frameTime = 0;
         _timeSinceErase = 0;
         _keepAliveTimer = 0;
         _drawGraphics = new Sprite();
         _drawSizes = new Array(2,5,10,20,35,50);
         _loc7_ = new Array(3,4,5,6,7,8);
         _airbrushes = [];
         _smudges = [];
         _masterpiecePreviewIconIds = [];
         _masterpiecePreviewIcons = [];
         _iconMediaHelpers = [];
         _masterpiecePreviewIconStrIds = [];
         _loc10_ = new Matrix();
         _loc9_ = 0;
         while(_loc9_ < _drawSizes.length)
         {
            _smudges[_loc9_] = {};
            _smudges[_loc9_].radius = _loc7_[_loc9_];
            _smudges[_loc9_].weightVector = new Vector.<Number>(_smudges[_loc9_].radius * 2 * _smudges[_loc9_].radius * 2,true);
            _loc1_ = new Shape();
            _loc11_ = new BitmapData(_smudges[_loc9_].radius * 2,_smudges[_loc9_].radius * 2,true,0);
            _loc10_.createGradientBox(_smudges[_loc9_].radius * 2,_smudges[_loc9_].radius * 2,0,0,0);
            _loc1_.graphics.beginGradientFill("radial",[16777215,16777215],[0.75,0],[0,255],_loc10_,"pad");
            _loc1_.graphics.drawCircle(_smudges[_loc9_].radius,_smudges[_loc9_].radius,_smudges[_loc9_].radius);
            _loc11_.draw(_loc1_);
            _loc8_ = _loc11_.getVector(new Rectangle(0,0,_smudges[_loc9_].radius * 2,_smudges[_loc9_].radius * 2));
            _loc2_ = 0;
            while(_loc2_ < _smudges[_loc9_].radius * 2)
            {
               _loc3_ = 0;
               while(_loc3_ < _smudges[_loc9_].radius * 2)
               {
                  _loc5_ = _loc8_[_loc2_ * _smudges[_loc9_].radius * 2 + _loc3_];
                  _loc6_ = _loc5_ >> 24 & 0xFF;
                  _smudges[_loc9_].weightVector[_loc2_ * _smudges[_loc9_].radius * 2 + _loc3_] = (255 - _loc6_) / 255;
                  _loc3_++;
               }
               _loc2_++;
            }
            _airbrushes[_loc9_] = {};
            _airbrushes[_loc9_].diameter = _drawSizes[_loc9_];
            _airbrushes[_loc9_]._drawOffSet = Math.floor(_drawSizes[_loc9_] / 2);
            _airbrushes[_loc9_]._drawTranslateMatrix = new Matrix();
            _loc12_ = new Shape();
            _loc12_.graphics.beginFill(2013265919,0.15);
            _loc12_.graphics.drawCircle(0,0,_drawSizes[_loc9_] / 2);
            _loc12_.graphics.endFill();
            _loc4_ = new Matrix();
            _loc4_.tx = _loc12_.width / 2;
            _loc4_.ty = _loc12_.height / 2;
            _airbrushes[_loc9_]._drawBrushData = new BitmapData(_loc12_.width,_loc12_.height,true,16711680);
            _airbrushes[_loc9_]._drawBrushData.draw(_loc12_,_loc4_);
            _loc9_++;
         }
         if(!_bInit)
         {
            _layerBackground = new Sprite();
            _layerInterface = new Sprite();
            _layerMouse = new Sprite();
            _guiLayer = new Sprite();
            addChild(_layerInterface);
            addChild(_layerBackground);
            addChild(_guiLayer);
            addChild(_layerMouse);
            loadScene("ArtStudioPaint/room_main.xroom");
            _bInit = true;
            _exitConfirmationActive = false;
         }
         else
         {
            startGame();
         }
      }
      
      private function startDraw(param1:MouseEvent) : void
      {
         var _loc2_:* = 0;
         if(ArtStudioKit.isPlacing() || ArtStudioKit.isDialogOpen())
         {
            return;
         }
         if(isHandActive())
         {
            startPan(param1);
            return;
         }
         if(!_pauseGame && _brush && _brush.loader.content)
         {
            var _activeBitmapData:BitmapData = _layerBitmapDatas[_activeLayerIndex];
            var preset:int = int(_interfaceObject.loader.content.brushSize);
            if(preset >= 1 && preset <= _drawSizes.length)
            {
               _brushSizeVal = _drawSizes[preset - 1];
            }
            _drawSize = _brushSizeVal;
            _currentTool = _interfaceObject.loader.content.currentTool;
            if(_currentTool == TOOL_EYEDROP || param1.altKey)
            {
               pickColorAt(_drawCanvas.mouseX,_drawCanvas.mouseY,_currentTool == TOOL_EYEDROP);
               return;
            }
            if(_currentTool == TOOL_ERASER && _layerLocks[_activeLayerIndex])
            {
               flashTip(_menuBtn,"This layer's transparency is locked (Menu > Lock Transparency).");
               return;
            }
            if(!(_layerBitmaps[_activeLayerIndex] as Bitmap).visible)
            {
               flashTip(_eyeBtn,"This layer is hidden. Show it to paint on it.");
               return;
            }
            pushUndo([_activeLayerIndex],false);
            _interfaceObject.loader.content.newHistory(_interfaceObject.loader.content.red,_interfaceObject.loader.content.green,_interfaceObject.loader.content.blue);
            switch(_currentTool - 1)
            {
               case 0:
                  if(_pencilShape)
                  {
                     if(_pencilShape.parent)
                     {
                        _pencilShape.parent.removeChild(_pencilShape);
                     }
                     _pencilShape.graphics.clear();
                  }
                  _pencilShape = new Shape();
                  _pencilMoved = false;
                  var penColor:uint = uint(_interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue);
                  var penAlpha:Number = _brushOpacity;
                  _pencilShape.graphics.lineStyle(_drawSize,penColor,penAlpha,true);
                  var startX:int = Math.round(_drawCanvas.mouseX);
                  var startY:int = Math.round(_drawCanvas.mouseY);
                  _pencilShape.graphics.moveTo(startX,startY);
                  _smX = startX;
                  _smY = startY;
                  _drawCanvas.addChild(_pencilShape);
                  _drawing = true;
                  break;
               case 2:
                  _activeBrush = getAirbrush(_brushSizeVal);
                  _drawing = true;
                  moveMouse(param1);
                  break;
               case 1:
               case 3:
               case 5:
               case 7:
                  _drawGraphics.graphics.clear();
                  _drawBitmapDataSnapShot.fillRect(_drawBitmapDataRect,0);
                  _drawCanvas.addChild(_drawBitmapSnapShot);
                  _drawStartX = _drawCanvas.mouseX;
                  _drawStartY = _drawCanvas.mouseY;
                  _drawing = true;
                  break;
               case 4:
                  _loc2_ = uint(-16777216 | _interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue);
                  _activeBitmapData.floodFill(_drawCanvas.mouseX,_drawCanvas.mouseY,_loc2_);
                  applyAlphaLock();
                  refreshLayerThumb(_activeLayerIndex);
                  syncCanvasButtons();
                  _needsSave = true;
                  break;
               case 6:
                  _activeSmudge = getSmudge(_brushSizeVal >> 1);
                  _drawStartX = _drawCanvas.mouseX;
                  _drawStartY = _drawCanvas.mouseY;
                  _drawing = true;
                  break;
               case TOOL_BLUR - 1:
                  _drawing = true;
                  _drawSize = _brushSizeVal;
                  break;
               case TOOL_ERASER - 1:
                  _drawing = true;
                  _drawSize = _brushSizeVal;
                  _activeBitmapData = _layerBitmapDatas[_activeLayerIndex];
                  _drawGraphics.graphics.clear();
                  _drawGraphics.graphics.beginFill(0,1);
                  _drawGraphics.graphics.drawCircle(_drawCanvas.mouseX,_drawCanvas.mouseY,_drawSize / 2);
                  _drawGraphics.graphics.endFill();
                  _activeBitmapData.draw(_drawGraphics,null,null,BlendMode.ERASE);
                  _drawGraphics.graphics.clear();
                  _drawGraphics.graphics.lineStyle(_drawSize,0,1,false,"round","round",3);
                  _drawGraphics.graphics.moveTo(_drawCanvas.mouseX,_drawCanvas.mouseY);
                  _drawStartX = _drawCanvas.mouseX;
                  _drawStartY = _drawCanvas.mouseY;
                  break;
               case TOOL_GRADIENT - 1:
                  _drawing = true;
                  _drawStartX = _drawCanvas.mouseX;
                  _drawStartY = _drawCanvas.mouseY;
                  _drawCanvas.addChild(_gradShape);
                  drawGradientPreview();
                  break;
               case TOOL_PEN - 1:
                  _drawing = true;
                  stampPenCircleAt(_drawCanvas.mouseX,_drawCanvas.mouseY);
                  _lastPenX = _drawCanvas.mouseX;
                  _lastPenY = _drawCanvas.mouseY;
                  _smX = _lastPenX;
                  _smY = _lastPenY;
            }
         }
      }
      
      private function getCompositePixel(x:int, y:int) : uint
      {
         var i:int = _layerBitmapDatas.length - 1;
         while(i >= 0)
         {
            var bmp:Bitmap = _layerBitmaps[i] as Bitmap;
            if(!(!bmp || !bmp.visible))
            {
               var bd:BitmapData = _layerBitmapDatas[i];
               if(!(x < 0 || y < 0 || x >= bd.width || y >= bd.height))
               {
                  var px:uint = bd.getPixel32(x,y);
                  var a:uint = uint(px >> 24 & 0xFF);
                  if(a != 0)
                  {
                     return px;
                  }
               }
            }
            i--;
         }
         return 0;
      }
      
      private function endDraw(param1:MouseEvent) : void
      {
         if(_drawing)
         {
            var _activeBitmapData:BitmapData = _layerBitmapDatas[_activeLayerIndex];
            _drawing = false;
            _masterpieceSubmitBtn.guiBtn.setGrayState(false);
            if(_submitButton != null)
            {
               _submitButton.guiBtn.setGrayState(false);
            }
            _printBtn.guiBtn.setGrayState(false);
            _clearAllButton.guiBtn.setGrayState(false);
            _needsSave = true;
            _hasDrawn = true;
            if(_currentTool - 1 == 0 && _pencilShape != null)
            {
               var penColor2:uint = uint(_interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue);
               var penAlpha2:Number = _brushOpacity;
               var softness:Number = 1 - _brushHardness;
               var blurAmount:Number = softness * (_drawSize * 0.5);
               if(!_pencilMoved)
               {
                  var dot:Shape = new Shape();
                  dot.graphics.beginFill(penColor2,penAlpha2);
                  dot.graphics.drawCircle(_drawCanvas.mouseX,_drawCanvas.mouseY,_drawSize * 0.5);
                  dot.graphics.endFill();
                  if(softness <= 0)
                  {
                     dot = new Shape();
                     dot.graphics.beginFill(penColor2,penAlpha2);
                     dot.graphics.drawCircle(_drawCanvas.mouseX,_drawCanvas.mouseY,_drawSize * 0.5);
                     dot.graphics.endFill();
                     _activeBitmapData.draw(dot,null,null,BlendMode.NORMAL);
                     dot.graphics.clear();
                  }
                  else
                  {
                     var blurRad:int = Math.ceil(blurAmount);
                     var tempSize:int = _drawSize + 2 * blurRad;
                     var dotBD:BitmapData = new BitmapData(tempSize,tempSize,true,0);
                     dot = new Shape();
                     dot.graphics.beginFill(penColor2,penAlpha2);
                     dot.graphics.drawCircle(tempSize / 2,tempSize / 2,_drawSize * 0.5);
                     dot.graphics.endFill();
                     dotBD.draw(dot);
                     var bfDot:BlurFilter = new BlurFilter(blurAmount,blurAmount,1);
                     dotBD.applyFilter(dotBD,dotBD.rect,new Point(0,0),bfDot);
                     var stampX:Number = _drawCanvas.mouseX - tempSize * 0.5;
                     var stampY:Number = _drawCanvas.mouseY - tempSize * 0.5;
                     var placeMat:Matrix = new Matrix(1,0,0,1,stampX,stampY);
                     _activeBitmapData.draw(dotBD,placeMat,null,BlendMode.NORMAL);
                     dotBD.dispose();
                     dot.graphics.clear();
                  }
                  dot.graphics.clear();
               }
               else if(softness > 0)
               {
                  var bounds:Rectangle = _pencilShape.getBounds(_drawCanvas);
                  blurRad = Math.ceil(blurAmount);
                  var padW:int = 2 * blurRad;
                  var padH:int = 2 * blurRad;
                  var pxBD:BitmapData = new BitmapData(Math.ceil(bounds.width) + padW,Math.ceil(bounds.height) + padH,true,0);
                  var mat:Matrix = new Matrix();
                  mat.translate(-bounds.x + blurRad,-bounds.y + blurRad);
                  pxBD.draw(_pencilShape,mat);
                  var bfStroke:BlurFilter = new BlurFilter(blurAmount,blurAmount,1);
                  pxBD.applyFilter(pxBD,pxBD.rect,new Point(0,0),bfStroke);
                  var drawMat:Matrix = new Matrix();
                  drawMat.translate(bounds.x - blurRad,bounds.y - blurRad);
                  _activeBitmapData.draw(pxBD,drawMat);
                  pxBD.dispose();
               }
               else
               {
                  _activeBitmapData.draw(_pencilShape,null,null,BlendMode.NORMAL);
               }
               if(_pencilShape.parent)
               {
                  _pencilShape.parent.removeChild(_pencilShape);
               }
               _pencilShape = null;
            }
            else
            {
               switch(_currentTool - 2)
               {
                  case 0:
                  case 2:
                  case 4:
                  case 6:
                     _drawBitmapSnapShot.parent.removeChild(_drawBitmapSnapShot);
                     _drawBitmapDataSnapShot.copyPixels(_activeBitmapData,_drawBitmapDataRect,_drawPoint_0_0);
                     _activeBitmapData.draw(_drawGraphics);
               }
               if(_brushOpacity >= 1)
               {
                  switch(_currentTool - 1)
                  {
                     case 0:
                     case 1:
                     case 3:
                     case 5:
                     case 7:
                        var diff:Object = _drawBitmapDataSnapShot.compare(_activeBitmapData);
                        if(diff)
                        {
                           var solidColor:uint = uint(-16777216 | _interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue);
                           var diffBD:BitmapData = diff;
                           _activeBitmapData.threshold(diffBD,_drawBitmapDataRect,_drawPoint_0_0,"!=",0,solidColor);
                           break;
                        }
                  }
               }
            }
            if(_currentTool == TOOL_GRADIENT)
            {
               commitGradient();
            }
            applyAlphaLock();
            refreshLayerThumb(_activeLayerIndex);
         }
      }
      
      private function moveMouse(param1:Event) : void
      {
         var _loc4_:Number = Number(NaN);
         var _loc9_:Number = Number(NaN);
         var _loc8_:* = NaN;
         var _loc7_:* = NaN;
         var _loc5_:* = NaN;
         var _loc3_:* = NaN;
         var _loc2_:int = 0;
         var _loc6_:* = undefined;
         if(_sceneLoaded && _brush)
         {
            var _activeBitmapData:BitmapData = _layerBitmapDatas[_activeLayerIndex];
            _brush.loader.x = mouseX;
            _brush.loader.y = mouseY;
            updateSizeRing();
            if(_drawing)
            {
               switch(_currentTool - 1)
               {
                  case 0:
                     if(_pencilShape)
                     {
                        _pencilMoved = true;
                        smoothStep(_drawCanvas.mouseX,_drawCanvas.mouseY);
                        var nextX:int = Math.round(_smX);
                        var nextY:int = Math.round(_smY);
                        _pencilShape.graphics.lineTo(nextX,nextY);
                     }
                     break;
                  case 1:
                     _drawGraphics.graphics.clear();
                     _drawBitmapDataSnapShot.fillRect(_drawBitmapDataRect,0);
                     _drawGraphics.graphics.lineStyle(_drawSize,-16777216 | _interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue,1,false,"normal","square","miter");
                     _drawGraphics.graphics.moveTo(_drawStartX,_drawStartY);
                     _drawGraphics.graphics.lineTo(_drawCanvas.mouseX,_drawCanvas.mouseY);
                     _drawGraphics.graphics.endFill();
                     _drawBitmapDataSnapShot.draw(_drawGraphics);
                     break;
                  case 2:
                     _activeBrush._drawTranslateMatrix.tx = _drawCanvas.mouseX - _activeBrush._drawOffSet;
                     _activeBrush._drawTranslateMatrix.ty = _drawCanvas.mouseY - _activeBrush._drawOffSet;
                     var ct2:ColorTransform = _brush.loader.content.brushTip.transform.colorTransform;
                     ct2.alphaMultiplier = _brushOpacity;
                     var softness2:Number = 1 - _brushHardness;
                     var blurAmt2:Number = softness2 * (_activeBrush.diameter * 0.5);
                     softness2 = 1 - _brushHardness;
                     blurAmt2 = softness2 * (_activeBrush.diameter * 0.5);
                     _activeBitmapData.lock();
                     if(softness2 > 0)
                     {
                        var blurRad2:int = Math.ceil(blurAmt2);
                        var tempBrushSize:int = _activeBrush.diameter + 2 * blurRad2;
                        var brushTempBD:BitmapData = new BitmapData(tempBrushSize,tempBrushSize,true,0);
                        var matCenter:Matrix = new Matrix();
                        matCenter.translate(blurRad2,blurRad2);
                        brushTempBD.draw(_activeBrush._drawBrushData,matCenter);
                        var bf2:BlurFilter = new BlurFilter(blurAmt2,blurAmt2,1);
                        brushTempBD.applyFilter(brushTempBD,brushTempBD.rect,new Point(0,0),bf2);
                        var stampX2:Number = _drawCanvas.mouseX - tempBrushSize * 0.5;
                        var stampY2:Number = _drawCanvas.mouseY - tempBrushSize * 0.5;
                        var placeMat2:Matrix = new Matrix(1,0,0,1,stampX2,stampY2);
                        _activeBitmapData.draw(brushTempBD,placeMat2,ct2,BlendMode.NORMAL,null,true);
                        brushTempBD.dispose();
                     }
                     else
                     {
                        _activeBitmapData.draw(_activeBrush._drawBrushData,_activeBrush._drawTranslateMatrix,ct2,BlendMode.NORMAL,null,true);
                     }
                     _activeBitmapData.unlock(new Rectangle(_drawCanvas.mouseX - _activeBrush._drawOffSet - blurRad2,_drawCanvas.mouseY - _activeBrush._drawOffSet - blurRad2,tempBrushSize,tempBrushSize));
                     break;
                  case 3:
                     _drawGraphics.graphics.clear();
                     _drawBitmapDataSnapShot.fillRect(_drawBitmapDataRect,0);
                     _drawGraphics.graphics.lineStyle(_drawSize,-16777216 | _interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue,1,false,"normal","square","miter");
                     if(_fillShapes)
                     {
                        _drawGraphics.graphics.beginFill(ArtStudioKit.currentColor(_interfaceObject.loader.content),1);
                     }
                     _drawGraphics.graphics.drawRect(Math.min(_drawStartX,_drawCanvas.mouseX),Math.min(_drawStartY,_drawCanvas.mouseY),Math.abs(_drawCanvas.mouseX - _drawStartX),Math.abs(_drawCanvas.mouseY - _drawStartY));
                     _drawGraphics.graphics.endFill();
                     _drawBitmapDataSnapShot.draw(_drawGraphics);
                     break;
                  case 5:
                     _drawGraphics.graphics.clear();
                     _drawBitmapDataSnapShot.fillRect(_drawBitmapDataRect,0);
                     _drawGraphics.graphics.lineStyle(_drawSize,-16777216 | _interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue);
                     if(_fillShapes)
                     {
                        _drawGraphics.graphics.beginFill(ArtStudioKit.currentColor(_interfaceObject.loader.content),1);
                     }
                     _drawGraphics.graphics.drawEllipse(_drawStartX - Math.abs(_drawCanvas.mouseX - _drawStartX),_drawStartY - Math.abs(_drawCanvas.mouseY - _drawStartY),Math.abs(_drawCanvas.mouseX - _drawStartX) * 2,Math.abs(_drawCanvas.mouseY - _drawStartY) * 2);
                     _drawGraphics.graphics.endFill();
                     _drawBitmapDataSnapShot.draw(_drawGraphics);
                     break;
                  case 6:
                     _loc8_ = _drawStartX;
                     _loc7_ = _drawStartY;
                     _loc5_ = _loc8_;
                     _loc3_ = _loc7_;
                     _loc2_ = 1;
                     _loc6_ = _activeBitmapData.getVector(_drawBitmapDataRect);
                     if(_drawCanvas.mouseX != _drawStartX)
                     {
                        _loc4_ = (_drawCanvas.mouseY - _drawStartY) / (_drawCanvas.mouseX - _drawStartX);
                     }
                     else
                     {
                        _loc4_ = 1;
                     }
                     _loc9_ = _drawStartY - _loc4_ * _drawStartX;
                     while(_loc5_ != _drawCanvas.mouseX || _loc3_ != _drawCanvas.mouseY)
                     {
                        if(_loc4_ < 1 && _loc4_ > -1)
                        {
                           if(_loc5_ < _drawCanvas.mouseX)
                           {
                              _loc5_ += _loc2_;
                              if(_loc5_ >= _drawCanvas.mouseX)
                              {
                                 _loc5_ = _drawCanvas.mouseX;
                              }
                           }
                           else
                           {
                              _loc5_ -= _loc2_;
                              if(_loc5_ <= _drawCanvas.mouseX)
                              {
                                 _loc5_ = _drawCanvas.mouseX;
                              }
                           }
                           if(_loc5_ != _drawCanvas.mouseX)
                           {
                              _loc3_ = _loc4_ * _loc5_ + _loc9_;
                           }
                           else
                           {
                              _loc3_ = _drawCanvas.mouseY;
                           }
                        }
                        else
                        {
                           if(_loc3_ < _drawCanvas.mouseY)
                           {
                              _loc3_ += _loc2_;
                              if(_loc3_ >= _drawCanvas.mouseY)
                              {
                                 _loc3_ = _drawCanvas.mouseY;
                              }
                           }
                           else
                           {
                              _loc3_ -= _loc2_;
                              if(_loc3_ <= _drawCanvas.mouseY)
                              {
                                 _loc3_ = _drawCanvas.mouseY;
                              }
                           }
                           if(_drawCanvas.mouseX != _drawStartX)
                           {
                              if(_loc3_ != _drawCanvas.mouseY)
                              {
                                 _loc5_ = (_loc3_ - _loc9_) / _loc4_;
                              }
                              else
                              {
                                 _loc5_ = _drawCanvas.mouseX;
                              }
                           }
                           else
                           {
                              _loc5_ = _drawStartX;
                           }
                        }
                        doSmudge(_loc6_,_loc8_,_loc7_,_loc5_,_loc3_);
                        _loc8_ = _loc5_;
                        _loc7_ = _loc3_;
                     }
                     _activeBitmapData.setVector(_drawBitmapDataRect,_loc6_);
                     _drawStartX = _drawCanvas.mouseX;
                     _drawStartY = _drawCanvas.mouseY;
                     break;
                  case 7:
                     _drawGraphics.graphics.clear();
                     _drawBitmapDataSnapShot.fillRect(_drawBitmapDataRect,0);
                     _drawGraphics.graphics.lineStyle(_drawSize,-16777216 | _interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue,1,false,"normal","square","miter");
                     if(_fillShapes)
                     {
                        _drawGraphics.graphics.beginFill(ArtStudioKit.currentColor(_interfaceObject.loader.content),1);
                     }
                     _drawGraphics.graphics.drawTriangles(Vector.<Number>([(_drawCanvas.mouseX - _drawStartX) / 2 + _drawStartX,_drawCanvas.mouseY,_drawCanvas.mouseX,_drawStartY,_drawStartX,_drawStartY]));
                     _drawGraphics.graphics.endFill();
                     _drawBitmapDataSnapShot.draw(_drawGraphics);
                     break;
                  case TOOL_BLUR - 1:
                     var BLUR_RADII:Array = [1,2,3,4,6,8];
                     var bs:int = int(_interfaceObject.loader.content.brushSize);
                     if(bs < 1 || bs > BLUR_RADII.length)
                     {
                        bs = 1;
                     }
                     var diameter:int = _brushSizeVal;
                     var blurSigma:Number = Number(BLUR_RADII[bs - 1]);
                     var half:int = diameter >> 1;
                     var blurArea:Rectangle = new Rectangle(_drawCanvas.mouseX - half,_drawCanvas.mouseY - half,diameter,diameter).intersection(_drawBitmapDataRect);
                     if(blurArea.isEmpty())
                     {
                        break;
                     }
                     var compositeBelow:BitmapData = new BitmapData(blurArea.width,blurArea.height,true,0);
                     var mat:Matrix = new Matrix();
                     mat.translate(-blurArea.x,-blurArea.y);
                     var li:int = 0;
                     while(li <= _activeLayerIndex)
                     {
                        compositeBelow.draw(_layerBitmapDatas[li],mat,null,null,null,true);
                        li++;
                     }
                     var tmp:BitmapData = new BitmapData(blurArea.width,blurArea.height,false);
                     tmp.copyPixels(compositeBelow,compositeBelow.rect,ORIGIN);
                     var bf:BlurFilter = new BlurFilter(blurSigma,blurSigma,1);
                     tmp.applyFilter(tmp,tmp.rect,ORIGIN,bf);
                     var maskFull:BitmapData = getBlurMask(diameter);
                     if(blurArea.width == diameter && blurArea.height == diameter)
                     {
                        var mask:BitmapData = maskFull;
                     }
                     else
                     {
                        mask = new BitmapData(blurArea.width,blurArea.height,true,0);
                        mask.copyPixels(maskFull,new Rectangle(blurArea.x < 0 ? -blurArea.x : 0,blurArea.y < 0 ? -blurArea.y : 0,blurArea.width,blurArea.height),ORIGIN);
                     }
                     var _activeBD:BitmapData = _layerBitmapDatas[_activeLayerIndex];
                     _activeBD.copyPixels(tmp,tmp.rect,blurArea.topLeft,mask,null,true);
                     compositeBelow.dispose();
                     tmp.dispose();
                     if(mask != maskFull)
                     {
                        mask.dispose();
                     }
                     _hasDrawn = true;
                     _needsSave = true;
                     break;
                  case TOOL_GRADIENT - 1:
                     drawGradientPreview();
                     break;
                  case TOOL_ERASER - 1:
                     _drawGraphics.graphics.lineTo(_drawCanvas.mouseX,_drawCanvas.mouseY);
                     _activeBitmapData.draw(_drawGraphics,null,null,BlendMode.ERASE);
                     _drawStartX = _drawCanvas.mouseX;
                     _drawStartY = _drawCanvas.mouseY;
                     break;
                  case TOOL_PEN - 1:
                     if(_drawing)
                     {
                        smoothStep(_drawCanvas.mouseX,_drawCanvas.mouseY);
                        var cx:Number = _smX;
                        var cy:Number = _smY;
                        var dx:Number = cx - _lastPenX;
                        var dy:Number = cy - _lastPenY;
                        var dist:Number = Math.sqrt(dx * dx + dy * dy);
                        var r:int = Math.ceil(_drawSize * 0.5);
                        var count:int = Math.ceil(dist / 1);
                        var i:int = 1;
                        while(i <= count)
                        {
                           var t:Number = i / count;
                           stampPenCircleAt(_lastPenX + dx * t,_lastPenY + dy * t);
                           i++;
                        }
                        _lastPenX = cx;
                        _lastPenY = cy;
                     }
               }
            }
         }
      }
      
      private function getBlurMask(diameter:int) : BitmapData
      {
         if(_blurMasks[diameter])
         {
            return _blurMasks[diameter];
         }
         var mask:BitmapData = new BitmapData(diameter,diameter,true,0);
         var s:Shape = new Shape();
         var m:Matrix = new Matrix();
         m.createGradientBox(diameter,diameter,0,0,0);
         s.graphics.beginGradientFill(GradientType.RADIAL,[16777215,16777215],[1,0],[0,255],m,SpreadMethod.PAD);
         s.graphics.drawCircle(diameter >> 1,diameter >> 1,diameter >> 1);
         s.graphics.endFill();
         mask.draw(s);
         _blurMasks[diameter] = mask;
         return mask;
      }
      
      private function stampPenCircleAt(mx:Number, my:Number) : void
      {
         var penColor:uint = uint(_interfaceObject.loader.content.red << 16 | _interfaceObject.loader.content.green << 8 | _interfaceObject.loader.content.blue);
         var bd:BitmapData = _layerBitmapDatas[_activeLayerIndex];
         var r:int = Math.ceil(_drawSize * 0.5);
         bd.lock();
         var dy:int = -r;
         while(dy <= r)
         {
            var yy:int = my + dy;
            if(!(yy < 0 || yy >= bd.height))
            {
               var dxMax:int = Math.floor(Math.sqrt(r * r - dy * dy));
               var dx:int = -dxMax;
               while(dx <= dxMax)
               {
                  var xx:int = mx + dx;
                  if(!(xx < 0 || xx >= bd.width))
                  {
                     bd.setPixel32(xx,yy,0xFF000000 | penColor);
                  }
                  dx++;
               }
            }
            dy++;
         }
         bd.unlock();
      }
      
      protected function doSmudge(param1:Vector.<uint>, param2:Number, param3:Number, param4:Number, param5:Number) : void
      {
         var _loc6_:int = 0;
         var _loc18_:int = 0;
         var _loc23_:int = 0;
         var _loc25_:int = 0;
         var _loc15_:int = 0;
         var _loc14_:int = 0;
         var _loc8_:* = 0;
         var _loc10_:* = 0;
         var _loc11_:* = 0;
         var _loc13_:* = 0;
         var _loc12_:* = 0;
         var _loc21_:* = 0;
         var _loc7_:* = 0;
         var _loc19_:* = 0;
         var _loc9_:* = 0;
         var _loc22_:* = 0;
         var _loc17_:* = 0;
         var _loc20_:Number = Number(NaN);
         var _loc24_:Number = Number(NaN);
         var _loc16_:int = 0;
         _loc6_ = 0;
         while(_loc6_ < _activeSmudge.radius * 2)
         {
            _loc18_ = 0;
            while(_loc18_ < _activeSmudge.radius * 2)
            {
               _loc23_ = param4 - _activeSmudge.radius + _loc18_;
               _loc25_ = param5 - _activeSmudge.radius + _loc6_;
               if(_loc23_ >= 0 && _loc23_ < _drawBitmapDataRect.width && _loc25_ >= 0 && _loc25_ < _drawBitmapDataRect.height)
               {
                  _loc15_ = param2 - _activeSmudge.radius + _loc18_;
                  _loc14_ = param3 - _activeSmudge.radius + _loc6_;
                  _loc8_ = param1[_loc25_ * _drawBitmapDataRect.width + _loc23_];
                  if(_loc15_ >= 0 && _loc15_ < _drawBitmapDataRect.width && _loc14_ >= 0 && _loc14_ < _drawBitmapDataRect.height)
                  {
                     _loc10_ = param1[_loc14_ * _drawBitmapDataRect.width + _loc15_];
                     _loc13_ = _loc10_ >> 16 & 0xFF;
                     _loc12_ = _loc10_ >> 8 & 0xFF;
                     _loc21_ = _loc10_ & 0xFF;
                     _loc7_ = _loc10_ >> 24 & 0xFF;
                     _loc19_ = _loc8_ >> 16 & 0xFF;
                     _loc9_ = _loc8_ >> 8 & 0xFF;
                     _loc22_ = _loc8_ & 0xFF;
                     _loc17_ = _loc8_ >> 24 & 0xFF;
                     _loc20_ = Number(_activeSmudge.weightVector[_loc16_]);
                     _loc24_ = (_loc19_ - _loc13_) * _loc20_;
                     _loc19_ = _loc13_ + Math.ceil(_loc24_);
                     _loc24_ = (_loc9_ - _loc12_) * _loc20_;
                     _loc9_ = _loc12_ + Math.ceil(_loc24_);
                     _loc24_ = (_loc22_ - _loc21_) * _loc20_;
                     _loc22_ = _loc21_ + Math.ceil(_loc24_);
                     _loc24_ = (_loc17_ - _loc7_) * _loc20_;
                     _loc17_ = _loc7_ + Math.ceil(_loc24_);
                     _loc11_ = uint(_loc17_ << 24 | _loc19_ << 16 | _loc9_ << 8 | _loc22_);
                     param1[_loc25_ * _drawBitmapDataRect.width + _loc23_] = _loc11_;
                  }
               }
               _loc16_++;
               _loc18_++;
            }
            _loc6_++;
         }
      }
      
      override protected function sceneLoaded(param1:Event) : void
      {
         var _loc4_:Object = null;
         var bg:Shape = null;
         var yy:int = 0;
         var xx:int = 0;
         var i:int = 0;
         var layerBD:BitmapData = null;
         var layerBmp:Bitmap = null;
         var checkerSize:int = 8;
         _loc4_ = _scene.getLayer("closeButton");
         addBtn("CloseButton",_loc4_.x,_loc4_.y,onCloseButton);
         _interfaceObject = _scene.getLayer("interface");
         if(_sharedObject != null)
         {
            _submitButton = addBtn("artStudioPaint_submitButton",502,5139,onSubmitButton);
            _submitButton.guiBtn.setGrayState(true);
            if(_sharedObject.data.userColors != null)
            {
               _interfaceObject.loader.content.loadColors(_sharedObject.data.userColors);
            }
         }
         _clearAllButton = addBtn("artStudioPaint_clearButton",502,519,onClearAllButton);
         _clearAllButton.guiBtn.setGrayState(true);
         _printBackground = _scene.getLayer("template");
         _printBackground.loader.x = 10000;
         _printBackground.loader.y = 10000;
         _printBtn = addBtn("artStudioPaint_printButton",230,5219,onPrintButton);
         _printBtn.guiBtn.setGrayState(true);
         addBtn("artStudioPaint_sketchButton",170,5219,onSketchButton);
         _masterpieceSubmitBtn = addBtn("artStudioPaint_createMasterpiece",740,519,onCreateMasterpieceBtn);
         _masterpieceSubmitBtn.guiBtn.setGrayState(true);
         _storageButton = addBtn("artStudioPaint_storageBtn",562,519,onStorageButton);
         _storageButton.guiBtn.setUsePressedState();
         _brush = _scene.getLayer("brush");
         _brush.loader.mouseEnabled = false;
         _brush.loader.mouseChildren = false;
         _brush.loader.content.mouseEnabled = false;
         _brush.loader.content.mouseChildren = false;
         _brush.loader.content.brushTip.mouseEnabled = false;
         _brush.loader.content.brushTip.mouseChildren = false;
         _brush.loader.x = mouseX;
         _brush.loader.y = mouseY;
         _interfaceObject.loader.content.initBrush(_brush.loader.content);
         _exitConfirmationActive = false;
         _sceneLoaded = true;
         stage.addEventListener("enterFrame",heartbeat,false,0,true);
         stage.addEventListener("mouseMove",moveMouse);
         stage.addEventListener("mouseUp",endDraw);
         stage.addEventListener("keyDown",onKeyDown,false,0,true);
         stage.addEventListener("keyUp",onKeyUp,false,0,true);
         stage.addEventListener("mouseWheel",onMouseWheel,false,0,true);
         startGame();
         _layerMouse.visible = false;
         _layerInterface.addChild(_interfaceObject.loader);
         _layerMouse.addChild(_brush.loader);
         _sizeRing.visible = false;
         _layerMouse.addChild(_sizeRing);
         _layerMouse.mouseEnabled = false;
         _layerMouse.mouseChildren = false;
         _prevFrameRate = stage.frameRate;
         stage.frameRate = 60;
         _layersContainer = new Sprite();
         _layerBitmapDatas = [];
         _layerBitmaps = [];
         _canvasW = int(_interfaceObject.loader.content.canvas.width);
         _canvasH = int(_interfaceObject.loader.content.canvas.height);
         bg = new Shape();
         yy = 0;
         while(yy < _canvasH)
         {
            xx = 0;
            while(xx < _canvasW)
            {
               bg.graphics.beginFill((xx / checkerSize + yy / checkerSize) % 2 == 0 ? 15658734 : 13421772);
               bg.graphics.drawRect(xx,yy,checkerSize,checkerSize);
               bg.graphics.endFill();
               xx += checkerSize;
            }
            yy += checkerSize;
         }
         i = 0;
         while(i < NUM_LAYERS)
         {
            layerBD = new BitmapData(_canvasW,_canvasH,true,0);
            _layerBitmapDatas.push(layerBD);
            layerBmp = new Bitmap(layerBD,"auto",false);
            _layerBitmaps.push(layerBmp);
            _layersContainer.addChild(layerBmp);
            i++;
         }
         _drawCanvas = new Sprite();
         _drawCanvas.addChild(bg);
         _drawCanvas.addEventListener("mouseDown",startDraw);
         _drawCanvas.addEventListener("mouseOver",drawCanvasMouseOver);
         _drawCanvas.addEventListener("mouseOut",drawCanvasMouseOut);
         _drawCanvas.addChild(_layersContainer);
         _canvasOriginalX = 0;
         _canvasOriginalY = 0;
         _drawing = false;
         _drawBitmapDataSnapShot = new BitmapData(_canvasW,_canvasH,true,4294967295);
         _drawBitmapSnapShot = new Bitmap(_drawBitmapDataSnapShot,"auto",false);
         _defaultBitmapData = new BitmapData(_canvasW,_canvasH,true,4294967295);
         _drawBitmapUndoSnapShot = new BitmapData(_canvasW,_canvasH,true,4294967295);
         _drawBitmapUndo = new Bitmap(_drawBitmapUndoSnapShot,"auto",false);
         _drawBitmapDataRect = _layerBitmapDatas[0].rect;
         _drawPoint_0_0 = new Point(0,0);
         _canvasMask = new Shape();
         _canvasMask.graphics.beginFill(0);
         _canvasMask.graphics.drawRect(0,0,_canvasW,_canvasH);
         _canvasMask.graphics.endFill();
         _interfaceObject.loader.content.canvas.addChild(_drawCanvas);
         _interfaceObject.loader.content.canvas.addChild(_canvasMask);
         _drawCanvas.mask = _canvasMask;
         buildModUI();
         updateLayerVisuals();
         super.sceneLoaded(param1);
      }
      
      private function drawCanvasMouseOver(param1:MouseEvent) : void
      {
         _overCanvas = true;
         updateCanvasCursor();
      }
      
      private function drawCanvasMouseOut(param1:MouseEvent) : void
      {
         _overCanvas = false;
         updateCanvasCursor();
      }
      
      private function onMergeLayerDown(e:MouseEvent) : void
      {
         var src:int = _activeLayerIndex;
         var dst:int = src - 1;
         var opacity:Number = NaN;
         if(src <= 0)
         {
            return;
         }
         pushUndo([src,dst],true);
         opacity = Number(_layerOpacities[src]);
         if((_layerBitmaps[src] as Bitmap).visible)
         {
            (_layerBitmapDatas[dst] as BitmapData).draw(_layerBitmapDatas[src],null,opacity < 1 ? new ColorTransform(1,1,1,opacity) : null,_layerBlends[src]);
         }
         (_layerBitmapDatas[src] as BitmapData).fillRect(_drawBitmapDataRect,0);
         _layerOpacities[src] = 1;
         _layerBlends[src] = BlendMode.NORMAL;
         _layerLocks[src] = false;
         (_layerBitmaps[src] as Bitmap).visible = true;
         _activeLayerIndex = dst;
         updateLayerVisuals();
         refreshLayerPanel(true);
         _needsSave = true;
      }
      
      private function onMoveLayerUp(e:MouseEvent) : void
      {
         if(_activeLayerIndex < NUM_LAYERS - 1)
         {
            swapLayers(_activeLayerIndex,_activeLayerIndex + 1);
         }
      }
      
      private function onMoveLayerDown(e:MouseEvent) : void
      {
         if(_activeLayerIndex > 0)
         {
            swapLayers(_activeLayerIndex,_activeLayerIndex - 1);
         }
      }
      
      public function message(param1:Array) : void
      {
         var _loc2_:int = 0;
         if(param1[0] != "ml")
         {
            if(param1[0] == "ms")
            {
               _dbIDs = [];
               _loc2_ = 0;
               while(_loc2_ < _pIDs.length)
               {
                  _dbIDs[_loc2_] = param1[_loc2_ + 1];
                  _loc2_++;
               }
            }
            else if(param1[0] == "mm")
            {
               if(param1[2] == "tkn")
               {
                  handleMasterpieceTokenReply(param1[3] == "1",param1[5],parseInt(param1[7]));
               }
            }
         }
      }
      
      public function handleMasterpieceTokenReply(param1:Boolean, param2:String, param3:int) : void
      {
         if(!_submitPending)
         {
            return;
         }
         if(!param1)
         {
            onSendError(null);
            return;
         }
         _masterPieceSubmissionToken = param2;
         if(param3 == 1)
         {
            startSubmitWatchdog(UPLOAD_TIMEOUT_MS);
            setupRequest(onSendComplete,onSendError,20,_denPreviewInvId,false,0);
         }
      }
      
      public function heartbeat(param1:Event) : void
      {
         if(_sceneLoaded)
         {
            _frameTime = (getTimer() - _lastTime) / 1000;
            _lastTime = getTimer();
            _timeSinceErase += _frameTime;
            _gameIdleTimer = 0;
            _keepAliveTimer += 1;
            if(_keepAliveTimer >= 60)
            {
               MinigameManager.keepAlive();
               _keepAliveTimer = 0;
            }
            if(_interfaceObject.loader.content.clickSound)
            {
               AJAudio.playHudBtnClick();
               _interfaceObject.loader.content.clickSound = false;
            }
            syncNativeControls();
            ArtStudioKit.syncColorPanel(_colorPanel);
         }
      }
      
      public function startGame() : void
      {
         if(_sceneLoaded)
         {
         }
      }
      
      private function onExportClick(e:MouseEvent) : void
      {
         var exportBD:BitmapData = null;
         var fr:FileReference = null;
         try
         {
            exportBD = getCompositeBitmapData(false);
            fr = new FileReference();
            fr.save(PNGEncoder.encode(exportBD),"masterpiece.png");
         }
         catch(err:Error)
         {
            DebugUtility.debugTrace(err.message);
         }
         if(exportBD != null)
         {
            exportBD.dispose();
         }
      }
      
      private function onZoomInClick(e:MouseEvent) : void
      {
         zoomIn();
      }
      
      private function onZoomOutClick(e:MouseEvent) : void
      {
         zoomOut();
      }
      
      private function onZoomResetClick(e:MouseEvent) : void
      {
         resetZoom();
      }
      
      private function startPan(e:MouseEvent) : void
      {
         var p:Point = _drawCanvas.parent.globalToLocal(new Point(e.stageX,e.stageY));
         e.stopPropagation();
         _isPanning = true;
         _panStartX = p.x;
         _panStartY = p.y;
         stage.addEventListener(MouseEvent.MOUSE_MOVE,updatePan);
         stage.addEventListener(MouseEvent.MOUSE_UP,endPan);
      }
      
      private function updatePan(e:MouseEvent) : void
      {
         var p:Point = null;
         if(_isPanning)
         {
            p = _drawCanvas.parent.globalToLocal(new Point(e.stageX,e.stageY));
            _drawCanvas.x += p.x - _panStartX;
            _drawCanvas.y += p.y - _panStartY;
            _panStartX = p.x;
            _panStartY = p.y;
            clampPan();
            e.updateAfterEvent();
         }
      }
      
      private function endPan(e:MouseEvent) : void
      {
         if(_isPanning)
         {
            _isPanning = false;
            stage.removeEventListener(MouseEvent.MOUSE_MOVE,updatePan);
            stage.removeEventListener(MouseEvent.MOUSE_UP,endPan);
            updateCanvasCursor();
         }
      }
      
      private function onKeyDown(e:KeyboardEvent) : void
      {
         if(stage.focus is TextField || _exitConfirmationActive || ArtStudioKit.isPlacing() || ArtStudioKit.isDialogOpen())
         {
            return;
         }
         if(e.ctrlKey && e.keyCode == 90 && !e.shiftKey)
         {
            e.preventDefault();
            e.stopPropagation();
            onUndoClick(null);
            return;
         }
         if(e.ctrlKey && e.keyCode == 89 || e.ctrlKey && e.shiftKey && e.keyCode == 90)
         {
            e.preventDefault();
            e.stopPropagation();
            onRedoClick(null);
            return;
         }
         if(e.ctrlKey && (e.keyCode == 187 || e.keyCode == 61))
         {
            e.preventDefault();
            e.stopPropagation();
            zoomIn();
            return;
         }
         if(e.ctrlKey && e.keyCode == 189)
         {
            e.preventDefault();
            e.stopPropagation();
            zoomOut();
            return;
         }
         if(e.ctrlKey && e.keyCode == 73)
         {
            e.preventDefault();
            applyInstant("invert");
            return;
         }
         if(e.ctrlKey && e.keyCode == 74)
         {
            e.preventDefault();
            duplicateLayer();
            return;
         }
         if(e.ctrlKey && e.keyCode == 48)
         {
            e.preventDefault();
            e.stopPropagation();
            resetZoom();
            return;
         }
         if(e.ctrlKey || e.altKey)
         {
            return;
         }
         if(e.keyCode == Keyboard.SPACE)
         {
            e.preventDefault();
            if(!_spaceHeld && !_drawing)
            {
               _spaceHeld = true;
               updateCanvasCursor();
            }
            return;
         }
         switch(e.keyCode)
         {
            case 72:
               selectModTool(TOOL_HAND);
               break;
            case 71:
               selectModTool(TOOL_GRADIENT);
               break;
            case 86:
               toggleFlipView();
               break;
            case 49:
            case 50:
            case 51:
            case 52:
            case 53:
            case 54:
            case 55:
            case 56:
            case 57:
            case 48:
               _brushOpacity = e.keyCode == 48 ? 1 : (e.keyCode - 48) / 10;
               ArtStudioKit.sliderSet(_opacitySlider,_brushOpacity * 100);
               break;
            case 219:
               setBrushSize(_brushSizeVal - Math.max(1,Math.round(_brushSizeVal * 0.15)));
               break;
            case 221:
               setBrushSize(_brushSizeVal + Math.max(1,Math.round(_brushSizeVal * 0.15)));
               break;
            case 80:
               selectModTool(TOOL_PEN);
               break;
            case 69:
               selectModTool(TOOL_ERASER);
               break;
            case 73:
               selectModTool(TOOL_EYEDROP);
         }
      }
      
      private function onMouseWheel(e:MouseEvent) : void
      {
         var c:Object = null;
         if(e.ctrlKey)
         {
            e.preventDefault();
            e.stopPropagation();
            c = _interfaceObject.loader.content.canvas;
            if(e.delta > 0)
            {
               zoomIn(c.mouseX,c.mouseY);
            }
            else
            {
               zoomOut(c.mouseX,c.mouseY);
            }
         }
      }
      
      private function zoomIn(anchorX:Number = NaN, anchorY:Number = NaN) : void
      {
         var newZoom:Number = _zoomLevel + _zoomStep;
         if(newZoom <= _maxZoom)
         {
            setZoom(newZoom,anchorX,anchorY);
         }
      }
      
      private function zoomOut(anchorX:Number = NaN, anchorY:Number = NaN) : void
      {
         var newZoom:Number = _zoomLevel - _zoomStep;
         if(newZoom >= _minZoom)
         {
            setZoom(newZoom,anchorX,anchorY);
         }
      }
      
      private function resetZoom() : void
      {
         _zoomLevel = 1;
         if(_drawCanvas)
         {
            _drawCanvas.scaleX = _viewFlipped ? -1 : 1;
            _drawCanvas.scaleY = 1;
            _drawCanvas.x = _viewFlipped ? _canvasOriginalX + _canvasW : _canvasOriginalX;
            _drawCanvas.y = _canvasOriginalY;
         }
         updateZoomUI();
      }
      
      // Zooms around an anchor point in canvas-frame coordinates (the pointer
      // for Ctrl+wheel, the middle of the frame otherwise), keeping whatever
      // is under it in place instead of re-centring and losing the pan.
      private function setZoom(zoom:Number, anchorX:Number = NaN, anchorY:Number = NaN) : void
      {
         var ratio:Number = zoom / _zoomLevel;
         if(isNaN(anchorX) || isNaN(anchorY))
         {
            anchorX = _canvasW * 0.5;
            anchorY = _canvasH * 0.5;
         }
         _zoomLevel = zoom;
         if(_drawCanvas)
         {
            _drawCanvas.scaleX = _viewFlipped ? -_zoomLevel : _zoomLevel;
            _drawCanvas.scaleY = _zoomLevel;
            _drawCanvas.x = anchorX - (anchorX - _drawCanvas.x) * ratio;
            _drawCanvas.y = anchorY - (anchorY - _drawCanvas.y) * ratio;
            clampPan();
         }
         updateZoomUI();
      }
      
      private function updateZoomUI() : void
      {
         if(_zoomLabelBtn != null)
         {
            ArtStudioKit.setLabel(_zoomLabelBtn,Math.round(_zoomLevel * 100) + "%");
            ArtStudioKit.setEnabled(_zoomInBtn,_zoomLevel < _maxZoom);
            ArtStudioKit.setEnabled(_zoomOutBtn,_zoomLevel > _minZoom);
         }
      }
      
      private function getAirbrush(dia:int) : Object
      {
         if(_airbrushCache[dia])
         {
            return _airbrushCache[dia];
         }
         var b:Object = {};
         b.diameter = dia;
         b._drawOffSet = Math.floor(dia / 2);
         b._drawTranslateMatrix = new Matrix();
         var s:Shape = new Shape();
         s.graphics.beginFill(16777215,0.15);
         s.graphics.drawCircle(0,0,dia / 2);
         s.graphics.endFill();
         var bmp:BitmapData = new BitmapData(s.width,s.height,true,0);
         var m:Matrix = new Matrix();
         m.tx = s.width / 2;
         m.ty = s.height / 2;
         bmp.draw(s,m);
         b._drawBrushData = bmp;
         _airbrushCache[dia] = b;
         return b;
      }
      
      private function getSmudge(radius:int) : Object
      {
         if(_smudgeCache[radius])
         {
            return _smudgeCache[radius];
         }
         var obj:Object = {};
         obj.radius = radius;
         obj.weightVector = new Vector.<Number>(radius * 2 * radius * 2,true);
         var s:Shape = new Shape();
         var g:Graphics = s.graphics;
         var m:Matrix = new Matrix();
         m.createGradientBox(radius * 2,radius * 2,0,0,0);
         g.beginGradientFill(GradientType.RADIAL,[16777215,16777215],[0.75,0],[0,255],m,SpreadMethod.PAD);
         g.drawCircle(radius,radius,radius);
         g.endFill();
         var bd:BitmapData = new BitmapData(radius * 2,radius * 2,true,0);
         bd.draw(s);
         var vec:Vector.<uint> = bd.getVector(bd.rect);
         var idx:int = 0;
         var y:int = 0;
         while(y < radius * 2)
         {
            var x:int = 0;
            while(x < radius * 2)
            {
               obj.weightVector[idx] = (255 - (vec[idx] >> 24 & 0xFF)) / 255;
               x++;
               idx++;
            }
            y++;
         }
         _smudgeCache[radius] = obj;
         return obj;
      }
      
      private function onToggleLayerClick(e:MouseEvent) : void
      {
         var bmp:Bitmap = _layerBitmaps[_activeLayerIndex] as Bitmap;
         bmp.visible = !bmp.visible;
         refreshLayerPanel(false);
         ArtStudioKit.showTip(_eyeBtn,_eyeBtn.tip);
      }
      
      private function onUploadCancel(e:Event) : void
      {
         _uploadFileRef = null;
      }
      
      private function onUploadSelect(e:Event) : void
      {
         _uploadFileRef.removeEventListener(Event.SELECT,onUploadSelect);
         _uploadFileRef.addEventListener(Event.COMPLETE,onUploadFileLoaded);
         _uploadFileRef.load();
      }
      
      private function onUploadFileLoaded(e:Event) : void
      {
         _uploadFileRef.removeEventListener(Event.COMPLETE,onUploadFileLoaded);
         var loader:Loader = new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onUploadLoaderComplete);
         loader.loadBytes(_uploadFileRef.data);
      }
      
      private function onUploadLoaderComplete(e:Event) : void
      {
         var srcBmp:Bitmap = e.target.content as Bitmap;
         if(srcBmp == null)
         {
            return;
         }
         _placingSrc = srcBmp.bitmapData.clone();
         srcBmp.bitmapData.dispose();
         (e.target as LoaderInfo).loader.unloadAndStop();
         _uploadFileRef = null;
         ArtStudioKit.beginPlace(_drawCanvas,_placingSrc,_canvasW,_canvasH,_layerInterface,494,58,onImagePlaced);
         updateCanvasCursor();
      }
      
      // The imported image is painted over the active layer where it was
      // placed, at the size it was given.
      private function onImagePlaced(m:Matrix) : void
      {
         if(m != null && _layerBitmapDatas != null)
         {
            pushUndo([_activeLayerIndex],false);
            (_layerBitmapDatas[_activeLayerIndex] as BitmapData).draw(_placingSrc,m,null,null,null,true);
            _needsSave = true;
            refreshLayerThumb(_activeLayerIndex);
            syncCanvasButtons();
         }
         if(_placingSrc != null)
         {
            _placingSrc.dispose();
            _placingSrc = null;
         }
         if(_layerMouse != null)
         {
            updateCanvasCursor();
         }
      }
      
      private function scaleAndCropToFill(src:BitmapData, tw:int, th:int) : BitmapData
      {
         var scale:Number = Math.max(tw / src.width,th / src.height);
         var scaledW:int = Math.ceil(src.width * scale);
         var scaledH:int = Math.ceil(src.height * scale);
         var m:Matrix = new Matrix();
         m.scale(scale,scale);
         var tmp:BitmapData = new BitmapData(scaledW,scaledH,src.transparent,0);
         tmp.draw(src,m,null,null,null,true);
         var cropX:int = scaledW - tw >> 1;
         var cropY:int = scaledH - th >> 1;
         var out:BitmapData = new BitmapData(tw,th,src.transparent,0);
         out.copyPixels(tmp,new Rectangle(cropX,cropY,tw,th),new Point(0,0));
         tmp.dispose();
         return out;
      }
      
      private function onStorage_Close() : void
      {
         hideDlg();
         _storageButton.guiBtn.setPressedState(false);
      }
      
      private function onStorage_Save() : void
      {
         onSaveButton();
      }
      
      private function onStorage_Load() : void
      {
         onLoadButton();
      }
      
      private function onStorageButton() : void
      {
         var _loc1_:MovieClip = null;
         if(!_exitConfirmationActive)
         {
            _exitAfterSave = false;
            _loc1_ = showDlg("ArtStudioColor_StorageDlg",[{
               "name":"button_close",
               "f":onStorage_Close
            },{
               "name":"button_save",
               "f":onStorage_Save,
               "grayed":(_needsSave ? "no" : "yes")
            },{
               "name":"button_load",
               "f":onStorage_Load
            }],353,401,true,true);
         }
      }
      
      private function onSketchButton() : void
      {
         if(!_exitConfirmationActive)
         {
            DarkenManager.showLoadingSpiral(true);
            GenericListGuiManager.genericListVolumeClicked(77,{
               "msg":"biggerFrame",
               "width":768,
               "height":432,
               "shouldRepeat":false
            });
         }
      }
      
      private function onPrintButton() : void
      {
         var _loc6_:Sprite = null;
         var _loc5_:Number = Number(NaN);
         var _loc4_:Number = Number(NaN);
         var _loc2_:Number = Number(NaN);
         var _loc3_:Number = Number(NaN);
         var _loc1_:Object = null;
         if(!_exitConfirmationActive && _hasDrawn)
         {
            _loc6_ = _drawCanvas;
            _loc5_ = _loc6_.x;
            _loc4_ = _loc6_.y;
            _loc2_ = _loc6_.scaleX;
            _loc3_ = _loc6_.scaleY;
            _loc1_ = _loc6_.parent;
            _loc1_.removeChild(_loc6_);
            _loc6_.x = 170;
            _loc6_.y = 240;
            super.printOnePerPage(_loc6_,20,20,_printBackground,"portrait");
            _loc1_.addChild(_loc6_);
            _loc6_.x = _loc5_;
            _loc6_.y = _loc4_;
            _loc6_.scaleX = _loc2_;
            _loc6_.scaleY = _loc3_;
         }
      }
      
      private function onCloseButton() : void
      {
         if(!_exitConfirmationActive)
         {
            _exitConfirmationActive = true;
            if(_needsSave)
            {
               _exitAfterSave = true;
               showDlg("ArtStudioColor_SaveExitDlg",[{
                  "name":"button_close",
                  "f":onExit_No
               },{
                  "name":"button_save",
                  "f":onExit_Save
               },{
                  "name":"button_exit",
                  "f":onExit_Yes
               }],450,275,true,true);
            }
            else
            {
               showDlg("ArtStudioColor_ExitDlg",[{
                  "name":"button_yes",
                  "f":onExit_Yes
               },{
                  "name":"button_no",
                  "f":onExit_No
               }],450,275,true,true);
            }
         }
      }
      
      private function onSubmitButton() : void
      {
         var _loc1_:MovieClip = null;
         if(!_exitConfirmationActive && _hasDrawn)
         {
            _exitConfirmationActive = true;
            _loc1_ = showDlg("ArtStudioColor_SubmitDlg",[{
               "name":"button_yes",
               "f":onSubmit_Yes
            },{
               "name":"button_no",
               "f":onExit_No
            }],450,275,true,true);
         }
      }
      
      private function onCreateMasterpieceBtn() : void
      {
         if(!_exitConfirmationActive && _hasDrawn)
         {
            if(_chooseMasterpiecePopup)
            {
               onChooseMasterpiecePopupLoaded(null);
            }
            else
            {
               _mediaHelper = new MediaHelper();
               _mediaHelper.init(4811,onChooseMasterpiecePopupLoaded);
            }
         }
      }
      
      private function onClearAllButton() : void
      {
         var _loc1_:MovieClip = null;
         if(!_exitConfirmationActive)
         {
            _exitConfirmationActive = true;
            _loc1_ = showDlg("ArtStudioColor_ClearDlg",[{
               "name":"button_yes",
               "f":onClear_Yes
            },{
               "name":"button_no",
               "f":onExit_No
            }],450,275,true,true);
         }
      }
      
      private function setNumMasterpieceIcons() : void
      {
         var _loc2_:int = 0;
         var _loc1_:DenItemCollection = gMainFrame.userInfo.playerAvatarInfo.denItems;
         _numMasterpieceTokens = 0;
         if(_loc1_ && _loc1_.length > 0)
         {
            _loc1_ = Utility.discardDefaultAudioItem(_loc1_);
            _loc2_ = 0;
            while(_loc2_ < _loc1_.length)
            {
               if(_loc1_.getDenItem(_loc2_).defId == 2947)
               {
                  ++_numMasterpieceTokens;
               }
               _loc2_++;
            }
         }
      }
      
      private function onChooseMasterpiecePopupLoaded(param1:MovieClip) : void
      {
         if(param1)
         {
            _chooseMasterpiecePopup = param1.getChildAt(0) as MovieClip;
            _chooseMasterpiecePopup.x = 450;
            _chooseMasterpiecePopup.y = 275;
            _chooseMasterpiecePopup.bx.addEventListener("mouseDown",onChooseMasterpiecePopupClose,false,0,true);
            _chooseMasterpiecePopup.arrowLBtn.addEventListener("mouseDown",onLeftRightMasterpiece,false,0,true);
            _chooseMasterpiecePopup.arrowRBtn.addEventListener("mouseDown",onLeftRightMasterpiece,false,0,true);
            _masterpiecePreviewIconStrIds = MasterpiecePreview.masterpiecePreviewIconStrIds;
            _masterpiecePreviewIconIdsOrdered = MasterpiecePreview.masterpiecePreviewIconIdsOrdered;
            if(_masterpiecePreviewIconIds == null || _masterpiecePreviewIconIds.length == 0)
            {
               GenericListXtCommManager.requestGenericList(416,onMasterpieceIconList);
            }
         }
         setupMasterpieceWindows();
         _guiLayer.addChild(_chooseMasterpiecePopup);
         DarkenManager.darken(_chooseMasterpiecePopup);
      }
      
      private function onMasterpieceIconList(param1:int, param2:Array, param3:Array) : void
      {
         _masterpiecePreviewIconIds = param2;
         _masterpiecePreviewIconStrIds = param3;
         MasterpiecePreview.masterpiecePreviewIconStrIds = param3;
         if(_masterpiecePreviewIconIdsOrdered == null || _masterpiecePreviewIconIdsOrdered.length == 0)
         {
            GenericListXtCommManager.requestGenericList(424,onMasterpieceIconOrderListLoaded);
         }
         else
         {
            setupMasterpieceWindows();
         }
      }
      
      private function onMasterpieceIconOrderListLoaded(param1:int, param2:Array, param3:Array) : void
      {
         _masterpiecePreviewIconIdsOrdered = param2;
         MasterpiecePreview.masterpiecePreviewIconIdsOrdered = param2;
         setupMasterpieceWindows();
      }
      
      private function setupMasterpieceWindows() : void
      {
         var _loc1_:int = 0;
         setNumMasterpieceIcons();
         _loc1_ = 0;
         while(_loc1_ < 4)
         {
            clearOutItemLayer(_chooseMasterpiecePopup["iw" + _loc1_]);
            _chooseMasterpiecePopup["iw" + _loc1_].tag.visible = false;
            _chooseMasterpiecePopup["iw" + _loc1_].frameNameCont.visible = false;
            _chooseMasterpiecePopup["iw" + _loc1_].newTag.visible = false;
            if(_masterpiecePreviewIconIds)
            {
               if(_masterpiecePreviewIconIds[_loc1_ + _itemOffset])
               {
                  if(_masterpiecePreviewIcons && _masterpiecePreviewIcons[_loc1_ + _itemOffset])
                  {
                     setupCurrIconAndBitmap(_loc1_);
                  }
                  else
                  {
                     new LoadingSpiral(_chooseMasterpiecePopup["iw" + _loc1_].itemLayer);
                     _mediaHelper = new MediaHelper();
                     _mediaHelper.init(_masterpiecePreviewIconIds[_loc1_ + _itemOffset],onMasterpieceIconLoaded,{
                        "index":_loc1_,
                        "offset":_itemOffset
                     });
                     _iconMediaHelpers[_loc1_ + _itemOffset] = _mediaHelper;
                  }
               }
            }
            else
            {
               new LoadingSpiral(_chooseMasterpiecePopup["iw" + _loc1_].itemLayer);
            }
            _loc1_++;
         }
      }
      
      private function clearOutItemLayer(param1:MovieClip) : void
      {
         var _loc2_:MovieClip = null;
         if(param1)
         {
            while(param1.itemLayer.numChildren > 0)
            {
               _loc2_ = param1.itemLayer.getChildAt(param1.itemLayer.numChildren - 1);
               if(_loc2_ is LoadingSpiral)
               {
                  (_loc2_ as LoadingSpiral).destroy();
               }
               while(param1.itemLayer.numChildren > 0)
               {
                  param1.itemLayer.removeChildAt(param1.itemLayer.numChildren - 1);
               }
            }
         }
      }
      
      private function setupCurrIconAndBitmap(param1:int) : void
      {
         var _loc4_:MovieClip = null;
         var _loc6_:MovieClip = null;
         var _loc5_:Bitmap = null;
         var _loc2_:Object = null;
         var _loc3_:Boolean = false;
         if(_masterpiecePreviewIcons[param1 + _itemOffset])
         {
            _loc4_ = _masterpiecePreviewIcons[param1 + _itemOffset];
            while(_loc4_.itemWindow.numChildren > 1)
            {
               _loc4_.itemWindow.removeChildAt(_loc4_.itemWindow.numChildren - 1);
            }
            _loc6_ = _chooseMasterpiecePopup["iw" + param1];
            var fullBmp:BitmapData = getCompositeBitmapData(true);
            var resizedUserBmp:BitmapData = Utility.resizeImage(fullBmp,_loc4_.itemWindow.width,_loc4_.itemWindow.height,true);
            fullBmp.dispose();
            _loc5_ = new Bitmap(resizedUserBmp,"auto",true);
            _loc5_.x = -_loc5_.width * 0.5;
            _loc5_.y = -_loc5_.height * 0.5;
            _loc4_.itemWindow.addChild(_loc5_);
            (_loc4_.nameBar as GuiSoundButton).setTextInLayer(gMainFrame.userInfo.myUserName,"name_txt");
            _loc4_.nameBar.mouseChildren = false;
            _loc4_.nameBar.mouseEnabled = false;
            _loc4_.report_btn.visible = false;
            _loc4_.likeBtn.visible = false;
            _loc6_.frameNameCont.visible = true;
            _loc6_.tag.visible = true;
            _loc6_.newTag.visible = _itemOffset == 0 && (param1 == 0 || param1 == 1);
            LocalizationManager.translateId(_loc6_.frameNameCont.frameTxt,_masterpiecePreviewIconStrIds[param1 + _itemOffset]);
            _loc2_ = DiamondXtCommManager.getDiamondDef(221);
            _loc3_ = UserCurrency.hasEnoughCurrency(3,_loc2_.value) || _numMasterpieceTokens > 0;
            if(!_loc3_)
            {
               if(_loc6_.tag.currentFrameLabel != "diamondred")
               {
                  _loc6_.tag.gotoAndPlay("diamondred");
               }
               _loc6_.tag.txt.textColor = "0x800000";
            }
            else
            {
               if(_loc6_.tag.currentFrameLabel != "diamondgreen")
               {
                  _loc6_.tag.gotoAndPlay("diamondgreen");
               }
               _loc6_.tag.txt.textColor = "0x386630";
            }
            _loc6_.tag.txt.text = Utility.convertNumberToString(_loc2_.value);
            clearOutItemLayer(_loc6_);
            if("frame" in _loc4_)
            {
               _loc4_.frame.filters = [FRAME_SELECT_FILTER_DARKER,FRAME_SELECT_FILTER_LIGHTER];
               _loc6_.itemLayer.filters = null;
            }
            else if(_loc6_.itemLayer.filters == null || _loc6_.itemLayer.filters.length == 0)
            {
               _loc6_.itemLayer.filters = [FRAME_SELECT_FILTER_DARKER,FRAME_SELECT_FILTER_LIGHTER];
            }
            _loc6_.itemLayer.addChild(_loc4_);
            _loc6_.currIcon = _loc4_;
            _loc6_.index = param1;
            _loc6_.addEventListener("mouseDown",onPreviewIcon,false,0,true);
            _loc6_.addEventListener("mouseOver",onPreviewIconOver,false,0,true);
            _loc6_.addEventListener("mouseOut",onPreviewIconOut,false,0,true);
         }
      }
      
      private function onPreviewIcon(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         param1.stopPropagation();
         _currPreviewIndex = param1.currentTarget.index;
         _loc2_ = 0;
         while(_loc2_ < _masterpiecePreviewIconIdsOrdered.length)
         {
            if(_masterpiecePreviewIconIdsOrdered[_loc2_] == _masterpiecePreviewIconIds[_currPreviewIndex + _itemOffset])
            {
               _currItemVersion = _loc2_;
               break;
            }
            _loc2_++;
         }
         var fullBmp:BitmapData = getCompositeBitmapData(true);
         _masterpiecePreviewPopup = new MasterpiecePreview(_guiLayer,_numMasterpieceTokens,"",gMainFrame.userInfo.myUserName,gMainFrame.clientInfo.dbUserId,gMainFrame.userInfo.myUUID,_currItemVersion,onPreviewClose,gMainFrame.userInfo.myUserName,null,new Bitmap(fullBmp,"auto",true),true);
         onPreviewIconOut(param1);
      }
      
      private function onPreviewIconOver(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if("frame" in param1.currentTarget.currIcon && param1.currentTarget.currIcon.frame.filters.length > 0)
         {
            param1.currentTarget.currIcon.frame.filters = null;
         }
         param1.currentTarget.itemLayer.filters = [FRAME_SELECT_FILTER_MOUSE_OVER];
         if(param1.currentTarget.currentFrameLabel != "mouse")
         {
            param1.currentTarget.gotoAndPlay("mouse");
         }
         param1.currentTarget.currIcon.nameBar.visible = false;
         AJAudio.playSubMenuBtnRollover();
      }
      
      private function onPreviewIconOut(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(param1.currentTarget.currentFrameLabel != "out")
         {
            param1.currentTarget.gotoAndPlay("out");
         }
         if("frame" in param1.currentTarget.currIcon)
         {
            param1.currentTarget.currIcon.frame.filters = [FRAME_SELECT_FILTER_DARKER,FRAME_SELECT_FILTER_LIGHTER];
            param1.currentTarget.itemLayer.filters = null;
         }
         else
         {
            param1.currentTarget.itemLayer.filters = [FRAME_SELECT_FILTER_DARKER,FRAME_SELECT_FILTER_LIGHTER];
         }
         param1.currentTarget.currIcon.nameBar.visible = true;
      }
      
      private function onPreviewClose(param1:Boolean) : void
      {
         var _loc2_:MovieClip = null;
         if(param1)
         {
            if(Utility.numDenItemsInList(gMainFrame.userInfo.playerUserInfo.denItemsFull,0) < ShopManager.maxDenItems)
            {
               askCopyCount();
            }
            else
            {
               new SBYesNoPopup(_guiLayer,LocalizationManager.translateIdOnly(14746),true,confirmRecycleHandler,4);
            }
         }
         else
         {
            if(_masterpiecePreviewPopup)
            {
               _masterpiecePreviewPopup.destroy();
               _masterpiecePreviewPopup = null;
            }
            clearOutItemLayer(_chooseMasterpiecePopup["iw" + _currPreviewIndex]);
            _loc2_ = _masterpiecePreviewIcons[_currPreviewIndex + _itemOffset];
            _chooseMasterpiecePopup["iw" + _currPreviewIndex].itemLayer.addChild(_loc2_);
            if("frame" in _loc2_)
            {
               _loc2_.frame.filters = [FRAME_SELECT_FILTER_DARKER,FRAME_SELECT_FILTER_LIGHTER];
            }
         }
      }
      
      private function onSubmissionRulesClose(param1:Boolean, param2:Boolean) : void
      {
         _submissionRules.destroy();
         _submissionRules = null;
         _isUsingTokens = param2;
         if(!param1)
         {
            stopCopies();
         }
         if(param1)
         {
            capCopiesToFunds();
            DarkenManager.showLoadingSpiral(true);
            DenXtCommManager.requestBuy(true,0,221,onPreviewItemBuy,onPreviewBuyInventoryResponse,0,null,_currItemVersion,1,true,_isUsingTokens,_masterpieceUuid);
         }
         else if(param2)
         {
            setupRequest(null,null,20,0,param2,1,false);
         }
         onPreviewClose(false);
      }
      
      private function confirmRecycleHandler(param1:Object) : void
      {
         var _loc2_:int = int(param1.passback);
         if(param1.status)
         {
            _recyclePopup = new RecycleItems();
            _recyclePopup.init(_loc2_,_guiLayer,true,onRecycleClose,900 * 0.5,550 * 0.5,true);
         }
         else if(_masterpiecePreviewPopup)
         {
            _masterpiecePreviewPopup.closeCallback = onPreviewClose;
         }
      }
      
      private function onRecycleClose(param1:Boolean = false) : void
      {
         if(_recyclePopup)
         {
            _recyclePopup.destroy();
            _recyclePopup = null;
         }
         if(param1)
         {
            setNumMasterpieceIcons();
            onPreviewClose(true);
         }
         else if(_masterpiecePreviewPopup)
         {
            _masterpiecePreviewPopup.closeCallback = onPreviewClose;
         }
      }
      
      private function onPreviewItemBuy(param1:int, param2:int, param3:int) : void
      {
         if(param1 == 1)
         {
            if(_copiesDone == 0)
            {
               onChooseMasterpiecePopupClose(null);
            }
            UserCurrency.setCurrency(param2,3);
            _denPreviewInvId = param3;
         }
         else
         {
            DarkenManager.showLoadingSpiral(false);
            new SBOkPopup(_guiLayer,LocalizationManager.translateIdOnly(14798));
            ItemXtCommManager.setItemBuyIlCallback(null);
            _denPreviewInvId = 0;
            stopCopies();
         }
      }
      
      private function onPreviewBuyInventoryResponse() : void
      {
         _copiesDone++;
         if(_copiesDone < _copiesWanted)
         {
            _denPreviewInvId = 0;
            DenXtCommManager.denEditorDIResponseCallback = null;
            showCopyBanner("Buying copies... " + _copiesDone + " of " + _copiesWanted + " done");
            setTimeout(nextCopy,COPY_GAP_MS);
            return;
         }
         finishCopies();
         var _loc3_:DenItem = null;
         var _loc2_:int = 0;
         DarkenManager.showLoadingSpiral(false);
         var _loc1_:DenItemCollection = gMainFrame.userInfo.playerUserInfo.denItemsFull;
         _loc2_ = 0;
         while(_loc2_ < _loc1_.length)
         {
            if(_loc1_.getDenItem(_loc2_).invIdx == _denPreviewInvId)
            {
               _loc3_ = _loc1_.getDenItem(_loc2_);
            }
            _loc2_++;
         }
         if(_loc3_)
         {
            _loc3_ = _loc3_.clone() as DenItem;
            _loc3_.initShopItem(_loc3_.defId,_loc3_.version);
            _itemReceivedPopup = new ItemReceivedPopup(_loc3_,_guiLayer,onItemReceivedClose);
         }
         _denPreviewInvId = 0;
         DenXtCommManager.denEditorDIResponseCallback = null;
      }
      
      private function onItemReceivedClose() : void
      {
         _itemReceivedPopup.destroy();
         _itemReceivedPopup = null;
         onPreviewClose(false);
         finishFeedbackSend();
      }
      
      private function onMasterpieceIconLoaded(param1:MovieClip) : void
      {
         if(_masterpiecePreviewIcons == null)
         {
            _masterpiecePreviewIcons = [];
         }
         _masterpiecePreviewIcons[param1.passback.index + param1.passback.offset] = param1.getChildAt(0) as MovieClip;
         setupCurrIconAndBitmap(param1.passback.index);
      }
      
      private function onChooseMasterpiecePopupClose(param1:MouseEvent) : void
      {
         if(param1)
         {
            param1.stopPropagation();
         }
         DarkenManager.unDarken(_chooseMasterpiecePopup);
         _guiLayer.removeChild(_chooseMasterpiecePopup);
      }
      
      private function onLeftRightMasterpiece(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(!param1.currentTarget.isGray)
         {
            if(param1.currentTarget == _chooseMasterpiecePopup.arrowLBtn)
            {
               if(_itemOffset == 0)
               {
                  _loc2_ = _masterpiecePreviewIconIds.length % 4;
                  if(_loc2_ != 0)
                  {
                     _itemOffset = _masterpiecePreviewIconIds.length - _loc2_;
                  }
                  else
                  {
                     _itemOffset = _masterpiecePreviewIconIds.length - 4;
                  }
               }
               else
               {
                  _itemOffset -= 4;
               }
            }
            else if(_itemOffset + 4 < _masterpiecePreviewIconIds.length)
            {
               _itemOffset += 4;
            }
            else
            {
               _itemOffset = 0;
            }
            setupMasterpieceWindows();
         }
      }
      
      private function encodeImage() : void
      {
         DarkenManager.showLoadingSpiral(true,true);
         _jpgEncoder = new JpegAsynchEncoder();
         _jpgEncoder.addEventListener("JPEGAsyncComplete",asyncEncodingComplete,false,0,true);
         _jpgEncoder.addEventListener("progress",onEncodingProgress,false,0,true);
         _jpgEncoder.PixelsPerIteration = 128;
         _jpgEncoder.JPEGAsyncEncoder(90);
         _encodingBitmapData = getCompositeBitmapData(true);
         _jpgEncoder.encode(_encodingBitmapData);
      }
      
      private function onSubmit_Yes() : void
      {
         _isMasterpieceSubmit = false;
         encodeImage();
      }
      
      private function asyncEncodingComplete(param1:JPEGAsyncCompleteEvent) : void
      {
         var _loc2_:Array = null;
         var _loc3_:* = false;
         var _loc4_:Date = null;
         var _loc5_:Number = Number(NaN);
         _jpgEncoder.removeEventListener("JPEGAsyncComplete",asyncEncodingComplete);
         _jpgEncoder.removeEventListener("progress",onEncodingProgress);
         if(_encodingBitmapData != null)
         {
            _encodingBitmapData.dispose();
            _encodingBitmapData = null;
         }
         if(_isMasterpieceSubmit)
         {
            _URLStatus = 0;
            startSubmitWatchdog(TOKEN_TIMEOUT_MS);
            _loc2_ = [];
            _loc2_[0] = "gmtkn";
            _loc2_[1] = "0";
            _loc2_[2] = "1";
            MinigameManager.msg(_loc2_);
         }
         else
         {
            _loc3_ = false;
            if(_sharedObject != null)
            {
               if(_sharedObject.data.userSubmits.length == 5)
               {
                  _loc4_ = new Date();
                  _loc5_ = Number(_loc4_.getTime());
                  _loc5_ -= _sharedObject.data.userSubmits[0];
                  _loc5_ = _loc5_ / 1000 / 60 / 60;
                  _loc3_ = _loc5_ >= 24;
               }
               else
               {
                  _loc3_ = true;
               }
            }
            if(_loc3_)
            {
               setupRequest(onSendComplete,onSendError,14,0,false,0);
            }
            else
            {
               SBTracker.trackPageview("/game/play/miniGame/#ColoringSendFiltered");
               finishFeedbackSend();
            }
         }
      }
      
      private function onEncodingProgress(param1:ProgressEvent) : void
      {
         DarkenManager.updateLoadingSpiralPercentage(Math.round(param1.bytesLoaded / param1.bytesTotal * 100) + "%");
      }
      
      private function onClear_Yes() : void
      {
         handleClear();
         hideDlg();
         _exitConfirmationActive = false;
      }
      
      private function handleClear() : void
      {
         var k:int = 0;
         if(_layerBitmapDatas == null)
         {
            return;
         }
         if(_hasDrawn)
         {
            pushUndo(allLayerIndices(),false);
         }
         k = 0;
         while(k < _layerBitmapDatas.length)
         {
            (_layerBitmapDatas[k] as BitmapData).fillRect(_drawBitmapDataRect,0);
            k++;
         }
         _timeSinceErase = 0;
         _needsSave = false;
         refreshLayerPanel(true);
         syncCanvasButtons();
      }
      
      // Flattens the visible layers at their opacity and blend mode.
      // opaque=true puts them on white, which is what a masterpiece is: the
      // JPEG encoder ignores alpha, so transparent pixels would otherwise
      // come out black.
      private function getCompositeBitmapData(opaque:Boolean = false) : BitmapData
      {
         var composite:BitmapData = opaque ? new BitmapData(_canvasW,_canvasH,false,16777215) : new BitmapData(_canvasW,_canvasH,true,0);
         var bmp:Bitmap = null;
         var i:int = 0;
         while(i < _layerBitmapDatas.length)
         {
            bmp = _layerBitmaps[i] as Bitmap;
            if(bmp != null && bmp.visible && _layerOpacities[i] > 0)
            {
               composite.draw(_layerBitmapDatas[i],null,_layerOpacities[i] < 1 ? new ColorTransform(1,1,1,_layerOpacities[i]) : null,_layerBlends[i],null,false);
            }
            i++;
         }
         return composite;
      }
      
      private function onExit_Save() : void
      {
         onSaveButton();
      }
      
      private function onExit_Yes() : void
      {
         Mouse.show();
         hideDlg();
         _exitConfirmationActive = false;
         end(null);
      }
      
      private function onExit_No() : void
      {
         hideDlg();
         _exitConfirmationActive = false;
      }
      
      public function setupRequest(param1:Function, param2:Function, param3:int, param4:int, param5:Boolean, param6:int, param7:Boolean = true) : void
      {
         var _loc11_:Object = null;
         var _loc9_:URLRequest = null;
         var _loc10_:URLLoader = null;
         var _loc8_:String = "---------------------------" + Math.floor(Math.random() * 100000000000000);
         if(param3 == 14)
         {
            _loc11_ = {
               "avatarName":gMainFrame.userInfo.playerAvatarInfo.unlocalizedAvName,
               "type":param3,
               "message":_timeSinceErase,
               "languageId":LocalizationManager.currentLanguage,
               "previewItemInvIndex":param4,
               "secondaryType":(param5 ? "1" : "0"),
               "tag":(param6 == 0 ? "" : param6),
               "userName":gMainFrame.userInfo.myUserName
            };
            _loc9_ = new URLRequest(gMainFrame.clientInfo.mdUrl + "fb");
         }
         else
         {
            _loc11_ = {"authToken":(_masterPieceSubmissionToken == null ? "" : _masterPieceSubmissionToken)};
            _loc9_ = new URLRequest(gMainFrame.clientInfo.mdUrl + "mp");
         }
         _loc9_.requestHeaders.push(new URLRequestHeader("Cache-Control","no-cache"));
         _loc9_.requestHeaders.push(new URLRequestHeader("Content-Type","multipart/form-data; boundary=" + _loc8_));
         _loc9_.method = "POST";
         _loc9_.data = createPostData("ArtStudioImage",param7 && _jpgEncoder != null ? _jpgEncoder.ImageData : null,_loc8_,_loc11_);
         _loc10_ = new URLLoader();
         _loc10_.dataFormat = "binary";
         if(param1 != null)
         {
            _loc10_.addEventListener("complete",param1);
            _uploadLoader = _loc10_;
         }
         if(param2 != null)
         {
            _loc10_.addEventListener("ioError",param2);
            _loc10_.addEventListener("securityError",param2);
            _loc10_.addEventListener("httpStatus",httpStatusHandler);
         }
         try
         {
            _loc10_.load(_loc9_);
         }
         catch(e:Error)
         {
            DebugUtility.debugTrace(e.message);
            if(param1 != null)
            {
               param2(null);
            }
         }
      }
      
      public function createPostData(param1:String, param2:ByteArray, param3:String, param4:Object = null) : ByteArray
      {
         var _loc5_:String = null;
         var _loc7_:int = 0;
         var _loc8_:ByteArray = new ByteArray();
         _loc8_.endian = "bigEndian";
         if(param4 == null)
         {
            param4 = {};
         }
         var _formFieldCount:int = 0;
         for(var _loc6_ in param4)
         {
            _formFieldCount++;
            var _fieldValue:String = param4[_loc6_];
            writeBoundary(_loc8_,param3);
            writeLineBreak(_loc8_);
            _loc5_ = "Content-Disposition: form-data; name=\"" + _loc6_ + "\"";
            _loc7_ = 0;
            while(_loc7_ < _loc5_.length)
            {
               _loc8_.writeByte(_loc5_.charCodeAt(_loc7_));
               _loc7_++;
            }
            writeLineBreak(_loc8_);
            writeLineBreak(_loc8_);
            _loc8_.writeUTFBytes(param4[_loc6_]);
            writeLineBreak(_loc8_);
         }
         if(param2)
         {
            writeBoundary(_loc8_,param3);
            writeLineBreak(_loc8_);
            _loc5_ = "Content-Disposition: form-data; name=\"image\"; filename=\"" + param1 + "\"";
            _loc7_ = 0;
            while(_loc7_ < _loc5_.length)
            {
               _loc8_.writeByte(_loc5_.charCodeAt(_loc7_));
               _loc7_++;
            }
            writeLineBreak(_loc8_);
            _loc5_ = "Content-Type: image/jpeg";
            _loc7_ = 0;
            while(_loc7_ < _loc5_.length)
            {
               _loc8_.writeByte(_loc5_.charCodeAt(_loc7_));
               _loc7_++;
            }
            writeLineBreak(_loc8_);
            writeLineBreak(_loc8_);
            _loc8_.writeBytes(param2);
            writeLineBreak(_loc8_);
         }
         writeBoundary(_loc8_,param3);
         writeDoubleDash(_loc8_);
         writeLineBreak(_loc8_);
         return _loc8_;
      }
      
      private function writeLineBreak(param1:ByteArray) : void
      {
         param1.writeShort(3338);
      }
      
      private function writeDoubleDash(param1:ByteArray) : void
      {
         param1.writeShort(11565);
      }
      
      private function writeBoundary(param1:ByteArray, param2:String) : void
      {
         var _loc3_:int = 0;
         writeDoubleDash(param1);
         _loc3_ = 0;
         while(_loc3_ < param2.length)
         {
            param1.writeByte(param2.charCodeAt(_loc3_));
            _loc3_++;
         }
      }
      
      private function onSendComplete(param1:Event) : void
      {
         var _loc4_:ByteArray = null;
         var _loc3_:Object = null;
         var _loc2_:Date = null;
         _uploadLoader = null;
         if(_isMasterpieceSubmit)
         {
            if(!_submitPending)
            {
               return;
            }
            _submitPending = false;
            stopSubmitWatchdog();
            DarkenManager.showLoadingSpiral(false);
            param1.currentTarget.data.position = 0;
            _loc4_ = param1.currentTarget.data;
            if(_loc4_ && _loc4_.length > 0)
            {
               try
               {
                  _loc3_ = JSON.parse(_loc4_.readMultiByte(_loc4_.bytesAvailable,"utf-8"));
                  if(_loc3_ && _loc3_.success)
                  {
                     _masterpieceUuid = _loc3_.uuid;
                     setNumMasterpieceIcons();
                     if(_copiesDone > 0)
                     {
                        buyCurrentCopy();
                        return;
                     }
                     _submissionRules = new SubmissionRulesPopup(DiamondXtCommManager.getDiamondDef(221).value,_numMasterpieceTokens,_guiLayer,onSubmissionRulesClose);
                     SBTracker.trackPageview("/game/play/miniGame/#MasterpiceSubmitted");
                     return;
                  }
               }
               catch(e:Error)
               {
               }
            }
            displayMasterpieceFailedPopup();
            SBTracker.trackPageview("/game/play/miniGame/#ColoringMasterpieceSendError");
         }
         else
         {
            if(_sharedObject != null)
            {
               _loc2_ = new Date();
               _sharedObject.data.userSubmits.push(_loc2_.getTime());
               while(_sharedObject.data.userSubmits.length > 5)
               {
                  _sharedObject.data.userSubmits.shift();
               }
               try
               {
                  _sharedObject.flush();
               }
               catch(e:Error)
               {
               }
            }
            SBTracker.trackPageview("/game/play/miniGame/#ColoringSubmitted");
            finishFeedbackSend();
         }
      }
      
      private function finishFeedbackSend() : void
      {
         handleClear();
         DarkenManager.showLoadingSpiral(false);
         hideDlg();
         var _loc1_:MovieClip = showDlg("ArtStudioColor_SubmitConfirmDlg",[{
            "name":"button_yes",
            "f":onExit_No
         }],450,275,true,true);
      }
      
      private function displayMasterpieceFailedPopup() : void
      {
         stopCopies();
         DarkenManager.showLoadingSpiral(false);
         new SBOkPopup(_guiLayer,LocalizationManager.translateIdOnly(25198));
         if(_masterpiecePreviewPopup)
         {
            _masterpiecePreviewPopup.closeCallback = onPreviewClose;
         }
      }
      
      private function httpStatusHandler(param1:HTTPStatusEvent) : void
      {
         _URLStatus = param1.status;
      }
      
      private function onSendError(param1:Event) : void
      {
         _uploadLoader = null;
         if(_isMasterpieceSubmit)
         {
            if(!_submitPending)
            {
               return;
            }
            _submitPending = false;
            stopSubmitWatchdog();
         }
         DarkenManager.showLoadingSpiral(false);
         if(_isMasterpieceSubmit)
         {
            stopCopies();
            if(_URLStatus == 403)
            {
               new SBOkPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(28329));
               SBTracker.trackPageview("/game/play/miniGame/#ColoringMasterpieceSendErrorBanned");
            }
            else
            {
               displayMasterpieceFailedPopup();
               SBTracker.trackPageview("/game/play/miniGame/#ColoringMasterpieceSendError");
            }
         }
         else
         {
            SBTracker.trackPageview("/game/play/miniGame/#ColoringSendError");
            finishFeedbackSend();
         }
      }
      
      private function handleSaveComplete(param1:Event) : void
      {
         _needsSave = false;
         if(_exitAfterSave)
         {
            onExit_Yes();
         }
         else
         {
            _storageButton.guiBtn.setPressedState(false);
            hideDlg();
         }
      }
      
      private function onSaveButton() : void
      {
         var fr:FileReference = null;
         var mergedBD:BitmapData = null;
         var pngBytes:ByteArray = null;
         try
         {
            mergedBD = getCompositeBitmapData(false);
            pngBytes = PNGEncoder.encode(mergedBD);
            pngBytes = _mediaObject["%&"](gMainFrame.userInfo.myUUID,pngBytes,true);
            fr = new FileReference();
            fr.addEventListener(Event.COMPLETE,handleSaveComplete);
            fr.save(pngBytes,"painting.ajart");
         }
         catch(e:Error)
         {
         }
         if(mergedBD != null)
         {
            mergedBD.dispose();
         }
      }
      
      private function handleLoadError(param1:int) : void
      {
         hideDlg();
         _storageButton.guiBtn.setPressedState(false);
         new SBOkPopup(GuiManager.guiLayer,LocalizationManager.translateIdOnly(param1),true);
      }
      
      private function handleLoad(param1:Event) : void
      {
         var incomingBD:BitmapData = null;
         var targetLayer:BitmapData = null;
         try
         {
            incomingBD = (param1.target.content as Bitmap).bitmapData;
            if(incomingBD == null)
            {
               throw new Error("Unable to load AJART as BitmapData");
            }
            pushUndo([_activeLayerIndex],false);
            targetLayer = _layerBitmapDatas[_activeLayerIndex];
            targetLayer.copyPixels(incomingBD,incomingBD.rect,new Point(0,0));
            _needsSave = false;
            refreshLayerThumb(_activeLayerIndex);
            syncCanvasButtons();
            hideDlg();
            _storageButton.guiBtn.setPressedState(false);
         }
         catch(e:Error)
         {
            handleLoadError(25320);
         }
      }
      
      private function onFileLoaded(param1:Event) : void
      {
         var _loc5_:FileReference = null;
         var _loc2_:ByteArray = null;
         var _loc3_:ByteArray = null;
         var _loc4_:Loader = null;
         try
         {
            _loc5_ = param1.target as FileReference;
            _loc2_ = _loc5_["data"];
            _loc3_ = new ByteArray();
            _loc3_.writeObject(_loc2_);
            try
            {
               _loc2_ = _mediaObject["%&"](gMainFrame.userInfo.myUUID,_loc2_,false);
            }
            catch(e:Error)
            {
               _loc2_ = null;
            }
            if(_loc2_ == null)
            {
               handleLoadError(25320);
            }
            if(_loc2_ != null)
            {
               _loc4_ = new Loader();
               _loc4_.contentLoaderInfo.addEventListener("complete",handleLoad);
               _loc4_.loadBytes(_loc2_);
            }
         }
         catch(e:Error)
         {
            handleLoadError(25320);
         }
      }
      
      private function selectHandler(param1:Event) : void
      {
         try
         {
            _fileRef.addEventListener("complete",onFileLoaded);
            _fileRef.load();
         }
         catch(e:Error)
         {
            handleLoadError(25320);
         }
      }
      
      private function onLoadButton() : void
      {
         var _loc2_:Array = null;
         var _loc1_:FileFilter = null;
         try
         {
            _fileRef = new FileReference();
            _fileRef.addEventListener("select",selectHandler);
            _loc2_ = [];
            _loc1_ = new FileFilter("AJArt Files (*.ajart)","*.*");
            _loc2_.push(_loc1_);
            _fileRef.browse(_loc2_);
         }
         catch(e:Error)
         {
         }
      }
      
      private function onUndoClick(e:MouseEvent) : void
      {
         var st:Object = null;
         if(_undoStack.length == 0 || _drawing)
         {
            return;
         }
         st = _undoStack.pop();
         _redoStack.push(captureState(st.idx,st.props));
         applyState(st);
         updateUndoRedoUI();
      }
      
      private function onRedoClick(e:MouseEvent) : void
      {
         var st:Object = null;
         if(_redoStack.length == 0 || _drawing)
         {
            return;
         }
         st = _redoStack.pop();
         _undoStack.push(captureState(st.idx,st.props));
         applyState(st);
         updateUndoRedoUI();
      }
      
      private function updateUndoRedoUI() : void
      {
         ArtStudioKit.setEnabled(_undoBtn,_undoStack.length > 0);
         ArtStudioKit.setEnabled(_redoBtn,_redoStack.length > 0);
      }
      
      private function updateLayerVisuals() : void
      {
         var i:int = 0;
         var layerBmp:Bitmap = null;
         while(i < _layerBitmaps.length)
         {
            layerBmp = _layerBitmaps[i] as Bitmap;
            if(layerBmp)
            {
               layerBmp.alpha = _layerOpacities[i];
               layerBmp.blendMode = _layerBlends[i];
            }
            i++;
         }
      }
      
      // Submitting waits on two replies (the gmtkn token over the game socket,
      // then the jammercentral upload). Neither had a timeout, so a reply that
      // never came left the loading spiral up for good.
      private function startSubmitWatchdog(ms:int) : void
      {
         stopSubmitWatchdog();
         _submitPending = true;
         _submitTimer = setTimeout(onSubmitTimeout,ms);
      }
      
      private function stopSubmitWatchdog() : void
      {
         if(_submitTimer != 0)
         {
            clearTimeout(_submitTimer);
            _submitTimer = 0;
         }
      }
      
      private function onSubmitTimeout() : void
      {
         _submitTimer = 0;
         if(!_submitPending)
         {
            return;
         }
         _submitPending = false;
         if(_uploadLoader != null)
         {
            try
            {
               _uploadLoader.close();
            }
            catch(e:Error)
            {
            }
            _uploadLoader = null;
         }
         DarkenManager.showLoadingSpiral(false);
         displayMasterpieceFailedPopup();
         SBTracker.trackPageview("/game/play/miniGame/#ColoringMasterpieceSendTimeout");
      }
      
      private function onImportClick(e:MouseEvent) : void
      {
         _uploadFileRef = new FileReference();
         _uploadFileRef.addEventListener(Event.SELECT,onUploadSelect);
         _uploadFileRef.addEventListener(Event.CANCEL,onUploadCancel);
         _uploadFileRef.browse([new FileFilter("Images (*.png, *.jpg, *.gif)","*.png;*.PNG;*.jpg;*.JPG;*.jpeg;*.JPEG;*.gif;*.GIF")]);
      }
      
      private function buildModUI() : void
      {
         ArtStudioKit.setTipLayer(_guiLayer);
         _colorPanel = ArtStudioKit.colorPanel(_layerInterface,128,5,_interfaceObject.loader.content);
         buildToolPanel();
         buildUndoButtons();
         buildBrushPanel();
         buildLayerPanel();
      }
      
      // The native toolbox shows its selection with h_2 (tools) and h_3
      // (brush sizes). Hide them while a mod tool or a slider size is in use,
      // and give them back when a native button is clicked.
      private function syncNativeControls() : void
      {
         var c:Object = _interfaceObject.loader.content;
         var tool:int = int(c.currentTool);
         var bs:int = int(c.brushSize);
         if(tool >= 1 && tool <= 8)
         {
            if(_modTool != 0)
            {
               _modTool = 0;
               updateToolButtons();
               updateCanvasCursor();
            }
            c.h_2.visible = true;
         }
         else
         {
            c.h_2.visible = false;
         }
         if(bs >= 1 && bs <= _drawSizes.length)
         {
            if(_drawSizes[bs - 1] != _brushSizeVal)
            {
               _brushSizeVal = _drawSizes[bs - 1];
               ArtStudioKit.sliderSet(_sizeSlider,_brushSizeVal);
            }
            if(tool != 5)
            {
               c.h_3.visible = true;
            }
         }
         else
         {
            c.h_3.visible = false;
         }
      }
      
      // Top right, between the title and the close button: the mod's tools,
      // then the menu (image, adjustments, filters, layer, view).
      private function buildToolPanel() : void
      {
         var px:int = 610;
         var py:int = 5;
         var x:int = px + 8;
         ArtStudioKit.panel(_layerInterface,px,py,226,36);
         _toolBtns = {};
         x = addToolButton(TOOL_PEN,"pen","Pen: hard pixel edges (P)",x,py + 4);
         x = addToolButton(TOOL_ERASER,"eraser","Eraser (E)",x,py + 4);
         x = addToolButton(TOOL_BLUR,"blur","Blur",x,py + 4);
         x = addToolButton(TOOL_EYEDROP,"picker","Colour picker (I, or Alt+click)",x,py + 4);
         x = addToolButton(TOOL_HAND,"hand","Hand: drag to move around (H, or hold Space)",x,py + 4);
         x = addToolButton(TOOL_GRADIENT,"gradient","Gradient: drag from where the colour starts (G)",x,py + 4);
         ArtStudioKit.divider(_layerInterface,x + 2,py + 6,24);
         _menuBtn = ArtStudioKit.button("menu","Menu: import/export, adjustments, filters, layers, view",26,28,onMenuButton);
         _menuBtn.x = x + 8;
         _menuBtn.y = py + 4;
         _layerInterface.addChild(_menuBtn);
      }
      
      private function addToolButton(tool:int, icon:String, tip:String, x:int, y:int) : int
      {
         var b:MovieClip = ArtStudioKit.button(icon,tip,26,28,onModToolClick);
         b.toolId = tool;
         b.x = x;
         b.y = y;
         _layerInterface.addChild(b);
         _toolBtns[tool] = b;
         return x + 29;
      }
      
      private function onModToolClick(e:MouseEvent) : void
      {
         selectModTool(int((e.currentTarget as MovieClip).toolId));
      }
      
      private function selectModTool(tool:int) : void
      {
         var c:Object = _interfaceObject.loader.content;
         if(tool == TOOL_EYEDROP && int(c.currentTool) != TOOL_EYEDROP)
         {
            _toolBeforePick = int(c.currentTool);
         }
         c.currentTool = tool;
         _currentTool = tool;
         _modTool = tool;
         c.h_2.visible = false;
         if(c.activeCursor)
         {
            c.activeCursor.gotoAndPlay("tool_2");
         }
         updateToolButtons();
         updateCanvasCursor();
      }
      
      private function updateToolButtons() : void
      {
         for(var key:String in _toolBtns)
         {
            ArtStudioKit.setActive(_toolBtns[key],int(key) == _modTool);
         }
      }
      
      private function pickColorAt(x:Number, y:Number, restoreTool:Boolean = true) : void
      {
         var c:Object = _interfaceObject.loader.content;
         var mx:int = Math.max(0,Math.min(int(x),_canvasW - 1));
         var my:int = Math.max(0,Math.min(int(y),_canvasH - 1));
         var argb:uint = getCompositeColor(mx,my);
         ArtStudioKit.applyColor(c,(argb >>> 24) == 0 ? 16777215 : int(argb & 0xFFFFFF));
         AJAudio.playSubMenuBtnRollover();
         if(!restoreTool)
         {
            return;
         }
         if(_toolBeforePick >= 1 && _toolBeforePick <= 8)
         {
            c.setTool(_toolBeforePick);
         }
         else if(_toolBeforePick == TOOL_PEN || _toolBeforePick == TOOL_ERASER || _toolBeforePick == TOOL_BLUR || _toolBeforePick == TOOL_GRADIENT)
         {
            selectModTool(_toolBeforePick);
         }
         else
         {
            c.setTool(1);
         }
      }
      
      // Multi-step undo/redo replaces the native one-step undo button, in the
      // same spot at the bottom of the toolbox.
      private function buildUndoButtons() : void
      {
         var c:Object = _interfaceObject.loader.content;
         var r:Rectangle = c.tool_9.getBounds(_layerInterface);
         var w:int = 0;
         if(r.width < 40 || r.width > 140 || r.height < 16 || r.height > 44)
         {
            r = new Rectangle(37,516,64,24);
         }
         c.tool_9.visible = false;
         w = int((r.width - 4) / 2);
         _undoBtn = ArtStudioKit.button("undo","Undo (Ctrl+Z)",w,int(r.height),onUndoClick);
         _undoBtn.x = int(r.x);
         _undoBtn.y = int(r.y);
         _layerInterface.addChild(_undoBtn);
         _redoBtn = ArtStudioKit.button("redo","Redo (Ctrl+Y)",w,int(r.height),onRedoClick);
         _redoBtn.x = int(r.x) + w + 4;
         _redoBtn.y = int(r.y);
         _layerInterface.addChild(_redoBtn);
         updateUndoRedoUI();
      }
      
      // Bottom left, in the strip the print and sketch buttons used to hold:
      // brush size, opacity and softness, then zoom.
      private function buildBrushPanel() : void
      {
         var px:int = 128;
         var py:int = 496;
         ArtStudioKit.panel(_layerInterface,px,py,338,50);
         _sizeSlider = ArtStudioKit.slider("SIZE",58,false,MIN_SIZE,MAX_SIZE,2.2,formatPx,onSizeSlider,"Brush size  ( [ and ] )");
         _sizeSlider.x = px + 12;
         _sizeSlider.y = py + 4;
         _layerInterface.addChild(_sizeSlider);
         ArtStudioKit.sliderSet(_sizeSlider,_brushSizeVal);
         _opacitySlider = ArtStudioKit.slider("OPACITY",58,false,0,100,1,formatPercent,onOpacitySlider,"Brush opacity");
         _opacitySlider.x = px + 88;
         _opacitySlider.y = py + 4;
         _layerInterface.addChild(_opacitySlider);
         ArtStudioKit.sliderSet(_opacitySlider,_brushOpacity * 100);
         _softSlider = ArtStudioKit.slider("SOFT",58,false,0,100,1,formatPercent,onSoftSlider,"Brush softness: blurs the edge of brush, airbrush and pen strokes");
         _softSlider.x = px + 164;
         _softSlider.y = py + 4;
         _layerInterface.addChild(_softSlider);
         ArtStudioKit.sliderSet(_softSlider,(1 - _brushHardness) * 100);
         ArtStudioKit.divider(_layerInterface,px + 230,py + 8,34);
         _zoomOutBtn = ArtStudioKit.button("zoomOut","Zoom out (Ctrl -)",24,26,onZoomOutClick);
         _zoomOutBtn.x = px + 237;
         _zoomOutBtn.y = py + 12;
         _layerInterface.addChild(_zoomOutBtn);
         _zoomLabelBtn = ArtStudioKit.button(null,"Reset zoom (Ctrl 0). Move around with the hand tool or Space+drag",42,26,onZoomResetClick,"100%");
         _zoomLabelBtn.x = px + 264;
         _zoomLabelBtn.y = py + 12;
         _layerInterface.addChild(_zoomLabelBtn);
         _zoomInBtn = ArtStudioKit.button("zoomIn","Zoom in (Ctrl +)",24,26,onZoomInClick);
         _zoomInBtn.x = px + 309;
         _zoomInBtn.y = py + 12;
         _layerInterface.addChild(_zoomInBtn);
         updateZoomUI();
      }
      
      private function formatPx(v:Number) : String
      {
         return Math.round(v) + "px";
      }
      
      private function formatPercent(v:Number) : String
      {
         return Math.round(v) + "%";
      }
      
      private function onSizeSlider(v:Number) : void
      {
         _brushSizeVal = Math.max(MIN_SIZE,Math.round(v));
         _interfaceObject.loader.content.brushSize = 0;
      }
      
      private function setBrushSize(v:Number) : void
      {
         _brushSizeVal = Math.max(MIN_SIZE,Math.min(MAX_SIZE,Math.round(v)));
         _interfaceObject.loader.content.brushSize = 0;
         ArtStudioKit.sliderSet(_sizeSlider,_brushSizeVal);
      }
      
      private function onOpacitySlider(v:Number) : void
      {
         _brushOpacity = v / 100;
      }
      
      private function onSoftSlider(v:Number) : void
      {
         _brushHardness = 1 - v / 100;
      }
      
      // Right of the canvas: the seven layers (top of the column is the top
      // layer) with thumbnails, then hide, move, merge and layer opacity.
      private function buildLayerPanel() : void
      {
         var px:int = 856;
         var py:int = 52;
         var cap:TextField = null;
         var chip:MovieClip = null;
         var thumb:BitmapData = null;
         var tb:Bitmap = null;
         var mark:Sprite = null;
         var markIcon:Shape = null;
         var i:int = 0;
         var y:int = 0;
         ArtStudioKit.panel(_layerInterface,px,py,40,434);
         cap = ArtStudioKit.text("LAYERS",10,ArtStudioKit.TEXT_LIGHT,40,"center");
         cap.x = px;
         cap.y = py + 3;
         _layerInterface.addChild(cap);
         _thumbChecker = new BitmapData(28,17,false,16777215);
         y = 0;
         while(y < 17)
         {
            i = 0;
            while(i < 28)
            {
               if((i / 4 + y / 4) % 2 == 1)
               {
                  _thumbChecker.fillRect(new Rectangle(i,y,4,4),14540253);
               }
               i += 4;
            }
            y += 4;
         }
         _layerChips = [];
         _layerThumbs = [];
         i = 0;
         while(i < NUM_LAYERS)
         {
            chip = ArtStudioKit.button(null,"Layer " + (i + 1),32,26,onLayerChipClick);
            chip.layerIndex = i;
            chip.x = px + 4;
            chip.y = py + 20 + (NUM_LAYERS - 1 - i) * 29;
            thumb = new BitmapData(28,17,false,16777215);
            tb = new Bitmap(thumb,"auto",true);
            tb.x = 2;
            tb.y = 4;
            chip.addChild(tb);
            mark = new Sprite();
            mark.graphics.beginFill(5910032,0.6);
            mark.graphics.drawRect(2,4,28,17);
            markIcon = new Shape();
            ArtStudioKit.drawIcon(markIcon.graphics,"eyeOff",16771522);
            markIcon.scaleX = markIcon.scaleY = 0.75;
            markIcon.x = 8.5;
            markIcon.y = 5;
            mark.addChild(markIcon);
            mark.visible = false;
            chip.addChild(mark);
            chip.hiddenMark = mark;
            _layerChips.push(chip);
            _layerThumbs.push(thumb);
            _layerInterface.addChild(chip);
            i++;
         }
         y = py + 20 + NUM_LAYERS * 29 + 4;
         _eyeBtn = addLayerButton("eye","Hide layer",px + 4,y,onToggleLayerClick);
         _upBtn = addLayerButton("up","Move layer up",px + 4,y + 27,onMoveLayerUp);
         _downBtn = addLayerButton("down","Move layer down",px + 4,y + 54,onMoveLayerDown);
         _mergeBtn = addLayerButton("merge","Merge into the layer below",px + 4,y + 81,onMergeLayerDown);
         _layerOpacitySlider = ArtStudioKit.slider("",56,true,0,100,1,formatPercent,onLayerOpacitySlider,"Layer opacity");
         _layerOpacitySlider.x = px + 20;
         _layerOpacitySlider.y = y + 112;
         _layerInterface.addChild(_layerOpacitySlider);
         _activeLayerIndex = 3;
         refreshLayerPanel(true);
      }
      
      private function addLayerButton(icon:String, tip:String, x:int, y:int, fn:Function) : MovieClip
      {
         var b:MovieClip = ArtStudioKit.button(icon,tip,32,24,fn);
         b.x = x;
         b.y = y;
         _layerInterface.addChild(b);
         return b;
      }
      
      private function refreshLayerPanel(thumbs:Boolean) : void
      {
         var i:int = 0;
         var chip:MovieClip = null;
         var shown:Boolean = false;
         if(_layerChips == null)
         {
            return;
         }
         while(i < _layerChips.length)
         {
            chip = _layerChips[i];
            ArtStudioKit.setActive(chip,i == _activeLayerIndex);
            chip.hiddenMark.visible = !(_layerBitmaps[i] as Bitmap).visible;
            chip.tip = "Layer " + (i + 1) + (_layerBlends[i] != BlendMode.NORMAL ? " - " + _layerBlends[i] : "") + (_layerLocks[i] ? " - transparency locked" : "");
            if(thumbs)
            {
               refreshLayerThumb(i);
            }
            i++;
         }
         shown = (_layerBitmaps[_activeLayerIndex] as Bitmap).visible;
         ArtStudioKit.setIcon(_eyeBtn,shown ? "eye" : "eyeOff");
         _eyeBtn.tip = shown ? "Hide layer" : "Show layer";
         ArtStudioKit.setEnabled(_upBtn,_activeLayerIndex < NUM_LAYERS - 1);
         ArtStudioKit.setEnabled(_downBtn,_activeLayerIndex > 0);
         ArtStudioKit.setEnabled(_mergeBtn,_activeLayerIndex > 0);
         ArtStudioKit.sliderSet(_layerOpacitySlider,_layerOpacities[_activeLayerIndex] * 100);
      }
      
      private function refreshLayerThumb(i:int) : void
      {
         var thumb:BitmapData = null;
         var src:BitmapData = null;
         var m:Matrix = null;
         if(_layerThumbs == null || i < 0 || i >= _layerThumbs.length)
         {
            return;
         }
         thumb = _layerThumbs[i];
         src = _layerBitmapDatas[i];
         m = new Matrix();
         m.scale(thumb.width / src.width,thumb.height / src.height);
         thumb.copyPixels(_thumbChecker,_thumbChecker.rect,ORIGIN);
         thumb.draw(src,m,null,null,null,true);
      }
      
      private function onLayerChipClick(e:MouseEvent) : void
      {
         _activeLayerIndex = int((e.currentTarget as MovieClip).layerIndex);
         refreshLayerPanel(false);
      }
      
      // Swaps two layers' bitmaps, display order and opacity; the active layer
      // follows the one that moved.
      private function swapLayers(a:int, b:int) : void
      {
         var tmpBD:BitmapData = _layerBitmapDatas[a];
         var tmpBmp:Bitmap = _layerBitmaps[a];
         var tmpOpacity:Number = Number(_layerOpacities[a]);
         var tmpBlend:String = _layerBlends[a];
         var tmpLock:Boolean = Boolean(_layerLocks[a]);
         pushUndo([a,b],true);
         _layerBlends[a] = _layerBlends[b];
         _layerBlends[b] = tmpBlend;
         _layerLocks[a] = _layerLocks[b];
         _layerLocks[b] = tmpLock;
         _layerBitmapDatas[a] = _layerBitmapDatas[b];
         _layerBitmapDatas[b] = tmpBD;
         _layerBitmaps[a] = _layerBitmaps[b];
         _layerBitmaps[b] = tmpBmp;
         _layerOpacities[a] = _layerOpacities[b];
         _layerOpacities[b] = tmpOpacity;
         _layersContainer.setChildIndex(_layerBitmaps[a],a);
         _layersContainer.setChildIndex(_layerBitmaps[b],b);
         _activeLayerIndex = b;
         updateLayerVisuals();
         refreshLayerPanel(true);
      }
      
      private function onLayerOpacitySlider(v:Number) : void
      {
         _layerOpacities[_activeLayerIndex] = v / 100;
         updateLayerVisuals();
      }
      
      private function flashTip(target:DisplayObject, msg:String) : void
      {
         if(target != null)
         {
            ArtStudioKit.showTip(target,msg);
            setTimeout(ArtStudioKit.hideTip,2200);
         }
      }
      
      private function allLayerIndices() : Array
      {
         var out:Array = [];
         var i:int = 0;
         while(i < NUM_LAYERS)
         {
            out.push(i);
            i++;
         }
         return out;
      }
      
      // One undo step holds copies of only the layers an action changed
      // (usually just the active one), not all seven: 100 full snapshots of
      // seven canvas-sized layers could use most of a gigabyte. withProps also
      // records opacity, visibility and the active layer, for moves and merges.
      private function captureState(indices:Array, withProps:Boolean) : Object
      {
         var bds:Array = [];
         var vis:Array = null;
         var st:Object = null;
         var k:int = 0;
         while(k < indices.length)
         {
            bds.push((_layerBitmapDatas[indices[k]] as BitmapData).clone());
            k++;
         }
         st = {
            "idx":indices.concat(),
            "bds":bds,
            "props":withProps
         };
         if(withProps)
         {
            vis = [];
            k = 0;
            while(k < _layerBitmaps.length)
            {
               vis.push((_layerBitmaps[k] as Bitmap).visible);
               k++;
            }
            st.opac = _layerOpacities.concat();
            st.blends = _layerBlends.concat();
            st.locks = _layerLocks.concat();
            st.vis = vis;
            st.active = _activeLayerIndex;
         }
         return st;
      }
      
      private function applyState(st:Object) : void
      {
         var bd:BitmapData = null;
         var k:int = 0;
         while(k < st.idx.length)
         {
            bd = st.bds[k];
            (_layerBitmapDatas[st.idx[k]] as BitmapData).copyPixels(bd,bd.rect,ORIGIN);
            bd.dispose();
            k++;
         }
         if(st.props)
         {
            _layerOpacities = (st.opac as Array).concat();
            _layerBlends = (st.blends as Array).concat();
            _layerLocks = (st.locks as Array).concat();
            k = 0;
            while(k < _layerBitmaps.length)
            {
               (_layerBitmaps[k] as Bitmap).visible = st.vis[k];
               k++;
            }
            _activeLayerIndex = int(st.active);
            updateLayerVisuals();
         }
         refreshLayerPanel(true);
         syncCanvasButtons();
         _needsSave = true;
      }
      
      private function disposeState(st:Object) : void
      {
         var k:int = 0;
         while(k < st.bds.length)
         {
            (st.bds[k] as BitmapData).dispose();
            k++;
         }
      }
      
      private function pushUndo(indices:Array, withProps:Boolean) : void
      {
         _undoStack.push(captureState(indices,withProps));
         while(_undoStack.length > MAX_UNDO)
         {
            disposeState(_undoStack.shift());
         }
         clearRedo();
         updateUndoRedoUI();
      }
      
      private function clearRedo() : void
      {
         while(_redoStack.length > 0)
         {
            disposeState(_redoStack.pop());
         }
      }
      
      // Grays the native create / print / clear buttons when every layer is
      // empty (after undo, clear or a merge), and enables them otherwise.
      private function syncCanvasButtons() : void
      {
         var has:Boolean = false;
         var i:int = 0;
         while(i < _layerBitmapDatas.length && !has)
         {
            has = (_layerBitmapDatas[i] as BitmapData).getColorBoundsRect(4278190080,0,false).width > 0;
            i++;
         }
         _hasDrawn = has;
         _masterpieceSubmitBtn.guiBtn.setGrayState(!has);
         if(_submitButton != null)
         {
            _submitButton.guiBtn.setGrayState(!has);
         }
         _printBtn.guiBtn.setGrayState(!has);
         _clearAllButton.guiBtn.setGrayState(!has);
      }
      
      // Keeps at least PAN_MARGIN px of the painting inside the canvas frame,
      // so it can't be dragged out of reach.
      private function clampPan() : void
      {
         var w:Number = _canvasW * _zoomLevel;
         var h:Number = _canvasH * _zoomLevel;
         var left:Number = canvasLeft();
         var clamped:Number = Math.max(PAN_MARGIN - w,Math.min(_canvasW - PAN_MARGIN,left));
         _drawCanvas.x += clamped - left;
         _drawCanvas.y = Math.max(PAN_MARGIN - h,Math.min(_canvasH - PAN_MARGIN,_drawCanvas.y));
      }
      
      private function isHandActive() : Boolean
      {
         return _spaceHeld || _modTool == TOOL_HAND;
      }
      
      // Over the canvas the brush cursor replaces the mouse, except with the
      // hand (tool or Space held), which shows the system hand.
      private function updateCanvasCursor() : void
      {
         var hand:Boolean = (_overCanvas || _isPanning) && isHandActive();
         if(ArtStudioKit.isPlacing())
         {
            Mouse.cursor = MouseCursor.AUTO;
            Mouse.show();
            _layerMouse.visible = false;
         }
         else if(hand)
         {
            Mouse.show();
            Mouse.cursor = MouseCursor.HAND;
            _layerMouse.visible = false;
         }
         else if(_overCanvas)
         {
            Mouse.cursor = MouseCursor.AUTO;
            Mouse.hide();
            _layerMouse.visible = true;
         }
         else
         {
            Mouse.cursor = MouseCursor.AUTO;
            Mouse.show();
            _layerMouse.visible = false;
         }
      }
      
      private function onKeyUp(e:KeyboardEvent) : void
      {
         if(e.keyCode == Keyboard.SPACE && _spaceHeld)
         {
            _spaceHeld = false;
            updateCanvasCursor();
         }
      }
      
      private function onMenuButton(e:MouseEvent) : void
      {
         if(ArtStudioKit.isMenuOpen())
         {
            ArtStudioKit.closeMenu();
            return;
         }
         if(ArtStudioKit.isPlacing() || ArtStudioKit.isDialogOpen())
         {
            return;
         }
         ArtStudioKit.hideTip();
         ArtStudioKit.openMenu(_guiLayer,836,44,[[{"header":"IMAGE"},{
            "id":"import",
            "label":"Import Image..."
         },{
            "id":"export",
            "label":"Export PNG"
         },{"header":"ADJUST LAYER"},{
            "id":"bc",
            "label":"Brightness / Contrast..."
         },{
            "id":"hsl",
            "label":"Hue / Saturation..."
         },{
            "id":"invert",
            "label":"Invert  (Ctrl+I)"
         },{
            "id":"bw",
            "label":"Black & White"
         },{
            "id":"fliph",
            "label":"Flip Horizontal"
         },{
            "id":"flipv",
            "label":"Flip Vertical"
         },{"header":"FILTER LAYER"},{
            "id":"blur",
            "label":"Blur..."
         },{
            "id":"sharpen",
            "label":"Sharpen"
         },{
            "id":"outline",
            "label":"Outline..."
         },{
            "id":"shadow",
            "label":"Drop Shadow"
         }],[{"header":"LAYER"},{
            "id":"dup",
            "label":"Duplicate  (Ctrl+J)"
         },{
            "id":"clear",
            "label":"Clear Layer"
         },{
            "id":"mergevis",
            "label":"Merge Visible"
         },{
            "id":"lock",
            "label":"Lock Transparency"
         },{"header":"BLEND MODE"},{
            "id":"b:normal",
            "label":"Normal"
         },{
            "id":"b:multiply",
            "label":"Multiply"
         },{
            "id":"b:screen",
            "label":"Screen"
         },{
            "id":"b:overlay",
            "label":"Overlay"
         },{
            "id":"b:darken",
            "label":"Darken"
         },{
            "id":"b:lighten",
            "label":"Lighten"
         },{
            "id":"b:add",
            "label":"Add"
         },{
            "id":"b:difference",
            "label":"Difference"
         },{"header":"VIEW & BRUSH"},{
            "id":"flipview",
            "label":"Flip View  (V)"
         },{
            "id":"fill",
            "label":"Filled Shapes"
         },{
            "id":"s:0",
            "label":"Smoothing: Off"
         },{
            "id":"s:1",
            "label":"Smoothing: Low"
         },{
            "id":"s:2",
            "label":"Smoothing: High"
         }]],onMenuPick,isMenuChecked,isMenuDisabled,_menuBtn);
      }
      
      private function isMenuChecked(id:String) : Boolean
      {
         if(id.indexOf("b:") == 0)
         {
            return _layerBlends[_activeLayerIndex] == id.substr(2);
         }
         if(id.indexOf("s:") == 0)
         {
            return SMOOTHING[int(id.substr(2))] == _smoothing;
         }
         switch(id)
         {
            case "lock":
               return Boolean(_layerLocks[_activeLayerIndex]);
            case "flipview":
               return _viewFlipped;
            case "fill":
               return _fillShapes;
            default:
               return false;
         }
      }
      
      private function isMenuDisabled(id:String) : Boolean
      {
         return id == "dup" && !canDuplicateLayer();
      }
      
      private function onMenuPick(id:String) : void
      {
         if(id.indexOf("b:") == 0)
         {
            _layerBlends[_activeLayerIndex] = id.substr(2);
            updateLayerVisuals();
            refreshLayerPanel(false);
            _needsSave = true;
            return;
         }
         if(id.indexOf("s:") == 0)
         {
            _smoothing = SMOOTHING[int(id.substr(2))];
            return;
         }
         switch(id)
         {
            case "import":
               onImportClick(null);
               break;
            case "export":
               onExportClick(null);
               break;
            case "bc":
               startAdjust("bc","BRIGHTNESS / CONTRAST",[{
                  "id":"brightness",
                  "label":"Brightness",
                  "min":-100,
                  "max":100,
                  "value":0,
                  "fmt":ArtStudioKit.formatSigned
               },{
                  "id":"contrast",
                  "label":"Contrast",
                  "min":-100,
                  "max":100,
                  "value":0,
                  "fmt":ArtStudioKit.formatSigned
               }]);
               break;
            case "hsl":
               startAdjust("hsl","HUE / SATURATION",[{
                  "id":"hue",
                  "label":"Hue",
                  "min":-180,
                  "max":180,
                  "value":0,
                  "fmt":ArtStudioKit.formatSigned
               },{
                  "id":"saturation",
                  "label":"Saturation",
                  "min":-100,
                  "max":100,
                  "value":0,
                  "fmt":ArtStudioKit.formatSigned
               },{
                  "id":"lightness",
                  "label":"Lightness",
                  "min":-100,
                  "max":100,
                  "value":0,
                  "fmt":ArtStudioKit.formatSigned
               }]);
               break;
            case "blur":
               startAdjust("blur","BLUR LAYER",[{
                  "id":"radius",
                  "label":"Radius",
                  "min":0,
                  "max":40,
                  "value":4,
                  "fmt":formatPx
               }]);
               break;
            case "outline":
               startAdjust("outline","OUTLINE IN CURRENT COLOUR",[{
                  "id":"size",
                  "label":"Size",
                  "min":1,
                  "max":20,
                  "value":3,
                  "fmt":formatPx
               }]);
               break;
            case "invert":
            case "bw":
            case "fliph":
            case "flipv":
            case "sharpen":
            case "shadow":
               applyInstant(id);
               break;
            case "dup":
               duplicateLayer();
               break;
            case "clear":
               pushUndo([_activeLayerIndex],false);
               (_layerBitmapDatas[_activeLayerIndex] as BitmapData).fillRect(_drawBitmapDataRect,0);
               refreshLayerThumb(_activeLayerIndex);
               syncCanvasButtons();
               _needsSave = true;
               break;
            case "mergevis":
               mergeVisibleLayers();
               break;
            case "lock":
               _layerLocks[_activeLayerIndex] = !_layerLocks[_activeLayerIndex];
               refreshLayerPanel(false);
               break;
            case "flipview":
               toggleFlipView();
               break;
            case "fill":
               _fillShapes = !_fillShapes;
         }
      }
      
      // Adjustments with sliders preview live on the active layer; Cancel puts
      // the layer back and drops the undo step it opened with.
      private function startAdjust(kind:String, title:String, sliders:Array) : void
      {
         var values:Object = {};
         var i:int = 0;
         pushUndo([_activeLayerIndex],false);
         _adjustBase = (_layerBitmapDatas[_activeLayerIndex] as BitmapData).clone();
         _adjustKind = kind;
         ArtStudioKit.openDialog(_guiLayer,494,270,title,sliders,onAdjustChange,onAdjustClose);
         while(i < sliders.length)
         {
            values[sliders[i].id] = sliders[i].value;
            i++;
         }
         onAdjustChange(values);
      }
      
      private function onAdjustChange(values:Object) : void
      {
         var bd:BitmapData = _layerBitmapDatas[_activeLayerIndex];
         var filters:Array = adjustFilters(_adjustKind,values);
         var i:int = 0;
         if(_adjustBase == null)
         {
            return;
         }
         bd.copyPixels(_adjustBase,_drawBitmapDataRect,ORIGIN);
         while(i < filters.length)
         {
            bd.applyFilter(bd,_drawBitmapDataRect,ORIGIN,filters[i]);
            i++;
         }
         applyAlphaLock();
         refreshLayerThumb(_activeLayerIndex);
      }
      
      private function onAdjustClose(ok:Boolean) : void
      {
         if(_adjustBase == null)
         {
            return;
         }
         if(!ok)
         {
            (_layerBitmapDatas[_activeLayerIndex] as BitmapData).copyPixels(_adjustBase,_drawBitmapDataRect,ORIGIN);
            if(_undoStack.length > 0)
            {
               disposeState(_undoStack.pop());
            }
            updateUndoRedoUI();
         }
         else
         {
            _needsSave = true;
         }
         _adjustBase.dispose();
         _adjustBase = null;
         refreshLayerThumb(_activeLayerIndex);
         syncCanvasButtons();
      }
      
      private function adjustFilters(kind:String, v:Object) : Array
      {
         var s:Number = NaN;
         var o:Number = NaN;
         switch(kind)
         {
            case "bc":
               s = v.contrast >= 0 ? 1 + v.contrast / 50 : 1 + v.contrast / 100;
               o = 128 * (1 - s) + v.brightness * 1.28;
               return [new ColorMatrixFilter([s,0,0,0,o,0,s,0,0,o,0,0,s,0,o,0,0,0,1,0])];
            case "hsl":
               return [new ColorMatrixFilter(hueMatrix(v.hue)),new ColorMatrixFilter(saturationMatrix(1 + v.saturation / 100)),new ColorMatrixFilter([1,0,0,0,v.lightness * 2.55,0,1,0,0,v.lightness * 2.55,0,0,1,0,v.lightness * 2.55,0,0,0,1,0])];
            case "blur":
               return v.radius > 0 ? [new BlurFilter(v.radius,v.radius,3)] : [];
            case "outline":
               return [new GlowFilter(ArtStudioKit.currentColor(_interfaceObject.loader.content),1,v.size * 2,v.size * 2,16,2)];
            default:
               return [];
         }
      }
      
      private function hueMatrix(deg:Number) : Array
      {
         var a:Number = deg * Math.PI / 180;
         var c:Number = Math.cos(a);
         var s:Number = Math.sin(a);
         var lr:Number = 0.213;
         var lg:Number = 0.715;
         var lb:Number = 0.072;
         return [lr + c * (1 - lr) - s * lr,lg - c * lg - s * lg,lb - c * lb + s * (1 - lb),0,0,lr - c * lr + s * 0.143,lg + c * (1 - lg) + s * 0.14,lb - c * lb - s * 0.283,0,0,lr - c * lr - s * (1 - lr),lg - c * lg + s * lg,lb + c * (1 - lb) + s * lb,0,0,0,0,0,1,0];
      }
      
      private function saturationMatrix(s:Number) : Array
      {
         var sr:Number = (1 - s) * 0.213;
         var sg:Number = (1 - s) * 0.715;
         var sb:Number = (1 - s) * 0.072;
         return [sr + s,sg,sb,0,0,sr,sg + s,sb,0,0,sr,sg,sb + s,0,0,0,0,0,1,0];
      }
      
      private function applyInstant(kind:String) : void
      {
         var bd:BitmapData = _layerBitmapDatas[_activeLayerIndex];
         var tmp:BitmapData = null;
         pushUndo([_activeLayerIndex],false);
         switch(kind)
         {
            case "invert":
               bd.applyFilter(bd,_drawBitmapDataRect,ORIGIN,new ColorMatrixFilter([-1,0,0,0,255,0,-1,0,0,255,0,0,-1,0,255,0,0,0,1,0]));
               break;
            case "bw":
               bd.applyFilter(bd,_drawBitmapDataRect,ORIGIN,new ColorMatrixFilter(saturationMatrix(0)));
               break;
            case "fliph":
            case "flipv":
               tmp = bd.clone();
               bd.fillRect(_drawBitmapDataRect,0);
               bd.draw(tmp,kind == "fliph" ? new Matrix(-1,0,0,1,_canvasW,0) : new Matrix(1,0,0,-1,0,_canvasH));
               tmp.dispose();
               break;
            case "sharpen":
               bd.applyFilter(bd,_drawBitmapDataRect,ORIGIN,new ConvolutionFilter(3,3,[0,-1,0,-1,5,-1,0,-1,0],1,0,true,true));
               break;
            case "shadow":
               bd.applyFilter(bd,_drawBitmapDataRect,ORIGIN,new DropShadowFilter(6,45,0,0.55,8,8,1,2));
         }
         applyAlphaLock();
         refreshLayerThumb(_activeLayerIndex);
         syncCanvasButtons();
         _needsSave = true;
      }
      
      private function isLayerEmpty(i:int) : Boolean
      {
         return (_layerBitmapDatas[i] as BitmapData).getColorBoundsRect(4278190080,0,false).width == 0;
      }
      
      // Duplicate needs the top layer free: the layers above the active one
      // shift up one to make room for the copy.
      private function canDuplicateLayer() : Boolean
      {
         return _activeLayerIndex < NUM_LAYERS - 1 && isLayerEmpty(NUM_LAYERS - 1);
      }
      
      private function duplicateLayer() : void
      {
         var i:int = 0;
         if(!canDuplicateLayer())
         {
            flashTip(_menuBtn,"No free layer: the top layer has to be empty.");
            return;
         }
         pushUndo(allLayerIndices(),true);
         i = NUM_LAYERS - 1;
         while(i > _activeLayerIndex)
         {
            copyLayer(i - 1,i);
            i--;
         }
         _activeLayerIndex++;
         updateLayerVisuals();
         refreshLayerPanel(true);
         _needsSave = true;
      }
      
      private function copyLayer(from:int, to:int) : void
      {
         (_layerBitmapDatas[to] as BitmapData).copyPixels(_layerBitmapDatas[from],_drawBitmapDataRect,ORIGIN);
         (_layerBitmaps[to] as Bitmap).visible = (_layerBitmaps[from] as Bitmap).visible;
         _layerOpacities[to] = _layerOpacities[from];
         _layerBlends[to] = _layerBlends[from];
         _layerLocks[to] = _layerLocks[from];
      }
      
      // Flattens the visible layers (at their opacity and blend) into the
      // lowest visible one; hidden layers are left alone.
      private function mergeVisibleLayers() : void
      {
         var target:int = -1;
         var flat:BitmapData = new BitmapData(_canvasW,_canvasH,true,0);
         var i:int = 0;
         pushUndo(allLayerIndices(),true);
         while(i < NUM_LAYERS)
         {
            if((_layerBitmaps[i] as Bitmap).visible)
            {
               if(target < 0)
               {
                  target = i;
               }
               flat.draw(_layerBitmapDatas[i],null,_layerOpacities[i] < 1 ? new ColorTransform(1,1,1,_layerOpacities[i]) : null,i == target ? null : _layerBlends[i]);
               if(i != target)
               {
                  (_layerBitmapDatas[i] as BitmapData).fillRect(_drawBitmapDataRect,0);
                  _layerOpacities[i] = 1;
                  _layerBlends[i] = BlendMode.NORMAL;
               }
            }
            i++;
         }
         if(target >= 0)
         {
            (_layerBitmapDatas[target] as BitmapData).copyPixels(flat,_drawBitmapDataRect,ORIGIN);
            _layerOpacities[target] = 1;
            _layerBlends[target] = BlendMode.NORMAL;
            _activeLayerIndex = target;
         }
         flat.dispose();
         updateLayerVisuals();
         refreshLayerPanel(true);
         syncCanvasButtons();
         _needsSave = true;
      }
      
      // Lock transparency: after a change to the active layer, put its alpha
      // back to what it was before (kept in the undo step the change opened),
      // so paint only lands where the layer already has pixels.
      private function applyAlphaLock() : void
      {
         var st:Object = null;
         var k:int = 0;
         if(!_layerLocks[_activeLayerIndex] || _undoStack.length == 0)
         {
            return;
         }
         st = _undoStack[_undoStack.length - 1];
         k = (st.idx as Array).indexOf(_activeLayerIndex);
         if(k >= 0)
         {
            (_layerBitmapDatas[_activeLayerIndex] as BitmapData).copyChannel(st.bds[k],_drawBitmapDataRect,ORIGIN,BitmapDataChannel.ALPHA,BitmapDataChannel.ALPHA);
         }
      }
      
      // Mirrors the view (not the painting) to check proportions; drawing
      // still lands where the pointer is.
      private function toggleFlipView() : void
      {
         _viewFlipped = !_viewFlipped;
         _drawCanvas.scaleX = -_drawCanvas.scaleX;
         _drawCanvas.x = _canvasW - _drawCanvas.x;
         clampPan();
      }
      
      private function canvasLeft() : Number
      {
         return _viewFlipped ? _drawCanvas.x - _canvasW * _zoomLevel : _drawCanvas.x;
      }
      
      // A ring under the pointer at the brush's real size (at this zoom), for
      // the tools that use the size.
      private function updateSizeRing() : void
      {
         var tool:int = _interfaceObject != null ? int(_interfaceObject.loader.content.currentTool) : 0;
         var r:Number = _brushSizeVal * 0.5 * _zoomLevel;
         var show:Boolean = _layerMouse.visible && tool != 5 && tool != TOOL_EYEDROP && tool != TOOL_HAND && tool != TOOL_GRADIENT && r >= 3;
         _sizeRing.visible = show;
         if(!show)
         {
            return;
         }
         _sizeRing.x = mouseX;
         _sizeRing.y = mouseY;
         if(r != _sizeRingRadius)
         {
            _sizeRingRadius = r;
            _sizeRing.graphics.clear();
            _sizeRing.graphics.lineStyle(2.5,0,0.45);
            _sizeRing.graphics.drawCircle(0,0,r);
            _sizeRing.graphics.lineStyle(1,16777215,0.9);
            _sizeRing.graphics.drawCircle(0,0,r);
         }
      }
      
      private function drawGradientPreview() : void
      {
         var dx:Number = _drawCanvas.mouseX - _drawStartX;
         var dy:Number = _drawCanvas.mouseY - _drawStartY;
         var len:Number = Math.max(1,Math.sqrt(dx * dx + dy * dy));
         var m:Matrix = new Matrix();
         var color:uint = uint(ArtStudioKit.currentColor(_interfaceObject.loader.content));
         m.createGradientBox(len,len,0,0,-len / 2);
         m.rotate(Math.atan2(dy,dx));
         m.translate(_drawStartX,_drawStartY);
         _gradShape.graphics.clear();
         _gradShape.graphics.beginGradientFill(GradientType.LINEAR,[color,color],[_brushOpacity,0],[0,255],m,SpreadMethod.PAD);
         _gradShape.graphics.drawRect(0,0,_canvasW,_canvasH);
         _gradShape.graphics.endFill();
      }
      
      private function commitGradient() : void
      {
         if(_gradShape.parent != null)
         {
            _gradShape.parent.removeChild(_gradShape);
            (_layerBitmapDatas[_activeLayerIndex] as BitmapData).draw(_gradShape);
         }
         _gradShape.graphics.clear();
      }
      
      private function smoothStep(x:Number, y:Number) : void
      {
         _smX += (x - _smX) * (1 - _smoothing);
         _smY += (y - _smY) * (1 - _smoothing);
      }

      // Mod: buy several copies of the masterpiece in one go, like the bulk
      // purchase in item shops. Each copy is the vanilla flow (upload the
      // painting for a new id, then buy it); copies after the first reuse the
      // encoded painting and the first copy's token/diamond choice, and skip
      // the rules popup. Capped by free den slots and by what you can afford;
      // the first failure stops the run.
      private function askCopyCount() : void
      {
         var free:int = ShopManager.maxDenItems - Utility.numDenItemsInList(gMainFrame.userInfo.playerUserInfo.denItemsFull,0);
         if(_copyPopup != null)
         {
            _copyPopup.destroy();
         }
         _copyFreeSlots = Math.max(1,free);
         _copyPopup = new QuantityInputPopup(_guiLayer,"Masterpiece (" + _copyFreeSlots + (_copyFreeSlots == 1 ? " den slot" : " den slots") + " free)",onCopyCountChosen);
      }

      private function onCopyCountChosen(result:Object) : void
      {
         var asked:int = int(result.quantity);
         _copyPopup = null;
         if(!result.status)
         {
            if(_masterpiecePreviewPopup)
            {
               _masterpiecePreviewPopup.closeCallback = onPreviewClose;
            }
            return;
         }
         _copiesWanted = Math.max(1,Math.min(asked,_copyFreeSlots));
         _copiesNote = asked > _copiesWanted ? " (only " + _copiesWanted + " den slots were free)" : "";
         _copiesDone = 0;
         _isMasterpieceSubmit = true;
         encodeImage();
      }

      private function capCopiesToFunds() : void
      {
         var price:int = int(DiamondXtCommManager.getDiamondDef(221).value);
         var afford:int = _isUsingTokens ? _numMasterpieceTokens : (price > 0 ? int(UserCurrency.getCurrency(3) / price) : _copiesWanted);
         if(_copiesWanted > 1 && afford < _copiesWanted)
         {
            _copiesWanted = Math.max(1,afford);
            _copiesNote = " (you could afford " + _copiesWanted + ")";
         }
      }

      private function buyCurrentCopy() : void
      {
         DarkenManager.showLoadingSpiral(true);
         DenXtCommManager.requestBuy(true,0,221,onPreviewItemBuy,onPreviewBuyInventoryResponse,0,null,_currItemVersion,1,true,_isUsingTokens,_masterpieceUuid);
      }

      private function nextCopy() : void
      {
         if(_guiLayer == null)
         {
            return;
         }
         if(_copiesDone >= _copiesWanted || _jpgEncoder == null)
         {
            stopCopies();
            DarkenManager.showLoadingSpiral(false);
            return;
         }
         _isMasterpieceSubmit = true;
         _URLStatus = 0;
         startSubmitWatchdog(TOKEN_TIMEOUT_MS);
         MinigameManager.msg(["gmtkn","0","1"]);
      }

      private function finishCopies() : void
      {
         if(_copiesWanted > 1)
         {
            showCopyBanner("Bought " + _copiesDone + " copies" + _copiesNote);
         }
         _copiesWanted = 1;
         _copiesDone = 0;
         _copiesNote = "";
      }

      private function stopCopies() : void
      {
         if(_copiesWanted > 1 && _copiesDone > 0)
         {
            showCopyBanner("Stopped: bought " + _copiesDone + " of " + _copiesWanted + " copies");
         }
         else
         {
            hideCopyBanner();
         }
         _copiesWanted = 1;
         _copiesDone = 0;
         _copiesNote = "";
      }

      private function showCopyBanner(msg:String) : void
      {
         var tf:TextField = ArtStudioKit.text(msg,15,ArtStudioKit.TEXT_LIGHT,520,"center");
         var w:int = 0;
         hideCopyBanner();
         if(_guiLayer == null)
         {
            return;
         }
         tf.autoSize = "center";
         w = int(tf.width) + 28;
         _copyBanner = new Sprite();
         _copyBanner.mouseEnabled = false;
         _copyBanner.mouseChildren = false;
         ArtStudioKit.panel(_copyBanner,0,0,w,32);
         tf.x = int((w - tf.width) / 2);
         tf.y = 5;
         _copyBanner.addChild(tf);
         _copyBanner.x = int(494 - w / 2);
         _copyBanner.y = 60;
         _guiLayer.addChild(_copyBanner);
         _copyBannerStamp = getTimer();
         setTimeout(autoHideCopyBanner,6000);
      }

      private function autoHideCopyBanner() : void
      {
         if(getTimer() - _copyBannerStamp >= 5900 && _copiesWanted <= 1)
         {
            hideCopyBanner();
         }
      }

      private function hideCopyBanner() : void
      {
         if(_copyBanner != null && _copyBanner.parent != null)
         {
            _copyBanner.parent.removeChild(_copyBanner);
         }
         _copyBanner = null;
      }
   }
}

