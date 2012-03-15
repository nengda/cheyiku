package DTS.Utilities
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class Delay
	{
		public static function Call(callback:Function, callbackData:Object=null, delay:int=10):void {
			new Delay(callback, callbackData, delay);
		}

		private var _timer:Timer;
		private var _callback:Function;
		private var _data:Object;

		public function Delay(callback:Function, callbackData:Object, delay:int) {
			_callback = callback;
			_data = callbackData;
			_timer = new Timer(delay, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, OnTimerComplete);
			_timer.start();
		}

		private function OnTimerComplete(event:TimerEvent):void {
			_callback(_data);
		}
	}
}
