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
   }

   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );

      var dir = getCheckoutDir();
      Sys.putEnv("HXCPP", dir);
      Sys.setCwd(dir + "/runtime" );

      command("neko", ["buildlibs.n", inBinary]);
      Sys.setCwd(dir);
      var bin = "";
      var bin64 = "";

      if (inBinary=="windows")
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
      else
      {
         throw "Unknown binary " + inBinary;
      }

      var args = ["cvzf", "hxcpp-bin-" + inBinary + ".tgz", "bin/"+bin, "lib/"+bin];
      if (bin64!="")
      {
         args.push("bin/" + bin64);
         args.push("lib/" + bin64);
      }
      command("tar", args );

      sendBinary("hxcpp-bin-" + inBinary +".tgz");
      updateBinary(inBinary);
   }
}


