import haxe.Http;
import sys.io.File;
import sys.FileSystem;

class Builder
{
   var bs:BuildServer;

   public var name:String;
   public var isGit:Bool;
   public var url:String;

   public var versionUrl:String;
   public var svnCmd:String;
   public var revisionMatch:EReg;

   public var binaryVersion:Int=0;
   public var svnVersion:Int=0;
   public var haxeVersion:String="";

   public var binaries:Array<String>;
   public var allBinaries:Array<String>;
   public var scratchDir:String;
   public var cloneDir:String;

   public function new(inBs:BuildServer,inName:String,inHasBinaries:Bool, inUrl:String,inIsGit:Bool=false)
   {
      revisionMatch = ~/^Revision: (\S+)/;
      bs = inBs;
      name = inName;
      binaryVersion = 0;
      isGit = inIsGit;
      svnCmd = Sys.getEnv("BS_SVN");
      if (svnCmd==null || svnCmd=="")
        svnCmd = "svn";
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

      if (isGit)
         setGitUrl(inUrl);
      else
         setSnvUrl(inUrl);
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
      return name;
   }

   public function setSnvUrl(inUrl:String)
   {
      url = inUrl;
      versionUrl = url + "trunk/haxelib.json";
   }

   public function setGitUrl(inUrl:String)
   {
      url = inUrl;
      cloneDir = scratchDir + "/clones";
      if (!FileSystem.exists(cloneDir))
         FileSystem.createDirectory(cloneDir);
      cloneDir += "/" + name;
      //versionUrl = "https://raw." + url.substr(8) + "/master/haxelib.json";
      versionUrl = cloneDir + "/haxelib.json";
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
         command("git",["pull"] );
      }
      else
      {
         log("clone...");
         Sys.setCwd(scratchDir + "/clones");
         log("cloning git clone " +  url + ".git");
         command("git",["clone", url + ".git"] );
      }
   }

   public function prepareBuild() : Int
   {
      log("Prepare build...");
      Sys.setCwd(scratchDir);
      var dir = getCheckoutDir();
      scrubDir(dir);

      if (isGit)
      {
         updateClone();
         Sys.setCwd(scratchDir);
         FileSystem.createDirectory(dir);
         var files = FileSystem.readDirectory(cloneDir);
         for(file in files)
         {
            if (file.substr(0,1)!=".")
               command("cp", ["-rp", cloneDir+"/"+file, dir] );
         }
      }
      else
      {
         log("checkout...");
         command(svnCmd,["checkout",url + "/trunk", dir]);
      }

      var version = File.getContent(dir + "/haxelib.json");
      var data = haxe.Json.parse(version);
      var binaryVersion = Std.parseInt(data.binaryversion);

      log("Done " + binaryVersion);
      return binaryVersion;
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
      if (isGit)
         updateClone();

      if (hasBinaries())
         buildBinaries();

      if (bs.shouldCreateRelease())
         checkRelease();
   }

   public function buildBinaries()
   {
      var ver = getBinaryVersion();
      log("Bin ver : "+ ver);
      var have:Array<Dynamic> = getServerBinaries(ver);

      log("Have : "+ have);
      binaryVersion = 0;
      for(bin in binaries)
      {
         log(bin + "...");
         var found = false;
         for(b in have)
            if (b==bin)
               found = true;

         if (!found)
         {
            if (binaryVersion==0)
               binaryVersion = prepareBuild();

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
      var result = hurts.Lib.runJson("UpdateBinary.n",
         { project:name, version:binaryVersion, platform:inPlatform } );
   }

   public function sendBinary(inFile:String)
   {
      log("Sending " + inFile + "...");
      var result = hurts.Lib.sendWebFile(inFile, "binaries/" + name + "/" + binaryVersion + "/" + inFile );
      if (result.substr(0,5)=="Wrote")
         log(result);
      else
         throw result;
   }

   public function command(cmd:String, args:Array<String>)
   {
      if (Sys.command(cmd,args)!=0)
         throw "Error running command: " + cmd + " " + args.join(" ");
   }

   public function buildRelease()
   {
      var binVersion = prepareBuild();
      if (hasBinaries())
      {
         log("Check binaries built...");
         var have = getServerBinaries(binVersion);
         for(bin in allBinaries)
         {
            var found = false;
            for(h in have)
               if (h==bin) found = true;
            if (!found)
            {
               throw("Missing binary  : " + bin );
               return;
            }
         }
      }

      var dir = getCheckoutDir();
      var svnVersion = getSvnRevision(dir);
      log("Releasing " + svnVersion);
      Sys.setCwd(dir);
      removeSpecialFiles(".");

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
            newVersion = versionMatch.matched(2) + "." + svnVersion;
            lines[idx]=versionMatch.matched(1) + newVersion + versionMatch.matched(3);
            found = true;
            break;
         }
         idx++;
      }
      if (!found)
         throw "Could not find version in " + jsonFile;

      File.saveContent(jsonFile, lines.join("\n") );

      log("Getting binaries...");
      for(bin in allBinaries)
      {
         var file = name + "-bin-" + bin + ".tgz";
         var url = "http://" + Sys.getEnv("HURTS_HOST") + "/binaries/" + name + "/" + binVersion + "/" + file;
         log("fetching " + url + "...");
         var data = haxe.Http.requestUrl(url);
         File.saveBytes( file, haxe.io.Bytes.ofString(data) );
         command("tar", [ "xvzf", file ]);
         command("rm", [  file ]);
      }
      if (allBinaries.length>0)
      {
         if (FileSystem.exists("bin"))
            command("chmod",["-R", "755", "bin" ]);
         if (FileSystem.exists("ndll"))
            command("chmod",["-R", "755", "ndll" ]);
      }

      Sys.setCwd(scratchDir);
      var newDir = name + "-" + newVersion;
      command("mv",[dir,newDir] );
      var zipName = name + "-" + newVersion + ".zip";
      command("rm",["-f", zipName] );
      command("zip",["-r", zipName, newDir] );
      command("mv",[newDir,dir] );
      log("sending " + zipName + "...");
      hurts.Lib.sendWebFile(zipName, "releases/" + name + "/" + zipName);
      log("update release db... ");
      hurts.Lib.runJson("UpdateRelease.n", { project:name, version:svnVersion } );
   }



 
   public function getSvnRevision(inUrl:String)
   {     

      log("Check svn version...");
      var output = readStdout(svnCmd, ["info", inUrl]);
      var svnRev = 0;
      for(line in output)
         if (revisionMatch.match(line))
            return Std.parseInt(revisionMatch.matched(1));
      return 0;
   }
 

   public function checkRelease()
   {
      if (hasBinaries())
      {
         log("Check binaries built...");
         var have:Array<Dynamic> = getServerBinaries( getBinaryVersion() );
         if (have.length < allBinaries.length)
         {
            log("binaries not built yet : " + have.length + "/" + allBinaries.length );
            return;
         }
      }

      svnVersion = getSvnRevision(url);
      log("      svn version = " + svnVersion);

      var isReleased = hurts.Lib.runJson("IsReleased.n", { project:name, version:svnVersion } );
      if (Std.parseInt(isReleased)>0 )
      {
         log("      already released = " + svnVersion);
         return;
      }
      buildRelease();
   }

   public function getServerBinaries(inVersion:Int)
   {
      var query:Dynamic = {};
      query.project = name;
      query.binaryVersion = inVersion;
      return hurts.Lib.runJson("QueryBinaries.n", query );
   }


   public function getBinaryVersion()
   {
      log("Check repo data " + versionUrl);

      var version = isGit ? File.getContent(versionUrl) : Http.requestUrl(versionUrl);
      var data = haxe.Json.parse(version);

      return Std.parseInt(data.binaryversion);
   }
}


