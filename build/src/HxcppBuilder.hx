import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class HxcppBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"hxcpp",true, "https://github.com/HaxeFoundation/hxcpp");
      writeVersionFilename = "include/HxcppVersion.h";
      writeBinaryVersionFilename = "include/HxcppBinVersion.h";
      changesFile = "Changes.md";
   }

   override public function createWorkingCopy()
   {
      super.createWorkingCopy();
      log("Build hxcpp.n...");
      var dir = getCheckoutDir();
      Sys.setCwd(dir + "/tools/hxcpp" );
      command("haxe", ["compile.hxml"]);
   }
   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );

      var dir = getCheckoutDir();
      Sys.putEnv("HXCPP", dir);
      Sys.setCwd(dir + "/tools/hxcpp" );
      command("haxe", ["compile.hxml"]);
      Sys.setCwd(dir + "/project" );

      var bin = "";
      var bin64 = "";
      var binName = inBinary;
      var staticOnly = inBinary=="mingw";
      var buildName = staticOnly ? "static-" + inBinary : inBinary;

      command("neko", ["build.n", buildName]);
      Sys.setCwd(dir);

      if (inBinary=="windows" || inBinary=="mingw")
      {
         bin = "Windows";
      }
      else if (inBinary=="mac")
      {
         bin="Mac";
         bin64="Mac64";
      }
      else if (inBinary=="ios")
      {
         bin="IPhone";
      }
      else if (inBinary=="android")
      {
         bin="Android";
      }
      else if (inBinary=="linux")
      {
         bin="Linux";
         bin64="Linux64";
      }
      else if (inBinary=="rpi")
      {
         bin="RPi";
      }
      else if (inBinary=="tizen")
      {
         bin="Tizen";
      }
      else if (inBinary=="blackberry")
      {
         bin="BlackBerry";
      }
      else
      {
         throw "Unknown binary " + inBinary;
      }

      var args = ["cvzf", "hxcpp-bin-" + binName + ".tgz", "lib/"+bin];
      if (!staticOnly)
         args.push("bin/"+bin);

      if (bin64!="")
      {
         args.push("bin/" + bin64);
         args.push("lib/" + bin64);
      }
      command("tar", args );

      sendBinary("hxcpp-bin-" + binName +".tgz");
      updateBinary(inBinary);
   }
}



