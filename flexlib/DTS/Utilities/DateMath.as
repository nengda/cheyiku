package DTS.Utilities
{
	public class DateMath
	{
		public static function AddDays(date:Date, days:Number):Date {
			return AddHours(date, days * 24);
		}

		public static function AddHours(date:Date, hours:Number):Date {
			return AddMinutes(date, hours * 60);
		}

		public static function AddMinutes(date:Date, minutes:Number):Date {
			return AddSeconds(date, minutes * 60);
		}

		public static function AddSeconds(date:Date, seconds:Number):Date {
			return AddMilliseconds(date, seconds * 1000);
		}

		public static function AddMilliseconds(date:Date, milliseconds:Number):Date {
			var r:Date = new Date();
			r.setTime(date.getTime() + milliseconds);
			return r;
		}
	}
}
