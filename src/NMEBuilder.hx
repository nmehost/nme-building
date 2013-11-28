import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme",true, "https://github.com/nmehost/nme");
      removeBinaries(["rpi","linux"]);
      writeVersionFilename = "project/include/NmeVersion.h";
      writeBinaryVersionFilename = "project/include/NmeBinVersion.h";
      writeHaxeVersionPackage = "nme";
      changesFile = "Changes.txt";
   }

   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );

      var dir = scratchDir + "/" + getCheckoutDir();
      Sys.setCwd(dir + "/project" );

      if (inBinary=="windows")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml" ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-windows.tgz", "ndll/Windows"]);
      }
      else if (inBinary=="mac")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml"]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-DHXCPP_M64"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-mac.tgz", "ndll/Mac", "ndll/Mac64"]);
      }
      else if (inBinary=="ios")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Diphoneos"]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Diphoneos", "-DHXCPP_ARMV7"]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Diphonesim"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-ios.tgz", "ndll/IPhone"]);
      }
      else if (inBinary=="android")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dandroid"]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dandroid", "-DHXCPP_ARMV7"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-android.tgz", "ndll/Android"]);
      }
      else if (inBinary=="linux")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dlinux"]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dlinux", "-DHXCPP_M64"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "nme-bin-linux.tgz", "ndll/Linux", "ndll/Linux64" ]);
      }
      else if (inBinary=="rpi")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Drpi"]);
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



