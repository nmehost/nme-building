import sys.FileSystem;

class QueryBinaries
{
   public static function run(connect:sys.db.Connection,arg:String)
   {
      var query = haxe.Json.parse(arg);

      var binDir = "../www/binaries/" + query.project + "/" + query.binaryVersion;
      if (!FileSystem.exists(binDir))
          FileSystem.createDirectory(binDir);

      var result = new Array<Dynamic>();
      var rset = connect.request("SELECT * FROM bsBinaries where project=" +
            connect.quote(query.project) + " and version=" + query.binaryVersion );
      var idx = 0;
      for(row in rset)
         result[idx++] = row.platform;

      Sys.println( haxe.Json.stringify(result) );
   }

   public static function main() { hurts.Db.run(run); }
}

