import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class BinaryBuilder extends Builder
{
   public var hasStatic:Bool;
   public var hasNdll:Bool;

   public function new(inBs:BuildServer, name:String, url:String,inHasStatic:Bool=true, inHasNdll:Bool=true)
   {
      super(inBs,name,true,url);
      useLatestProjects(["hxcpp"]);
      hasStatic = inHasStatic;
      hasNdll = inHasNdll;
   }

   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );
      for(depend in depends)
         depend.updateHaxelib();

      var dir = getCheckoutDir();
      Sys.setCwd(dir + "/project" );

      if (inBinary=="windows")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         var args = ["cvzf", name + "-bin-windows.tgz"];
         if (hasStatic)
            args.push("lib/Windows");
         if (hasNdll)
            args.push("ndll/Windows");
         command("tar", args);
      }
      else if (inBinary=="mac")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         var args = ["cvzf", name + "-bin-mac.tgz"];
         if (hasNdll)
            args = args.concat(["ndll/Mac", "ndll/Mac64"]);
         if (hasStatic)
            args = args.concat(["lib/Mac", "lib/Mac64"]);
         command("tar", args);
      }
      else if (inBinary=="ios")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-ios.tgz", "lib/IPhone"]);
      }
      else if (inBinary=="android")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         var args = ["cvzf", name + "-bin-android.tgz"];
         if (hasStatic)
            args.push("lib/Android");
         if (hasNdll)
            args.push("ndll/Android");
         command("tar", args);
      }
      else if (inBinary=="linux")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         var args = ["cvzf", name + "-bin-linux.tgz"];
         if (hasNdll)
            args = args.concat(["ndll/Linux", "ndll/Linux64"]);
         if (hasStatic)
            args = args.concat(["lib/Linux", "lib/Linux64"]);
         command("tar",args);
      }
      else if (inBinary=="rpi")
      {
         command("neko", ["build.n", inBinary ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", name + "-bin-rpi.tgz", "ndll/RPi"]);
      }
      else
      {
         throw "Unknown binary " + inBinary;
      }

      sendBinary(name + "-bin-" + inBinary +".tgz");
      updateBinary(inBinary);
   }
}



