package DTS.UI.Skins
{
	import flash.geom.Rectangle;
	
	import mx.core.EdgeMetrics;
	import mx.core.UIComponent;
	import mx.skins.Border;
	import mx.styles.IStyleClient;

	public class UnderlineBorder extends Border
	{
		private var _borderMetrics:EdgeMetrics = new EdgeMetrics(0, 0, 0, 1);

		public function UnderlineBorder() {
			super();
		}

		override public function get borderMetrics():EdgeMetrics {
			return _borderMetrics;
		}

		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);

			var backgroundAlpha:Number = getStyle("backgroundAlpha");	
			var backgroundColor:Number = getStyle("backgroundColor");
			var borderColor:uint = getStyle("borderColor");
	
			graphics.clear();

			drawRoundRect(0, 0, w, h, 0, backgroundColor, backgroundAlpha);

			graphics.lineStyle(1, borderColor);
			graphics.moveTo(0, h - 1);
			graphics.lineTo(w, h - 1);
		}
	}
}
