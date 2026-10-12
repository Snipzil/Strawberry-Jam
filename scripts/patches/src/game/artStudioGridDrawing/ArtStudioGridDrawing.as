package game.artStudioGridDrawing
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
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.HTTPStatusEvent;
   import flash.events.MouseEvent;
   import flash.events.ProgressEvent;
   import flash.filters.GlowFilter;
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
   import flash.ui.Mouse;
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
   import flash.display.LoaderInfo;
   import flash.events.KeyboardEvent;
   import flash.text.TextField;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import game.ArtStudioKit;
   import gui.QuantityInputPopup;
   
   public class ArtStudioGridDrawing extends GameBase implements IMinigame
   {
      
      private static const TYPE_ARTSTUDIO:int = 14;
      
      private static const TYPE_ARTSTUDIO_MASTERPIECE:int = 20;
      
      private static const POPUP_X:int = 450;
      
      private static const POPUP_Y:int = 275;
      
      private static const CHOOSE_MASTERPIECE_POPUP_ID:int = 4811;
      
      private static const ITEMS_PER_SCREEN:int = 4;
      
      private const FRAME_SELECT_FILTER_DARKER:GlowFilter = new GlowFilter(3047612,1,5,5,15);
      
      private const FRAME_SELECT_FILTER_LIGHTER:GlowFilter = new GlowFilter(3648190,1,7,7,15);
      
      private const FRAME_SELECT_FILTER_MOUSE_OVER:GlowFilter = new GlowFilter(16777215,1,10,10,15);

      private static const TOOL_EYEDROP:int = 10;
      
      private static const TOOL_ERASER:int = 11;
      
      private static const MAX_UNDO:int = 40;
      
      private static const TOKEN_TIMEOUT_MS:int = 20000;

      private static const COPY_GAP_MS:int = 1200;
      
      private static const UPLOAD_TIMEOUT_MS:int = 60000;
      
      private var _undoStack:Array = [];
      
      private var _redoStack:Array = [];
      
      private var _undoBtn:MovieClip;
      
      private var _redoBtn:MovieClip;
      
      private var _colorPanel:MovieClip;
      
      private var _toolBtns:Object;
      
      private var _modTool:int;
      
      private var _toolBeforePick:int = 1;
      
      private var _gridBtn:MovieClip;
      
      private var _mirrorBtn:MovieClip;
      
      private var _importBtn:MovieClip;
      
      private var _exportBtn:MovieClip;
      
      private var _showGrid:Boolean;
      
      private var _mirror:Boolean;
      
      private var _cellCursor:Shape;
      
      private var _placingSrc:BitmapData;
      
      private var _lastCellX:int = -1;
      
      private var _lastCellY:int = -1;
      
      private var _canvasW:int;
      
      private var _canvasH:int;
      
      private var _uploadFileRef:FileReference;
      
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
            
      private var _myId:uint;
      
      private var _pIDs:Array;
      
      private var _dbIDs:Array;
      
      private var _sceneLoaded:Boolean;
      
      private var _bInit:Boolean;
      
      private var _exitConfirmationActive:Boolean;
      
      private var _interfaceObject:Object;
      
      private var _brush:Object;
      
      private var _layerBackground:Sprite;
      
      private var _layerInterface:Sprite;
      
      private var _layerMouse:Sprite;
      
      private var _layerGrid:Sprite;
      
      private var _submitButton:MovieClip;
      
      private var _clearAllButton:MovieClip;
      
      private var _printBtn:MovieClip;
      
      private var _masterpieceSubmitBtn:MovieClip;
      
      private var _storageButton:MovieClip;
      
      private var _jpgEncoder:JpegAsynchEncoder;
      
      private var _selectBackground:Object;
      
      private var _drawBitmapUndoSnapShot:BitmapData;
      
      private var _drawBitmapUndo:Bitmap;
      
      private var _defaultBitmapData:BitmapData;
      
      private var _drawBitmapDataSnapShot:BitmapData;
      
      private var _drawBitmapSnapShot:Bitmap;
      
      private var _drawBitmapData:BitmapData;
      
      private var _drawBitmap:Bitmap;
      
      private var _drawGraphics:Sprite;
      
      private var _drawCanvas:Sprite;
      
      private var _activeBrush:Object;
      
      private var _drawing:Boolean;
      
      private var _drawStartX:Number;
      
      private var _drawStartY:Number;
      
      private var _currentTool:int;
      
      private var _drawBitmapDataRect:Rectangle;
      
      private var _drawPoint_0_0:Point;
      
      private var _undoable:Boolean;
      
      private var _printBackground:Object;
      
      private var _hasDrawn:Boolean;
      
      private var _needsSave:Boolean;
      
      private var _frameTime:Number;
      
      private var _lastTime:Number;
      
      private var _timeSinceErase:Number;
      
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
      
      private var _fileRef:FileReference;
      
      private var _masterpieceUuid:String;
      
      private var _gridPixelSize:int;
      
      private var _gridPencil:Object;
      
      private var _zoomFactor:int;
      
      private var _scrollX:int;
      
      private var _scrollY:int;
      
      public function ArtStudioGridDrawing()
      {
         super();
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
         Mouse.show();
         releaseBase();
         if(_musicLoop)
         {
            _musicLoop.stop();
            _musicLoop = null;
         }
         _chooseMasterpiecePopup = null;
         stage.removeEventListener("enterFrame",heartbeat);
         stage.removeEventListener("mouseMove",moveMouse);
         stage.removeEventListener("mouseUp",endDraw);
         stage.removeEventListener("keyDown",onKeyDown);
         _drawCanvas.removeEventListener("mouseDown",startDraw);
         _drawCanvas.removeEventListener("mouseOver",drawCanvasMouseOver);
         _drawCanvas.removeEventListener("mouseOut",drawCanvasMouseOut);
         clearRedo();
         while(_undoStack.length > 0)
         {
            (_undoStack.pop() as BitmapData).dispose();
         }
         _bInit = false;
         removeLayer(_layerBackground);
         removeLayer(_layerInterface);
         removeLayer(_layerMouse);
         removeLayer(_guiLayer);
         _drawBitmapUndoSnapShot.dispose();
         _drawBitmapUndo = null;
         _defaultBitmapData.dispose();
         _drawBitmapDataSnapShot.dispose();
         _drawBitmapSnapShot = null;
         _drawBitmapData.dispose();
         _drawBitmap = null;
         _layerBackground = null;
         _layerInterface = null;
         _layerMouse = null;
         _layerGrid = null;
         _guiLayer = null;
         MinigameManager.leave();
      }
      
      private function onMediaLoaded(param1:MovieClip) : void
      {
         _mediaObject = param1;
      }
      
      private function init() : void
      {
         _mediaLoader = new MediaHelper();
         _mediaLoader.init(5871,onMediaLoaded);
         try
         {
            _sharedObject = SharedObject.getLocal(gMainFrame.userInfo.myUserName);
            if(_sharedObject.data.userSubmits == null)
            {
               _sharedObject.data.userSubmits = [];
               try
               {
                  _sharedObject.flush();
               }
               catch(e:Error)
               {
               }
            }
         }
         catch(e:Error)
         {
            _sharedObject = null;
         }
         _gridPixelSize = 10;
         _lastTime = getTimer();
         _frameTime = 0;
         _timeSinceErase = 0;
         _keepAliveTimer = 0;
         _drawGraphics = new Sprite();
         _masterpiecePreviewIconIds = [];
         _masterpiecePreviewIcons = [];
         _iconMediaHelpers = [];
         _masterpiecePreviewIconStrIds = [];
         _zoomFactor = 1;
         _scrollX = 0;
         _scrollY = 0;
         var _loc2_:Matrix = new Matrix();
         if(!_bInit)
         {
            _layerBackground = new Sprite();
            _layerInterface = new Sprite();
            _layerMouse = new Sprite();
            _layerGrid = new Sprite();
            _guiLayer = new Sprite();
            addChild(_layerInterface);
            addChild(_layerBackground);
            addChild(_guiLayer);
            addChild(_layerMouse);
            loadScene("ArtStudioGridDrawing/room_main.xroom");
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
         var c:Object = null;
         var color:uint = 0;
         if(!_pauseGame && _brush && _brush.loader.content && !ArtStudioKit.isPlacing())
         {
            c = _interfaceObject.loader.content;
            _currentTool = c.currentTool;
            if(_currentTool == TOOL_EYEDROP)
            {
               pickColorAt(_drawCanvas.mouseX,_drawCanvas.mouseY);
               return;
            }
            pushUndo();
            c.newHistory(c.red,c.green,c.blue);
            switch(_currentTool)
            {
               case 1:
               case TOOL_ERASER:
                  _drawing = true;
                  _lastCellX = -1;
                  _lastCellY = -1;
                  moveMouse(param1);
                  break;
               case 5:
                  color = uint(4278190080 | ArtStudioKit.currentColor(c));
                  _drawBitmapData.floodFill(_drawCanvas.mouseX,_drawCanvas.mouseY,color);
                  if(_mirror)
                  {
                     _drawBitmapData.floodFill(_canvasW - 1 - int(_drawCanvas.mouseX),_drawCanvas.mouseY,color);
                  }
                  markDrawn();
            }
         }
      }
      
      private function endDraw(param1:MouseEvent) : void
      {
         if(_drawing)
         {
            _drawing = false;
            markDrawn();
         }
      }
      
      private function moveMouse(param1:Event) : void
      {
         var cx:int = 0;
         var cy:int = 0;
         if(_sceneLoaded && _brush)
         {
            _brush.loader.x = mouseX;
            _brush.loader.y = mouseY;
            drawCellCursor();
            if(_drawing && (_currentTool == 1 || _currentTool == TOOL_ERASER))
            {
               cx = Math.floor(_drawCanvas.mouseX / _gridPixelSize);
               cy = Math.floor(_drawCanvas.mouseY / _gridPixelSize);
               if(_lastCellX < 0)
               {
                  paintCell(cx,cy);
               }
               else if(cx != _lastCellX || cy != _lastCellY)
               {
                  paintLine(_lastCellX,_lastCellY,cx,cy);
               }
               _lastCellX = cx;
               _lastCellY = cy;
            }
         }
      }
      
      override protected function sceneLoaded(param1:Event) : void
      {
         var _loc9_:Object = null;
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         _loc9_ = _scene.getLayer("closeButton");
         addBtn("CloseButton",_loc9_.x,_loc9_.y,onCloseButton);
         _interfaceObject = _scene.getLayer("interface");
         if(_sharedObject != null)
         {
            _submitButton = addBtn("artStudioPaint_submitButton",502,519,onSubmitButton);
            _submitButton.guiBtn.setGrayState(true);
            if(_sharedObject.data.userColors != null)
            {
               _interfaceObject.loader.content.loadColors(_sharedObject.data.userColors);
            }
         }
         _gridPixelSize = _interfaceObject.loader.content.pixelSize;
         _canvasW = int(_interfaceObject.loader.content.canvas.width);
         _canvasH = int(_interfaceObject.loader.content.canvas.height);
         _clearAllButton = addBtn("artStudioPaint_clearButton",290,519,onClearAllButton);
         _clearAllButton.guiBtn.setGrayState(true);
         _printBackground = _scene.getLayer("template");
         _printBackground.loader.x = 10000;
         _printBackground.loader.y = 10000;
         _printBtn = addBtn("artStudioPaint_printButton",230,519,onPrintButton);
         _printBtn.guiBtn.setGrayState(true);
         addBtn("artStudioPaint_sketchButton",170,519,onSketchButton);
         _masterpieceSubmitBtn = addBtn("artStudioPaint_createMasterpiece",740,519,onCreateMasterpieceBtn);
         _masterpieceSubmitBtn.guiBtn.setGrayState(true);
         _storageButton = addBtn("artStudioPaint_storageBtn",350,519,onStorageButton);
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
         startGame();
         _layerMouse.visible = false;
         _layerInterface.addChild(_interfaceObject.loader);
         _layerMouse.addChild(_brush.loader);
         _layerMouse.mouseEnabled = false;
         _layerMouse.mouseChildren = false;
         _layerGrid.visible = false;
         _layerGrid.mouseEnabled = false;
         _layerGrid.mouseChildren = false;
         var _loc3_:BitmapData = new BitmapData(_canvasW,_canvasH,true,16777215);
         var _loc7_:Bitmap = new Bitmap(_loc3_,"auto",false);
         _layerGrid.addChild(_loc7_);
         _layerGrid.x = 0;
         _layerGrid.y = 0;
         var _loc8_:Shape = new Shape();
         _loc8_.graphics.lineStyle(1,0,0.12,true);
         _loc4_ = _gridPixelSize;
         while(_loc4_ < _canvasW)
         {
            _loc8_.graphics.moveTo(_loc4_ - 1,0);
            _loc8_.graphics.lineTo(_loc4_ - 1,_canvasH);
            _loc4_ += _gridPixelSize;
         }
         _loc6_ = _gridPixelSize;
         while(_loc6_ < _canvasH)
         {
            _loc8_.graphics.moveTo(0,_loc6_ - 1);
            _loc8_.graphics.lineTo(_canvasW,_loc6_ - 1);
            _loc6_ += _gridPixelSize;
         }
         _loc3_.draw(_loc8_,null);
         _drawBitmapData = new BitmapData(_canvasW,_canvasH,true,4294967295);
         _drawBitmap = new Bitmap(_drawBitmapData,"auto",false);
         _drawCanvas = new Sprite();
         _drawCanvas.addEventListener("mouseDown",startDraw);
         _drawCanvas.addEventListener("mouseOver",drawCanvasMouseOver);
         _drawCanvas.addEventListener("mouseOut",drawCanvasMouseOut);
         _drawCanvas.addChild(_drawBitmap);
         _drawCanvas.x = 0;
         _drawCanvas.y = 0;
         _drawing = false;
         _drawBitmapDataSnapShot = new BitmapData(_canvasW,_canvasH,true,4294967295);
         _drawBitmapSnapShot = new Bitmap(_drawBitmapDataSnapShot,"auto",false);
         _defaultBitmapData = new BitmapData(_canvasW,_canvasH,true,4294967295);
         _drawBitmapUndoSnapShot = new BitmapData(_canvasW,_canvasH,true,4294967295);
         _drawBitmapUndo = new Bitmap(_drawBitmapUndoSnapShot,"auto",false);
         _drawBitmapDataRect = _drawBitmapData.rect;
         _drawPoint_0_0 = new Point(0,0);
         _interfaceObject.loader.content.canvas.addChild(_drawCanvas);
         _interfaceObject.loader.content.canvas.addChild(_layerGrid);
         _cellCursor = new Shape();
         _cellCursor.visible = false;
         _interfaceObject.loader.content.canvas.addChild(_cellCursor);
         _undoable = false;
         buildModUI();
         super.sceneLoaded(param1);
      }
      
      private function drawCanvasMouseOver(param1:MouseEvent) : void
      {
         _layerGrid.visible = true;
         if(ArtStudioKit.isPlacing())
         {
            return;
         }
         Mouse.hide();
         _layerMouse.visible = true;
      }
      
      private function drawCanvasMouseOut(param1:MouseEvent) : void
      {
         Mouse.show();
         _layerMouse.visible = false;
         _layerGrid.visible = _showGrid;
         _cellCursor.visible = false;
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
            _keepAliveTimer++;
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
            syncNativeTool();
            ArtStudioKit.syncColorPanel(_colorPanel);
         }
      }
      
      public function startGame() : void
      {
         if(_sceneLoaded)
         {
         }
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
         var _loc5_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
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
         if(!_exitConfirmationActive && _hasDrawn)
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
                  _numMasterpieceTokens++;
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
               if(param1.itemLayer.numChildren > 0)
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
            _loc6_ = _chooseMasterpiecePopup["iw" + param1];
            _loc5_ = new Bitmap(Utility.resizeImage(_drawBitmapData.clone(),_loc4_.itemWindow.width,_loc4_.itemWindow.height,true),"auto",true);
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
            _loc6_.newTag.visible = param1 == 0 && _itemOffset == 0;
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
         _masterpiecePreviewPopup = new MasterpiecePreview(_guiLayer,_numMasterpieceTokens,"",gMainFrame.userInfo.myUserName,gMainFrame.clientInfo.dbUserId,gMainFrame.userInfo.myUUID,_currItemVersion,onPreviewClose,gMainFrame.userInfo.myUserName,null,new Bitmap(_drawBitmapData.clone(),"auto",true),true);
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
            setupRequest(null,null,20,0,_isUsingTokens,1,false);
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
         _jpgEncoder.encode(_drawBitmapData);
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
         var _loc5_:Number = NaN;
         _jpgEncoder.removeEventListener("JPEGAsyncComplete",asyncEncodingComplete);
         _jpgEncoder.removeEventListener("progress",onEncodingProgress);
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
                  _loc5_ = _loc5_ - _sharedObject.data.userSubmits[0];
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
         if(_hasDrawn)
         {
            pushUndo();
         }
         _drawBitmapData.fillRect(_drawBitmapDataRect,4294967295);
         _timeSinceErase = 0;
         _needsSave = false;
         syncCanvasButtons();
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
         var _loc10_:URLLoader = new URLLoader();
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
         for(var _loc6_ in param4)
         {
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
         var _loc1_:FileReference = null;
         var _loc2_:ByteArray = null;
         try
         {
            _loc1_ = new FileReference();
            _loc2_ = PNGEncoder.encode(_drawBitmapData);
            _loc2_ = _mediaObject["%&"](gMainFrame.userInfo.myUUID,_loc2_,true);
            _loc1_.addEventListener("complete",handleSaveComplete);
            _loc1_.save(_loc2_,"painting.ajgart");
         }
         catch(e:Error)
         {
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
         var _loc2_:BitmapData = null;
         try
         {
            _loc2_ = param1.target.content.bitmapData;
            pushUndo();
            _drawPoint_0_0 = new Point(0,0);
            _drawBitmapData.copyPixels(_loc2_,_loc2_.rect,_drawPoint_0_0);
            _needsSave = false;
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
            _loc1_ = new FileFilter("AJGArt Files (*.ajgart)","*.*");
            _loc2_.push(_loc1_);
            _fileRef.browse(_loc2_);
         }
         catch(e:Error)
         {
         }
      }
      
      // Fills every cell between two cells (Bresenham), so a quick stroke
      // doesn't skip cells the way the vanilla per-frame stamp did.
      private function paintLine(x0:int, y0:int, x1:int, y1:int) : void
      {
         var dx:int = Math.abs(x1 - x0);
         var dy:int = -Math.abs(y1 - y0);
         var sx:int = x0 < x1 ? 1 : -1;
         var sy:int = y0 < y1 ? 1 : -1;
         var err:int = dx + dy;
         var e2:int = 0;
         var guard:int = 0;
         _drawBitmapData.lock();
         while(guard < 4096)
         {
            paintCell(x0,y0);
            if(x0 == x1 && y0 == y1)
            {
               break;
            }
            e2 = 2 * err;
            if(e2 >= dy)
            {
               err += dy;
               x0 += sx;
            }
            if(e2 <= dx)
            {
               err += dx;
               y0 += sy;
            }
            guard++;
         }
         _drawBitmapData.unlock();
      }
      
      private function paintCell(cx:int, cy:int) : void
      {
         var px:int = _gridPixelSize;
         var cols:int = int(_canvasW / px);
         var color:uint = _currentTool == TOOL_ERASER ? 4294967295 : uint(4278190080 | ArtStudioKit.currentColor(_interfaceObject.loader.content));
         if(cx < 0 || cy < 0 || cx * px >= _canvasW || cy * px >= _canvasH)
         {
            return;
         }
         _drawBitmapData.fillRect(new Rectangle(cx * px,cy * px,px,px),color);
         if(_mirror)
         {
            _drawBitmapData.fillRect(new Rectangle((cols - 1 - cx) * px,cy * px,px,px),color);
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
         displayMasterpieceFailedPopup();
         SBTracker.trackPageview("/game/play/miniGame/#ColoringMasterpieceSendTimeout");
      }
      
      private function buildModUI() : void
      {
         ArtStudioKit.setTipLayer(_guiLayer);
         _colorPanel = ArtStudioKit.colorPanel(_layerInterface,128,5,_interfaceObject.loader.content);
         buildToolPanel();
         buildUndoButtons();
      }
      
      // Top right, between the title and the close button: eraser and colour
      // picker, grid and mirror toggles, then import/export.
      private function buildToolPanel() : void
      {
         var px:int = 604;
         var py:int = 5;
         var x:int = px + 8;
         ArtStudioKit.panel(_layerInterface,px,py,240,36);
         _toolBtns = {};
         x = addToolButton(TOOL_ERASER,"eraser","Eraser (E)",x,py + 4);
         x = addToolButton(TOOL_EYEDROP,"picker","Colour picker (I)",x,py + 4);
         ArtStudioKit.divider(_layerInterface,x + 2,py + 6,24);
         _gridBtn = ArtStudioKit.button("grid","Always show the grid (G)",30,28,onGridClick);
         _gridBtn.x = x + 8;
         _gridBtn.y = py + 4;
         _layerInterface.addChild(_gridBtn);
         _mirrorBtn = ArtStudioKit.button("mirror","Mirror: paint both halves (M)",30,28,onMirrorClick);
         _mirrorBtn.x = x + 42;
         _mirrorBtn.y = py + 4;
         _layerInterface.addChild(_mirrorBtn);
         x += 76;
         ArtStudioKit.divider(_layerInterface,x + 2,py + 6,24);
         _importBtn = ArtStudioKit.button("import","Import an image as pixel art",30,28,onImportClick);
         _importBtn.x = x + 8;
         _importBtn.y = py + 4;
         _layerInterface.addChild(_importBtn);
         _exportBtn = ArtStudioKit.button("export","Export as PNG",30,28,onExportClick);
         _exportBtn.x = x + 42;
         _exportBtn.y = py + 4;
         _layerInterface.addChild(_exportBtn);
      }
      
      private function addToolButton(tool:int, icon:String, tip:String, x:int, y:int) : int
      {
         var b:MovieClip = ArtStudioKit.button(icon,tip,30,28,onModToolClick);
         b.toolId = tool;
         b.x = x;
         b.y = y;
         _layerInterface.addChild(b);
         _toolBtns[tool] = b;
         return x + 34;
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
      }
      
      private function updateToolButtons() : void
      {
         for(var key:String in _toolBtns)
         {
            ArtStudioKit.setActive(_toolBtns[key],int(key) == _modTool);
         }
      }
      
      // The native toolbox marks its tool with h_2; hide it while a mod tool
      // is active and give it back when a native tool is clicked.
      private function syncNativeTool() : void
      {
         var c:Object = _interfaceObject.loader.content;
         var tool:int = int(c.currentTool);
         if(tool == 1 || tool == 5)
         {
            if(_modTool != 0)
            {
               _modTool = 0;
               updateToolButtons();
            }
            c.h_2.visible = true;
         }
         else
         {
            c.h_2.visible = false;
         }
      }
      
      private function pickColorAt(x:Number, y:Number) : void
      {
         var c:Object = _interfaceObject.loader.content;
         var mx:int = Math.max(0,Math.min(int(x),_canvasW - 1));
         var my:int = Math.max(0,Math.min(int(y),_canvasH - 1));
         ArtStudioKit.applyColor(c,int(_drawBitmapData.getPixel(mx,my)));
         AJAudio.playSubMenuBtnRollover();
         if(_toolBeforePick == 1 || _toolBeforePick == 5)
         {
            c.setTool(_toolBeforePick);
         }
         else if(_toolBeforePick == TOOL_ERASER)
         {
            selectModTool(TOOL_ERASER);
         }
         else
         {
            c.setTool(1);
         }
      }
      
      // Outlines the cell under the pointer (and its mirror twin), so it's
      // clear which pixel a click paints.
      private function drawCellCursor() : void
      {
         var px:int = _gridPixelSize;
         var cols:int = int(_canvasW / px);
         var cx:int = Math.floor(_drawCanvas.mouseX / px);
         var cy:int = Math.floor(_drawCanvas.mouseY / px);
         _cellCursor.graphics.clear();
         _cellCursor.visible = _layerMouse.visible;
         if(!_cellCursor.visible || cx < 0 || cy < 0 || cx >= cols || cy * px >= _canvasH)
         {
            return;
         }
         outlineCell(cx * px,cy * px,px);
         if(_mirror && cols - 1 - cx != cx)
         {
            outlineCell((cols - 1 - cx) * px,cy * px,px);
         }
      }
      
      private function outlineCell(x:int, y:int, px:int) : void
      {
         _cellCursor.graphics.lineStyle(1,0,0.85,true);
         _cellCursor.graphics.drawRect(x,y,px - 1,px - 1);
         _cellCursor.graphics.lineStyle(1,16777215,0.85,true);
         _cellCursor.graphics.drawRect(x + 1,y + 1,px - 3,px - 3);
      }
      
      private function onGridClick(e:MouseEvent) : void
      {
         _showGrid = !_showGrid;
         ArtStudioKit.setActive(_gridBtn,_showGrid);
         _layerGrid.visible = _showGrid || _layerMouse.visible;
      }
      
      private function onMirrorClick(e:MouseEvent) : void
      {
         _mirror = !_mirror;
         ArtStudioKit.setActive(_mirrorBtn,_mirror);
      }
      
      private function onKeyDown(e:KeyboardEvent) : void
      {
         var c:Object = _interfaceObject.loader.content;
         if(stage.focus is TextField || _exitConfirmationActive || ArtStudioKit.isPlacing())
         {
            return;
         }
         if(e.ctrlKey && e.keyCode == 90 && !e.shiftKey)
         {
            onUndoClick(null);
            return;
         }
         if(e.ctrlKey && e.keyCode == 89 || e.ctrlKey && e.shiftKey && e.keyCode == 90)
         {
            onRedoClick(null);
            return;
         }
         if(e.ctrlKey || e.altKey)
         {
            return;
         }
         switch(e.keyCode)
         {
            case 80:
               c.setTool(1);
               break;
            case 66:
               c.setTool(5);
               break;
            case 69:
               selectModTool(TOOL_ERASER);
               break;
            case 73:
               selectModTool(TOOL_EYEDROP);
               break;
            case 71:
               onGridClick(null);
               break;
            case 77:
               onMirrorClick(null);
         }
      }
      
      // Multi-step undo/redo replaces the native one-step undo button, in the
      // same spot at the bottom of the toolbox.
      private function buildUndoButtons() : void
      {
         var c:Object = _interfaceObject.loader.content;
         var r:Rectangle = c.tool_9.getBounds(_layerInterface);
         var w:int = 0;
         if(r.width < 40 || r.width > 140 || r.height < 16 || r.height > 50)
         {
            r = new Rectangle(27,495,84,38);
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
      
      private function pushUndo() : void
      {
         _undoStack.push(_drawBitmapData.clone());
         while(_undoStack.length > MAX_UNDO)
         {
            (_undoStack.shift() as BitmapData).dispose();
         }
         clearRedo();
         updateUndoRedoUI();
      }
      
      private function clearRedo() : void
      {
         while(_redoStack.length > 0)
         {
            (_redoStack.pop() as BitmapData).dispose();
         }
      }
      
      private function onUndoClick(e:MouseEvent) : void
      {
         var bd:BitmapData = null;
         if(_undoStack.length == 0 || _drawing)
         {
            return;
         }
         _redoStack.push(_drawBitmapData.clone());
         bd = _undoStack.pop();
         _drawBitmapData.copyPixels(bd,bd.rect,_drawPoint_0_0);
         bd.dispose();
         _needsSave = true;
         syncCanvasButtons();
         updateUndoRedoUI();
      }
      
      private function onRedoClick(e:MouseEvent) : void
      {
         var bd:BitmapData = null;
         if(_redoStack.length == 0 || _drawing)
         {
            return;
         }
         _undoStack.push(_drawBitmapData.clone());
         bd = _redoStack.pop();
         _drawBitmapData.copyPixels(bd,bd.rect,_drawPoint_0_0);
         bd.dispose();
         _needsSave = true;
         syncCanvasButtons();
         updateUndoRedoUI();
      }
      
      private function updateUndoRedoUI() : void
      {
         ArtStudioKit.setEnabled(_undoBtn,_undoStack.length > 0);
         ArtStudioKit.setEnabled(_redoBtn,_redoStack.length > 0);
      }
      
      private function markDrawn() : void
      {
         _needsSave = true;
         syncCanvasButtons();
      }
      
      // Grays the native create / print / clear buttons while the canvas is
      // blank (all white), and enables them otherwise.
      private function syncCanvasButtons() : void
      {
         var has:Boolean = _drawBitmapData.getColorBoundsRect(4294967295,4294967295,false).width > 0;
         _hasDrawn = has;
         _masterpieceSubmitBtn.guiBtn.setGrayState(!has);
         if(_submitButton != null)
         {
            _submitButton.guiBtn.setGrayState(!has);
         }
         _printBtn.guiBtn.setGrayState(!has);
         _clearAllButton.guiBtn.setGrayState(!has);
      }
      
      private function onImportClick(e:MouseEvent) : void
      {
         _uploadFileRef = new FileReference();
         _uploadFileRef.addEventListener(Event.SELECT,onImportSelect);
         _uploadFileRef.browse([new FileFilter("Images (*.png, *.jpg, *.gif)","*.png;*.PNG;*.jpg;*.JPG;*.jpeg;*.JPEG;*.gif;*.GIF")]);
      }
      
      private function onImportSelect(e:Event) : void
      {
         _uploadFileRef.removeEventListener(Event.SELECT,onImportSelect);
         _uploadFileRef.addEventListener(Event.COMPLETE,onImportFileLoaded);
         _uploadFileRef.load();
      }
      
      private function onImportFileLoaded(e:Event) : void
      {
         var loader:Loader = new Loader();
         _uploadFileRef.removeEventListener(Event.COMPLETE,onImportFileLoaded);
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onImportDecoded);
         loader.loadBytes(_uploadFileRef.data);
      }
      
      private function onImportDecoded(e:Event) : void
      {
         var src:Bitmap = (e.target as LoaderInfo).content as Bitmap;
         if(src == null)
         {
            return;
         }
         _placingSrc = src.bitmapData.clone();
         src.bitmapData.dispose();
         (e.target as LoaderInfo).loader.unloadAndStop();
         _uploadFileRef = null;
         _cellCursor.visible = false;
         ArtStudioKit.beginPlace(_drawCanvas,_placingSrc,_canvasW,_canvasH,_layerInterface,496,56,onImagePlaced);
         if(_layerMouse.visible)
         {
            Mouse.show();
            _layerMouse.visible = false;
         }
      }
      
      // Turns the placed image into cells, one colour per cell, painted over
      // the existing drawing. Cells the image covers less than half of (by
      // alpha) are left alone.
      private function onImagePlaced(m:Matrix) : void
      {
         var px:int = _gridPixelSize;
         var cols:int = int(_canvasW / px);
         var rows:int = int(_canvasH / px);
         var small:BitmapData = null;
         var cell:Matrix = null;
         var argb:uint = 0;
         var cx:int = 0;
         var cy:int = 0;
         if(m != null && _drawBitmapData != null)
         {
            cell = m.clone();
            cell.scale(1 / px,1 / px);
            small = new BitmapData(cols,rows,true,0);
            small.draw(_placingSrc,cell,null,null,null,true);
            pushUndo();
            _drawBitmapData.lock();
            cy = 0;
            while(cy < rows)
            {
               cx = 0;
               while(cx < cols)
               {
                  argb = small.getPixel32(cx,cy);
                  if((argb >>> 24) >= 128)
                  {
                     _drawBitmapData.fillRect(new Rectangle(cx * px,cy * px,px,px),uint(4278190080 | argb & 16777215));
                  }
                  cx++;
               }
               cy++;
            }
            _drawBitmapData.unlock();
            small.dispose();
            markDrawn();
         }
         if(_placingSrc != null)
         {
            _placingSrc.dispose();
            _placingSrc = null;
         }
      }
      
      private function onExportClick(e:MouseEvent) : void
      {
         var fr:FileReference = null;
         try
         {
            fr = new FileReference();
            fr.save(PNGEncoder.encode(_drawBitmapData),"pixel-art.png");
         }
         catch(err:Error)
         {
            DebugUtility.debugTrace(err.message);
         }
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

