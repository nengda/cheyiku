package DTS.Utilities
{
	public class Indentation
	{
		public static function Add(s:String, prefix:String="\t", eol:String="\n", removeEmptyLines:Boolean=false):String {
			var lines:Array = s.replace(/\r/g, '').split(/\n/);
			var result:String = "";
			for (var i:int = 0; i < lines.length; i++) {
				var line:String = lines[i];
				if (line.match(/^\s*$/) != null && (i == lines.length - 1 || removeEmptyLines)) {
				}
				else {
					result += prefix + line + eol;
				}
			}
			return result;
		}
	}
}