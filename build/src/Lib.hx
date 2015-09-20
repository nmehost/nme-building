import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;

class Lib
{
   public static var partsDir = "";
   public static var filePath = ["."];

   public static function sendData(inAction:String, inFunction:String, inParams:String) : String
   {
      var passwd = Sys.getEnv("HURTS_PASSWORD");
      if (passwd==null)
      {
         throw("Please set HURTS_PASSWORD for your site.");
      }
      var host = Sys.getEnv("HURTS_HOST");
      if (host==null)
      {
         throw("Please set HURTS_HOST for your site.");
      }

      var nonce = haxe.Http.requestUrl("http://" + host + "/hurts/nonce.php");
      nonce = Std.string(Std.parseInt(nonce));

      var post = new haxe.Http("http://" + host + "/hurts/run.php");
      post.cnxTimeout = 300;
      var data:String = null;
      post.onData = function(s) data = s;
      post.onError = function(s) throw(s);
      //post.onStatus = function(i) trace("status  " +i );

      post.setParameter( "action", inAction ); 
      post.setParameter( "data", inFunction ); 
      post.setParameter( "nonce", nonce ); 
      post.setParameter( "params", inParams ); 
      post.setParameter( "md5", haxe.crypto.Md5.encode(inAction+inParams+inFunction+nonce+passwd) ); 
      post.request(true);
      return data;
   }

   public static function addFilePath(inPath:String)
   {
      filePath.push(inPath);
   }

   static function getBytes(inFilename:String) : Bytes
   {
      var fullPath:String = null;

      if (inFilename.substr(0,1)=="/" || inFilename.substr(0,1)=="\\" ||
           inFilename.substr(1,1)==":" )
         fullPath = inFilename;
      else
      {
         for(path in filePath)
         {
            var testName = path + "/" + inFilename;
            if (sys.FileSystem.exists(testName))
            {
               fullPath = testName;
               break;
            }
         }
      }
      if (fullPath==null)
          throw "Could not find " + inFilename + " in " +filePath;

      try
      {
         return File.getBytes(fullPath);
      }
      catch(e:Dynamic)
      {
         throw "Could not open " + fullPath;
      }
      return null;
   }

   public static function runJson(inModuleName:String, inQuery:Dynamic) : Dynamic
   {
      var json = haxe.Json.stringify(inQuery);
      var result = sendData("run", inModuleName, json );
      if (result.substr(0,5)=="Error")
         throw result;
      return haxe.Json.parse(result);
   }

   public static function runNeko(inModuleName:String, ?inArg:String) : String
   {
      return sendData("run", inModuleName, inArg==null ? "" : inArg );
   }

   public static function sendFile(inSource:String, inDest:String) : String
   {
      var scp = Sys.getEnv("HURTS_SCP_URL");
      if (scp!=null && scp!="")
      {
         var result = Sys.command("scp",[ inSource, scp+":"+inDest ]);
         if (result!=0)
            throw "Error running scp " + inSource + " to " + inDest;
         return "Wrote " + inDest;
      }
      else
      {
         throw "scp not initialized";
      }
   }

   public static function sendWebFile(inSource:String, inDest:String) : String
   {
      var size = 1024*1024;

      var bytes = File.getBytes(inSource);
      if (partsDir=="" || bytes.length<=size)
      {
         return sendFile(inSource, "www/"+inDest);
      }
      else
      {
         var chunks = Std.int( (bytes.length+size-1)/size );
         var prefix = inDest.split("/").pop();
         var dest = "hurts/parts/";
         var sent = 0;
         var remaining = bytes.length;
         for(c in 0...chunks)
         {
            var partName = prefix + "-" + c;
            var src = partsDir + "/" + partName;
            var send = remaining < size ? remaining : size;
            File.saveBytes( src, bytes.sub(sent, send) );
            sendFile(src,dest + partName);
            remaining -= send;
            sent += send;
         }
         runJson("JoinFiles.n", { src:dest+prefix, count:chunks, dest:inDest, lenght:bytes.length } );

         return "ok";
      }
   }

   public static function initServer(inBase:String)
   {
      var scp = Sys.getEnv("HURTS_SCP_URL");
      if (scp!=null && scp!="")
      {
         var src = inBase + "/run.php";
         var dest = "www/hurts/run.php";
         Sys.println('scp $src -> $dest');
         var result = Sys.command("scp",[ src, scp+":"+dest ]);
         if (result!=0)
            throw "Error sending " + src;

         var funcDir = inBase + "/bin";
         var files = FileSystem.readDirectory(funcDir);
         for(file in files)
         {
            if (file.substr(file.length-2)==".n")
            {
               var src = funcDir + "/" + file;
               var dest = "hurts/scripts/" + file;
               Sys.println('scp $src -> $dest');
               var result = Sys.command("scp",[ src, scp+":"+dest ]);
               if (result!=0)
                throw "Error sending " + file;
            }
         }
      }
   }

}

