import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class HxcppBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"hxcpp", "https://github.com/HaxeFoundation/hxcpp");
      writeVersionFilename = "include/HxcppVersion.h";
      changesFile = "Changes.md";
   }

   override public function createWorkingCopy()
   {
      super.createWorkingCopy();
      log("Build hxcpp.n...");
      var dir = getCheckoutDir();
      command("haxelib", ["dev", "hxcpp", dir]);
      Sys.setCwd(dir + "/tools/hxcpp" );
      command("haxe", ["compile.hxml"]);
   }


   override public function buildWindows(dir:String)
   {
      var files = new Array<String>();

      command("haxe", ["compile-cppia.hxml", "-D", "HXCPP_M64"]);
      files.push("bin/Windows64/Cppia.exe");
      return files;
   }


   override public function buildMac(dir:String)
   {
      var files = new Array<String>();

      command("haxe", ["compile-cppia.hxml", "-D", "HXCPP_M64" ]);
      files.push("bin/Mac64/Cppia");
      command("haxe", ["compile-cppia.hxml", "-D", "linux", "-D", "HXCPP_M64" ]);
      files.push("bin/Linux64/Cppia");
      return files;
   }



}



