class HxcppDebuggerBuilder extends Builder
{
   public function new(inBs:BuildServer)
   {
      super(inBs,"hxcpp-debugger",false,"https://github.com/HaxeFoundation/hxcpp-debugger");
      writeHaxeVersionPackage = "debugger";
      changesFile = "Changes.md";
   }
}



