import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class WaxeWorksBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"waxe-works",false, "https://github.com/nmehost/waxe-works");
      writeVersionFilename = "include/WaxeWorksVersion.h";
      changesFile = "Changes.md";
   }
}



