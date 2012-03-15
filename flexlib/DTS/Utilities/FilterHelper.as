package DTS.Utilities
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	public class FilterHelper
	{
		private var _control:DisplayObject;
		private var _eventFilters:Object;

		public static function SetFiltersForEvents(control:DisplayObject, eventFilters:Object):void {
			new FilterHelper(control, eventFilters);
		}

		public function FilterHelper(control:DisplayObject, eventFilters:Object) {
			_control = control;
			_eventFilters = eventFilters;
			for (var event:String in _eventFilters) {
				_control.addEventListener(event, EventHandler);
			}
		}

		private function EventHandler(event:Event):void {
			var filters:Array = _eventFilters[event.type];
			if (filters != null) {
				_control.filters = filters;
			}
		}
	}
}
