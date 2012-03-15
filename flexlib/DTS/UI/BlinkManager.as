package DTS.UI
{
	import DTS.Logger.LogWindow;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.core.UIComponent;

	public class BlinkManager
	{
		private static var _activeBlinkManagers:ArrayCollection = new ArrayCollection();

		private var _timer:Timer = null;
		private var _control:UIComponent = null;
		private var _stopCondition:Function = null;
		private var _callbackData:Object = null;
		private var _styleName:String = "";
		private var _originalStyle:Object = null;
		private var _toggle:Boolean = false;

		public function BlinkManager(control:UIComponent, stopCondition:Function, callbackData:Object=null) {
			for (var i:int = 0; i < _activeBlinkManagers.length; i++) {
				var bm:BlinkManager = _activeBlinkManagers[i] as BlinkManager;
				if (bm.Control == control) {
					bm.Stop();
					break;
				}
			}

			_control = control;
			_stopCondition = stopCondition;
			_callbackData = callbackData;

			var possibleStyleNames:Array = ["fillColors", "backgroundColor"];
			_styleName = possibleStyleNames[0];
			for (i = 0; i < possibleStyleNames.length; i++) {
				if (_control.getStyle(possibleStyleNames[i]) != undefined) {
					_styleName = possibleStyleNames[i];
					_originalStyle = _control.getStyle(_styleName);
				}
			}

			_control.addEventListener(MouseEvent.CLICK, function(event:Event):void {
				Stop();
//				_control.callLater(function():void {
//					_control.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
//				});
			});

			_control.addEventListener(Event.REMOVED_FROM_STAGE, function(event:Event):void {
				Stop();
			});

			_timer = new Timer(500);
			_timer.addEventListener("timer", OnTimerInterval);
			_timer.start();

			_activeBlinkManagers.addItem(this);
		}

		private function OnTimerInterval(event:TimerEvent):void {
			var stop:Boolean = false;
			if (_callbackData == null) {
				stop = _stopCondition(_control);
			}
			else {
				stop = _stopCondition(_control, _callbackData);
			}

			if (stop) {
				Stop();
				return;
			}

			try {
				_toggle = !_toggle;
				if (_toggle) {
					switch (_styleName) {
						case "backgroundColor":
							_control.setStyle(_styleName, 0xffdddd);
							break;
						case "fillColors":
							var fillColors:Array = _originalStyle as Array;
							_control.setStyle(_styleName, [fillColors[0], 0xffaaaa]);
							break;
					}
				}
				else {
					_control.setStyle(_styleName, _originalStyle);
				}
			}
			catch (error:Error) {
				LogWindow.Log("BlinkManager", "Error: " + error.message + "\n\n" + error.getStackTrace());
			}
		}

		public function Stop():void {
			var idx:int = _activeBlinkManagers.getItemIndex(this);
			if (idx != -1) {
				_activeBlinkManagers.removeItemAt(idx);
			}
			_timer.stop();
			_control.setStyle(_styleName, _originalStyle);
			return;
		}

		public function get Control():UIComponent {
			return _control;
		}
	}
}
