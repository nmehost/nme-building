import sys.FileSystem;

class BuildServer
{
   public var scratchDir:String;
   public var binDir:String;
   public var isWindows:Bool;
   public var isMac:Bool;
   public var isLinux:Bool;

   public var binaries:Array<String>;
   public var allBinaries:Array<String>;

   public var bsDir:String;

   public function new()
   {
      bsDir = Sys.getCwd();
      log("Using nme-building " + bsDir);

      Lib.addFilePath( bsDir + "/build/functions/bin" );
      scratchDir = Sys.getEnv("BS_SCRATCH_DIR");
      if (scratchDir==null || scratchDir=="")
      {
         scratchDir = Sys.getEnv("HOME") + "/bs-scratch";
         if (!FileSystem.exists(scratchDir))
         {
            FileSystem.createDirectory(scratchDir);
         }
      }
      if (!FileSystem.exists(scratchDir))
        throw "Could not find binDir '" + scratchDir + "'";

      log("Using scratchDir " + scratchDir);

      binDir = Sys.getEnv("BS_BIN_DIR");
      if (binDir==null || binDir=="" || !FileSystem.exists(binDir))
        throw "Shared binary directory BS_BIN_DIR not found scratchDir '" + scratchDir + "'";
 
      var projects = new Array<String>();
      var args = Sys.args();
      var idx = 0;
      while(idx<args.length-1)
      {
         if (args[idx]=="-p")
         {
            idx++;
            projects.push(args[idx]);
            idx++;
         }
         else
           idx++;
      }

      var windowsBinaries = [ "windows" ];
      var linuxBinaries = [ "linux" ];
      var macBinaries = [ "mac", "ios", "linux", "android" ];


      var os = Sys.systemName();
      isWindows = (new EReg("window","i")).match(os);
      isMac = (new EReg("mac","i")).match(os);
      isLinux = (new EReg("linux","i")).match(os);

      if (isWindows)
         binaries = windowsBinaries;
      else if (isLinux)
         binaries = linuxBinaries;
      else if (isMac)
         binaries = macBinaries;
      else
         throw "Could not determine host";

      allBinaries = windowsBinaries.copy();
      for(b in linuxBinaries)
         if (!Lambda.exists(allBinaries,function(x) return x==b))
            allBinaries.push(b);
      for(b in macBinaries)
         if (!Lambda.exists(allBinaries,function(x) return x==b))
            allBinaries.push(b);


      var builders:Array<Builder> =
         [
            new NMEStateBuilder(this),
            new HxcppBuilder(this),
            new NMEBuilder(this),
            new WaxeWorksBuilder(this)
            //new WaxeBuilder(this)
         ];

      while(true)
      {
         for(builder in builders)
         {
            if (projects.length>0)
            {
               if (!Lambda.exists(projects, function(x) return x==builder.name) )
               {
                  log("skip " + builder.name);
                  continue;
               }
            }
            log(" --- " + builder.name + " ---");
            try
            {
               builder.build();
            }
            catch(e:Dynamic)
            {
               log("Error building " + builder.name + ":" + e );
            }
            log(" ------------");
         }
         if (projects.length>0)
            break;
         log("zzz...");
         Sys.sleep(60);
      }
   }

   public function shouldCreateRelease()
   {
      return isMac;
   }

   public function log(s:String)
   {
      Sys.println(s);
   }
}
