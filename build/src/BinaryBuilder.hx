import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class BinaryBuilder extends Builder
{

   public function new(inBs:BuildServer, name:String, url:String)
   {
      super(inBs,name,url);
      if (name!="hxcpp")
         useLatestProjects(["hxcpp"]);
      log("DEPENDS " + name + " -> " + depends);
   }

   override public function hasBinaries() return true;

 
   public function buildMac(dir:String) : Array<String> return [];
   public function buildWindows(dir:String) : Array<String> return [];


   override public function buildBinary()
   {
      if (bs.isMac)
         log("Build on mac");
      else if (bs.isWindows)
         log("Build on windows");
      else
         throw "Unknown binary host";

      var dir = getCheckoutDir();

      Sys.setCwd(dir + "/project" );

      var files:Array<String> = null;
      if (bs.isMac)
         files = buildMac(dir);
      else if (bs.isWindows)
         files = buildWindows(dir);



      Sys.setCwd(dir);
      var tar = bs.host + ".tgz";
      var args = ["cvzf", tar].concat(files);
      command("tar", args );

      sendBinary(tar);
   }
}



