package DTS.Utilities
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.controls.AdvancedDataGrid;
	import mx.events.ListEvent;

	public class AdvancedDataGridDoubleClick
	{
		public static function OnItemDoubleClicked(dataGrid:AdvancedDataGrid, handler:Function):void {
			new AdvancedDataGridDoubleClick(dataGrid, handler);
		}

		private var _dataGrid:AdvancedDataGrid;
		private var _handler:Function;
		private var _timer:Timer;
		private var _lastItemClicked:Object = null;

		public function AdvancedDataGridDoubleClick(dataGrid:AdvancedDataGrid, handler:Function) {
			_dataGrid = dataGrid;
			_handler = handler;

			_timer = new Timer(500, 1);
			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, OnTimerComplete);

			_dataGrid.addEventListener(ListEvent.ITEM_CLICK, OnItemClicked);
		}

		private function OnItemClicked(event:ListEvent):void {
			if (_dataGrid.selectedItems.length == 1 && _lastItemClicked == event.itemRenderer.data) {
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