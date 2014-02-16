import sys.io.File;
import haxe.io.Bytes;

class Lib
{
   public static var filePath = ["."];

   public static function sendData(inAction:String, inData:Bytes, inParams:String) : String
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

      var postData = neko.zip.Compress.run(inData,9);
      post.setParameter( "action", inAction ); 
      post.setParameter( "data", postData.toString() ); 
      post.setParameter( "nonce", nonce ); 
      post.setParameter( "params", inParams ); 
      post.setParameter( "md5", haxe.crypto.Md5.encode(inAction+inParams+postData+nonce+passwd) ); 
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
      var result = sendData("run", getBytes(inModuleName), json );
      if (result.substr(0,5)=="Error")
         throw result;
      return haxe.Json.parse(result);
   }

   public static function runNeko(inModuleName:String, ?inArg:String) : String
   {
      return sendData("run", getBytes(inModuleName), inArg==null ? "" : inArg );
   }

   public static function sendFile(inSource:String, inDest:String) : String
   {
      var scp = Sys.getEnv("HURTS_SCP_URL");
      if (scp!=null && scp!="")
      {
         var result = Sys.command("scp",[ inSource, scp+":"+inDest ]);
         if (result!=0)
            throw "Error running scp";
         return "Wrote " + inDest;
      }
      else
      {
         var result = sendData("put", getBytes(inSource), inDest );
         if (result.substr(0,5)!="Wrote")
           throw "Error sending file " + result;
         return result;
      }
   }

   public static function sendWebFile(inSource:String, inDest:String) : String
   {
      var scp = Sys.getEnv("HURTS_SCP_URL");
      if (scp!=null && scp!="")
      {
         var result = Sys.command("scp",[ inSource, scp+":www/"+inDest ]);
         if (result!=0)
            throw "Error running scp";
         return "Wrote www/" + inDest;
      }
      else
      {
         var result = sendData("wput", getBytes(inSource), inDest );
         if (result.substr(0,5)!="Wrote")
           throw "Error sending file " + result;
         return result;
      }
   }

}

