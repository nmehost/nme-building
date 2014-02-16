import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEStateBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme-state",false, "https://github.com/nmehost/nme-state");
         writeVersionFilename = "include/NmeStateVersion.h";
      changesFile = "Changes.txt";
   }
}



