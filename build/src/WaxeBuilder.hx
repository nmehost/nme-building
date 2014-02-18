import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class WaxeBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"waxe",true, "https://github.com/nmehost/waxe");
      removeBinaries(["rpi","ios","android"]);
      writeBinaryVersionFilename = "project/waxe/WaxeBinVersion.h";
      writeHaxeVersionPackage = "waxe";
      changesFile = "Changes.md";
   }

   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );

      var dir = getCheckoutDir();
      Sys.setCwd(dir + "/project" );

      if (inBinary=="windows")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml" ]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dstatic_link" ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "waxe-bin-windows.tgz", "ndll/Windows", "lib/Windows"]);
      }
      else if (inBinary=="mac")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml", "-DHXCPP_M32" ]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-DHXCPP_M64" ]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-DHXCPP_M64", "-Dstatic_link" ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "waxe-bin-mac.tgz", "ndll/Mac", "ndll/Mac64", "lib/Mac64"]);
      }
      else if (inBinary=="linux")
      {
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dlinux", "-DHXCPP_M32" ]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dlinux", "-DHXCPP_M32", "-Dstatic_link" ]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dlinux", "-DHXCPP_M64" ]);
         command("haxelib", ["run", "hxcpp", "Build.xml", "-Dlinux", "-DHXCPP_M64", "-Dstatic_link" ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "waxe-bin-linux.tgz", "ndll/Linux", "ndll/Linux64", "lib/Linux", "lib/Linux64" ]);
      }
      else
      {
         throw "Unknown binary " + inBinary;
      }

      sendBinary("waxe-bin-" + inBinary +".tgz");
      updateBinary(inBinary);
   }
}



