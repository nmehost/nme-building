import sys.FileSystem;

class IsReleased
{
   public static function run(connect:sys.db.Connection,arg:String)
   {
      var query = haxe.Json.parse(arg);
      var result:Dynamic = {};

      // Check to see if directory needs building...
      try {
         var dir = "../www/releases/" + query.project;
         if (!FileSystem.exists(dir))
             FileSystem.createDirectory(dir);
      } catch (e:Dynamic) { }

      var sql = "SELECT COUNT(project) FROM bsRelease where project=" +
        connect.quote(query.project) + " and version=" + query.version;

      var rset = connect.request(sql);
      Sys.println( haxe.Json.stringify( rset.getIntResult(0) ) );
   }

   public static function main() { hurts.Db.run(run); }
}

