package DTS.Globalization
{
	import DTS.Utilities.DateParser;
	
	import mx.collections.ArrayCollection;
	import mx.utils.StringUtil;
	
	public class Timezone
	{
		// Data from http://en.wikipedia.org/wiki/Time_zones_by_country
		[Embed(source="Data/timezones.txt", mimeType="application/octet-stream")]
		private static var _rawData:Class;

		private static var _initialized:Boolean = false;
		private static var _namesByCountry:XML;
		private static var _names:ArrayCollection;
		
		public static function Names():ArrayCollection {
			Initialize();
			return _names;
		}

		public static function NamesByCountry():XML {
			Initialize();
			return _namesByCountry;
		}
		
		public static function LocalToUTC(o:Object):Date {
			if (o == null) {
				return null;
			}
			var date:Date = null;
			if (o is Date) {
				date = o as Date;
			} else {
				date = ParseDateTime(o.toString());
			}
			if (date != null) {
				date.setTime(date.getTime() + date.getTimezoneOffset() * 60 * 1000);
				return date;
			} else {
				return null;
			}
		}
		
		public static function UTCToLocal(o:Object):Date {
			if (o == null) {
				return null;
			}
			var date:Date = null;
			if (o is Date) {
				date = o as Date;
			} else {
				date = ParseDateTime(o.toString());
			}
			if (date != null) {
				date.setTime(date.getTime() - date.getTimezoneOffset() * 60 * 1000);
				return date;
			} else {
				return null;
			}
		}

		private static function Initialize():void {
			if (_initialized) {
				return;
			}
			_initialized = true;

			_names = new ArrayCollection();
			var rawText:String = (new _rawData()).toString();
			var lines:Array = rawText.replace(/\r/g, '').split(/\n/);
			var countries:Array = new Array();
			var country:XML = <Country/>;
			for each (var line:String in lines) {
				var m:Array = line.match(/^ (.*)\t(.*)\t(.*)$/);
				if (m != null) {
					var countryName:String = StringUtil.trim(m[1]);
					country = <Country/>;
					country.@name = countryName;
					countries.push({
						"name":countryName,
						"xml":country
					});
					ParseLine(country, m[3]);
				}
				else {
					ParseLine(country, line);
				}
			}
			countries = countries.sortOn("name", Array.CASEINSENSITIVE);

			_namesByCountry = <Countries/>;
			for each (var o:Object in countries) {
				_namesByCountry.appendChild(o.xml);
			}

			var names:Array = new Array();
			for each (var name:String in _names) {
				var offset:int = 0;
				var matches:Array = name.match(/^UTC([+-])(\d+)(:\d+)?$/);
				if (matches != null) {
					offset += Number(matches[2]) * 60;
					if (matches.length > 3 && matches[3] != null && matches[3].toString().length > 0) {
						offset += Number(matches[3].toString().substr(1));
					}
					if (matches[1].toString() == "-") {
						offset = offset * -1;
					}
				}
				names.push({
					"offset":offset,
					"name":name
				});
			}
			names.sortOn("offset", Array.NUMERIC);
			_names = new ArrayCollection(names);
		}

		private static function ParseLine(country:XML, s:String):void {
			s = StringUtil.trim(s);
			s = s.replace(/\s+/, ' ');
			if (s.match(/^See /) != null) {
				return;
			}
			var timezone:XML = <Timezone/>;
			var idxSpace:int = s.indexOf(" ");
			if (idxSpace == -1) {
				timezone.@name = s;
			}
			else {
				timezone.@name = s.substr(0, idxSpace);
				s = s.substr(idxSpace + 1);
				if (s.charAt(0) == '(') {
					var idxAlias:int = s.indexOf(')');
					timezone.@alias = s.substr(1, idxAlias - 1);
					s = s.substr(idxAlias + 2);
				}
				if (s.length > 2) {
					timezone.@locations = s.substr(2);
				}
			}
			var name:String = timezone.@name;
			if (!_names.contains(name)) {
				_names.addItem(name);
			}
			country.appendChild(timezone);
		}
		
		private static function ParseDateTime(s:String):Date {
			if (s == null || s.match(/^\s*$/) != null) {
				return null;
			}
			try {
				var dateTime:Array = s.split(/\s+|T/);
				var ymd:Date = DateParser.ParseYMD(dateTime[0].toString());
				if (ymd == null){
					return null;
				}
				var timeStr:String = dateTime[1].toString();
				var timeTokens:Array = timeStr.split(/:/);
				if (timeTokens.length == 3) {
					var year:Number = ymd.getFullYear();
					var month:Number = ymd.getMonth();
					var date:Number = ymd.getDate();
					var hour:Number = Number(timeTokens[0]);
					var minute:Number = Number(timeTokens[1]);
					var second:Number = Number(timeTokens[2]);
					return new Date(year, month, date, hour, minute, second);
				} else {
					return ymd;
				}
			}
			catch (error:Error) {}
			return null;
		}
	}
}