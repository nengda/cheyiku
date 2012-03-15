package DTS.UI
{
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Matrix;
    
    import mx.controls.Text;
    import mx.core.Application;
    import mx.effects.Fade;
    import mx.styles.CSSStyleDeclaration;
    import mx.styles.StyleManager;

	[Style(name="arrowFlip", type="Boolean", inherit="no")]
	[Style(name="arrowOffset", type="Number", inherit="no")]
	[Style(name="arrowPosition", type="String", enumeration="left,right,top,bottom", inherit="no")]
	[Style(name="arrowSize", type="Number", inherit="no")]
	[Style(name="backgroundAlpha", type="Number", inherit="no")]
	[Style(name="backgroundColor", type="uint", format="Color", inherit="no")]
	[Style(name="cornerRadius", type="Number", inherit="no")]
    public class Balloon extends Text
    {
    	private var _arrow:Sprite;
    	private var _balloon:Sprite;
    	private var _hideOnClick:Boolean = false;
    	private var _useDefaultShowEffect:Boolean = true;
    	private var _useDefaultHideEffect:Boolean = true;

		public function Balloon() {
			var style:CSSStyleDeclaration = StyleManager.getStyleDeclaration("Balloon");
			if (style == null) {
				style = new CSSStyleDeclaration("Balloon");
				StyleManager.setStyleDeclaration("Balloon", style, true);
			}
			if (style.defaultFactory == null) {
	        	style.defaultFactory = function():void {
	            	this.color = 0xFFFFFF;
	            	this.backgroundAlpha = 0.8;
	            	this.backgroundColor = Application.application.getStyle("themeColor");

	            	this.paddingLeft = 10;
	            	this.paddingRight = 10;
	            	this.paddingTop = 10;
	            	this.paddingBottom = 10;

	            	this.arrowFlip = false;
	            	this.arrowOffset = 10;
	            	this.arrowPosition = "bottom";
	            	this.arrowSize = 10;
	            	this.cornerRadius = 3;
	            };
	        }

	        var f:Array = filters;
			if (f == null) {
				f = new Array();
			}
			f.push(new BlurFilter(0, 0, 0));
			filters = f;

	        _arrow = new Sprite();
			addChild(_arrow);

			_balloon = new Sprite();
			addChild(_balloon);

			this.addEventListener(MouseEvent.CLICK, DefaultClickHandler);
        }

        override public function set visible(value:Boolean):void {
        	if (_useDefaultShowEffect) {
	        	var fadeIn:Fade = new Fade(this);
				fadeIn.alphaFrom = 0;
				fadeIn.alphaTo = getStyle("backgroundAlpha");
				fadeIn.duration = 500;
				setStyle("showEffect", fadeIn);
        	}
			if (_useDefaultHideEffect) {
				var fadeOut:Fade = new Fade(this);
				fadeOut.alphaFrom = getStyle("backgroundAlpha");
				fadeOut.alphaTo = 0;
				fadeOut.duration = 500;
				setStyle("hideEffect", fadeOut);
			}
        	super.visible = value;
        }

		public function get UseDefaultShowEffect():Boolean {
			return _useDefaultShowEffect;
		}

		public function set UseDefaultShowEffect(value:Boolean):void {
			_useDefaultShowEffect = value;
			setStyle("showEffect", null);
			visible = visible;
		}

		public function get UseDefaultHideEffect():Boolean {
			return _useDefaultHideEffect;
		}

		public function set UseDefaultHideEffect(value:Boolean):void {
			_useDefaultHideEffect = value;
			setStyle("hideEffect", null);
			visible = visible;
		}

		public function get HideOnClick():Boolean {
			return _hideOnClick;
		}

		public function set HideOnClick(value:Boolean):void {
			_hideOnClick = value;
		}

        private function DefaultClickHandler(event:MouseEvent=null):void {
        	if (_hideOnClick) {
        		visible = false;
        	}
        }

        override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
        	var backgroundAlpha:Number = getStyle("backgroundAlpha");
        	var backgroundColor:uint = getStyle("backgroundColor");
        	var arrowFlip:Boolean = getStyle("arrowFlip");
        	var arrowOffset:Number = getStyle("arrowOffset");
        	var arrowPosition:String = getStyle("arrowPosition") + ((arrowFlip) ? "_flip" : "");
        	var arrowSize:Number = getStyle("arrowSize");
        	var cornerRadius:Number = getStyle("cornerRadius");

			_arrow.graphics.clear();
			_arrow.graphics.beginFill(backgroundColor, backgroundAlpha);
			var arrowShape:String = "";
			switch (arrowPosition) {
				case "left":
					_arrow.x = -arrowSize;
					_arrow.y = arrowOffset;
					arrowShape = "bl";
					break;
				case "left_flip":
					_arrow.x = -arrowSize;
					_arrow.y = unscaledHeight - arrowOffset - arrowSize;
					arrowShape = "tl";
					break;
				case "right":
					_arrow.x = unscaledWidth;
					_arrow.y = arrowOffset;
					arrowShape = "br";
					break;
				case "right_flip":
					_arrow.x = unscaledWidth;
					_arrow.y = unscaledHeight - arrowOffset - arrowSize;
					arrowShape = "tr";
					break;
				case "top":
					_arrow.x = arrowOffset;
					_arrow.y = -arrowSize;
					arrowShape = "tr";
					break;
				case "top_flip":
					_arrow.x = unscaledWidth - arrowOffset - arrowSize;
					_arrow.y = -arrowSize;
					arrowShape = "tl";
					break;
				case "bottom":
					_arrow.x = arrowOffset;
					_arrow.y = unscaledHeight;
					arrowShape = "br";
					break;
				case "bottom_flip":
					_arrow.x = unscaledWidth - arrowOffset - arrowSize;
					_arrow.y = unscaledHeight;
					arrowShape = "bl";
					break;
			}

			switch (arrowShape) {
				case "tl":
					_arrow.graphics.moveTo(arrowSize, 0);
					_arrow.graphics.lineTo(arrowSize, arrowSize);
					_arrow.graphics.lineTo(0, arrowSize);
					_arrow.graphics.lineTo(arrowSize, 0);
					break;
				case "tr":
					_arrow.graphics.moveTo(0, 0);
					_arrow.graphics.lineTo(0, arrowSize);
					_arrow.graphics.lineTo(arrowSize, arrowSize);
					_arrow.graphics.lineTo(0, 0);
					break;
				case "bl":
					_arrow.graphics.moveTo(0, 0);
					_arrow.graphics.lineTo(arrowSize, 0);
					_arrow.graphics.lineTo(arrowSize, arrowSize);
					_arrow.graphics.lineTo(0, 0);
					break;
				case "br":
					_arrow.graphics.moveTo(0, 0);
					_arrow.graphics.lineTo(0, arrowSize);
					_arrow.graphics.lineTo(arrowSize, 0);
					_arrow.graphics.lineTo(0, 0);
					break;
			}

			_balloon.graphics.clear();
        	_balloon.graphics.beginFill(backgroundColor, backgroundAlpha);
			_balloon.graphics.drawRoundRect(0, 0, unscaledWidth, unscaledHeight, cornerRadius * 2);

			super.updateDisplayList(unscaledWidth, unscaledHeight);
        }
    }
}
