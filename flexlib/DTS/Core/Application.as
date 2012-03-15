package DTS.Core
{
	import DTS.UI.Colors;
	
	import mx.core.Application;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;

	public class Application extends mx.core.Application
	{
		public function Application() {
			super();

			layout = "absolute";

			var appCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("mx.core.Application");
			if (appCSS != null) {
				appCSS.setStyle("color", 0x333333);
				appCSS.setStyle("themeColor", Colors.THEME_COLOR);
				appCSS.setStyle("backgroundAlpha", 0);
				appCSS.setStyle("modalTransparencyColor", 0x999999);
				appCSS.setStyle("modalTransparencyBlur", 0);
			}

			var alertCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("mx.controls.Alert");
			if (alertCSS != null) {
				alertCSS.setStyle("backgroundColor", Colors.THEME_COLOR);
				alertCSS.setStyle("borderColor", Colors.THEME_COLOR);
			}

			var panelCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("mx.containers.Panel");
			if (panelCSS != null) {
				panelCSS.setStyle("color", 0x000000);
				panelCSS.setStyle("backgroundColor", 0xEEEEEE);
				panelCSS.setStyle("backgroundAlpha", 0.95);
				panelCSS.setStyle("borderColor", 0xEEEEEE);
				panelCSS.setStyle("borderAlpha", 0.95);
			}

			var titleWindowCSS:CSSStyleDeclaration = StyleManager.getStyleDeclaration("mx.containers.TitleWindow");
			if (titleWindowCSS != null) {
				titleWindowCSS.setStyle("color", 0x000000);
				titleWindowCSS.setStyle("backgroundColor", 0xEEEEEE);
				titleWindowCSS.setStyle("backgroundAlpha", 0.95);
				titleWindowCSS.setStyle("borderColor", 0xEEEEEE);
				titleWindowCSS.setStyle("borderAlpha", 0.95);
			}
		}
	}
}
