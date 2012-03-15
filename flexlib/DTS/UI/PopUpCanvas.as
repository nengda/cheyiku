package DTS.UI
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.core.Application;
	import mx.effects.Fade;
	import mx.events.SandboxMouseEvent;
	import mx.managers.IFocusManagerComponent;
	import mx.managers.ISystemManager;
	import mx.managers.PopUpManager;

	public class PopUpCanvas extends Canvas implements IFocusManagerComponent
	{
		private static var _activePopUps:ArrayCollection = new ArrayCollection();

		private var _application:Application;
		private var _fadeIn:Fade;

		public function PopUpCanvas() {
			super();
			_application = Application.application as Application;
			filters = [new BlurFilter(0,0,0)];
			_fadeIn = new Fade();
			_fadeIn.alphaFrom = 0;
			_fadeIn.alphaTo = 1;
			_fadeIn.duration = 500;
			alpha = 0;
		}

		public function Open(x:int, y:int, ensureVisible:Boolean=true):void {
			for each (var activePopUp:PopUpCanvas in _activePopUps.toArray()) {
				activePopUp.Close();
			}

			PopUpManager.addPopUp(this, _application as DisplayObject, false);

			systemManager.activate(this);
			focusManager.setFocus(this);

			this.x = x;
			this.y = y;

			if (ensureVisible) {
				EnsureVisible();
			}
			callLater(function(canvas:PopUpCanvas):void {
				_fadeIn.play([canvas]);
			}, [this]);

			var sm:ISystemManager = systemManager.topLevelSystemManager;
        	var sbRoot:DisplayObject = sm.getSandboxRoot();
        	sbRoot.addEventListener(MouseEvent.MOUSE_DOWN, OnMouseDownOutside, false, 0, true);
        	addEventListener(SandboxMouseEvent.MOUSE_DOWN_SOMEWHERE, OnMouseDownOutside, false, 0, true);

        	_activePopUps.addItem(this);
		}

		public function EnsureVisible(margin:Object=null, now:Boolean=false):void {
			if (!now) {
				callLater(EnsureVisible, [margin, true]);
				return;
			}
			if (margin == null) {
				margin = {top: 0, bottom: 0, left: 0, right: 0};
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
		}

		public function Close():void {
			alpha = 0;
			PopUpManager.removePopUp(this);
			var sm:ISystemManager = systemManager.topLevelSystemManager;
        	var sbRoot:DisplayObject = sm.getSandboxRoot();
        	sbRoot.removeEventListener(MouseEvent.MOUSE_DOWN, OnMouseDownOutside);
			removeEventListener(SandboxMouseEvent.MOUSE_DOWN_SOMEWHERE, OnMouseDownOutside);
			var idx:int = _activePopUps.getItemIndex(this);
			if (idx != -1) {
				_activePopUps.removeItemAt(idx);
			}
		}

		private function OnMouseDownOutside(event:Event=null):void {
			if (event is MouseEvent) {
	            var mouseEvent:MouseEvent = MouseEvent(event);
	            if (!getBounds(_application as DisplayObject).contains(mouseEvent.stageX, mouseEvent.stageY)) {
	            	Close();
	            }
	        }
	        else if (event is SandboxMouseEvent) {
	            Close();
	        }
		}
	}
}