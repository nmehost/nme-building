
class Gm2dBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"gm2d", "https://github.com/nmehost/gm2d");
      writeHaxeVersionPackage = "gm2d";
      changesFile = "Changes.md";
   }
}



