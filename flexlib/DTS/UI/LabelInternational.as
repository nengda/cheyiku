package DTS.UI
{
	import flash.text.Font;
	
	import mx.controls.Label;

	public class LabelInternational extends Label
	{
		private static const CHARACTER_CLASS_CJK:String = "CJK"; // Chinese, Japanese, and Korean
		private static const CHARACTER_CLASS_OTHER:String = "Other";

		private var _text:String;

		public function LabelInternational() {
			super();
		}

		override public function get text():String {
			return _text;
		}

		override public function set text(value:String):void {
			if (_text != value) {
				_text = value;
				if (_text != null) {
					htmlText = GetHTMLTextFromText(_text);
				}
				else {
					htmlText = "";
				}
			}
		}

		// Supporting methods

		private static var _characterClassMap:Object = [
			[[0x1100, 0x11FF], CHARACTER_CLASS_CJK],
			[[0x2E80, 0xD7AF], CHARACTER_CLASS_CJK],
			[[0xF900, 0xFAFF], CHARACTER_CLASS_CJK],
			[[0xFE30, 0xFE4F], CHARACTER_CLASS_CJK],
			[[0x20000, 0x2FA1F], CHARACTER_CLASS_CJK]
		];

		private static var _preferredFontStyle:Object = {};

		private static function GetCharacterClass(char:String):String {
			var charCode:uint = char.charCodeAt(0);
			for each (var characterClass:Array in _characterClassMap) {
				var range:Array = characterClass[0];
				if (charCode < range[0]) {
					break;
				}
				else if (charCode >= range[0] && charCode <= range[1]) {
					return characterClass[1];
				}
			}
			return CHARACTER_CLASS_OTHER;
		}

		private static function GetPreferredFontStyle(characterClass:String):Object {
			if (!_preferredFontStyle.hasOwnProperty(characterClass)) {
				var preferredFontStyleForSpecifiedClass:Object = null;
				switch (characterClass) {
					case CHARACTER_CLASS_CJK:
						var preferencesCJK:Array = [
							{ face: "新細明體", size: 12 }, // Chinese default font
							{ face: "굴림", size: 12 }, // Korean default font
							{ face: "MS UI Gothic", size: 12 } // Japanese default font
						];
						var deviceFonts:Array = Font.enumerateFonts(true);
						var deviceFontMap:Object = {};
						for each (var f:Font in deviceFonts) {
							deviceFontMap[f.fontName] = true;
						}
						for each (var preference:Object in preferencesCJK) {
							if (deviceFontMap.hasOwnProperty(preference.face)) {
								preferredFontStyleForSpecifiedClass = preference;
								break;
							}
						}
						break;
					default:
						break;
				}
				_preferredFontStyle[characterClass] = preferredFontStyleForSpecifiedClass;
			}
			return _preferredFontStyle[characterClass];
		}

		public static function GetHTMLTextFromText(text:String, escapeHtml:Boolean=true):String {
			var htmlText:String = "";
			var inFontTag:Boolean = false;
			var currentCharacterClass:String = CHARACTER_CLASS_OTHER;
			for (var i:int = 0; i < text.length; i++) {
				var char:String = text.charAt(i);
				var characterClass:String = GetCharacterClass(char);
				if (characterClass != currentCharacterClass) {
					if (inFontTag) {
						htmlText += "</font>";
						inFontTag = false;
					}
					var preferredStyle:Object = GetPreferredFontStyle(characterClass);
					if (preferredStyle != null) {
						var fontAttrs:String = "";
						for (var attr:String in preferredStyle) {
							fontAttrs += " " + attr + "=\"" + preferredStyle[attr] + "\"";
						}
						htmlText += "<font" + fontAttrs + ">";
						inFontTag = true;
					}
					currentCharacterClass = characterClass;
				}
				if (escapeHtml) {
					switch (char) {
						case ">":
							htmlText += "&gt;";
							break;
						case "<":
							htmlText += "&lt;";
							break;
						case "&":
							htmlText += "&amp;";
							break;
						default:
							htmlText += char;
							break;
					}
				}
				else {
					htmlText += char;
				}
			}
			return htmlText;
		}
	}
}
