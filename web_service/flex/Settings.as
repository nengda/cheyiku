package
{
	import DTS.Configurations.BuildTypes;
	import DTS.Configurations.UserPreference;
	import DTS.Logger.LogWindow;
	
	public class Settings
	{
		public static const UserPreferenceNS:String = "CYC.AdminUI";
		public static const EndPoint:String = "";
		public static const AutoRefreshInterval:int = 60;

		public static function get Debug():Boolean {
			return (Build.Type == BuildTypes.DEBUG);
		}

/*
		public static function get HostPerformanceCharts():String {
			return UserPreference.Get(UserPreferenceNS, "HostPerformanceCharts", "") as String;
		}

		public static function set HostPerformanceCharts(value:String):void {
			UserPreference.Set(UserPreferenceNS, "HostPerformanceCharts", value);
		}

*/
		public static function ApplicationInit():void {
			DTSFlexLib.Debug = Debug;
			LogWindow.Enabled = Debug;
		}
	}
}
