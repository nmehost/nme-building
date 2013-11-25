import sys.FileSystem;

class UpdateBinary
{
   public static function run(connect:sys.db.Connection,query:Dynamic) : Dynamic
   {
      connect.request("INSERT into bsBinaries (project,platform,version) VALUES(" +
        connect.quote(query.project) + "," +  connect.quote(query.platform) + "," + query.version+
        ")" );

      return {};
   }

   public static function main() { hurts.Db.runJson(run); }
}

