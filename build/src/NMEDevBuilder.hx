import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEDevBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme-dev", "https://github.com/haxenme/nme-dev",true,false);
      writeVersionFilename = "include/NmeDevVersion.h";
      changesFile = "Changes.md";
   }
}



