package DTS.UI
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.Application;
	import mx.managers.CursorManager;
	import mx.managers.CursorManagerPriority;

	public class Dialog extends DialogFixed
	{
		// Constants
		[Embed(source="DialogAssets/verticalSize.gif")]
		public static const VERTICAL_SIZE:Class;
		[Embed(source="DialogAssets/horizontalSize.gif")]
		public static const HORIZONTAL_SIZE:Class;
		[Embed(source="DialogAssets/leftObliqueSize.gif")]
		public static const LEFT_OBLIQUE_SIZE:Class;
		[Embed(source="DialogAssets/rightObliqueSize.gif")]
		public static const RIGHT_OBLIQUE_SIZE:Class;

		public static const SIDE_OTHER:Number = 0;
		public static const SIDE_TOP:Number = 1;
		public static const SIDE_BOTTOM:Number = 2;
		public static const SIDE_LEFT:Number = 4;
		public static const SIDE_RIGHT:Number = 8;

		// Private static variables
		private static var resizeObj:Object;
		private static var mouseState:Number = 0;
		private static var mouseMargin:Number = 10;

		// Private class members
		private var oWidth:Number = 0;
		private var oHeight:Number = 0;
		private var oX:Number = 0;
		private var oY:Number = 0;
		private var oPoint:Point = new Point();

		private var _application:Application;
		private var _windowMinWidth:Number = 50;
		private var _windowMinHeight:Number = 50;

		// Getters/Setters
		public function set WindowMinWidth(value:Number):void {
			if (value > 0) {
				_windowMinWidth = value;
				EnsureMinSize();
			}
		}

		public function get WindowMinWidth():Number {
			return _windowMinWidth;
		}

		public function set WindowMinHeight(value:Number):void {
			if (value > 0) {
				_windowMinHeight = value;
				EnsureMinSize();
			}
		}

		public function get WindowMinHeight():Number {
			return _windowMinHeight;
		}

		// Class methods
		public function Dialog() {
			super();
			_application = Application.application as Application;
			InitPosition(this);

			addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			addEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
			addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);

			_application.parent.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			_application.parent.addEventListener(MouseEvent.MOUSE_MOVE, OnResize);
		}

		public static function Open(className:Class, modal:Boolean=true, center:Boolean=true):Object {
			return DialogFixed.Open(className, modal, center);
		}

		public function EnsureVisible(margin:Object=null, now:Boolean=false):void {
			if (!now) {
				callLater(EnsureVisible, [margin, true]);
				return;
			}
			if (margin == null) {
				margin = {top: 20, bottom: 20, left: 20, right: 20};
			}
			if (width > _application.width - margin.left - margin.right) {
				width = _application.width - margin.left - margin.right;
			}
			if (height > _application.height - margin.top - margin.bottom) {
				height = _application.height - margin.top - margin.bottom;
			}
			if (x < margin.left) {
				x = margin.left;
			}
			if (y < margin.top) {
				y = margin.top;
			}
			if (x + width > _application.width - margin.right) {
				x = _application.width - margin.right - width;
			}
			if (y + height > _application.height - margin.bottom) {
				y = _application.height - margin.bottom - height;
			}
			EnsureMinSize();
		}

		private function EnsureMinSize(now:Boolean=false):void {
			if (!now) {
				callLater(EnsureMinSize, [true]);
				return;
			}
			var rect:Rectangle = getRect(_application);
			if (rect.width < _windowMinWidth) {
				width = _windowMinWidth;
			}
			if (rect.height < _windowMinHeight) {
				height = _windowMinHeight;
			}
		}

		private function OnMouseDown(event:MouseEvent):void {
			if (mouseState != SIDE_OTHER) {
				resizeObj = event.currentTarget;
				InitPosition(resizeObj);
				oPoint.x = resizeObj.mouseX;
				oPoint.y = resizeObj.mouseY;
				oPoint = this.localToGlobal(oPoint);
			}
		}

		private function OnMouseUp(event:MouseEvent):void {
			if (resizeObj != null) {
				InitPosition(resizeObj);
			}
			resizeObj = null;
		}

		private function OnMouseMove(event:MouseEvent):void {
			if (resizeObj == null) {
				var xPosition:Number = _application.parent.mouseX;
				var yPosition:Number = _application.parent.mouseY;
				if (xPosition >= (this.x + this.width - mouseMargin) && yPosition >= (this.y + this.height - mouseMargin)) {
					ChangeCursor(LEFT_OBLIQUE_SIZE, -6, -6);
					mouseState = SIDE_RIGHT | SIDE_BOTTOM;
				}
				else if (xPosition <= (this.x + mouseMargin) && yPosition <= (this.y + mouseMargin)) {
					ChangeCursor(LEFT_OBLIQUE_SIZE, -6, -6);
					mouseState = SIDE_LEFT | SIDE_TOP;
				}
				else if (xPosition <= (this.x + mouseMargin) && yPosition >= (this.y + this.height - mouseMargin)) {
					ChangeCursor(RIGHT_OBLIQUE_SIZE, -6, -6);
					mouseState = SIDE_LEFT | SIDE_BOTTOM;
				}
				else if (xPosition >= (this.x + this.width - mouseMargin) && yPosition <= (this.y + mouseMargin)) {
					ChangeCursor(RIGHT_OBLIQUE_SIZE, -6, -6);
					mouseState = SIDE_RIGHT | SIDE_TOP;
				}
				else if (xPosition >= (this.x + this.width - mouseMargin)) {
					ChangeCursor(HORIZONTAL_SIZE, -9, -9);
					mouseState = SIDE_RIGHT;	
				}
				else if (xPosition <= (this.x + mouseMargin)) {
					ChangeCursor(HORIZONTAL_SIZE, -9, -9);
					mouseState = SIDE_LEFT;
				}
				else if (yPosition >= (this.y + this.height - mouseMargin)) {
					ChangeCursor(VERTICAL_SIZE, -9, -9);
					mouseState = SIDE_BOTTOM;
				}
				else if (yPosition <= (this.y + mouseMargin)) {
					ChangeCursor(VERTICAL_SIZE, -9, -9);
					mouseState = SIDE_TOP;
				}
				else {
					mouseState = SIDE_OTHER;
					ChangeCursor(null, 0, 0);
				}
			}
		}

		private function OnMouseOut(event:MouseEvent):void {
			if (resizeObj == null) {
				ChangeCursor(null, 0, 0);
			}
		}

		private function OnResize(event:MouseEvent):void {
			if (resizeObj != null) {	
				resizeObj.stopDragging();
				var xPlus:Number = _application.parent.mouseX - resizeObj.oPoint.x;
				var yPlus:Number = _application.parent.mouseY - resizeObj.oPoint.y;
			    switch (mouseState) {
			    	case SIDE_RIGHT | SIDE_BOTTOM:
			    		resizeObj.width = resizeObj.oWidth + xPlus > _windowMinWidth ? resizeObj.oWidth + xPlus : _windowMinWidth;
		    			resizeObj.height = resizeObj.oHeight + yPlus > _windowMinHeight ? resizeObj.oHeight + yPlus : _windowMinHeight;
			    		break;
			    	case SIDE_LEFT | SIDE_TOP:
		    			resizeObj.x = xPlus < resizeObj.oWidth - _windowMinWidth ? resizeObj.oX + xPlus: resizeObj.x;
		    			resizeObj.y = yPlus < resizeObj.oHeight - _windowMinHeight ? resizeObj.oY + yPlus : resizeObj.y;
			    		resizeObj.width = resizeObj.oWidth - xPlus > _windowMinWidth ? resizeObj.oWidth - xPlus : _windowMinWidth;
		    			resizeObj.height = resizeObj.oHeight - yPlus > _windowMinHeight ? resizeObj.oHeight - yPlus : _windowMinHeight;
			    		break;
			    	case SIDE_LEFT | SIDE_BOTTOM:
			    		resizeObj.x = xPlus < resizeObj.oWidth - _windowMinWidth ? resizeObj.oX + xPlus: resizeObj.x;
			    		resizeObj.width = resizeObj.oWidth - xPlus > _windowMinWidth ? resizeObj.oWidth - xPlus : _windowMinWidth;
		    			resizeObj.height = resizeObj.oHeight + yPlus > _windowMinHeight ? resizeObj.oHeight + yPlus : _windowMinHeight;
			    		break;
			    	case SIDE_RIGHT | SIDE_TOP:
			    		resizeObj.y = yPlus < resizeObj.oHeight - _windowMinHeight ? resizeObj.oY + yPlus : resizeObj.y;
			    		resizeObj.width = resizeObj.oWidth + xPlus > _windowMinWidth ? resizeObj.oWidth + xPlus : _windowMinWidth;
		    			resizeObj.height = resizeObj.oHeight - yPlus > _windowMinHeight ? resizeObj.oHeight - yPlus : _windowMinHeight;
			    		break;
			    	case SIDE_RIGHT:
			    		resizeObj.width = resizeObj.oWidth + xPlus > _windowMinWidth ? resizeObj.oWidth + xPlus : _windowMinWidth;
			    		break;
			    	case SIDE_LEFT:
			    		resizeObj.x = xPlus < resizeObj.oWidth - _windowMinWidth ? resizeObj.oX + xPlus: resizeObj.x;
			    		resizeObj.width = resizeObj.oWidth - xPlus > _windowMinWidth ? resizeObj.oWidth - xPlus : _windowMinWidth;
			    		break;
			    	case SIDE_BOTTOM:
			    		resizeObj.height = resizeObj.oHeight + yPlus > _windowMinHeight ? resizeObj.oHeight + yPlus : _windowMinHeight;
			    		break;
			    	case SIDE_TOP:
			    		resizeObj.y = yPlus < resizeObj.oHeight - _windowMinHeight ? resizeObj.oY + yPlus : resizeObj.y;
			    		resizeObj.height = resizeObj.oHeight - yPlus > _windowMinHeight ? resizeObj.oHeight - yPlus : _windowMinHeight;
			    		break;
			    }
			}
		}

		// Private helper functions
		private static var _currentType:Class = null;
		private static function ChangeCursor(type:Class, xOffset:Number = 0, yOffset:Number = 0):void {
			if (_currentType != type) {
				_currentType = type;
				CursorManager.removeCursor(CursorManager.currentCursorID);
				if (type != null) {
					CursorManager.setCursor(type, CursorManagerPriority.MEDIUM, xOffset, yOffset);
				}
			}
		}

		private static function InitPosition(obj:Object):void {
			obj.oHeight = obj.height;
			obj.oWidth = obj.width;
			obj.oX = obj.x;
			obj.oY = obj.y;
		}
	}
}
