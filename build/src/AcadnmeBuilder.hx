import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class AcadnmeBuilder extends Builder
{

   public function new(inBs:BuildServer)
   {
      super(inBs,"acadnme",true,"https://github.com/nmehost/acadnme");
      filterBinaries(["mac","windows", "android"]);
      changesFile = "Changes.md";
      useLatestProjects(["hxcpp"]);
   }

   override public function createWorkingCopy()
   {
      super.createWorkingCopy();
      log("Build run.n...");
      var dir = getCheckoutDir();
      Sys.setCwd(dir + "/tools/run" );
      command("haxe", ["compile.hxml"]);
   }


   override public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );
      for(depend in depends)
         depend.updateHaxelib();

      var dir = getCheckoutDir();

      command("haxelib", ["dev", "acadnme", dir]);
      Sys.setCwd(dir + "/engine" );
      command("haxelib", ["run", "nme", "nocompile" ]);

      Sys.setCwd(dir + "/apps/boot" );
      command("haxelib", ["run", "nme", "cppia", "installer" ]);
      Sys.setCwd(dir + "/apps/Flappybalt" );
      command("haxelib", ["run", "nme", "cppia", "installer" ]);
      Sys.setCwd(dir + "/apps/PiratePig" );
      command("haxelib", ["run", "nme", "cppia", "installer" ]);
      Sys.setCwd(dir + "/apps/Tilemap" );
      command("haxelib", ["run", "nme", "cppia", "installer" ]);
      Sys.setCwd(dir + "/apps/HerokuShaders" );
      command("haxelib", ["run", "nme", "cppia", "installer" ]);

      Sys.setCwd(dir + "/engine" );
      if (inBinary=="windows" )
      {
         command("haxelib", ["run", "nme", "cpp", "build" ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "acadnme-bin-windows.tgz", "bin/Windows"]);
      }
      else if (inBinary=="mac")
      {

         command("haxelib", ["run", "nme", "cpp", "build" ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "acadnme-bin-mac.tgz", "bin/Mac", "export" ]);
      }
      else if (inBinary=="ios")
      {
      }
      else if (inBinary=="android")
      {
         command("haxelib", ["run", "nme", "android", "build" ]);
         Sys.setCwd(dir);
         sys.io.File.saveContent("engine/temp/.build", "1400");
         command("mkdir", ["-p", "bin/Android" ]);
         command("cp", ["engine/temp/android/Acadnme/bin/Acadnme-release.apk", "bin/Android" ]);
         command("tar", ["cvzf", "acadnme-bin-android.tgz", "bin/Android" ]);
      }
      else if (inBinary=="linux")
      {
         command("haxelib", ["run", "nme", "linux", "build" ]);
         Sys.setCwd(dir);
         command("tar", ["cvzf", "acadnme-bin-linux.tgz", "bin/Linux"]);
      }
      else
      {
         throw "Unknown binary " + inBinary;
      }

      sendBinary("acadnme-bin-" + inBinary +".tgz");
      updateBinary(inBinary);
   }
}



