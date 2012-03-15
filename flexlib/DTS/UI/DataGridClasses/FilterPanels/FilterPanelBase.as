package DTS.UI.DataGridClasses.FilterPanels
{
	import DTS.Core.GenericEvent;
	import DTS.UI.PopUpCanvas;

	[Event(name="FilterChanged", type="DTS.Core.GenericEvent")]
	public class FilterPanelBase extends PopUpCanvas
	{
		private var _opened:Boolean = false;

		public function FilterPanelBase() {
			super();
		}

		public function Filter(o:Object):Boolean {
			throw new Error("Not implemented");
		}

		public function get FilterValue():Object {
			throw new Error("Not implemented");
		}

		public function set FilterValue(value:Object):void {
			throw new Error("Not implemented");
		}

		public function get FilterEnabled():Boolean {
			throw new Error("Not implemented");
		}

		protected function FilterChanged():void {
			dispatchEvent(new GenericEvent("FilterChanged", null));
		}

		public function get Opened():Boolean {
			return _opened;
		}

		override public function Open(x:int, y:int, ensureVisible:Boolean=true):void {
			super.Open(x, y, ensureVisible);
			_opened = true;
		}

		override public function Close():void {
			super.Close();
			_opened = false;
		}
	}
}
