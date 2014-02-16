class Db
{
   public static function run(run:sys.db.Connection->String->Void)
   {
      var arg = Sys.args()[0];
      try
      {
         var file = sys.io.File.getContent("passwd.txt");
         var lines = file.split("\n");
         if (lines.length<2)
            throw "Expected at least 2 lines in password file";
         var parts = lines[1].split(":");
         if (parts.length!=3)
            throw "Expected database:user:passwd in password file";

         var connect =  { user : parts[1], pass:parts[2], host:"localhost", database:parts[0]};
         var connection = sys.db.Mysql.connect(connect);

         run(connection,arg);
      }
      catch(e:Dynamic)
      {
         Sys.println("Error : " + e + " query=" + arg);
      }
   }

   public static function runJson(run:sys.db.Connection->Dynamic->Dynamic)
   {
      var arg = Sys.args()[0];
      try
      {
         var file = sys.io.File.getContent("passwd.txt");
         var lines = file.split("\n");
         if (lines.length<2)
            throw "Expected at least 2 lines in password file";
         var parts = lines[1].split(":");
         if (parts.length!=3)
            throw "Expected database:user:passwd in password file";

         var connect =  { user : parts[1], pass:parts[2], host:"localhost", database:parts[0]};
         var connection = sys.db.Mysql.connect(connect);

         var json = haxe.Json.parse(arg);
         var result = run(connection,json);
         Sys.println(haxe.Json.stringify(result));
      }
      catch(e:Dynamic)
      {
         Sys.println("Error : " + e + " query=" + arg);
      }
   }
}


