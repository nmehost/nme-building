import sys.FileSystem;

class UpdateRelease
{
   public static function run(connect:sys.db.Connection,query:Dynamic) : Dynamic
   {
      var git = connect.quote( query.git==null ? "" : query.git );
      connect.request("INSERT into bsRelease (project,version,git) VALUES(" +
        connect.quote(query.project) + "," + query.version + "," + git +
        ")" );

      return {};
   }

   public static function main() { hurts.Db.runJson(run); }
}

