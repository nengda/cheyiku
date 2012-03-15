package DTS.UI
{
	import flash.events.MouseEvent;
	
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;

	public class Hyperlink extends LabelInternational
	{
		private var _textDecor:Object = null;

		public function Hyperlink() {
			super();
			addEventListener(MouseEvent.MOUSE_OVER, OnMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
		}

		private function OnMouseOver(event:MouseEvent):void {
			_textDecor = getStyle("textDecoration");
			setStyle("textDecoration", "underline");
		}

		private function OnMouseOut(event:MouseEvent):void {
			setStyle("textDecoration", _textDecor);
		}

		// Default Style
		private static var _defaultStyleSet:Boolean = SetDefaultStyle();
		private static function SetDefaultStyle():Boolean {
			if (!StyleManager.getStyleDeclaration("Hyperlink")) {
				var cssStyle:CSSStyleDeclaration = new CSSStyleDeclaration();
				cssStyle.defaultFactory = function():void {
					this.color = 0x0000ff;
				};
				StyleManager.setStyleDeclaration("Hyperlink", cssStyle, false);
			}
			return true;
		}
	}
}
