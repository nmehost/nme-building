import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class HxcppBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"hxcpp",true, "http://hxcpp.googlecode.com/svn/");
   }

   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );

      var dir = scratchDir + "/" + getCheckoutDir();
      Sys.putEnv("HXCPP", dir);
      Sys.setCwd(dir + "/runtime" );

      if (inBinary=="windows")
      {
         command("neko", ["../run.n", "BuildLibs.xml"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "hxcpp-bin-windows.tgz", "bin/Windows"]);
      }
      else if (inBinary=="mac")
      {
         command("neko", ["../run.n", "BuildLibs.xml"]);
         command("neko", ["../run.n", "BuildLibs.xml", "-DHXCPP_M64"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "hxcpp-bin-mac.tgz", "bin/Mac", "bin/Mac64"]);
      }
      else if (inBinary=="ios")
      {
         command("neko", ["../run.n", "BuildLibs.xml", "-Diphoneos"]);
         command("neko", ["../run.n", "BuildLibs.xml", "-Diphoneos", "-DHXCPP_ARMV7"]);
         command("neko", ["../run.n", "BuildLibs.xml", "-Diphonesim"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "hxcpp-bin-ios.tgz", "bin/IPhone"]);
      }
      else if (inBinary=="android")
      {
         command("neko", ["../run.n", "BuildLibs.xml", "-Dandroid"]);
         command("neko", ["../run.n", "BuildLibs.xml", "-Dandroid", "-DHXCPP_ARMV7"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "hxcpp-bin-android.tgz", "bin/Android"]);
      }
      else if (inBinary=="linux")
      {
         command("neko", ["../run.n", "BuildLibs.xml", "-Dlinux"]);
         command("neko", ["../run.n", "BuildLibs.xml", "-Dlinux", "-DHXCPP_M64"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "hxcpp-bin-linux.tgz", "bin/Linux", "bin/Linux64" ]);
      }
      else if (inBinary=="rpi")
      {
         command("neko", ["../run.n", "BuildLibs.xml", "-Drpi"]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "hxcpp-bin-rpi.tgz", "bin/RPi"]);
      }
      else
      {
         throw "Unknown binary " + inBinary;
      }

      sendBinary("hxcpp-bin-" + inBinary +".tgz");
      updateBinary(inBinary);
   }
}



