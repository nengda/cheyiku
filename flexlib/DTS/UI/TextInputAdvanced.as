package DTS.UI
{
	import DTS.Core.GenericEvent;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.controls.TextInput;
	import mx.core.EdgeMetrics;
	import mx.core.IRectangularBorder;
	import mx.core.UITextField;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;

	use namespace mx_internal;

	[Event(name="changeDelayed", type="DTS.Core.GenericEvent")]
	public class TextInputAdvanced extends TextInput
	{
		protected var _initialized:Boolean = false;
		protected var _hint:UITextField = null;
		protected var _timer:Timer;

		public function TextInputAdvanced() {
			super();

			_hint = new UITextField();
			_hint.setColor(0x999999);
			addChild(_hint);

			addEventListener(FlexEvent.CREATION_COMPLETE, OnCreationComplete);
			addEventListener(FocusEvent.FOCUS_IN, OnFocusIn);
			addEventListener(FocusEvent.FOCUS_OUT, OnFocusOut);
			addEventListener(Event.CHANGE, OnChange);

			_timer = new Timer(500, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void {
				dispatchEvent(new GenericEvent("changeDelayed", text));
			});
		}

		public function get Hint():String {
			return _hint.text;
		}

		public function set Hint(value:String):void {
			_hint.text = value;
		}

		override public function set text(value:String):void {
			super.text = value;
			OnFocusOut();
		}

		private function OnCreationComplete(event:Event=null):void {
			_initialized = true;
		}

		private function OnFocusIn(event:Event=null):void {
			_hint.visible = false;
		}

		private function OnFocusOut(event:Event=null):void {
			_hint.visible = (text == null || text.match(/^\s*$/) != null);
		}

		private function OnChange(event:Event=null):void {
			_timer.stop();
			_timer.start();
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			var bm:EdgeMetrics = EdgeMetrics.EMPTY;
			if (border != null && border is IRectangularBorder) {
				bm = IRectangularBorder(border).borderMetrics;
			}
			var paddingLeft:Number = getStyle("paddingLeft");
			var paddingRight:Number = getStyle("paddingRight");
			var paddingTop:Number = getStyle("paddingTop");
			var paddingBottom:Number = getStyle("paddingBottom");
			var widthPad:Number = bm.left + bm.right + paddingLeft + paddingRight;
			var heightPad:Number = bm.top + bm.bottom + paddingTop + paddingBottom + 1;

			_hint.x = bm.left + paddingLeft;
        	_hint.y = bm.top + paddingTop;
			_hint.width = Math.max(0, unscaledWidth - widthPad);
        	_hint.height = Math.max(0, unscaledHeight - heightPad);
		}
	}
}
