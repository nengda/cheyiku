package DTS.UI
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.ControlBar;
	import mx.core.Application;
	import mx.events.FlexEvent;
	import mx.managers.CursorManager;
	import mx.managers.CursorManagerPriority;

	// Must be used with DialogFixed or its subclasses
	public class ControlBarResizable extends ControlBar
	{
		[Embed(source="DialogAssets/leftObliqueSize.gif")]
		public static const LEFT_OBLIQUE_SIZE:Class;

		public static const SIDE_OTHER:Number = 0;
		public static const SIDE_TOP:Number = 1;
		public static const SIDE_BOTTOM:Number = 2;
		public static const SIDE_LEFT:Number = 4;
		public static const SIDE_RIGHT:Number = 8;

		private static var resizeObj:Object;
		private static var mouseState:Number = 0;
		private static var mouseMargin:Number = 10;

		private var oWidth:Number = 0;
		private var oHeight:Number = 0;
		private var oX:Number = 0;
		private var oY:Number = 0;
		private var oPoint:Point = new Point();

		private var _application:Application;
		private var _windowMinWidth:Number = 50;
		private var _windowMinHeight:Number = 50;

		public function set WindowMinWidth(value:Number):void {
			if (value > 0) {
				_windowMinWidth = value;
			}
		}

		public function get WindowMinWidth():Number{
			return _windowMinWidth;
		}

		public function set WindowMinHeight(value:Number):void {
			if (value > 0) {
				_windowMinHeight = value;
			}
		}

		public function get WindowMinHeight():Number{
			return _windowMinHeight;
		}

		public function ControlBarResizable() {
			super();
			this.addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
		}

		private function OnCreationComplete(event:FlexEvent):void {
			_application = Application.application as Application;
			InitPosition(this);

			this.addEventListener(MouseEvent.MOUSE_MOVE, OnMouseMove);
			this.addEventListener(MouseEvent.MOUSE_OUT, OnMouseOut);
			this.addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDown);

			_application.parent.addEventListener(MouseEvent.MOUSE_UP, OnMouseUp);
			_application.parent.addEventListener(MouseEvent.MOUSE_MOVE, OnResize);
		}

		public function EnsureVisible(margin:Object=null, now:Boolean=false):void {
			if (!now) {
				callLater(EnsureVisible, [margin, true]);
				return;
			}
			if (margin == null) {
				margin = {top: 20, bottom: 20, left: 20, right: 20};
			}
			if (parent.width > _application.width - margin.left - margin.right) {
				parent.width = _application.width - margin.left - margin.right;
			}
			if (parent.height > _application.height - margin.top - margin.bottom) {
				parent.height = _application.height - margin.top - margin.bottom;
			}
			if (parent.x < margin.left) {
				parent.x = margin.left;
			}
			if (parent.y < margin.top) {
				parent.y = margin.top;
			}
			if (parent.x + width > _application.width - margin.right) {
				parent.x = _application.width - margin.right - width;
			}
			if (parent.y + height > _application.height - margin.bottom) {
				parent.y = _application.height - margin.bottom - height;
			}
			EnsureMinSize();
		}

		private function EnsureMinSize(now:Boolean=false):void {
			if (!now) {
				callLater(EnsureMinSize, [true]);
				return;
			}
			var rect:Rectangle = parent.getRect(_application);
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
				var rect:Rectangle = getBounds(_application);
				if (xPosition >= (rect.x + rect.width - mouseMargin) && yPosition >= (rect.y + rect.height - mouseMargin)) {
					ChangeCursor(LEFT_OBLIQUE_SIZE, -6, -6);
					mouseState = SIDE_RIGHT | SIDE_BOTTOM;
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
				resizeObj.parent.stopDrag();
				var xPlus:Number = _application.parent.mouseX - resizeObj.oPoint.x;
				var yPlus:Number = _application.parent.mouseY - resizeObj.oPoint.y;
			    switch (mouseState) {
			    	case SIDE_RIGHT | SIDE_BOTTOM:
			    		resizeObj.parent.width = resizeObj.oWidth + xPlus > _windowMinWidth ? resizeObj.oWidth + xPlus : _windowMinWidth;
		    			resizeObj.parent.height = resizeObj.oHeight + yPlus > _windowMinHeight ? resizeObj.oHeight + yPlus : _windowMinHeight;
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
			obj.oHeight = obj.parent.height;
			obj.oWidth = obj.parent.width;
			obj.oX = obj.parent.x;
			obj.oY = obj.parent.y;
		}
	}
}