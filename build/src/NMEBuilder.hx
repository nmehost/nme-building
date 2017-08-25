import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NMEBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"nme", "https://github.com/haxenme/nme");
      writeVersionFilename = "project/include/NmeVersion.h";
      writeHaxeVersionPackage = "nme";
      writeHaxeVersionPackageRoot = "src/";
      changesFile = "Changes.md";
      //useLatestProjects(["nme-dev"]);
   }

   override public function buildWindows(dir:String)
   {
      command("haxelib", ["run", "hxcpp", "ToolkitBuild.xml", "-DHXCPP_M64"]);
      command("haxelib", ["run", "hxcpp", "ToolkitBuild.xml", "-DHXCPP_M32"]);
      Sys.setCwd(dir + "/acadnme" );
      command("haxelib", ["run", "nme", "cpp", "nocompile"]);
      Sys.setCwd(dir + "/samples/AcadnmeBoot" );
      command("haxelib", ["run", "nme", "cppia", "installer"]);
      Sys.setCwd(dir + "/acadnme" );
      command("haxelib", ["run", "nme", "cpp", "build"]);
      return ["ndll/Windows/nme.ndll",
              "ndll/Windows64/nme.ndll",
              "bin/Windows/Acadnme/Acadnme.exe"
              ];
   }


   override public function buildMac(dir:String)
   {
      command("haxelib", ["run", "hxcpp", "ToolkitBuild.xml"]);
      command("haxelib", ["run", "hxcpp", "ToolkitBuild.xml", "-Dlinux"]);
      command("neko", ["build.n", "jsprime"]);
      Sys.setCwd(dir + "/acadnme" );
      command("haxelib", ["run", "nme", "cpp", "nocompile"]);
      Sys.setCwd(dir + "/samples/AcadnmeBoot" );
      command("haxelib", ["run", "nme", "cppia", "installer"]);
      Sys.setCwd(dir + "/acadnme" );
      command("haxelib", ["run", "nme", "cpp", "build"]);
      return ["ndll/Mac64/nme.ndll",
              "ndll/Linux64/nme.ndll",
              "ndll/Emscripten/nme.js",
              "ndll/Emscripten/nme.js.mem",
              "ndll/Emscripten/nmeclasses.js",
              "ndll/Emscripten/preloader.js",
              "ndll/Emscripten/parsenme.js",
              "ndll/Emscripten/export_classes.info",
              "bin/Mac/Acadnme.app",
              "src/cppia/export_classes.info",
              ];
 
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



