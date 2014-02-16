import sys.FileSystem;

class QueryVersions
{
   public static function run(connect:sys.db.Connection,arg:String)
   {
      var query = haxe.Json.parse(arg);
      var result:Dynamic = {};

      var rset = connect.request("SELECT COUNT(project) FROM bsRelease where project=" +
        connect.quote(query.project) + " and version=" + query.svnVersion );
      result.released = rset.getIntResult(0)>0;

      if (!result.released)
      {
         var binDir = "../www/binaries/" + query.project + "/" + query.binaryVersion;
         if (!FileSystem.exists(binDir))
            FileSystem.createDirectory(binDir);

         result.binaries = new Array<Dynamic>();
         var rset = connect.request("SELECT * FROM bsBinaries where project=" +
            connect.quote(query.project) + " and version=" + query.binaryVersion );
         var idx = 0;
         for(row in rset)
            result.binaries[idx++] = row.platform;
      }

      Sys.println( haxe.Json.stringify(result) );
   }

   public static function main() { hurts.Db.run(run); }
}

