import sys.FileSystem;

class UpdateRelease
{
   public static function run(connect:sys.db.Connection,query:Dynamic) : Dynamic
   {
      var project = connect.quote(query.project);
      var base = connect.quote(query.base);
      var git = connect.quote(query.git);
      var release = connect.quote(query.release);
      var build = query.build;
      connect.request("INSERT into bsRelease (project,base,build,git,`release`)" +
                      ' VALUES ($project,$base,$build,$git,$release)' );
      return {};
   }

   public static function main() { hurts.Db.runJson(run); }
}

