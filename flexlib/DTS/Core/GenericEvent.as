package DTS.Core
{
	import flash.events.Event;

	public class GenericEvent extends Event
	{
		private var _tag:Object;
		
		public function GenericEvent(type:String, tag:Object, bubbles:Boolean=false, cancelable:Boolean=false) {
			super(type, bubbles, cancelable);
			this._tag = tag;
		}
		
		public function Tag():Object {
			return this._tag;
		}
	}
}
