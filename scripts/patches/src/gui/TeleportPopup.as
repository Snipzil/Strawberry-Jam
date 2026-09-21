package gui
{
   import avatar.Avatar;
   import avatar.AvatarManager;
   import buddy.BuddyXtCommManager;
   import com.sbi.popup.SBOkPopup;
   import flash.display.MovieClip;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import loader.MediaHelper;
   import room.RoomManagerWorld;
   
   public class TeleportPopup
   {
      
      private var _teleportPopup:MovieClip;
      
      private var _mediaHelper:MediaHelper;
      
      private var _closeCallback:Function;
      
      private var _predictiveTextManager:PredictiveTextManager;
      
      public function TeleportPopup(param1:Function)
      {
         super();
         _closeCallback = param1;
         DarkenManager.showLoadingSpiral(true);
         createTeleportInterface();
      }
      
      private function createTeleportInterface() : void
      {
         var titleTxt:TextField;
         var usernameTxt:TextField;
         var teleportBtn:MovieClip;
         var closeBtn:MovieClip;
         _teleportPopup = new MovieClip();
         var bg:MovieClip = ModMenuUIHelper.createPopupBackground(400,200,0.9);
         bg.x = -200;
         bg.y = -100;
         _teleportPopup.addChild(bg);
         titleTxt = new TextField();
         titleTxt.text = "Teleport to Player";
         titleTxt.textColor = 16777215;
         titleTxt.x = -120;
         titleTxt.y = -80;
         titleTxt.width = 240;
         titleTxt.height = 30;
         titleTxt.selectable = false;
         _teleportPopup.addChild(titleTxt);
         usernameTxt = new TextField();
         usernameTxt.type = "input";
         usernameTxt.border = true;
         usernameTxt.borderColor = ModMenuUIHelper.COLOR_BORDER;
         usernameTxt.background = true;
         usernameTxt.backgroundColor = 1118481;
         usernameTxt.textColor = ModMenuUIHelper.COLOR_TEXT;
         usernameTxt.x = -150;
         usernameTxt.y = -40;
         usernameTxt.width = 300;
         usernameTxt.height = 25;
         usernameTxt.maxChars = 32;
         usernameTxt.text = "";
         try
         {
            usernameTxt.restrict = Utility.getUsernameRestrictions();
         }
         catch(e:Error)
         {
            usernameTxt.restrict = "a-zA-Z0-9";
         }
         _teleportPopup.addChild(usernameTxt);
         _teleportPopup.usernameTxt = usernameTxt;
         teleportBtn = ModMenuUIHelper.createButton("Teleport",5025616);
         teleportBtn.x = -80;
         teleportBtn.y = 20;
         _teleportPopup.addChild(teleportBtn);
         _teleportPopup.teleportBtn = teleportBtn;
         try
         {
            closeBtn = ModMenuUIHelper.createCloseXButton();
            closeBtn.x = 165;
            closeBtn.y = -80;
            closeBtn.addEventListener("mouseDown",onCloseBtn,false,0,true);
            closeBtn.addEventListener("click",onCloseBtn,false,0,true);
            _teleportPopup.closeBtn = closeBtn;
            _teleportPopup.addChild(closeBtn);
         }
         catch(closeBtnError:Error)
         {
         }
         _teleportPopup.x = 450;
         _teleportPopup.y = 275;
         GuiManager.guiLayer.addChild(_teleportPopup);
         DarkenManager.darken(_teleportPopup);
         gMainFrame.stage.focus = usernameTxt;
         addEventListeners();
         DarkenManager.showLoadingSpiral(false);
      }
      
      private function addEventListeners() : void
      {
         _teleportPopup.addEventListener("mouseDown",onPopup,false,0,true);
         _teleportPopup.teleportBtn.addEventListener("mouseDown",onTeleportBtn,false,0,true);
         _teleportPopup.closeBtn.addEventListener("mouseDown",onCloseBtn,false,0,true);
         _teleportPopup.usernameTxt.addEventListener("keyDown",keyDownListener,false,0,true);
      }
      
      private function removeEventListeners() : void
      {
         _teleportPopup.removeEventListener("mouseDown",onPopup);
         _teleportPopup.teleportBtn.removeEventListener("mouseDown",onTeleportBtn);
         if(_teleportPopup.closeBtn)
         {
            _teleportPopup.closeBtn.removeEventListener("mouseDown",onCloseBtn);
            _teleportPopup.closeBtn.removeEventListener("click",onCloseBtn);
         }
         _teleportPopup.usernameTxt.removeEventListener("keyDown",keyDownListener);
      }
      
      private function onPopup(param1:MouseEvent) : void
      {
         param1.stopPropagation();
      }
      
      private function onTeleportBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         performTeleport();
      }
      
      private function onCloseBtn(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         destroy();
      }
      
      private function keyDownListener(param1:KeyboardEvent) : void
      {
         param1.stopPropagation();
         if(param1.keyCode == 13)
         {
            performTeleport();
         }
         else if(param1.keyCode == 27)
         {
            destroy();
         }
      }
      
      private function performTeleport() : void
      {
         var username:String;
         try
         {
            if(!_teleportPopup || !_teleportPopup.usernameTxt)
            {
               return;
            }
            username = _teleportPopup.usernameTxt.text;
            if(!username)
            {
               username = "";
            }
            while(username.length > 0 && (username.charAt(0) == " " || username.charAt(0) == "\t"))
            {
               username = username.substr(1);
            }
            while(username.length > 0 && (username.charAt(username.length - 1) == " " || username.charAt(username.length - 1) == "\t"))
            {
               username = username.substr(0,username.length - 1);
            }
            if(username == "")
            {
               new SBOkPopup(GuiManager.guiLayer,"Please enter a username.");
               return;
            }
            if(!gMainFrame || !gMainFrame.userInfo || !gMainFrame.userInfo.myUserName)
            {
               new SBOkPopup(GuiManager.guiLayer,"User information not available.");
               return;
            }
            if(username.toLowerCase() == gMainFrame.userInfo.myUserName.toLowerCase())
            {
               new SBOkPopup(GuiManager.guiLayer,"You cannot teleport to yourself!");
               return;
            }
            teleportToPlayer(username);
         }
         catch(error:Error)
         {
            new SBOkPopup(GuiManager.guiLayer,"Teleportation error: " + error.message);
         }
      }
      
      private function teleportToPlayer(username:String) : void
      {
         var roomMgr:RoomManagerWorld = RoomManagerWorld.instance;
         if(!roomMgr)
         {
            new SBOkPopup(GuiManager.guiLayer,"Teleportation failed - room manager not available.");
            return;
         }
         var targetAvatar:Avatar = AvatarManager.getAvatarByUserName(username);
         if(targetAvatar != null)
         {
            roomMgr.setGotoUsername(username,true);
            new SBOkPopup(GuiManager.guiLayer,"Teleporting to " + username + " in current room!");
            destroy();
            return;
         }
         new SBOkPopup(GuiManager.guiLayer,"Searching for " + username + " across all rooms...");
         BuddyXtCommManager.sendBuddyRoomRequest(username,onPlayerLocationFound);
      }
      
      private function onPlayerLocationFound(buddyRoomName:String, buddyRoomDisplay:String, isOffline:Boolean) : void
      {
         var username:String = _teleportPopup ? _teleportPopup.usernameTxt.text : "unknown";
         while(username.length > 0 && (username.charAt(0) == " " || username.charAt(0) == "\t"))
         {
            username = username.substr(1);
         }
         while(username.length > 0 && (username.charAt(username.length - 1) == " " || username.charAt(username.length - 1) == "\t"))
         {
            username = username.substr(0,username.length - 1);
         }
         if(isOffline || !buddyRoomName || buddyRoomName == "" || buddyRoomName == "Unknown")
         {
            new SBOkPopup(GuiManager.guiLayer,"Player \'" + username + "\' is offline or not found.");
            return;
         }
         var currentRoomName:String = gMainFrame.server.getCurrentRoomName();
         var nodeIndex:int = int(buddyRoomName.indexOf("@"));
         var targetNode:String = null;
         var targetRoomName:String = buddyRoomName;
         if(nodeIndex >= 0)
         {
            targetNode = buddyRoomName.substr(nodeIndex + 1);
            targetRoomName = buddyRoomName.substring(0,nodeIndex);
         }
         if(currentRoomName == buddyRoomName)
         {
            var roomMgr:RoomManagerWorld = RoomManagerWorld.instance;
            roomMgr.setGotoUsername(username,true);
            new SBOkPopup(GuiManager.guiLayer,"Found " + username + " in current room!");
            destroy();
            return;
         }
         if(targetNode && targetNode != gMainFrame.server.serverIp)
         {
            new SBOkPopup(GuiManager.guiLayer,"Teleporting to " + username + " on different server...");
            roomMgr = RoomManagerWorld.instance;
            if(roomMgr)
            {
               roomMgr.setGotoUsername(username,false);
            }
            gMainFrame.clientInfo.autoStartRoom = username;
            gMainFrame.clientInfo.autoStartRoomShardId = -3;
            if(gMainFrame.switchServersIfNeeded(targetNode))
            {
               destroy();
            }
            else
            {
               new SBOkPopup(GuiManager.guiLayer,"Failed to switch servers for teleportation.");
            }
         }
         else
         {
            new SBOkPopup(GuiManager.guiLayer,"Teleporting to " + username + " in " + (buddyRoomDisplay || targetRoomName) + "... (will keep retrying if the room is full)");
            roomMgr = RoomManagerWorld.instance;
            if(roomMgr)
            {
               roomMgr.setGotoUsername(username,false);
            }
            GuiManager.beginRoomJoinRetry(buddyRoomName,username);
            destroy();
         }
      }
      
      public function destroy() : void
      {
         var closeCallback:Function = null;
         if(_teleportPopup)
         {
            if(_closeCallback != null)
            {
               closeCallback = _closeCallback;
               _closeCallback = null;
               closeCallback();
               return;
            }
            removeEventListeners();
            DarkenManager.unDarken(_teleportPopup);
            GuiManager.guiLayer.removeChild(_teleportPopup);
            _teleportPopup = null;
         }
      }
   }
}

