package DTS.Utilities
{
	public class DateParser
	{
		public static function ParseYMD(s:String):Date {
			if (s == null || s.match(/^\s*$/) != null) {
				return null;
			}
			try {
				var dateTokens:Array = s.split(/-/);
				if (dateTokens.length != 3) {
					return null;
				}
				var year:Number = Number(dateTokens[0]);
				var month:Number = Number(dateTokens[1]) - 1;
				var date:Number = Number(dateTokens[2]);
				var dateObj:Date = new Date(year, month, date);
				if (dateObj.getFullYear() != year || dateObj.getMonth() != month || dateObj.getDate() != date) {
					return null;
				}
				return dateObj;
			}
			catch (error:Error) {}
			return null;
		}

		public static function ParseYMDHMS(s:String):Date {
			if (s == null || s.match(/^\s*$/) != null) {
				return null;
			}
			try {
				var dateTime:Array = s.split(/\s+|T/);
				var ymd:Date = ParseYMD(dateTime[0].toString());
				var year:Number = ymd.getFullYear();
				var month:Number = ymd.getMonth();
				var date:Number = ymd.getDate();
				var timeStr:String = dateTime[1].toString();
				var timeTokens:Array = timeStr.split(/:/);
				if (timeTokens.length != 3) {
					return null;
				}
				var hour:Number = Number(timeTokens[0]);
				var minute:Number = Number(timeTokens[1]);
				var second:Number = Number(timeTokens[2]);
				var dateObj:Date = new Date(year, month, date, hour, minute, second);
				// Assumption: date string is always in UTC.
				dateObj.setTime(dateObj.getTime() - dateObj.getTimezoneOffset() * 60 * 1000);
				return dateObj;
			}
			catch (error:Error) {}
			return null;
		}
	}
}
