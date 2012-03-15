package DTS.Configurations
{
	import flash.net.SharedObject;
	
	public class UserPreference
	{
		public static function Get(ns:String, name:String, defaultValue:Object):Object {
			var so:SharedObject = SharedObject.getLocal(ns);
			if (so.size > 0 && so.data.hasOwnProperty(name)) {
				return so.data[name];
			}
			return defaultValue;
		}

		public static function Set(ns:String, name:String, value:Object):void {
			var so:SharedObject = SharedObject.getLocal(ns);
			so.data[name] = value;
			so.flush();
		}
	}
}
