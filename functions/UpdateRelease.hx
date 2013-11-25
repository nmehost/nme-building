import sys.FileSystem;

class UpdateRelease
{
   public static function run(connect:sys.db.Connection,query:Dynamic) : Dynamic
   {
      connect.request("INSERT into bsRelease (project,version) VALUES(" +
        connect.quote(query.project) + "," + query.version+
        ")" );

      return {};
   }

   public static function main() { hurts.Db.runJson(run); }
}

