class Release
{
   public var git:String;
   public var status:String;
   public var isReleased:Bool;

   public function new(inInfo:Dynamic)
   {
      git = inInfo.git;
      status = inInfo.status;
      isReleased = status.split(":")[0] == "released";
   }

}
