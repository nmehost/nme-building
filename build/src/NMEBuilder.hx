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
}



