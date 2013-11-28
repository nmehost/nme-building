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
      var notes:Array<Dynamic> = query.notes;

      var rset = connect.request("SELECT COUNT(note) FROM bsReleaseNotes where project=" + 
                  project );
      var noteCount:Int = rset.getIntResult(0);

      if (notes!=null && notes.length>0)
      {
         for(note in notes)
         {
            var qnote = connect.quote(note);
            connect.request("INSERT into bsReleaseNotes (project,id,note)" +
                      ' VALUES ($project,$noteCount,$qnote)' );
            noteCount++;
         }
      }


      connect.request("INSERT into bsRelease (project,base,build,git,`release`,notes)" +
                      ' VALUES ($project,$base,$build,$git,$release,$noteCount)' );
      return {};
   }

   public static function main() { hurts.Db.runJson(run); }
}

