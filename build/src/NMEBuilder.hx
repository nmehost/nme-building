import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme", "https://github.com/haxenme/nme");
      removeBinaries(["rpi","tizen","blackberry"]);
      writeVersionFilename = "project/include/NmeVersion.h";
      writeBinaryVersionFilename = "project/include/NmeBinVersion.h";
      writeHaxeVersionPackage = "nme";
      changesFile = "Changes.md";
      useLatestProjects(["nme-dev"]);
   }

   override public function getBuildExtra(bin)
   {
      if (bin!="android")
         return null;
      return [ ["android-armv5"], ["android-armv7"] ];
   }

   override public function createWorkingCopy()
   {
      super.createWorkingCopy();
      log("Build nme.n...");
      var dir = getCheckoutDir();
      Sys.setCwd(dir + "/tools/nme" );
      command("haxe", ["compile.hxml"]);
   }

}



