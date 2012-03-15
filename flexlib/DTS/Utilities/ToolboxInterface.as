package DTS.Utilities
{
	import flash.external.ExternalInterface;

	public class ToolboxInterface
	{
		public static function get UserId():String {
			var userId:String = null;
			try {
				userId = ExternalInterface.call("GetUserId");
			}
			catch (error:Error) {}
			return (userId == null) ? "Unknown" : userId;
		}

		public static function get PageTitleWidth():int {
			var value:int = 0;
			try {
				value = int(ExternalInterface.call("GetTitleWidth"));
			}
			catch (error:Error) {
			}
			return (value > 0) ? value : 50;
		}

		public static function get PageTitleHeight():int {
			var value:int = 0;
			try {
				value = int(ExternalInterface.call("GetTitleHeight"));
			}
			catch (error:Error) {
			}
			return (value > 0) ? value : 50;
		}
	}
}
