import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme",true, "https://github.com/nmehost/nme");
      removeBinaries(["rpi"]);
      writeVersionFilename = "project/include/NmeVersion.h";
      writeBinaryVersionFilename = "project/include/NmeBinVersion.h";
      writeHaxeVersionPackage = "nme";
      changesFile = "Changes.txt";
   }

   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );

      var dir = getCheckoutDir();
      Sys.setCwd(dir + "/project" );

      if (inBinary=="windows")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-windows.tgz", "ndll/Windows", "lib/Windows"]);
      }
      else if (inBinary=="mac")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-mac.tgz", "ndll/Mac", "ndll/Mac64", "lib/Mac", "lib/Mac64"]);
      }
      else if (inBinary=="ios")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-ios.tgz", "lib/IPhone"]);
      }
      else if (inBinary=="android")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-android.tgz", "ndll/Android", "lib/Android"]);
      }
      else if (inBinary=="linux")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-linux.tgz", "ndll/Linux", "ndll/Linux64", "lib/Linux", "lib/Linux64" ]);
      }
      else if (inBinary=="rpi")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-rpi.tgz", "ndll/RPi"]);
      }
      else
      {
         throw "Unknown binary " + inBinary;
      }

      sendBinary("nme-bin-" + inBinary +".tgz");
      updateBinary(inBinary);
   }
}



