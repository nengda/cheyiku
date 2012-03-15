package DTS.Utilities
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.controls.listClasses.ListBase;
	import mx.events.ListEvent;

	public class ListDoubleClick
	{
		public static function OnItemDoubleClicked(list:ListBase, handler:Function):void {
			new ListDoubleClick(list, handler);
		}

		private var _list:ListBase;
		private var _handler:Function;
		private var _timer:Timer;
		private var _lastItemClicked:Object = null;

		public function ListDoubleClick(list:ListBase, handler:Function) {
			_list = list;
			_handler = handler;

			_timer = new Timer(500, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, OnTimerComplete);

			_list.addEventListener(ListEvent.ITEM_CLICK, OnItemClicked);
		}

		private function OnItemClicked(event:ListEvent):void {
			if (_list.selectedItems.length == 1 && _lastItemClicked == _list.selectedItem) {
				_handler(event.itemRenderer.data);
			}
			else {
				_lastItemClicked = event.itemRenderer.data;
				_timer.start();
			}
		}

		private function OnTimerComplete(event:TimerEvent):void {
			_lastItemClicked = null;
		}
	}
}