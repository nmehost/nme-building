import sys.FileSystem;

class JoinFiles
{
   public static function main()
   {
      var json = haxe.Json.parse(Sys.args()[0]);
      var src:String = json.src;
      var dest:String = json.dest;
      var count:Int = json.count;
      var length:Int = json.length;

      var pos = 0;

      var buffer = haxe.io.Bytes.alloc(length);
      for(c in 0...count)
      {
         var chunk = sys.io.File.getBytes(src+"-"+c);
         buffer.blit(pos, chunk, 0, chunk.length);
         pos += chunk.length;
      }

      sys.io.File.saveBytes(dest, buffer);
   }
}

