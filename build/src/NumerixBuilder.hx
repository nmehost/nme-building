import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class NumerixBuilder extends BinaryBuilder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"numerix", "https://github.com/hughsando/numerix");
      //writeVersionFilename = "project/include/NumerixVersion.h";
      //writeHaxeVersionPackage = "numerix";
      //writeHaxeVersionPackageRoot = "src/";
      //changesFile = "Changes.md";
      //useLatestProjects(["nme-dev"]);
   }

   override public function buildWindows(dir:String)
   {
      command("haxelib", ["run", "hxcpp", "numerix.xml", "-DHXCPP_M64","-DNX_OPENCL","-DNX_CAFFE" ]);
      return [ "ndll/Windows64/numerix.ndll" ];
   }


   override public function buildMac(dir:String)
   {
      return [ ];
   }


/*
   override public function onVersionWritten()
   {
      var dir = getCheckoutDir();
      command("haxelib", ["dev","nme",dir]);
      Sys.setCwd(dir + "/tools/nme" );
      command("haxe", ["compile.hxml"]);
      Sys.setCwd(dir);
   }
*/
}



