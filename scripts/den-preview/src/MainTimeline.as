package PlushiePetKitten_Floor_fla
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.geom.Rectangle;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;

   // Den item preview for the Burrow item finder (assets/client/burrowItems.js
   // serves this, the item and the report endpoint from 127.0.0.1). It loads
   // one den item's SWF the way the game's DenItemHelper does, picks a
   // version with the item's own setVersion, fits it to the stage, and
   // reports getVersions() back to "report", which the finder reads to offer
   // the versions. Flashvars: t (the item's token), v (the version).
   // Built from a den item SWF whose MainTimeline this replaces
   // (scripts/den-preview/README.md); `item1` is the instance its timeline
   // still names.
   public dynamic class MainTimeline extends MovieClip
   {

      public var item1:MovieClip;

      private var _loader:Loader;

      private var _reporter:URLLoader;

      private var _token:String;

      private var _version:int;

      public function MainTimeline()
      {
         super();
         stop();
         var params:Object = loaderInfo.parameters;
         _token = String(params.t || "");
         _version = int(params.v || 0);
         if(!/^[a-f0-9]{8,40}$/.test(_token))
         {
            return;
         }
         addEventListener(Event.ENTER_FRAME,clearBase);
         _loader = new Loader();
         _loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoaded);
         _loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,onFailed);
         _loader.load(new URLRequest("item/" + _token + ".swf"),new LoaderContext(false,new ApplicationDomain()));
      }

      // the base item's own art, which this SWF was built from
      private function clearBase(event:Event) : void
      {
         removeEventListener(Event.ENTER_FRAME,clearBase);
         var i:int = numChildren - 1;
         while(i >= 0)
         {
            if(getChildAt(i) != _loader)
            {
               removeChildAt(i);
            }
            i--;
         }
      }

      private function onLoaded(event:Event) : void
      {
         var content:Object = _loader.content;
         var versions:Array = null;
         try
         {
            if(content.hasOwnProperty("getVersions"))
            {
               versions = content.getVersions() as Array;
            }
         }
         catch(e:Error)
         {
            versions = null;
         }
         try
         {
            if(content.hasOwnProperty("setVersion"))
            {
               content.setVersion(_version);
            }
         }
         catch(e:Error)
         {
         }
         clearBase(null);
         addChild(_loader);
         fit();
         report(versions ? versions.join(",") : "");
      }

      // the art centred and scaled to fill most of the stage
      private function fit() : void
      {
         var bounds:Rectangle = _loader.getBounds(_loader);
         if(bounds.width <= 0 || bounds.height <= 0)
         {
            return;
         }
         var width:Number = loaderInfo.width;
         var height:Number = loaderInfo.height;
         var scale:Number = Math.min(width * 0.9 / bounds.width,height * 0.9 / bounds.height,3);
         _loader.scaleX = _loader.scaleY = scale;
         _loader.x = (width - bounds.width * scale) / 2 - bounds.x * scale;
         _loader.y = (height - bounds.height * scale) / 2 - bounds.y * scale;
      }

      private function onFailed(event:IOErrorEvent) : void
      {
         report("error");
      }

      private function report(versions:String) : void
      {
         _reporter = new URLLoader();
         _reporter.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void
         {
         });
         _reporter.load(new URLRequest("report?t=" + _token + "&versions=" + encodeURIComponent(versions)));
      }
   }
}
