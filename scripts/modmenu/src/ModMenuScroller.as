package gui
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.utils.getTimer;

   public class ModMenuScroller
   {

      private var _container:Sprite;

      private var _scrollY:int = 0;

      private var _maxScrollY:int = 0;

      private var _startY:int;

      private var _maskHeight:int;

      private var _lastScrollTime:int = 0;

      private var _scrollUpBtn:MovieClip;

      private var _scrollDownBtn:MovieClip;

      private var _track:MovieClip;

      private var _thumb:MovieClip;

      private var _trackHeight:int = 0;

      private var _dragging:Boolean = false;

      private var _dragOffset:Number = 0;

      private var _dragStage:Stage;

      private var _onScrollChangeCallback:Function;

      public function ModMenuScroller(param1:Sprite, param2:int, param3:int)
      {
         super();
         _container = param1;
         _startY = param2;
         _maskHeight = param3;
      }

      public function setOnScrollChangeCallback(callback:Function) : void
      {
         _onScrollChangeCallback = callback;
      }

      public function setScrollButtons(param1:MovieClip, param2:MovieClip) : void
      {
         _scrollUpBtn = param1;
         _scrollDownBtn = param2;
      }

      public function setScrollTrack(track:MovieClip, thumb:MovieClip, trackHeight:int) : void
      {
         _track = track;
         _thumb = thumb;
         _trackHeight = trackHeight;
         if(_track)
         {
            _track.addEventListener("mouseDown",onTrackDown,false,0,false);
         }
         if(_thumb)
         {
            _thumb.addEventListener("mouseDown",onThumbDown,false,0,false);
         }
         updateScrollButtons();
      }

      public function calculateMaxScroll() : void
      {
         var contentHeight:int = _container.height;
         _maxScrollY = Math.max(0,contentHeight - _maskHeight);
         updateScrollButtons();
      }

      public function setMaxScrollForHeight(contentHeight:int) : void
      {
         _maxScrollY = Math.max(0,contentHeight - _maskHeight);
         if(_scrollY > _maxScrollY)
         {
            _scrollY = _maxScrollY;
            _container.y = _startY - _scrollY;
         }
         updateScrollButtons();
      }

      public function scrollContent(delta:int) : void
      {
         var oldScrollY:int = _scrollY;
         _scrollY = Math.max(0,Math.min(_maxScrollY,_scrollY + delta));
         _container.y = _startY - _scrollY;
         updateScrollButtons();
         _lastScrollTime = getTimer();
         if(_onScrollChangeCallback != null && _scrollY != oldScrollY)
         {
            _onScrollChangeCallback(_scrollY);
         }
      }

      public function resetScroll() : void
      {
         _scrollY = 0;
         _container.y = _startY;
         updateScrollButtons();
      }

      public function updateScrollButtons() : void
      {
         var canScroll:Boolean = _maxScrollY > 0;
         var thumbH:int;
         var ratio:Number;
         if(_scrollUpBtn)
         {
            _scrollUpBtn.alpha = canScroll && _scrollY > 0 ? 1 : 0.35;
            _scrollUpBtn.mouseEnabled = true;
         }
         if(_scrollDownBtn)
         {
            _scrollDownBtn.alpha = canScroll && _scrollY < _maxScrollY ? 1 : 0.35;
            _scrollDownBtn.mouseEnabled = true;
         }
         if(_track)
         {
            _track.alpha = canScroll ? 1 : 0.35;
         }
         if(_thumb && _track)
         {
            if(!canScroll)
            {
               _thumb.visible = false;
            }
            else
            {
               _thumb.visible = true;
               thumbH = int(_trackHeight * (_maskHeight / (_maskHeight + _maxScrollY)));
               if(thumbH < 24)
               {
                  thumbH = 24;
               }
               if(thumbH > _trackHeight)
               {
                  thumbH = _trackHeight;
               }
               if(int(_thumb["thumbHeight"]) != thumbH)
               {
                  ModMenuUIHelper.drawThumb(_thumb,thumbH,_dragging);
               }
               ratio = _maxScrollY > 0 ? _scrollY / _maxScrollY : 0;
               _thumb.x = _track.x;
               _thumb.y = _track.y + (_trackHeight - thumbH) * ratio;
            }
         }
      }

      public function onMouseWheel(e:MouseEvent) : Boolean
      {
         var target:* = e.target;
         if(target && target is TextField && TextField(target).type == "input")
         {
            return false;
         }
         if(_maxScrollY <= 0)
         {
            return false;
         }
         var currentTime:int = getTimer();
         if(currentTime - _lastScrollTime < 16)
         {
            return false;
         }
         var delta:int = e.delta > 0 ? -50 : 50;
         scrollContent(delta);
         return true;
      }

      public function onScrollUp(e:MouseEvent) : void
      {
         e.stopPropagation();
         var currentTime:int = getTimer();
         if(currentTime - _lastScrollTime < 50)
         {
            return;
         }
         scrollContent(-100);
      }

      public function onScrollDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         var currentTime:int = getTimer();
         if(currentTime - _lastScrollTime < 50)
         {
            return;
         }
         scrollContent(100);
      }

      private function onTrackDown(e:MouseEvent) : void
      {
         var thumbH:int;
         var ratio:Number;
         e.stopPropagation();
         if(!_track || _maxScrollY <= 0 || _trackHeight <= 0)
         {
            return;
         }
         thumbH = _thumb ? int(_thumb["thumbHeight"]) : 24;
         ratio = (_track.mouseY - thumbH / 2) / (_trackHeight - thumbH);
         setScrollY(int(ratio * _maxScrollY));
      }

      private function onThumbDown(e:MouseEvent) : void
      {
         e.stopPropagation();
         if(!_thumb || _maxScrollY <= 0)
         {
            return;
         }
         _dragging = true;
         _dragOffset = _thumb.mouseY;
         _dragStage = _thumb.stage;
         if(_dragStage)
         {
            _dragStage.addEventListener("mouseMove",onDragMove,false,0,false);
            _dragStage.addEventListener("mouseUp",onDragUp,false,0,false);
         }
         ModMenuUIHelper.drawThumb(_thumb,int(_thumb["thumbHeight"]),true);
      }

      private function onDragMove(e:MouseEvent) : void
      {
         var thumbH:int;
         var localY:Number;
         var ratio:Number;
         if(!_dragging || !_track || !_thumb)
         {
            return;
         }
         thumbH = int(_thumb["thumbHeight"]);
         localY = _track.mouseY - _dragOffset;
         ratio = localY / (_trackHeight - thumbH);
         setScrollY(int(ratio * _maxScrollY));
         e.updateAfterEvent();
      }

      private function onDragUp(e:MouseEvent) : void
      {
         stopDrag();
      }

      private function stopDrag() : void
      {
         _dragging = false;
         if(_dragStage)
         {
            _dragStage.removeEventListener("mouseMove",onDragMove);
            _dragStage.removeEventListener("mouseUp",onDragUp);
            _dragStage = null;
         }
         if(_thumb)
         {
            ModMenuUIHelper.drawThumb(_thumb,int(_thumb["thumbHeight"]),false);
         }
      }

      public function destroy() : void
      {
         stopDrag();
         if(_track)
         {
            _track.removeEventListener("mouseDown",onTrackDown);
         }
         if(_thumb)
         {
            _thumb.removeEventListener("mouseDown",onThumbDown);
         }
         _track = null;
         _thumb = null;
         _scrollUpBtn = null;
         _scrollDownBtn = null;
         _onScrollChangeCallback = null;
      }

      public function getScrollY() : int
      {
         return _scrollY;
      }

      public function getMaxScrollY() : int
      {
         return _maxScrollY;
      }

      public function setScrollY(value:int) : void
      {
         var oldScrollY:int = _scrollY;
         _scrollY = Math.max(0,Math.min(_maxScrollY,value));
         _container.y = _startY - _scrollY;
         updateScrollButtons();
         if(_onScrollChangeCallback != null && _scrollY != oldScrollY)
         {
            _onScrollChangeCallback(_scrollY);
         }
      }
   }
}
