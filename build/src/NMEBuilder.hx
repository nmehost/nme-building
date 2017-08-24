import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme", "https://github.com/haxenme/nme",false);
      removeBinaries(["rpi", "ios", "android"]);
      writeVersionFilename = "project/include/NmeVersion.h";
      writeBinaryVersionFilename = "project/include/NmeBinVersion.h";
      writeHaxeVersionPackage = "nme";
      writeHaxeVersionPackageRoot = "src/";
      changesFile = "Changes.md";
      //useLatestProjects(["nme-dev"]);
   }

   override public function buildMacExtra(args:Array<String>):Array<String>
   {
      var dir = getCheckoutDir();

      Sys.setCwd(dir + "/project" );
      command("haxelib", ["run","hxcpp","ToolkitBuild.xml","-Demscripten","-DHXCPP_JS_PRIME"]);

      Sys.setCwd(dir + "/tools/make_classes" );
      command("haxe", ["--run","MakeClasses.hx"]);

      Sys.setCwd(dir);
      return args.concat(["ndll/Emscripten"]);
   }

 
   override public function getBuildExtra(inBinary:String)
   {
      if (inBinary=="mac")
        return [["mac-m64"]];
      else if (inBinary=="linux")
        return [["linux-m64"]];
      return null;
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



