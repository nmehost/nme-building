import sys.FileSystem;

class GetVersionInfo
{
   public static function run(connect:sys.db.Connection,arg:String)
   {
      var query = haxe.Json.parse(arg);

      var binDir = "../www/binaries/" + query.project + "/" + query.binaryVersion;
      if (!FileSystem.exists(binDir))
          FileSystem.createDirectory(binDir);

      var proj =  connect.quote(query.project);
      var info:Dynamic = {};
      var result = new Array<Dynamic>();
      var rset = connect.request("SELECT * FROM bsBinaries where project=" + proj +
           " and version=" + query.binaryVersion );
      var idx = 0;
      for(row in rset)
         result[idx++] = row.platform;
      info.have = result;

      var rset = connect.request("SELECT project,builtNumber FROM bsRelease where git=" + 
                 connect.quote(query.git) );
      info.isReleased =  rset.hasNext();

      var rset = connect.request("SELECT MAX(buildNumber) FROM bsBuild where haxelib=" + 
                 connect.quote(query.haxelib) + " project =" + proj );
      if (rset==null)
         info.buildNumber = 1;
      else
         info.buildNumber = rset.getIntResult(0) + 1;

      Sys.println( haxe.Json.stringify(info) );
   }

   public static function main() { hurts.Db.run(run); }
}

