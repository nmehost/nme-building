import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class WaxeBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"waxe", "https://github.com/nmehost/waxe");
      filterBinaries(["mac","windows","linux"]);
      writeBinaryVersionFilename = "project/src/WaxeBinVersion.h";
      writeHaxeVersionPackage = "waxe";
      changesFile = "Changes.md";
      useLatestProjects(["waxe-works"]);
   }
}



