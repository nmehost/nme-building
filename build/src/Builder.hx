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

   public var binaryVersion:Int=0;
   public var baseVersion:String="";
   public var gitVersion:String;
   public var versionInfo:Dynamic=null;

   public var binaries:Array<String>;
   public var allBinaries:Array<String>;
   public var scratchDir:String;
   public var cacheDir:String;
   public var cloneDir:String;
   public var writeVersionFilename:String;
   public var writeBinaryVersionFilename:String;
   public var writeHaxeVersionPackage:String;
   public var changesFile:String;

   public function new(inBs:BuildServer,inName:String,inHasBinaries:Bool, inUrl:String)
   {
      revisionMatch = ~/^Revision: (\S+)/;
      commitMatch = ~/^commit (\S+)/;
      bs = inBs;
      name = inName;
      binaryVersion = 0;
      gitVersion = "";

      gitCmd = Sys.getEnv("BS_GIT");
      if (gitCmd==null || gitCmd=="")
        gitCmd = "git";
      if (inHasBinaries)
      {
         binaries = bs.binaries.copy();
         allBinaries = bs.allBinaries.copy();
      }
      else
      {
         binaries = [];
         allBinaries = [];
      }

      scratchDir = bs.scratchDir;
      cacheDir = scratchDir + "/cache";

      setGitUrl(inUrl);
   }

   function removeBinaries(remove:Array<String>)
   {
      var filtered = new Array<String>();
      for(b in allBinaries)
         if (!Lambda.exists(remove,function(x) return x==b))
            filtered.push(b);
      allBinaries = filtered;
      trace("->filtered all " + allBinaries );

      var filtered = new Array<String>();
      for(b in binaries)
         if (!Lambda.exists(remove,function(x) return x==b))
            filtered.push(b);
      binaries = filtered;
      trace("->filtered " + binaries );
   }

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
      try
      {
         while(true)
         {
            var out = proc.stdout.readLine();
            result.push(out);
         }
      } catch(e:Dynamic){}
      proc.close();
      return result;
   }

   public function updateClone()
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

      var jsonFile = "haxelib.json";
      var data = haxe.Json.parse(File.getContent(jsonFile));

      binaryVersion = Std.parseInt(data.binaryversion);
      baseVersion = data.version;

      updateVersionInfo();
   }

   public function  updateVersionInfo()
   {
      var query = { binaryVersion:binaryVersion, base:baseVersion, git:gitVersion, project:name };
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
      if (writeVersionFilename!=null && inVersionName!=null)
      {
         var define = name.split("-").join("_").toUpperCase() + "_VERSION_NAME";
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
        File.saveContent( writeHaxeVersionPackage.split(".").join("/") + "/Version.hx",
              lines.join("\n") );
      }

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
   }


   public function buildBinary(inBinary:String)
   {
      log("Build :" + inBinary );
   }

   public function hasBinaries()
   {
      return allBinaries.length > 0;
   }

   public function build()
   {
      updateClone();

      if (hasBinaries())
         buildBinaries();

      if (bs.shouldCreateRelease())
         checkRelease();
   }

   public function buildBinaries()
   {
      var first = true;
      var have:Array<Dynamic> = versionInfo.have;
      log("Build binaries, have " + have );
      for(bin in binaries)
      {
         var found = Lambda.exists(have,function(x) return bin==x);
         if (!found)
         {
            log(bin + "...");
            if (first)
            {
               createWorkingCopy();
               writeVersions();
               first = false;
            }

            buildBinary(bin);
         }
         else
         {
            log("Already built :" + bin );
         }
      }
   }

   public function updateBinary(inPlatform:String)
   {
      var result = Lib.runJson("UpdateBinary.n",
         { project:name, version:binaryVersion, platform:inPlatform } );
   }

   public function sendBinary(inFile:String)
   {
      log("Sending " + inFile + "...");
      var result = Lib.sendWebFile(inFile, "binaries/" + name + "/" + binaryVersion + "/" + inFile );
      if (result.substr(0,5)=="Wrote")
         log(result);
      else
         throw result;
     command("rm", [inFile]);
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
      for(bin in allBinaries)
      {
         var file = name + "-bin-" + bin + ".tgz";
         // Check cache...
         var dir = cacheDir;
         for(sub in ["/binaries", "/"+name, "/"+binaryVersion] )
         {
            dir+="/" + sub;
            if (!FileSystem.exists(dir))
               FileSystem.createDirectory(dir);
         }

         var cacheFile = dir + "/" + file;
         var bytes:haxe.io.Bytes = null;
         if (FileSystem.exists(cacheFile))
            bytes = File.getBytes(cacheFile);
         else
         {
            var url = "http://" + Sys.getEnv("HURTS_HOST") + "/binaries/" + name + "/" + binaryVersion + "/" + file;
            log("fetching " + url + "...");
            var data = haxe.Http.requestUrl(url);
            bytes = haxe.io.Bytes.ofString(data);
            File.saveBytes( cacheFile, bytes );
         }
         File.saveBytes( file, bytes );
         command("tar", [ "xvzf", file ]);
         command("rm", [  file ]);
      }
      if (allBinaries.length>0)
      {
         if (FileSystem.exists("bin"))
            command("chmod",["-R", "755", "bin" ]);
         if (FileSystem.exists("ndll"))
         {
            // Work around haxelib bug for now...
            for(hackDir in ["ndll/Linux","ndll/Linux64"])
               if (!FileSystem.exists(hackDir))
                  FileSystem.createDirectory(hackDir);
            command("chmod",["-R", "755", "ndll" ]);
         }
      }

      Sys.setCwd(scratchDir);
      var newDir = name + "-" + newVersion;
      command("rm",["-rf", newDir] );
      command("mv",[dir,newDir] );
      var zipName = name + "-" + newVersion + ".zip";
      command("rm",["-f", zipName] );
      command("zip",["-r", zipName, newDir] );
      command("mv",[newDir,dir] );
      log("sending " + zipName + "...");
      Lib.sendWebFile(zipName, "releases/" + name + "/" + zipName);
      log("update release db... ");

      Lib.runJson("UpdateRelease.n", { project:name, base:baseVersion, build:buildNumber, release:newVersion, git:gitVersion, notes:newNotes } );

     command("rm", ["-f", "sent/" + zipName]);
     command("mv", [zipName, "sent"]);
   }

   public function checkRelease()
   {
      if (hasBinaries())
      {
         var ver = binaryVersion;
         log("Check binaries built...");
         updateVersionInfo();

         var have:Array<Dynamic> = versionInfo.have;
         if (have.length < allBinaries.length)
         {
            log("binaries not built yet : " + have.length + "/" + allBinaries.length );
            return;
         }
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

   public function getServerBinaries(inVersion:Int)
   {
      var query:Dynamic = {};
      query.project = name;
      query.binaryVersion = inVersion;
      return Lib.runJson("QueryBinaries.n", query );
   }

}


