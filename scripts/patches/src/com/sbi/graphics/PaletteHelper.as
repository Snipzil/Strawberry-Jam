package com.sbi.graphics
{
   import flash.utils.ByteArray;
   
   public class PaletteHelper
   {
      
      public static var gamePalette:Array;
      
      public static var avatarPalette1:Array;
      
      public static var avatarPalette2:Array;
      
      private static const PALETTE_ALPHA_OFFSET:int = 25;
      
      public static var customColors:Object = {};

      // set once the server has sent "xcc": only a Burrow server does
      public static var serverSentCustomColors:Boolean = false;
      
      public static var onCustomRegistered:Function;
      
      public function PaletteHelper()
      {
         super();
      }
      
      public static function setGamePalette(param1:ByteArray, param2:ByteArray = null, param3:ByteArray = null) : void
      {
         var _loc4_:int = param1.length / 4;
         gamePalette = new Array(_loc4_);
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_)
         {
            gamePalette[_loc5_] = uint(_loc5_ << 24 | param1.readUnsignedInt() & 0xFFFFFF);
            _loc5_++;
         }
         if(param2)
         {
            _loc4_ = int(param2.length);
            avatarPalette1 = new Array(_loc4_);
            _loc5_ = 0;
            while(_loc5_ < _loc4_)
            {
               avatarPalette1[_loc5_++] = param2.readUnsignedByte();
            }
         }
         if(param3)
         {
            param3.position = 0;
            _loc4_ = int(param3.length);
            avatarPalette2 = new Array(_loc4_);
            _loc5_ = 0;
            while(_loc5_ < _loc4_)
            {
               avatarPalette2[_loc5_++] = param3.readUnsignedByte();
            }
         }
      }
      
      public static function isCustom(param1:uint) : Boolean
      {
         return customColors[param1] != null;
      }
      
      public static function resolve(param1:uint) : Array
      {
         var _loc2_:Array = customColors[param1];
         if(_loc2_ != null)
         {
            return _loc2_.concat();
         }
         return [uint(gamePalette[param1 >> 24 & 0xFF]) & 0xFFFFFF,uint(gamePalette[param1 >> 16 & 0xFF]) & 0xFFFFFF,uint(gamePalette[param1 >> 8 & 0xFF]) & 0xFFFFFF,uint(gamePalette[param1 & 0xFF]) & 0xFFFFFF];
      }
      
      public static function handleCustomColors(param1:Object) : void
      {
         var _loc2_:int = int(param1[2]);
         var _loc3_:int = 0;
         var _loc4_:int = 3;
         var _loc5_:uint = 0;
         var _loc6_:Array = null;
         serverSentCustomColors = true;
         while(_loc3_ < _loc2_)
         {
            _loc5_ = uint(param1[_loc4_]);
            _loc6_ = [uint(param1[_loc4_ + 1]) & 0xFFFFFF,uint(param1[_loc4_ + 2]) & 0xFFFFFF,uint(param1[_loc4_ + 3]) & 0xFFFFFF,uint(param1[_loc4_ + 4]) & 0xFFFFFF];
            customColors[_loc5_] = _loc6_;
            if(onCustomRegistered != null)
            {
               onCustomRegistered(_loc5_,_loc6_);
            }
            _loc4_ += 5;
            _loc3_++;
         }
      }
      
      public static function mixColors(param1:uint, param2:uint) : uint
      {
         var _loc7_:uint = uint(param1 >> 16 & 0xFF);
         var _loc5_:uint = uint(param1 >> 8 & 0xFF);
         var _loc8_:uint = uint(param1 & 0xFF);
         var _loc3_:uint = uint(param2 >> 16 & 0xFF);
         var _loc6_:uint = uint(param2 >> 8 & 0xFF);
         var _loc4_:uint = uint(param2 & 0xFF);
         _loc7_ = (_loc7_ + _loc3_) / 2;
         _loc5_ = (_loc5_ + _loc6_) / 2;
         _loc8_ = (_loc8_ + _loc4_) / 2;
         return _loc7_ << 16 | _loc5_ << 8 | _loc8_;
      }
      
      public static function setColorGradient(param1:Array, param2:uint, param3:uint, param4:uint) : void
      {
         var _loc9_:* = 0;
         var _loc6_:* = 0;
         var _loc12_:uint = uint(param2 >> 16 & 0xFF);
         var _loc7_:uint = uint(param2 >> 8 & 0xFF);
         var _loc5_:uint = uint(param2 & 0xFF);
         var _loc13_:uint = _loc12_ / (param4 + 2);
         var _loc10_:uint = _loc7_ / (param4 + 2);
         var _loc11_:uint = _loc5_ / (param4 + 2);
         var _loc8_:int = param3 + param4 - 1;
         _loc9_ = 0;
         while(_loc9_ < param4)
         {
            _loc6_ = uint(_loc12_ << 16 | _loc7_ << 8 | _loc5_);
            param1[_loc8_] = _loc6_ | -16777216;
            param1[_loc8_ + 25] = _loc6_ | -1073741824;
            param1[_loc8_ + 25 * 2] = _loc6_ | -2147483648;
            param1[_loc8_ + 25 * 3] = _loc6_ | 0x40000000;
            _loc12_ -= _loc13_;
            _loc7_ -= _loc10_;
            _loc5_ -= _loc11_;
            _loc8_--;
            _loc9_++;
         }
      }
      
      public static function AddRGB(param1:uint, param2:int, param3:int, param4:int) : uint
      {
         var _loc7_:int = param1 >> 24 & 0xFF;
         var _loc5_:int = param1 >> 16 & 0xFF;
         var _loc8_:int = param1 >> 8 & 0xFF;
         var _loc6_:int = param1 & 0xFF;
         _loc5_ += param2;
         if(_loc5_ < 0)
         {
            _loc5_ = 0;
         }
         else if(_loc5_ > 255)
         {
            _loc5_ = 255;
         }
         _loc8_ += param3;
         if(_loc8_ < 0)
         {
            _loc8_ = 0;
         }
         else if(_loc8_ > 255)
         {
            _loc8_ = 255;
         }
         _loc6_ += param4;
         if(_loc6_ < 0)
         {
            _loc6_ = 0;
         }
         else if(_loc6_ > 255)
         {
            _loc6_ = 255;
         }
         return uint(_loc7_ << 24 | _loc5_ << 16 | _loc8_ << 8 | _loc6_);
      }
      
      public static function getAnimalPalette() : Array
      {
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc3_:* = 0;
         var _loc4_:* = 0;
         var _loc1_:Array = new Array(4278255615,4286513152,4290707456,4294901760,4278222592,4278238976,4278255360,4278190207,4278190271,4278190335,4286545791,4290756543,4294967295,4282400768,4286611456,4278206528,4278222976,4282384448,4286578816,4286595136,4294934656,4282417216,4286644096,4282400896,4286611711,4278190080);
         var _loc2_:* = 4294967295;
         _loc5_ = 0;
         while(_loc5_ < 3)
         {
            _loc6_ = 1;
            while(_loc6_ <= 25)
            {
               _loc3_ = uint(_loc1_[_loc6_] & 0xFFFFFF);
               _loc4_ = uint(_loc3_ | _loc2_);
               _loc1_.push(_loc4_);
               _loc6_++;
            }
            _loc2_ -= 1073741824;
            _loc5_++;
         }
         return _loc1_;
      }
      
      public static function BuildAnimalPalette(param1:Array, param2:uint, param3:uint, param4:uint, param5:uint) : void
      {
         var _loc6_:Array = customColors[uint((param2 >>> 24) << 24 | (param3 >>> 24) << 16 | (param4 >>> 24) << 8 | param5 >>> 24)];
         if(_loc6_ != null)
         {
            param2 = uint(_loc6_[0]);
            param3 = uint(_loc6_[1]);
            param4 = uint(_loc6_[2]);
            param5 = uint(_loc6_[3]);
         }
         setColorGradient(param1,param2,1,3);
         setColorGradient(param1,param3,4,3);
         setColorGradient(param1,param4,7,3);
         setColorGradient(param1,param5,10,3);
         setColorGradient(param1,PaletteHelper.mixColors(param2,param3),13,2);
         setColorGradient(param1,PaletteHelper.mixColors(param3,param4),15,2);
         setColorGradient(param1,PaletteHelper.mixColors(param2,param4),17,2);
         setColorGradient(param1,PaletteHelper.mixColors(param2,param5),19,2);
         setColorGradient(param1,PaletteHelper.mixColors(param3,param5),21,2);
         setColorGradient(param1,PaletteHelper.mixColors(param4,param5),23,2);
      }
      
      public static function adjustPaletteColor(param1:Array, param2:uint) : void
      {
         var _loc7_:int = 0;
         var _loc6_:* = 0;
         var _loc5_:int = 0;
         var _loc10_:int = 0;
         var _loc12_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Number = NaN;
         var _loc8_:Number = (param2 >> 24 & 0xFF) / 255;
         var _loc9_:int = param2 >> 16 & 0xFF;
         var _loc11_:int = param2 >> 8 & 0xFF;
         var _loc13_:int = param2 & 0xFF;
         while(_loc7_ < param1.length)
         {
            _loc6_ = uint(param1[_loc7_]);
            _loc5_ = _loc6_ >> 24 & 0xFF;
            _loc10_ = _loc6_ >> 16 & 0xFF;
            _loc12_ = _loc6_ >> 8 & 0xFF;
            _loc3_ = _loc6_ & 0xFF;
            _loc4_ = _loc9_ - _loc10_;
            _loc4_ = _loc4_ * _loc8_;
            _loc10_ += _loc4_;
            if(_loc10_ < 0)
            {
               _loc10_ = 0;
            }
            else if(_loc10_ > 255)
            {
               _loc10_ = 255;
            }
            _loc4_ = _loc11_ - _loc12_;
            _loc4_ = _loc4_ * _loc8_;
            _loc12_ += _loc4_;
            if(_loc12_ < 0)
            {
               _loc12_ = 0;
            }
            else if(_loc12_ > 255)
            {
               _loc12_ = 255;
            }
            _loc4_ = _loc13_ - _loc3_;
            _loc4_ = _loc4_ * _loc8_;
            _loc3_ += _loc4_;
            if(_loc3_ < 0)
            {
               _loc3_ = 0;
            }
            else if(_loc3_ > 255)
            {
               _loc3_ = 255;
            }
            param1[_loc7_] = uint(_loc5_ << 24 | _loc10_ << 16 | _loc12_ << 8 | _loc3_);
            _loc7_++;
         }
      }
      
      public static function getHexColorsFromPalette(param1:uint) : Array
      {
         return resolve(param1);
      }
      
      public static function getRGBColors(param1:uint) : Array
      {
         var _loc3_:Array = resolve(param1);
         var _loc2_:Array = [];
         _loc2_[0] = decToRGBObj(_loc3_[0]);
         _loc2_[1] = decToRGBObj(_loc3_[1]);
         _loc2_[2] = decToRGBObj(_loc3_[2]);
         _loc2_[3] = decToRGBObj(_loc3_[3]);
         return _loc2_;
      }
      
      private static function decToRGBObj(param1:uint) : Object
      {
         return {
            "r":param1 >> 16 & 0xFF,
            "g":param1 >> 8 & 0xFF,
            "b":param1 & 0xFF
         };
      }
   }
}

