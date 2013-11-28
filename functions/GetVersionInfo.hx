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

      var rset = connect.request("SELECT build,git FROM bsRelease where project=" + 
                 connect.quote(query.project) + " and base=" + connect.quote(query.base) );

      var biggest = 0;
      info.isReleased = false;
      for(row in rset)
      {
         if (row.git == query.git)
         {
            info.isReleased = true;
            info.buildNumber = row.build;
            break;
         }
      }
      if (!info.isReleased)
         info.buildNumber = biggest + 1;

      var rset = connect.request("SELECT COUNT(note) FROM bsReleaseNotes where project=" + 
                 connect.quote(query.project) );
      info.noteCount = rset.getIntResult(0);

      Sys.println( haxe.Json.stringify(info) );
   }

   public static function main() { hurts.Db.run(run); }
}

