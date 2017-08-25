import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class Builder
{
   var bs:BuildServer;

   public var name:String;
   public var url:String;

   public var gitCmd:String;
   public var revisionMatch:EReg;
   public var commitMatch:EReg;

   public var baseVersion:String="";
   public var gitVersion:String;
   public var cloneVersion:String;
   public var versionInfo:Dynamic=null;

   public var scratchDir:String;
   public var binDir:String;
   public var cloneDir:String;
   public var writeVersionFilename:String;
   public var writeHaxeVersionPackage:String;
   public var writeHaxeVersionPackageRoot:String = "";
   public var changesFile:String;

   public var depends:Array<Builder>;


   public var lastGoodGitVersion:String;
   public var haxelibUpdated:Bool;
   public var lastGoodHaxelib:String;
   public var lastGood:Bool;

   public function new(inBs:BuildServer,inName:String, inUrl:String)
   {
      revisionMatch = ~/^Revision: (\S+)/;
      commitMatch = ~/^commit (\S+)/;
      bs = inBs;
      name = inName;
      gitVersion = "";
      depends = [];
      haxelibUpdated = false;
      lastGood = false;

      gitCmd = Sys.getEnv("BS_GIT");
      if (gitCmd==null || gitCmd=="")
        gitCmd = "git";

      scratchDir = bs.scratchDir;

      binDir = bs.binDir + "/" + inName;
      if (!FileSystem.exists(binDir + "/releases"))
      {
         try
         {
            if (!FileSystem.exists(binDir))
               FileSystem.createDirectory(binDir);
             FileSystem.createDirectory(binDir+"/releases");
         }
         catch(e:Dynamic)
         {
            Sys.println("Could not open binDir " + binDir + " " + e); 
            throw("Unable to create " + inName);
         }
      }
      log(name + " binDir = " + binDir);

      setGitUrl(inUrl);
   }

   function useLatestProjects(inDepends:Array<String>)
   {
      for( depend in inDepends)
         depends.push( bs.findDepend(depend) );
   }

   public function updateDepends()
   {
      log("UPDATE " + depends);
      for(depend in depends)
         depend.updateHaxelib();
   }



   public function toString() return 'Project($name)';

   public function getCheckoutDir()
   {
      return scratchDir + "/" + name;
   }


   public function setGitUrl(inUrl:String)
   {
      url = inUrl;
      cloneDir = scratchDir + "/clones";
      if (!FileSystem.exists(cloneDir))
         FileSystem.createDirectory(cloneDir);
      cloneDir += "/" + name;
   }


   inline function log(s:String) { bs.log(s); }

   public function scrubDir(inName:String)
   {
      Sys.command("rm",["-rf",inName] );
   }

   function removeSpecialFiles(inDir:String)
   {
      try
      {
         var files = FileSystem.readDirectory(inDir);
         for(file in files)
         {
            var path = inDir + "/" + file;
            if (file==".svn")
               command("rm", ["-rf", path] );
            else if (file.substr(0,1)!="." && FileSystem.isDirectory(path))
               removeSpecialFiles(path);
         }
      }
      catch(e:Dynamic) { };
   }



   public static function readStdout(inCommand:String,inArgs:Array<String>)
   {
      var result = new Array<String>();
      var proc = new sys.io.Process(inCommand,inArgs);
      var stdout = proc.stdout;
      if (stdout!=null)
      {
         try
         {
            while(true)
            {
               var out = stdout.readLine();
               result.push(out);
            }
         } catch(e:Dynamic){}
         stdout.close();
      }
      proc.close();
      return result;
   }


   public function updateClone(inVersion:String)
   {
      if (inVersion!=gitVersion)
      {
         if (FileSystem.exists(cloneDir))
         {
            log("update...");
            Sys.setCwd(cloneDir);
            command(gitCmd,["pull"] );
         }
         else
         {
            log("clone...");
            Sys.setCwd(scratchDir + "/clones");
            log("cloning git clone " +  url + ".git");
            command(gitCmd,["clone", url + ".git"] );
         }
         Sys.setCwd(cloneDir);
         var lines = readStdout(gitCmd,["log", "-n", "1" ] );
         gitVersion = "";
         if (lines.length>0 && commitMatch.match(lines[0]))
            gitVersion = commitMatch.matched(1);
      }

      if (gitVersion==lastGoodGitVersion)
      {
         if (versionInfo==null || !versionInfo.isReleased)
            updateVersionInfo();
         return versionInfo.isReleased;
      }

      Sys.setCwd(cloneDir);
      var jsonFile = "haxelib.json";
      var content = File.getContent(jsonFile);
      var data:Dynamic = haxe.Json.parse(File.getContent(jsonFile));
      trace("Parsed " + data);

      baseVersion = data.version;

      updateVersionInfo();
      return false;
   }

   public function  updateVersionInfo()
   {
      //var query = { binaryVersion:binaryVersion, base:baseVersion, git:gitVersion, project:name };
      var query = { binaryVersion:0, base:baseVersion, git:gitVersion, project:name };
      log(query + "...");
      versionInfo = Lib.runJson("GetVersionInfo.n", query );
      log(versionInfo);
   }

   public function createWorkingCopy()
   {
      log("Prepare build...");
      Sys.setCwd(scratchDir);
      var dir = getCheckoutDir();
      scrubDir(dir);

      Sys.setCwd(scratchDir);
      FileSystem.createDirectory(dir);
      var files = FileSystem.readDirectory(cloneDir);
      for(file in files)
      {
         if (file.substr(0,1)!=".")
            command("cp", ["-rp", cloneDir+"/"+file, dir] );
      }
   }

   public function writeVersions(?inVersionName:String)
   {
      Sys.setCwd(getCheckoutDir());

      var lines = [
         "<html>","<body>","<h1>",
         "<a href='" + url + "/tree/" + gitVersion + "'>Source Code</a>",
         "</h1>","</body>","</html>",
      ];
      File.saveContent( "release.html", lines.join("\n") );


      if (writeVersionFilename!=null && inVersionName!=null)
      {
         var define = name.split("-").join("_").toUpperCase() + "_VERSION";
         var lines = [
           '#ifndef $define',
           '#define $define "$inVersionName"',
           '#endif'
           ];
        File.saveContent( writeVersionFilename, lines.join("\n") );
      }
      if (writeHaxeVersionPackage!=null && inVersionName!=null)
      {
         var lines = [
           'package $writeHaxeVersionPackage;',
           "class Version {",
           '   public static inline var name="$inVersionName";',
           "}"
           ];
        File.saveContent( writeHaxeVersionPackageRoot + writeHaxeVersionPackage.split(".").join("/") + "/Version.hx",
              lines.join("\n") );
      }

      /*
      if (writeBinaryVersionFilename!=null)
      {
         var define = name.toUpperCase() + "_BINARY_VERSION";
         var lines = [
           '#ifndef $define',
           '#define $define ' + binaryVersion,
           '#endif'
           ];
        File.saveContent( writeBinaryVersionFilename, lines.join("\n") );
      }
      */
   }


   public function buildBinary( )
   {
   }

   public function hasBinaries() return false;


   public function build()
   {
      var release = bs.releases.get(name);

      if (!hasBinaries() && !bs.shouldCreateRelease())
      {
         log("no binaries - skip");
      }
      else if (release==null)
      {
         log("Could not get information about " + name);
      }
      else if (release.isReleased)
      {
         log("Already released " + gitVersion );
      }
      else if (updateClone(release.git))
      {
         log("Already built + released " + gitVersion );
      }
      else
      {
         updateDepends();

         if (hasBinaries())
            buildBinaries();

         if (bs.shouldCreateRelease())
            checkRelease();

         lastGoodGitVersion = gitVersion;
      }
   }

   public function buildBinaries()
   {

      var dir = binDir + "/" + gitVersion;
      var base = dir + "/" + bs.host;
      var okFile = base+".ok";
      var errFile = base+".err";

      if (FileSystem.exists(okFile))
         log("Already built " + okFile);
      else if (FileSystem.exists(errFile))
      {
         throw "Bad build - " + errFile;
         log("Already bad");
      }
      else
      {
         FileSystem.createDirectory(dir);
         try
         {
            createWorkingCopy();
            writeVersions();
            buildBinary();
         }
         catch(d:Dynamic)
         {
            File.saveContent(errFile, "err");
            throw "Bad build";
         }
      }
   }

   public function sendBinary(inFile:String)
   {
      log("Sending " + inFile + "...");
      var dir = binDir + "/" + gitVersion;

      for(test in 0...2)
      {
         if (!FileSystem.exists(dir))
         {
            try { FileSystem.createDirectory(dir); }
            catch(e:Dynamic) { }
         }
      }
      if (!FileSystem.exists(dir))
         throw "Could not create binary target :" + dir;

      var dest = dir + "/" + inFile;
      if (FileSystem.exists(dest))
         command("rm", [dest]);

      command("cp", [inFile, dest] );
      command("rm", [inFile]);
      log("Created " + dest);
      File.saveContent(dir + "/" + bs.host + ".ok", "ok");

      /*
      var result = Lib.sendWebFile(inFile, "binaries/" + name + "/" + binaryVersion + "/" + inFile );
      if (result.substr(0,5)=="Wrote")
         log(result);
      else
         throw result;
     command("rm", [inFile]);
     */
   }

   public function command(cmd:String, args:Array<String>)
   {
      Sys.println(cmd + " " + args.join(" "));
      if (Sys.command(cmd,args)!=0)
         throw "Error running command: " + cmd + " " + args.join(" ");
   }

   public function buildRelease(buildNumber:Int)
   {
      log("Releasing " + buildNumber);

      createWorkingCopy();
      var dir = getCheckoutDir();

      Sys.setCwd(dir);

      var jsonFile = "haxelib.json";
      var lines = File.getContent(jsonFile).split("\n");
      var idx = 0;
      var versionMatch = ~/(.*"version"\s*:\s*")(.*)(".*)/;
      var found = false;
      var newVersion = "";
      while(idx<lines.length)
      {
         if (versionMatch.match(lines[idx]))
         {
            var parts = versionMatch.matched(2).split(".");
            if (parts.length==3)
               parts[2] = buildNumber+"";
            else
               parts.push(buildNumber+"");
            newVersion = parts.join(".");
            lines[idx]=versionMatch.matched(1) + newVersion + versionMatch.matched(3);
            found = true;
            break;
         }
         idx++;
      }
      if (!found)
         throw "Could not find version in " + jsonFile;

      File.saveContent(jsonFile, lines.join("\n") );

      var newNotes = new Array<String>();
      if (changesFile!=null)
      {
         var notes = new Array<String>();
         var lines = File.getContent(changesFile).split("\n");
         for(l in lines)
            if (l.substr(0,1)=="*")
               notes.push( l.substr(2) );
         for(n in versionInfo.noteCount...notes.length)
            newNotes.push( notes[notes.length-1-n] );
         log("New notes: " + newNotes.join("//") );
      }

      writeVersions(newVersion);

      log("Getting binaries...");
      if (hasBinaries())
      {
         for(bin in bs.hosts)
         {
            var file = bin + ".tgz";
            var binFile = binDir + "/" + gitVersion + "/" + file;
   
            var bytes:haxe.io.Bytes = null;
            if (FileSystem.exists(binFile))
            bytes = File.getBytes(binFile);
            else
               throw "Missing binary " + binFile;
            File.saveBytes( file, bytes );
            command("tar", [ "xvzf", file ]);
            command("rm", [  file ]);
         }

         if (FileSystem.exists("bin"))
         {
            command("chmod",["-R", "755", "bin" ]);
            if (bs.isMac)
               command("find",["bin", "-name", "*.hash", "-exec", "rm", "{}", ";" ]);
         }
         if (FileSystem.exists("ndll"))
         {
            // Work around haxelib bug for now...
            for(hackDir in ["ndll/Linux","ndll/Linux64"])
               if (!FileSystem.exists(hackDir))
                  FileSystem.createDirectory(hackDir);
            command("chmod",["-R", "755", "ndll" ]);
            if (bs.isMac)
               command("find",["ndll", "-name", "*.hash", "-exec", "rm", "{}", ";" ]);
         }
         if (FileSystem.exists("lib"))
            if (bs.isMac)
               command("find",["lib", "-name", "*.hash", "-exec", "rm", "{}", ";" ]);
      }

      Sys.setCwd(scratchDir);
      var newDir = name + "-" + newVersion;
      command("rm",["-rf", newDir] );
      command("mv",[dir,newDir] );
      var zipName = name + "-" + newVersion + ".zip";
      command("rm",["-f", zipName] );
      command("zip",["-r", zipName, newDir] );
      command("rm",["-rf", newDir] );

      var release = binDir + "/releases/"+zipName;
      var size = File.getBytes(release).length;
      command("rm",["-f", release] );
      command("mv",[zipName, binDir+"/releases/" + zipName] );
      log("sending " + release + " x " + size + "...");
      Lib.sendWebFile(release, "releases/" + name + "/" + zipName);
      log("update release db... ");

      Lib.runJson("UpdateRelease.n", { project:name, base:baseVersion, build:buildNumber, release:newVersion, git:gitVersion, notes:newNotes } );
      versionInfo.isReleased = true;
   }

   public function checkRelease()
   {
      if (hasBinaries())
      {
         log("Check binaries built...");
         updateVersionInfo();
         if (!versionInfo.isReleased)
         {
            for(bin in bs.hosts)
            {
               var base = binDir + "/" + gitVersion + "/" + bin;
               if (FileSystem.exists(base+".ok"))
               {
                  // ok
               }
               else if (FileSystem.exists(base+".err"))
                  throw "errors building " + bin;
               else
                  throw "waiting " + bin;
            }

            log("All binaries built");
            versionInfo.binState = "ok";
         }
         else
            versionInfo.binState = "released";
      }

      if (!versionInfo.isReleased)
      {
         buildRelease(versionInfo.buildNumber);
      }
      else
      {
         log("      already released.");
      }
   }


   public function updateHaxelib()
   {
      var release = bs.releases.get(name);
      if (release==null)
      {
         throw("Could not get information about " + name);
      }
      else if (!release.isReleased)
      {
         throw("Not released " + name + "(" + gitVersion  +") " + bs.releases );
      }
 
      var parts = release.version.split(".");
      if (parts.length!=3)
         throw "Could not parse version " + release.version + " in project " + name;
      var haxelib = parts.join(".");
      log("Check " + name + " for version " + haxelib + "...");

      if (lastGoodHaxelib!=haxelib)
      {
         var commas = parts.join(",");
         if (!FileSystem.exists(bs.haxelibConfig + "/" + name + "/" + commas))
         {
            var release = binDir + "/releases/"+name + "-" + haxelib + ".zip";

            command("haxelib", ["install", release ] );
         }
         if (!FileSystem.exists(bs.haxelibConfig + "/" + name + "/" + commas))
            throw "Failed to install " + name + " version " + haxelib;

         command("haxelib", ["set", name, haxelib ] );
         // Disable development
         command("haxelib", ["dev", name] );


         log("haxelib " + name + " set to " + haxelib);
         lastGoodHaxelib = haxelib;
      }
      else 
      {
         log("... already good - set");
         command("haxelib", ["set", name, haxelib ] );
         // Disable development
         command("haxelib", ["dev", name] );
      }
   }
}


