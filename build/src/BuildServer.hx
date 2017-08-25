import sys.FileSystem;

class BuildServer
{
   public var scratchDir:String;
   public var binDir:String;
   public var isWindows:Bool;
   public var isMac:Bool;
   public var isLinux:Bool;
   public var isPrimary:Bool;
   public var host:String;
   public var hosts:Array<String>;

   public var builders:Array<Builder>;
   public var releases:Map<String,Release>;

   public var haxelibConfig:String;

   public var bsDir:String;

   public function new()
   {
      bsDir = Sys.getCwd();
      log("Using nme-building " + bsDir);
      releases = new Map<String,Release>();


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

      var partsDir = scratchDir+"/parts";
      if (!FileSystem.exists(partsDir))
         FileSystem.createDirectory(partsDir);
      if (FileSystem.exists(partsDir))
         Lib.partsDir = partsDir;

      log("Using scratchDir " + scratchDir);

      binDir = Sys.getEnv("BS_BIN_DIR");
      log("Using binDir " + binDir);
      if (binDir==null || binDir=="" /*|| !FileSystem.exists(binDir)*/)
        throw "Shared binary directory BS_BIN_DIR '" + binDir + "' not found scratchDir '" + scratchDir + "'";
 
      var projects = new Array<String>();
      var args = Sys.args();
      var idx = 0;
      var init = false;
      while(idx<args.length-1)
      {
         if (args[idx]=="-p")
         {
            idx++;
            projects.push(args[idx]);
            idx++;
         }
         else
         {
           if (args[idx]=="-init")
              init = true;
           idx++;
         }
      }

      if (init)
         Lib.initServer( bsDir + "/build/functions" );

      hosts = [ "mac", "windows" ];

      var lines = Builder.readStdout("haxelib",["config"]);
      if (lines.length!=1)
         throw "Could not setup haxelib (" + lines + ")";
      haxelibConfig = lines[0];

      var os = Sys.systemName();
      isWindows = (new EReg("window","i")).match(os);
      isMac = (new EReg("mac","i")).match(os);
      isLinux = (new EReg("linux","i")).match(os);
      isPrimary = isMac;

      if (!isMac && !isWindows)
         throw "Could not determine host";
      host = isMac ? "mac" : "windows";

      builders = [];
      builders.push(new HxcppBuilder(this));
      builders.push(new NMEBuilder(this));
      //builders.push(new WaxeWorksBuilder(this));
      //builders.push(new WaxeBuilder(this));
      //builders.push(new Gm2dBuilder(this));
      //builders.push(new HxcppDebuggerBuilder(this));


      var goes = isMac ? 100 : 1000000000;
      for(count in 0...goes)
      {
         var ok = false;
         try
         {
            getReleases();
            ok = true;
         }
         catch(e:Dynamic)
         {
            log("Error getting releases :" + e);
         }
         if (ok)
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
                  Sys.println(haxe.CallStack.toString( haxe.CallStack.exceptionStack()));
                  log("Error building " + builder.name + ":" + e );
               }
               log(" ------------");
            }
         if (projects.length>0)
            break;
         log("zzz...");
         Sys.sleep(360);
      }
   }

   static var firstRelease = true;
   public function getReleases()
   {
      var hurts = Sys.getEnv("HURTS_HOST");
      if (hurts==null)
         throw("Please set HURTS_HOST for your site.");

      var extra = "";
      if (firstRelease && isMac)
      {
         var projs = [];
         for(b in builders)
            projs.push(b.name);
         extra = "?" + projs.join("&");
      }

      var data = haxe.Http.requestUrl("http://" + hurts + "/api/versions.php" + extra);
      var obj = haxe.Json.parse(data);
      var fields = Reflect.fields(obj);
      for(f in fields)
      {
         var value = Reflect.field(obj,f);
         log(f + "=>" + value);
         releases.set(f, new Release(value) );
      }

   }

   public function findDepend(inDepend:String) : Builder
   {
      for(builder in builders)
         if (builder.name==inDepend)
            return builder;
      throw "Could not find dependant project "+ inDepend; 
   }

   public function shouldCreateRelease()
   {
      return isPrimary;
   }

   public function log(s:String)
   {
      Sys.println(s);
   }
}


