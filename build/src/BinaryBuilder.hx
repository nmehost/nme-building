import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class BinaryBuilder extends Builder
{
   public function new(inBs:BuildServer, name:String, url:String)
   {
      super(inBs,name,true,url);
      useLatestProjects(["hxcpp"]);
   }

   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );
      for(depend in depends)
         depend.updateHaxelib();

      var dir = getCheckoutDir();
      Sys.setCwd(dir + "/project" );

      if (inBinary=="windows")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-windows.tgz", "ndll/Windows", "lib/Windows"]);
      }
      else if (inBinary=="mac")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-mac.tgz", "ndll/Mac", "ndll/Mac64", "lib/Mac", "lib/Mac64"]);
      }
      else if (inBinary=="ios")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-ios.tgz", "lib/IPhone"]);
      }
      else if (inBinary=="android")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-android.tgz", "ndll/Android", "lib/Android"]);
      }
      else if (inBinary=="linux")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-linux.tgz", "ndll/Linux", "ndll/Linux64", "lib/Linux", "lib/Linux64" ]);
      }
      else if (inBinary=="rpi")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-rpi.tgz", "ndll/RPi"]);
      }
      else
      {
         throw "Unknown binary " + inBinary;
      }

      sendBinary(name + "-bin-" + inBinary +".tgz");
      updateBinary(inBinary);
   }
}



