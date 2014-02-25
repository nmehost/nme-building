import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEStateBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme-state", "https://github.com/nmehost/nme-state");
      writeVersionFilename = "include/NmeStateVersion.h";
      changesFile = "Changes.txt";
   }
}



