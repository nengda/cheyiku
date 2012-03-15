package DTS.UI.Skins
{
	import flash.display.DisplayObjectContainer;
	import flash.display.GradientType;
	import flash.geom.Rectangle;
	
	import mx.containers.TabNavigator;
	import mx.core.EdgeMetrics;
	import mx.core.UIComponent;
	import mx.skins.Border;
	import mx.skins.halo.HaloColors;
	import mx.styles.IStyleClient;
	import mx.styles.StyleManager;
	import mx.utils.ColorUtil;

	public class InvertedTabSkin extends Border
	{
		private var _borderMetrics:EdgeMetrics = new EdgeMetrics(1, 1, 1, 1);

		public function InvertedTabSkin() {
			super();
		}

		override public function get borderMetrics():EdgeMetrics {
			return _borderMetrics;
		}

		override public function get measuredWidth():Number {
			return UIComponent.DEFAULT_MEASURED_MIN_WIDTH;
		}

		override public function get measuredHeight():Number {
			return UIComponent.DEFAULT_MEASURED_MIN_HEIGHT;
		}

		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);

			var backgroundAlpha:Number = getStyle("backgroundAlpha");	
			var backgroundColor:Number = getStyle("backgroundColor");
			var borderColor:uint = getStyle("borderColor");
			var cornerRadius:Number = getStyle("cornerRadius");
			var fillAlphas:Array = getStyle("fillAlphas");
			var fillColors:Array = getStyle("fillColors");
			StyleManager.getColorNames(fillColors);
			var highlightAlphas:Array = getStyle("highlightAlphas");		
			var themeColor:uint = getStyle("themeColor");

			var falseFillColors:Array = [];
			falseFillColors[0] = ColorUtil.adjustBrightness2(fillColors[0], -5);
			falseFillColors[1] = ColorUtil.adjustBrightness2(fillColors[1], -5);

			var derStyles:Object = CalcDerivedStyles(themeColor, borderColor, falseFillColors[0], falseFillColors[1], fillColors[0], fillColors[1]);
			var parentedByTabNavigator:Boolean = parent != null && parent.parent != null && parent.parent.parent != null && parent.parent.parent is TabNavigator;
			var tabOffset:Number = 1;
			var drawBottomLine:Boolean = parentedByTabNavigator && IStyleClient(parent.parent.parent).getStyle("borderStyle") != "none" && tabOffset >= 0;
			var cornerRadius2:Number = Math.max(cornerRadius - 2, 0);

			if (parentedByTabNavigator) tabOffset = TabNavigator(parent.parent.parent).borderMetrics.bottom;
			var cr:Object = { tl: 0, tr: 0, bl: cornerRadius, br: cornerRadius };
			var cr2:Object = { tl: 0, tr: 0, bl: cornerRadius2, br: cornerRadius2 };
			var outerEdge:Rectangle = new Rectangle(0, 1, w, h - 1);	
			var bottomLine:Rectangle = new Rectangle(1, 0, w - 2, tabOffset);
			graphics.clear();
			
			switch (name) {
				case "upSkin":
	   				var upFillColors:Array = [ falseFillColors[0], falseFillColors[1] ];
					var upFillAlphas:Array = [ fillAlphas[0], fillAlphas[1] ];
					// outer edge
					drawRoundRect(outerEdge.x, outerEdge.y, outerEdge.width, outerEdge.height, cr, [ derStyles.borderColorDrk1, borderColor], 1, verticalGradientMatrix(0, 0, w, h), GradientType.LINEAR, null, { x: 1, y: 1, w: w - 2, h: h - 2, r: cr2 }); 
					// tab fill
					drawRoundRect(1, 1, w - 2, h - 2, cr2, upFillColors, upFillAlphas, verticalGradientMatrix(0, 2, w - 2, h - 6));
					// tab highlight
					drawRoundRect(1, 1, w - 2, (h - 2) / 2, cr2, [ 0xFFFFFF, 0xFFFFFF ], highlightAlphas, verticalGradientMatrix(1, 1, w - 2, (h - 2) / 2));
					// tab bottom line
					if (drawBottomLine) drawRoundRect(bottomLine.x, bottomLine.y, bottomLine.width, bottomLine.height, 0, borderColor, fillAlphas[1]);
					// tab shadow	
					drawRoundRect(0, h - 2, w, 1, 0, 0x000000, 0.09);
					drawRoundRect(0, h - 3, w, 1, 0, 0x000000, 0.03);
					break;
				case "overSkin":
					var overFillColors:Array;
					if (fillColors.length > 2)
						overFillColors = [ fillColors[2], fillColors[3] ];
					else
						overFillColors = [ fillColors[0], fillColors[1] ];

					var overFillAlphas:Array;
					if (fillAlphas.length > 2)
						overFillAlphas = [ fillAlphas[2], fillAlphas[3] ];
	  				else
						overFillAlphas = [ fillAlphas[0], fillAlphas[1] ];

					// outer edge
					drawRoundRect(outerEdge.x, outerEdge.y, outerEdge.width, outerEdge.height, cr, [ themeColor, derStyles.themeColDrk2 ], 1, verticalGradientMatrix(0, 0, w, h - 6), GradientType.LINEAR, null, { x: 1, y: 1, w: w - 2, h: h - 2, r: cr2 });
					// tab fill
					drawRoundRect(1, 1, w - 2, h - 2, cr2, [ derStyles.falseFillColorBright1, derStyles.falseFillColorBright2 ], overFillAlphas, verticalGradientMatrix(2, 2, w - 2, h - 2));
					// tab highlight
					drawRoundRect(1, 1, w - 2, (h - 2) / 2, cr2, [ 0xFFFFFF, 0xFFFFFF ], highlightAlphas, verticalGradientMatrix(1, 1, w - 2, (h - 2) / 2));
					// tab bottom line
					if (drawBottomLine) drawRoundRect(bottomLine.x, bottomLine.y, bottomLine.width, bottomLine.height, 0, borderColor, fillAlphas[1]);
					// tab shadow	
					drawRoundRect(0, h - 2, w, 1, 0, 0x000000, 0.09);
					drawRoundRect(0, h - 3, w, 1, 0, 0x000000, 0.03);
					break;
				case "disabledSkin":
	   				var disFillColors:Array = [ fillColors[0], fillColors[1] ];
	   				var disFillAlphas:Array =
						[ Math.max(0, fillAlphas[0] - 0.15),
						  Math.max(0, fillAlphas[1] - 0.15) ];
					// outer edge
					drawRoundRect(outerEdge.x, outerEdge.y, outerEdge.width, outerEdge.height, cr, [ derStyles.borderColorDrk1, borderColor], 0.5, verticalGradientMatrix(0, 0, w, h - 6));
					// tab fill
					drawRoundRect(1, 1, w - 2, h - 2, cr2, disFillColors, disFillAlphas, verticalGradientMatrix(0, 2, w - 2, h - 2));
					// tab bottom line
					if (drawBottomLine) drawRoundRect(bottomLine.x, bottomLine.y, bottomLine.width, bottomLine.height, 0, borderColor, fillAlphas[1]);
					// tab shadow	
					drawRoundRect(0, h - 2, w, 1, 0, 0x000000, 0.09);
					drawRoundRect(0, h - 3, w, 1, 0, 0x000000, 0.03);
					break;
				case "downSkin":
				case "selectedUpSkin":
				case "selectedDownSkin":
				case "selectedOverSkin":
				case "selectedDisabledSkin":
					if (isNaN(backgroundColor)) {
						// Walk the parent chain until we find a background color
						var p:DisplayObjectContainer = parent;
						while (p) {
							if (p is IStyleClient)
								backgroundColor = IStyleClient(p).getStyle("backgroundColor");
							if (!isNaN(backgroundColor))
								break;
							p = p.parent;
						}
						// Still no backgroundColor? Use white.
						if (isNaN(backgroundColor))
							backgroundColor = 0xFFFFFF;
					}
					// outer edge
					drawRoundRect(outerEdge.x, outerEdge.y, outerEdge.width, outerEdge.height, cr, [ derStyles.borderColorDrk1, borderColor], 1, verticalGradientMatrix(0, 0, w, h - 2), GradientType.LINEAR, null, { x: 1, y: 1, w: w - 2, h: h - 2, r: cr2 });
					// tab fill color
					drawRoundRect(1, 1, w - 2, h - 2, cr2, backgroundColor, backgroundAlpha);
					// tab bottom line
					if (drawBottomLine) drawRoundRect(bottomLine.x, bottomLine.y, bottomLine.width, bottomLine.height, 0, backgroundColor, backgroundAlpha);
					break;
			}
		}

		// Helper function
		private static var cache:Object = {};
		private static function CalcDerivedStyles(themeColor:uint, borderColor:uint, falseFillColor0:uint, falseFillColor1:uint, fillColor0:uint, fillColor1:uint):Object {
			var key:String = HaloColors.getCacheKey(themeColor, borderColor, falseFillColor0, falseFillColor1, fillColor0, fillColor1);
			if (!cache[key]) {
				var o:Object = cache[key] = {};
				HaloColors.addHaloColors(o, themeColor, fillColor0, fillColor1);
				o.borderColorDrk1 = ColorUtil.adjustBrightness2(borderColor, 10);
				o.falseFillColorBright1 = ColorUtil.adjustBrightness(falseFillColor0, 15);
				o.falseFillColorBright2 = ColorUtil.adjustBrightness(falseFillColor1, 15);
			}
			return cache[key];
		}
	}
}