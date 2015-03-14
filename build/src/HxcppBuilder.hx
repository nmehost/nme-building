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

      command("neko", ["build.n", inBinary]);
      if (inBinary=="windows")
         command("neko", ["build.n", "static-mingw"]);
      if (inBinary=="windows" || inBinary=="mac" || inBinary=="linux")
      {
         command("haxelib", ["dev", "hxcpp", dir ]);
         command("haxe", ["compile-cppia.hxml", "-D",  inBinary ]);
         command("haxelib", ["dev", "hxcpp" ]);
      }

      Sys.setCwd(dir);

      if (inBinary=="windows")
      {
         bin = "Windows";
         bin64 = "Windows64";
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



